---
name: restack
description: Safely diagnose and drive a git rebase or Graphite restack/sync that is paused mid-flight — usually stopped on a conflict. Use whenever a `git status` shows "rebase in progress", a `gt restack`/`gt sync`/`gt modify` halted on a conflict, the working tree has unmerged paths from a replay, or the user says things like "I'm in the middle of a rebase", "the restack got stuck", "help me finish this rebase", "resolve these conflicts and continue", or invokes `/restack`. Always reach for this before blindly running `git rebase --continue` or `gt continue`, because picking the wrong driver corrupts Graphite's stack metadata and picking the wrong conflict side silently drops work.
---

# restack

Take a repository that is paused in the middle of a rebase or a Graphite restack and bring it to a clean, correct state — without losing commits or desyncing Graphite's stack metadata.

The whole job is four moves: **diagnose** the exact paused state, **pick the right driver** (plain git vs. Graphite — they are not interchangeable here), **resolve each conflict by intent**, then **continue or abort** to a known-good state. Rushing straight to `--continue` is how work gets silently dropped, so slow down on diagnosis.

## 1. Diagnose before touching anything

Run these read-only checks first and read what they actually say — don't assume:

```bash
git status                              # confirms the operation + lists unmerged paths
git diff --name-only --diff-filter=U    # just the conflicted files
```

Then identify **which operation** is paused by what's on disk:

- `.git/rebase-merge/` exists → an interactive or merge-based rebase (this is also what Graphite uses under the hood).
- `.git/rebase-apply/` exists → an `am`/patch-based rebase (`git rebase` without `-i`).
- `.git/MERGE_HEAD` exists (and no rebase dir) → this is a paused **merge**, not a rebase. Different drivers: `git merge --continue` / `--abort`. Tell the user; the rest of this skill assumes a rebase.
- `.git/CHERRY_PICK_HEAD` or `.git/REVERT_HEAD` → a paused cherry-pick/revert. `git cherry-pick --continue` / `git revert --continue`.

For a rebase, see exactly where you are — this tells you the *intent* of the commit you're being asked to merge, which you need to resolve correctly:

```bash
git rebase --show-current-patch        # the commit currently being replayed (its message + diff)
cat .git/rebase-merge/done             # steps already applied
cat .git/rebase-merge/git-rebase-todo  # steps still remaining
```

A rebase can stop on several commits in turn, so expect to repeat the resolve→continue cycle more than once.

## 2. Pick the right driver: git vs. Graphite

This is the step people get wrong. If a **Graphite** command (`gt restack`, `gt sync`, `gt modify`, `gt reorder`, `gt move`) started the rebase, you must finish it with `gt continue` / `gt abort`. Driving it with `git rebase --continue` *will work mechanically* but leaves Graphite's stack metadata (parent/child relationships, branch tracking) stale — the next `gt` command then does something surprising. Conversely, `gt continue` only resumes operations Graphite itself halted.

Decide like this:

1. Is the repo Graphite-managed? Check `git rev-parse --git-dir`/`.graphite_repo_config` exists, or `gt ls` / `gt log` succeeds and shows the current branch tracked.
2. If yes → **default to `gt continue` / `gt abort`.** In a Graphite repo the paused rebase was almost certainly Graphite-initiated.
3. If `gt continue` reports there is no Graphite operation to resume, it was a raw `git rebase` — fall back to `git rebase --continue`.
4. If the repo isn't Graphite-managed at all → plain `git` only.

When unsure, prefer `gt continue` in a Graphite repo: it knows whether it owns the operation and refuses cleanly if it doesn't, whereas a stray `git rebase --continue` desyncs silently.

## 3. Resolve each conflict by intent, not by reflex

For every unmerged file, read the conflict and understand both sides before editing.

**Mind the rebase side-inversion.** During a rebase, `HEAD` is the branch you're landing *onto* (the new base / upstream), and the commit being replayed is "theirs". So:

- `<<<<<<< HEAD` / `ours` = the target branch's version.
- `>>>>>>> <sha>` / `theirs` = *your* commit's version being replayed.
- `git checkout --ours <f>` keeps the upstream version; `--theirs <f>` keeps your replayed change. This is the opposite of what "ours" feels like during a normal merge — slow down here.

Resolve by reconstructing the *intended* end state — usually a combination of both sides, not a blind pick of one. Pick a single side only when you're confident one fully supersedes the other. When the correct resolution depends on a genuine semantic/product decision you can't infer from the code, surface the specific choice to the user instead of guessing.

After editing, verify nothing is left dangling:

```bash
git diff --check                        # flags leftover conflict markers / whitespace errors
grep -rn '^<<<<<<<\|^=======\|^>>>>>>>' $(git diff --name-only --diff-filter=U)
```

Then stage the resolutions: `git add <resolved files>` (or `git add -A` once you've confirmed the set). Staging is what tells the rebase the step is resolved.

## 4. Continue, skip, or abort

- **Continue:** `gt continue` (Graphite) or `git rebase --continue` (plain). Repeat from step 3 for each further conflict until the tree is clean and the rebase reports done. `gt continue -a` / `git rebase --continue` can stage for you, but staging explicitly first keeps you in control of exactly what lands.
- **Empty commit:** if a replayed commit's changes are already present upstream, the step becomes empty and git says "no changes — did you forget `git add`? … or `git rebase --skip`". Only `--skip` (or let `gt continue` drop it) once you've *confirmed* the commit is genuinely redundant — don't skip just to make the error go away, or you'll drop real work. If the tree is empty because you accidentally resolved the change *out*, re-resolve instead.
- **Abort — the safe escape hatch:** `gt abort` / `git rebase --abort` restores the exact pre-operation state. Use it whenever you're unsure rather than pressing forward into a worse state. Note that aborting throws away any conflict resolutions done so far.

## 5. After it lands

- Rebasing rewrote history, so the branch has diverged from its remote. Push with `gt submit` (Graphite — it force-pushes the stack correctly and updates PR bases) or, for plain git, `git push --force-with-lease` (never bare `--force`: `--force-with-lease` refuses if the remote moved under you).
- If you had to drive a Graphite-initiated rebase with raw `git` for any reason, run `gt restack` / `gt sync` afterward so Graphite re-syncs its metadata.
- Run the project's build/tests before pushing — a clean rebase can still produce code that doesn't compile (e.g. two commits that each touched the same area in compatible-looking but incompatible ways).

## Footguns — don't

- **Don't `git commit` to finish a conflicted step.** That creates a stray commit and confuses the rebase. Stage and `--continue` instead.
- **Don't start a new rebase/sync** (`git rebase`, `gt sync`, `gt restack`) while one is in progress. Finish or abort the current one first.
- **Don't switch branches** (`git checkout` / `gt checkout`) mid-rebase. The detached/in-progress state needs to stay put.
- **Don't mix drivers** within one operation (some `gt continue`, some `git rebase --continue`). Pick one per the step-2 rule and stay consistent.

## Recovery if it goes wrong

History edits are recoverable. `git reflog` shows every prior tip — `git reset --hard <sha>` returns to one. `git rebase` also leaves the pre-rebase tip in `ORIG_HEAD`. In a Graphite repo, `gt undo` reverses the last Graphite mutation. Reach for these rather than improvising further edits on top of a confused state.
