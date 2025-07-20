import subprocess
import json
import os

GITHUB_REPO = "spectinga/new-api"


def get_merged_branches():
    try:
        result = subprocess.run(
            [
                "gh",
                "pr",
                "list",
                "--repo",
                GITHUB_REPO,
                "--state",
                "closed",
                "-L",
                "500",
                "-A",
                "zopu",
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


def get_folder_names():
    try:
        result = subprocess.run(
            ["ls"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.splitlines()
    except subprocess.CalledProcessError as e:
        print(f"Failed to get folder names: {e}")
        return []


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


def delete_worktree(branch):
    print("Deleting worktree " + branch)
    try:
        subprocess.run(["git", "worktree", "remove", branch], check=True)
        print("Worktree deleted.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to delete worktree {branch}: {e}")


mb = get_merged_branches()
branches = get_git_branch_names()
folders = get_folder_names()

for [branch, merged_at] in mb:
    if branch not in branches and branch not in folders:
        continue
    print("Branch " + branch + " was merged at " + merged_at)
    if branch in folders:
        print("...worktree exists.")
    if branch in branches:
        print("...branch exists.")
    if "y" == get_user_confirmation("Delete worktree and/or branch? (y/n)"):
        if branch in folders:
            delete_worktree(branch)
        if branch in branches:
            delete_branch(branch)
