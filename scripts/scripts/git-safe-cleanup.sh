#!/bin/bash

# Fetch the latest changes from the remote repository, including the main branch
git fetch origin

# Set the main branch name
mainBranch="main"

# Ensure the local main branch is up to date
git checkout "$mainBranch"
git pull origin "$mainBranch"

# List all local branches
for branch in $(git branch --format "%(refname:short)"); do
	# Skip the main branch
	if [ "$branch" == "$mainBranch" ]; then
		continue
	fi

	# Use git cherry to find commits in the branch that are not in main
	# If the output is empty, all commits from the branch are in main
	if [ -z "$(git cherry "$mainBranch" "$branch")" ]; then
		echo "All commits from '$branch' are included in '$mainBranch'."
		read -p "Do you want to delete this branch? (y/n) " answer
		if [ "$answer" == "y" ]; then
			git branch -d "$branch"
			echo "Deleted branch '$branch'."
		fi
	else
		echo "Some commits from '$branch' are not included in '$mainBranch'."
	fi
done
