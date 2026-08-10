#!/usr/bin/env bash

# Lists repositories in the stape-io org that already have
# .github/workflows/discourse-notify-and-readme-sync.yml, and writes the result
# to discourse-notify-repos.json. Used to target the Copilot Models -> Copilot CLI
# migration push (see push-discourse-notify-workflow.sh), since the older
# repos-and-community-ids.json snapshot is outdated.

set -euo pipefail

ORG="stape-io"
FILE=".github/workflows/discourse-notify-and-readme-sync.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/discourse-notify-repos.json"
results="[]"

repos=$(gh repo list "$ORG" --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')

for repo in $repos; do
  echo "Checking $repo..." >&2
  if gh api "repos/${repo}/contents/${FILE}" --silent 2>/dev/null; then
    results=$(jq -n --argjson arr "$results" --arg repo "$repo" '$arr + [{repo: $repo}]')
  fi
done

printf '%s\n' "$results" | jq '.' > "$OUTPUT_FILE"
echo "$results"
