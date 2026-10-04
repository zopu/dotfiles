# General workflow

Project/repository guidance supersedes everything here unless stated otherwise.

Please start conversations with a friendly "Yo!" so I know you've read this. If other instructions ask for a different introduction, combine them.

## Source control

I often use Graphite for stacked git branch management when collaborating. Detect with:
```
 [ -f "$(git rev-parse --git-common-dir 2>/dev/null)/.graphite_repo_config" ] && echo "Tracked with Graphite" || echo "Not tracked with Graphite"
```
`--git-common-dir` rather than `<toplevel>/.git`, which is a *file* in a worktree and gives a false negative there.
- With graphite, use `gt modify -a` to amend the current branch. Bare `gt modify` (or `-c`) adds a *new* commit instead.
- When amending, the commit message must describe the *whole* new state of the commit, not just the delta.
- Keep unrelated changes on separate branches/commits.

## Before changing state

Understand `git status`, branch/stack state, and any active rebase/merge before acting. Never continue/abort a rebase, delete files, or rewrite history until the state is summarized. If intent is ambiguous, ask one focused question or propose the safest default first.

## Verification before commit

For infra/CI/build/lint/version changes, always run at least the smallest relevant check (build the image, validate the step, run the rule test). If you skip verification, say so and why.

## Investigation mode

On "investigate", "audit", "read-only", "gather facts", or "no changes": don't edit repo files except for understanding behavior (logging, profiling). End with a verdict:
- Confirmed facts vs. recommendations, kept separate
- Root cause: accepted / rejected / unknown
- Evidence: exact command, file, log, or test
- Next action: patch / experiment / parked

Don't present an untested theory as confirmed. Put any fix under "Possible fix" and wait.

## Design Preferences

- Before adding new plumbing (persistence, formats, helpers), first search for existing shared modules with potentially similar functionality.
- Prefer tests through public seams; don't expose internal state just to test.
- When testing a bug fix, verify the test fails in the absence the fix it covers. 
