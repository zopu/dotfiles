import subprocess
import json
import os
import sys

def get_config():
    """Get repo and user from command line args"""
    if len(sys.argv) != 3:
        print("Usage: python git-safe-cleanup.py <repo> <username>")
        print("Example: python git-safe-cleanup.py owner/repo-name username")
        sys.exit(1)
    
    return sys.argv[1], sys.argv[2]


def get_merged_branches(github_repo, github_user):
    try:
        result = subprocess.run(
            [
                "gh",
                "pr",
                "list",
                "--repo",
                github_repo,
                "--state",
                "closed",
                "-L",
                "500",
                "-A",
                github_user,
                "--json",
                "headRefName,mergedAt",
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        prs = json.loads(result.stdout)
        merged_branches = [
            [pr["headRefName"], pr["mergedAt"]] for pr in prs if pr["mergedAt"]
        ]
        return merged_branches
    except subprocess.CalledProcessError as e:
        print(f"Failed to get merged branches: {e}")
        return []


def get_git_branch_names():
    try:
        result = subprocess.run(
            ["git", "branch", "--list", "--format=%(refname:short)"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.splitlines()
    except subprocess.CalledProcessError as e:
        print(f"Failed to get git branch names: {e}")
        return []


def get_worktrees():
    """Get a dict mapping branch names to their worktree paths."""
    try:
        result = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            capture_output=True,
            text=True,
            check=True,
        )
        worktrees = {}
        current_path = None
        for line in result.stdout.splitlines():
            if line.startswith("worktree "):
                current_path = line[9:]
            elif line.startswith("branch refs/heads/"):
                branch = line[18:]
                if current_path:
                    worktrees[branch] = current_path
                current_path = None
        return worktrees
    except subprocess.CalledProcessError as e:
        print(f"Failed to get worktrees: {e}")
        return {}


def has_changes_vs_main(branch):
    """Check if a branch has any changes compared to main."""
    try:
        result = subprocess.run(
            ["git", "diff", "--quiet", "main..." + branch],
            capture_output=True,
        )
        # Exit code 0 means no diff (identical to main)
        return result.returncode != 0
    except subprocess.CalledProcessError:
        return True  # Assume changes if we can't check


def get_branches_with_no_changes(branches, merged_branch_names):
    """Find branches that have no changes vs main and aren't already in merged list."""
    no_change_branches = []
    for branch in branches:
        if branch == "main" or branch == "master":
            continue
        if branch in merged_branch_names:
            continue
        if not has_changes_vs_main(branch):
            no_change_branches.append(branch)
    return no_change_branches


def get_user_confirmation(msg):
    while True:
        user_input = input(msg).strip().lower()
        if user_input in ("y", "n"):
            return user_input
        else:
            print("Invalid input. Please enter 'y' or 'n'.")


def delete_branch(branch):
    print("Deleting branch " + branch)
    try:
        subprocess.run(["git", "branch", "-D", branch], check=True)
        print("Branch deleted.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to delete branch {branch}: {e}")


def delete_worktree(path):
    print("Deleting worktree " + path)
    try:
        subprocess.run(["git", "worktree", "remove", path], check=True)
        print("Worktree deleted.")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to delete worktree {path}: {e}")
        return False


github_repo, github_user = get_config()
mb = get_merged_branches(github_repo, github_user)
branches = get_git_branch_names()
worktrees = get_worktrees()
merged_branch_names = [branch for [branch, _] in mb]

# Clean up merged branches
print("=== Merged branches ===\n")
merged_found = False
for [branch, merged_at] in mb:
    has_worktree = branch in worktrees
    has_branch = branch in branches
    if not has_branch and not has_worktree:
        continue
    merged_found = True
    print("Branch " + branch + " was merged at " + merged_at)
    if has_worktree:
        print("...worktree exists at " + worktrees[branch])
    if has_branch:
        print("...branch exists.")
    if "y" == get_user_confirmation("Delete worktree and/or branch? (y/n) "):
        if has_worktree:
            if not delete_worktree(worktrees[branch]):
                print("Skipping branch deletion since worktree removal failed.")
                continue
        if has_branch:
            delete_branch(branch)
if not merged_found:
    print("No merged branches to clean up.")

# Clean up branches with no changes vs main
print("\n=== Branches with no changes vs main ===\n")
no_change_branches = get_branches_with_no_changes(branches, merged_branch_names)
no_change_found = False
for branch in no_change_branches:
    has_worktree = branch in worktrees
    has_branch = branch in branches
    if not has_branch and not has_worktree:
        continue
    no_change_found = True
    print("Branch " + branch + " has no changes vs main")
    if has_worktree:
        print("...worktree exists at " + worktrees[branch])
    if has_branch:
        print("...branch exists.")
    if "y" == get_user_confirmation("Delete worktree and/or branch? (y/n) "):
        if has_worktree:
            if not delete_worktree(worktrees[branch]):
                print("Skipping branch deletion since worktree removal failed.")
                continue
        if has_branch:
            delete_branch(branch)
if not no_change_found:
    print("No branches with no changes vs main.")
