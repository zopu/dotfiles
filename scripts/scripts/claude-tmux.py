#!/usr/bin/env uv run
# /// script
# requires-python = ">=3.12"
# dependencies = ["textual>=1.0.0"]
# ///
"""Find and interact with Claude Code instances running in tmux.

Subcommands:
  picker  - Interactive TUI to browse and switch to sessions (default)
  status  - Print a one-line-per-session summary to stdout

Usage:
  uv run scripts/scripts/claude-tmux.py [picker|status]
"""

import subprocess
import re
import os
import sys
from dataclasses import dataclass


@dataclass
class ClaudeTmuxSession:
    pid: int
    tmux_session: str
    tmux_window: str
    tmux_pane: str
    cwd: str
    status: str = "unknown"
    mode: str | None = None
    last_activity: str | None = None
    pending_edits: str | None = None


def run(cmd: list[str]) -> list[str]:
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return []
    return [line for line in r.stdout.strip().splitlines() if line]


def build_process_tree() -> dict[int, list[dict]]:
    """Build a full process tree (parent -> children) from a single ps call."""
    lines = run(["ps", "-eo", "pid,ppid,comm"])
    by_parent: dict[int, list[dict]] = {}
    for line in lines[1:]:
        parts = line.split(None, 2)
        if len(parts) == 3:
            pid, ppid, comm = int(parts[0]), int(parts[1]), parts[2]
            by_parent.setdefault(ppid, []).append({"pid": pid, "comm": comm})
    return by_parent


def walk_descendants(tree: dict[int, list[dict]], pid: int) -> list[dict]:
    """Walk descendants of a PID using a pre-built process tree."""
    result = []
    stack = [pid]
    while stack:
        current = stack.pop()
        for child in tree.get(current, []):
            result.append(child)
            stack.append(child["pid"])
    return result


def parse_claudecode_tmux_status(pane_id: str) -> dict:
    """Capture the pane scrollback and infer Claude Code's status."""
    lines = run(["tmux", "capture-pane", "-p", "-t", pane_id, "-S", "-30"])

    status = "unknown"
    last_activity = None
    mode = None
    pending_edits = None
    seen_separator = False

    for line in reversed(lines):
        stripped = line.strip()

        # Claude Code draws ─── separator lines around the input area.
        # Track these so we can distinguish the live input prompt from
        # a completed-turn prompt.
        if stripped and all(c == "─" for c in stripped):
            seen_separator = True
            continue

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
            am = re.match(r"\s*[✻✽]\s+(.+)", stripped)
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

        # Prompt line (❯). Claude uses non-breaking space (\xa0) after ❯.
        # Skip the empty ❯ inside the input area (between separator lines) —
        # that's the live input prompt, not a sign of idleness.
        if stripped == "❯" or stripped.startswith(("❯ ", "❯\xa0")):
            if seen_separator and stripped == "❯":
                # Empty prompt between separators = active input area, skip it
                seen_separator = False
                continue
            if status == "unknown":
                status = "idle"
            break

    return {
        "status": status,
        "mode": mode,
        "last_activity": last_activity,
        "pending_edits": pending_edits,
    }


def find_claude_tmux_sessions() -> list[ClaudeTmuxSession]:
    """Find all Claude Code instances in tmux panes."""
    pane_fmt = (
        "#{session_name}\t#{window_name}\t#{pane_id}\t#{pane_pid}\t#{pane_current_path}"
    )
    lines = run(["tmux", "list-panes", "-a", "-F", pane_fmt])
    tree = build_process_tree()

    sessions = []
    for line in lines:
        parts = line.split("\t")
        if len(parts) != 5:
            continue
        session_name, window_name, pane_id, pane_pid, pane_cwd = parts

        for proc in walk_descendants(tree, int(pane_pid)):
            if re.search(r"\bclaude$", proc["comm"]):
                status_info = parse_claudecode_tmux_status(pane_id)
                sessions.append(
                    ClaudeTmuxSession(
                        pid=proc["pid"],
                        tmux_session=session_name,
                        tmux_window=window_name,
                        tmux_pane=pane_id,
                        cwd=pane_cwd,
                        **status_info,
                    )
                )
    return sessions


def shorten_path(path: str) -> str:
    home = os.path.expanduser("~")
    if path.startswith(home):
        path = "~" + path[len(home):]
    return path


def status_display(session: ClaudeTmuxSession) -> str:
    s = session.status.upper()
    if session.mode:
        s += f" ({session.mode})"
    return s


def cmd_status() -> None:
    sessions = find_claude_tmux_sessions()
    if not sessions:
        print("No Claude Code instances found in tmux.")
        return

    for s in sessions:
        parts = [
            f"{s.tmux_session}:{s.tmux_window}",
            status_display(s),
            shorten_path(s.cwd),
        ]
        if s.last_activity:
            parts.append(s.last_activity)
        print("  ".join(parts))


def cmd_picker() -> None:
    from textual.app import App, ComposeResult
    from textual.widgets import DataTable, Header, Footer
    from textual.binding import Binding

    class ClaudeTmuxPicker(App):
        CSS = """
        DataTable {
            height: 1fr;
        }
        """

        BINDINGS = [
            Binding("q", "quit", "Quit"),
            Binding("escape", "quit", "Quit", show=False),
            Binding("r", "refresh", "Refresh"),
        ]

        TITLE = "Claude Code Sessions"

        def __init__(self):
            super().__init__()
            self._sessions: list[ClaudeTmuxSession] = []

        def compose(self) -> ComposeResult:
            yield Header()
            yield DataTable(cursor_type="row")
            yield Footer()

        def on_mount(self) -> None:
            self._load_sessions()

        def _load_sessions(self) -> None:
            table = self.query_one(DataTable)
            table.clear(columns=True)
            table.add_columns("Session", "Window", "Status", "CWD", "Activity")

            self._sessions = find_claude_tmux_sessions()

            if not self._sessions:
                table.add_row("No sessions found", "", "", "", "")
                return

            for s in self._sessions:
                table.add_row(
                    s.tmux_session,
                    s.tmux_window,
                    status_display(s),
                    shorten_path(s.cwd),
                    s.last_activity or "",
                )

        def on_data_table_row_selected(self, event: DataTable.RowSelected) -> None:
            if not self._sessions:
                return
            idx = event.cursor_row
            if idx < 0 or idx >= len(self._sessions):
                return
            session = self._sessions[idx]
            subprocess.run(
                ["tmux", "switch-client", "-t", session.tmux_pane],
                capture_output=True,
            )
            subprocess.run(
                ["tmux", "select-pane", "-t", session.tmux_pane],
                capture_output=True,
            )
            self.exit()

        def action_refresh(self) -> None:
            self._load_sessions()

    ClaudeTmuxPicker().run()


def main() -> None:
    subcmd = sys.argv[1] if len(sys.argv) > 1 else "picker"

    match subcmd:
        case "picker":
            cmd_picker()
        case "status":
            cmd_status()
        case _:
            print(f"Unknown subcommand: {subcmd}")
            print("Usage: claude-tmux.py [picker|status]")
            sys.exit(1)


if __name__ == "__main__":
    main()
