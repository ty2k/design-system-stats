#!/usr/bin/env bash
# Requires: gh CLI (authenticated), jq, node, react-scanner (npm install -g react-scanner)
# Usage: bash scan-org.sh react-repos.txt
# Output: adoption-report.json

set -euo pipefail

REPOS_FILE="${1:-adopting-repos.txt}"
WORK_DIR="$(mktemp -d)"
RESULTS_DIR="$(mktemp -d)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Work dir:    $WORK_DIR"bash scan-org.sh adopting-repos.txt
echo "Results dir: $RESULTS_DIR"
echo ""

if [[ ! -f "$REPOS_FILE" ]]; then
  echo "Error: repos file '$REPOS_FILE' not found."
  exit 1
fi

# Clone each repo and scan it
while IFS= read -r REPO || [[ -n "$REPO" ]]; do
  [[ -z "$REPO" || "$REPO" == \#* ]] && continue  # skip blank lines and comments

  REPO_NAME="${REPO##*/}"  # strip owner prefix
  CLONE_PATH="$WORK_DIR/$REPO_NAME"
  RESULT_FILE="$RESULTS_DIR/$REPO_NAME.json"

  echo "▶ Cloning $REPO..."
  if ! gh repo clone "$REPO" "$CLONE_PATH" -- --depth=1 --quiet 2>/dev/null; then
    echo "  ⚠ Skipping $REPO (clone failed)"
    echo '{"reactVersions":[],"designSystemVersions":[],"components":{}}' > "$RESULT_FILE"
    continue
  fi

  echo "  Scanning..."
  if node "$SCRIPT_DIR/scan-repo.mjs" "$CLONE_PATH" > "$RESULT_FILE"; then
    COMPONENT_COUNT=$(jq '.components | keys | length' "$RESULT_FILE")
    REACT_VERSION_COUNT=$(jq '.reactVersions | length' "$RESULT_FILE")
    echo "  ✔ Found $COMPONENT_COUNT component(s), $REACT_VERSION_COUNT React declaration(s)"
  else
    echo "  ⚠ Scan failed for $REPO"
    echo '{"reactVersions":[],"designSystemVersions":[],"components":{}}' > "$RESULT_FILE"
  fi

  # Clean up clone immediately to save disk space
  rm -rf "$CLONE_PATH"

done < "$REPOS_FILE"

echo ""
echo "Aggregating results..."

# Merge all per-repo JSON files into one report keyed by repo name
jq -n \
  --slurpfile files <(
    for f in "$RESULTS_DIR"/*.json; do
      REPO_NAME="$(basename "$f" .json)"
      jq --arg repo "$REPO_NAME" '{($repo): .}' "$f"
    done | jq -s '.'
  ) \
  '$files[0] | add' > adoption-report.json

echo "✔ Done! Report written to adoption-report.json"
echo ""
echo "Summary:"
jq '{
  total_repos: (keys | length),
  repos_with_usage: [to_entries[] | select(.value.components | length > 0)] | length,
  repos_with_library_dependency: [to_entries[] | select((.value.designSystemVersions // []) | length > 0)] | length,
  repos_with_react_version: [to_entries[] | select(.value.reactVersions | length > 0)] | length
}' adoption-report.json


# Clean up temp dirs
rm -rf "$RESULTS_DIR"
