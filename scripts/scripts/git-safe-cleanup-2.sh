#!/bin/bash
MERGED_BRANCHES=$(gh pr list --repo spectinga/new-api --state closed -L 100 -A zopu --json headRefName | jq '.[].headRefName' | sed -e 's/^"//' -e 's/"$//' | sort)
echo "Merged branches:"
echo $MERGED_BRANCHES
