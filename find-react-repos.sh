#!/usr/bin/env bash
# Requires: gh CLI (authenticated), jq
# Usage: bash find-react-repos.sh

ORG="bcgov"
PACKAGE="@bcgov/design-system-react-components"

if ! gh auth status >/dev/null 2>&1; then
  echo "Error: GitHub CLI is not authenticated. Run 'gh auth login' and try again."
  exit 1
fi

echo "Searching for repos in '$ORG' that use React or '$PACKAGE'..." >&2

search() {
  gh search code "$1" \
    --owner "$ORG" \
    --filename package.json \
    --json repository \
    --jq '.[].repository.nameWithOwner' \
    --limit 1000
}

{
  search "$PACKAGE"
  search '"react":'
} | sort -u
