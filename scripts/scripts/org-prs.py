#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Fetch PR details for all repos in a GitHub org within a time range.

Usage:
    uv run org-prs.py <org> <output.json> [--since YYYY-MM-DD] [--until YYYY-MM-DD]

Examples:
    uv run org-prs.py my-org prs.json
    uv run org-prs.py my-org prs.json --since 2025-03-01 --until 2025-03-07
"""

import argparse
import json
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone


def gh_api(endpoint: str) -> dict | list:
    """Call gh api and return parsed JSON. Retries on rate limits."""
    for attempt in range(6):
        result = subprocess.run(
            ["gh", "api", endpoint, "-H", "Accept: application/vnd.github+json"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return json.loads(result.stdout)

        stderr = result.stderr.lower()
        if "rate limit" in stderr or "abuse" in stderr or "secondary" in stderr:
            wait = min(2**attempt * 10, 120)
            print(f"  Rate limited, waiting {wait}s...", file=sys.stderr)
            time.sleep(wait)
            continue

        # Non-rate-limit error
        raise RuntimeError(
            f"gh api error for {endpoint} (exit {result.returncode}): {result.stderr}"
        )

    raise RuntimeError(f"Rate limited after retries: {endpoint}")


def list_org_repos(org: str) -> list[str]:
    """List all repo names in an org, paginated."""
    names = []
    page = 1
    while True:
        data = gh_api(
            f"/orgs/{org}/repos?per_page=100&page={page}&type=all"
        )
        if not data:
            break
        names.extend(r["name"] for r in data)
        print(f"  Fetched {len(names)} repos...", file=sys.stderr)
        if len(data) < 100:
            break
        page += 1
    return sorted(names)


def list_prs_in_range(
    owner: str, repo: str, start: datetime, end: datetime
) -> list[dict]:
    """List all PRs created in [start, end] for a single repo.

    Fetches PRs sorted by created date descending and stops as soon as
    we see a PR older than start, guaranteeing 100% recall without
    fetching the entire history.
    """
    prs = []
    page = 1
    while True:
        try:
            data = gh_api(
                f"/repos/{owner}/{repo}/pulls"
                f"?state=all&sort=created&direction=desc&per_page=100&page={page}"
            )
        except RuntimeError as e:
            print(f" ERROR: {e}", file=sys.stderr)
            return prs

        if not data:
            break

        done = False
        for pr in data:
            created = datetime.fromisoformat(
                pr["created_at"].replace("Z", "+00:00")
            )
            if created > end:
                # Newer than our window — skip but keep paginating
                continue
            if created < start:
                # Older than our window — all remaining are older too
                done = True
                break

            prs.append(
                {
                    "repo": repo,
                    "number": pr["number"],
                    "title": pr["title"],
                    "body": pr.get("body") or "",
                    "author": (pr.get("user") or {}).get("login"),
                    "state": "merged" if pr.get("merged_at") else pr["state"],
                    "created_at": pr["created_at"],
                    "updated_at": pr["updated_at"],
                    "merged_at": pr.get("merged_at"),
                    "closed_at": pr.get("closed_at"),
                    "url": pr["html_url"],
                    "labels": [l["name"] for l in pr.get("labels", [])],
                }
            )

        if done or len(data) < 100:
            break
        page += 1

    return prs


def main():
    parser = argparse.ArgumentParser(
        description="Fetch PR details for all repos in a GitHub org within a time range."
    )
    parser.add_argument("org", help="GitHub organization name")
    parser.add_argument("output", help="Output JSON file path")
    parser.add_argument(
        "--since",
        help="Start date inclusive (YYYY-MM-DD). Default: 7 days ago.",
        default=None,
    )
    parser.add_argument(
        "--until",
        help="End date inclusive (YYYY-MM-DD). Default: today.",
        default=None,
    )
    args = parser.parse_args()

    now = datetime.now(timezone.utc)
    if args.since:
        start = datetime.strptime(args.since, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    else:
        start = (now - timedelta(days=7)).replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    if args.until:
        end = datetime.strptime(args.until, "%Y-%m-%d").replace(
            hour=23, minute=59, second=59, tzinfo=timezone.utc
        )
    else:
        end = now

    print(f"Org:   {args.org}", file=sys.stderr)
    print(f"Range: {start.isoformat()} .. {end.isoformat()}", file=sys.stderr)

    # --- List all repos in the org ---
    print("\nListing repos...", file=sys.stderr)
    repos = list_org_repos(args.org)
    print(f"Found {len(repos)} repos\n", file=sys.stderr)

    # --- Fetch PRs per repo ---
    all_prs: list[dict] = []
    for i, repo_name in enumerate(repos, 1):
        print(
            f"[{i}/{len(repos)}] {repo_name}...",
            file=sys.stderr,
            end="",
            flush=True,
        )
        prs = list_prs_in_range(args.org, repo_name, start, end)
        print(f" {len(prs)} PRs", file=sys.stderr)
        all_prs.extend(prs)

    all_prs.sort(key=lambda p: p["created_at"], reverse=True)

    output = {
        "org": args.org,
        "time_range": {
            "start": start.isoformat(),
            "end": end.isoformat(),
        },
        "repos_scanned": len(repos),
        "total_prs": len(all_prs),
        "prs": all_prs,
    }

    with open(args.output, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"\nDone! {len(all_prs)} PRs written to {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
