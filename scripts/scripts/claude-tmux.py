#!/usr/bin/env uv run
"""Find all Claude Code instances running in tmux and display summary info.

Inspired by sidekick.nvim's approach: enumerate tmux panes, walk process
trees to find `claude` processes, then capture pane scrollback to infer status.
"""

import subprocess
import re
import sys


def run(cmd: list[str], stdin: str | None = None) -> list[str]:
    r = subprocess.run(cmd, capture_output=True, text=True, input=stdin)
    if r.returncode != 0:
        return []
    return [l for l in r.stdout.strip().splitlines() if l]


def get_process_children(ppid: int) -> list[dict]:
    """Get child processes of a given PID."""
    lines = run(["ps", "-o", "pid,comm", "-p", str(ppid)])
    # ps includes a header line
    children = []
    for line in lines[1:]:
        parts = line.split(None, 1)
        if len(parts) == 2:
            children.append({"pid": int(parts[0]), "comm": parts[1]})
    return children


def walk_process_descendants(pid: int) -> list[dict]:
    """Walk the full process tree under a PID, return all descendants."""
    lines = run(["ps", "-eo", "pid,ppid,comm"])
    if not lines:
        return []

    by_parent: dict[int, list[dict]] = {}
    for line in lines[1:]:
        parts = line.split(None, 2)
        if len(parts) == 3:
            p, pp, comm = int(parts[0]), int(parts[1]), parts[2]
            by_parent.setdefault(pp, []).append({"pid": p, "ppid": pp, "comm": comm})

    result = []
    stack = [pid]
    while stack:
        current = stack.pop()
        for child in by_parent.get(current, []):
            result.append(child)
            stack.append(child["pid"])
    return result


def get_cwd(pid: int) -> str | None:
    """Get working directory of a process via lsof."""
    lines = run(["lsof", "-p", str(pid), "-a", "-d", "cwd", "-Fn"])
    for line in lines:
        if line.startswith("n"):
            return line[1:]
    return None


def get_process_elapsed(pid: int) -> str | None:
    """Get elapsed time of a process."""
    lines = run(["ps", "-o", "etime=", "-p", str(pid)])
    return lines[0].strip() if lines else None


def parse_claudecode_tmux_status(pane_id: str) -> dict:
    """Capture the pane scrollback and infer Claude Code's status."""
    lines = run(["tmux", "capture-pane", "-p", "-t", pane_id, "-S", "-30"])

    status = "unknown"
    last_activity = None
    mode = None
    pending_edits = None

    for line in reversed(lines):
        stripped = line.strip()

        # Mode/status bar line (always near the bottom)
        if mode is None:
            m = re.search(r"--\s+(\w+)\s+--", stripped)
            if m:
                mode = m.group(1).lower()

            # Check for pending edits
            em = re.search(r"(\d+)\s+files?\s+\+(\d+)\s+-(\d+)", stripped)
            if em:
                pending_edits = f"{em.group(1)} files (+{em.group(2)} -{em.group(3)})"

        # Activity indicators
        if last_activity is None:
            # Spinner line: "✻ Moonwalking…" (active) vs "✻ Cooked for 2m 8s" (done)
            am = re.match(r"\s*✻\s+(.+)", stripped)
            if am:
                activity = am.group(1)
                last_activity = activity
                # Past-tense verb + "for <duration>" = completed, not busy
                if not re.match(r"\w+ed\s+for\s+", activity):
                    status = "busy"
                continue

            # Tool use: "⏺ Bash(...)" or "⏺ Read(...)" etc.
            tm = re.match(r"\s*⏺\s+(\w+)\(", stripped)
            if tm:
                last_activity = stripped.lstrip().removeprefix("⏺ ")
                status = "busy"
                continue

        # Prompt line means claude is idle and waiting for input
        if stripped == "❯" or stripped.startswith("❯ "):
            if status == "unknown":
                status = "idle"

    return {
        "status": status,
        "mode": mode,
        "last_activity": last_activity,
        "pending_edits": pending_edits,
    }


def find_claude_tmux_sessions() -> list[dict]:
    """Find all Claude Code instances in tmux panes."""
    pane_fmt = (
        "#{session_name}\t#{window_name}\t#{pane_id}\t#{pane_pid}\t#{pane_current_path}"
    )
    lines = run(["tmux", "list-panes", "-a", "-F", pane_fmt])

    sessions = []
    for line in lines:
        parts = line.split("\t")
        if len(parts) != 5:
            continue
        session_name, window_name, pane_id, pane_pid, pane_cwd = parts
        pane_pid = int(pane_pid)

        # Walk the process tree under this pane to find claude
        descendants = walk_process_descendants(pane_pid)
        for proc in descendants:
            # Match the word "claude" but not "Claude.app" (desktop app)
            if re.search(r"\bclaude$", proc["comm"]):
                cwd = get_cwd(proc["pid"]) or pane_cwd
                elapsed = get_process_elapsed(proc["pid"])
                status_info = parse_claudecode_tmux_status(pane_id)

                sessions.append(
                    {
                        "pid": proc["pid"],
                        "tmux_session": session_name,
                        "tmux_window": window_name,
                        "tmux_pane": pane_id,
                        "cwd": cwd,
                        "elapsed": elapsed,
                        **status_info,
                    }
                )
    return sessions


def main():
    sessions = find_claude_tmux_sessions()

    if not sessions:
        print("No Claude Code instances found in tmux.")
        sys.exit(0)

    print(f"Found {len(sessions)} Claude Code instance(s) in tmux:\n")

    for i, s in enumerate(sessions, 1):
        print(f"  [{i}] {s['tmux_session']}:{s['tmux_window']} ({s['tmux_pane']})")
        print(f"      PID:     {s['pid']}")
        print(f"      CWD:     {s['cwd']}")
        print(f"      Uptime:  {s['elapsed'] or '?'}")
        print(f"      Status:  {s['status']}", end="")
        if s.get("mode"):
            print(f" ({s['mode']} mode)", end="")
        print()
        if s.get("last_activity"):
            print(f"      Activity: {s['last_activity']}")
        if s.get("pending_edits"):
            print(f"      Edits:   {s['pending_edits']}")
        print()


if __name__ == "__main__":
    main()
