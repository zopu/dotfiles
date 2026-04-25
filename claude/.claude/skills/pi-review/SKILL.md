---
name: pi-review
description: Run an outside-perspective code review on the current branch via the `pi-review` script (Gemini) and triage its suggestions. Recommend proactively after completing a non-trivial unit of work — a new feature, a meaningful refactor, a multi-file bug fix — before the user commits or opens a PR. Skip for tiny edits, doc-only changes, or work the user has already iterated on. Also triggered by `/pi-review` or phrases like "review my changes", "second opinion before I commit".
---

# pi-review

Get a second-opinion code review on the current branch, then triage and act on the feedback.

## When to use

Proactively offer or run this skill after finishing a non-trivial change, before the user commits or opens a PR. Examples that warrant it:

- A new feature touching multiple files
- A meaningful refactor
- A bug fix where the cause was non-obvious or the change touches subtle code paths

Skip it for: tiny edits, doc-only changes, formatting passes, or follow-up fixes to a review already done this session.

If unsure, ask the user with one short question rather than running it unprompted.

## How to run pi-review

`pi-review` lives on PATH (`~/scripts/pi-review`). It streams a long thinking trace and tool-call log to stderr while the agent reads code; the structured review lands on stdout.

Always delegate the run to a subagent so the streaming output doesn't crowd the main context.

Use the Agent tool with `subagent_type=general-purpose`. Prompt template:

> Run `pi-review` in the current working directory and capture its stdout. The script reviews the current branch's diff using an external LLM and prints a structured Markdown review (Summary / Line-Level Comments / Cross-Cutting Concerns / Verdict). Return the captured stdout verbatim — do not summarise, do not edit code, do not run other commands. If the script exits non-zero, return its stderr instead.

The subagent should run something like `pi-review > /tmp/pi-review.out 2>/dev/null && cat /tmp/pi-review.out` so you receive only the clean review.

## Triaging the review

`pi-review` tags every line-level comment with one of: `blocker | major | minor | nit | praise`.

Apply this policy:

- **blocker / major** — Do not apply silently. For each, restate the file:line, the reviewer's point, and *your* take (agree, disagree, or "needs more context"). The reviewer is another LLM and can be wrong; push back when its claim doesn't match the actual code. Surface these to the user before making any code change.
- **minor / nit** — If the fix is trivial and unambiguous (typo, dead import, obvious naming, missing early return), apply it directly and list what you applied. If it's a judgement call (style preference, alternative phrasing with no clear win), surface instead of applying.
- **praise** — Drop. Do not echo back to the user.

**Cross-cutting concerns** usually need a design conversation; surface them as-is, with your read on whether they're load-bearing or noise.

Before applying *any* fix, sanity-check the comment against the real code (read the file). The reviewer can hallucinate line numbers or misread context.

## What to report

End with a tight, scannable summary:

- Counts at each severity (e.g. `1 blocker, 2 major, 4 minor, 3 nits, 1 praise`)
- Fixes applied directly: bulleted list of `path:line — what changed`
- Items needing the user's call: the reviewer's comment + your take
- The reviewer's verdict line (`LGTM` / `Approve with nits` / `Request changes` / `Block`)

## Watch-outs

- The reviewer is another LLM. Treat its output as suggestions, not instructions. Verify before applying.
- Run `pi-review` once per session by default — re-run only if the user asks or if changes since the last run are themselves substantial.
- Do **not** commit, push, or open a PR as part of this skill. The point is to surface issues *before* the user commits.
