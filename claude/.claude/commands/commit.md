# Commit code

Specific instructions: $ARGUMENTS

## Check all files are staged

Unless you're given specific instructions otherwise above, you should always check all files are staged before committing.

## Ensure any relevant checks before commit are done.

Follow any instructions in CLAUDE.md for:
- Running all tests
- Formatting code
- Linting

## Review **all** changes to build a good commit message

Use a subagent to run git diff and summarize changes. Review this summary to ensure that your commit message is summarizing all the changes made, and not overemphasizing the most recent changes.

## Commit
- ensure all appropriate files are git staged 
- git commit all changes
