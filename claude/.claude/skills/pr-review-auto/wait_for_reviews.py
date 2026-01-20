#!/usr/bin/env python3
"""Wait for AI reviews on a GitHub PR."""
import argparse
import json
import subprocess
import sys
import time


def get_review_comments(repo: str, pr_number: int) -> list:
    """Fetch review comments from GitHub API."""
    result = subprocess.run(
        ["gh", "api", f"repos/{repo}/pulls/{pr_number}/comments", "--paginate"],
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout) if result.returncode == 0 else []


def get_reviews(repo: str, pr_number: int) -> list:
    """Fetch reviews from GitHub API."""
    result = subprocess.run(
        ["gh", "api", f"repos/{repo}/pulls/{pr_number}/reviews", "--paginate"],
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout) if result.returncode == 0 else []


def main():
    parser = argparse.ArgumentParser(description="Wait for AI reviews on a GitHub PR")
    parser.add_argument("repo", help="Repository in owner/repo format")
    parser.add_argument("pr_number", type=int, help="PR number")
    parser.add_argument(
        "--timeout", type=int, default=900, help="Max wait time in seconds (default: 900)"
    )
    parser.add_argument(
        "--interval", type=int, default=300, help="Poll interval in seconds (default: 300)"
    )
    args = parser.parse_args()

    start = time.time()
    check_num = 0

    while time.time() - start < args.timeout:
        check_num += 1
        comments = get_review_comments(args.repo, args.pr_number)
        reviews = get_reviews(args.repo, args.pr_number)

        if comments or reviews:
            print(json.dumps({"status": "found", "comments": comments, "reviews": reviews}))
            return 0

        elapsed = int(time.time() - start)
        remaining = args.timeout - elapsed
        print(
            f"Check {check_num}: No reviews yet. Waited {elapsed}s, {remaining}s remaining. "
            f"Next check in {min(args.interval, remaining)}s...",
            file=sys.stderr,
        )

        if remaining <= 0:
            break

        time.sleep(min(args.interval, remaining))

    # Final check after timeout
    comments = get_review_comments(args.repo, args.pr_number)
    reviews = get_reviews(args.repo, args.pr_number)
    status = "found" if (comments or reviews) else "timeout"
    print(json.dumps({"status": status, "comments": comments, "reviews": reviews}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
