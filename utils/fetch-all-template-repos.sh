#!/usr/bin/env bash

set -euo pipefail

ORG="stape-io"
FILE="template.tpl"
results="[]"

repos=$(gh repo list "$ORG" --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')

for repo in $repos; do
  echo "Checking $repo..." >&2
  if gh api "repos/${repo}/contents/${FILE}" --silent 2>/dev/null; then
    results=$(jq -n --argjson arr "$results" --arg repo "$repo" '$arr + [{repo: $repo}]')
  fi
done

echo "$results"
