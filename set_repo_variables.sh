#!/bin/zsh

# Script to add COMMUNITY_TOPIC_ID and COMMUNITY_POST_ID repository variables
# for all repos from progress.json.

set -uo pipefail

PROGRESS_FILE="progress.json"

TOTAL=$(jq '.created | length' "$PROGRESS_FILE")
echo "Total repos in 'created': $TOTAL"
echo ""

for i in $(seq 0 $((TOTAL - 1))); do
  REPO=$(jq -r ".created[$i].repo" "$PROGRESS_FILE")
  TOPIC_ID=$(jq -r ".created[$i].topic_id" "$PROGRESS_FILE")
  POST_ID=$(jq -r ".created[$i].post_id" "$PROGRESS_FILE")

  if [[ "$TOPIC_ID" == "null" || "$POST_ID" == "null" ]]; then
    echo "=== Skipping $REPO (topic_id or post_id is null) ==="
    echo ""
    continue
  fi

  echo "=== Processing $REPO (topic_id=$TOPIC_ID, post_id=$POST_ID) ==="

  if gh variable get COMMUNITY_TOPIC_ID --repo "$REPO" &>/dev/null; then
    echo "  COMMUNITY_TOPIC_ID already exists, skipping."
  else
    if gh variable set COMMUNITY_TOPIC_ID --repo "$REPO" --body "$TOPIC_ID" 2>/dev/null; then
      echo "  ✅ Set COMMUNITY_TOPIC_ID=$TOPIC_ID"
    else
      echo "  ❌ Failed to set COMMUNITY_TOPIC_ID (no permissions?), skipping repo."
      echo ""
      continue
    fi
  fi

  if gh variable get COMMUNITY_POST_ID --repo "$REPO" &>/dev/null; then
    echo "  COMMUNITY_POST_ID already exists, skipping."
  else
    if gh variable set COMMUNITY_POST_ID --repo "$REPO" --body "$POST_ID" 2>/dev/null; then
      echo "  ✅ Set COMMUNITY_POST_ID=$POST_ID"
    else
      echo "  ❌ Failed to set COMMUNITY_POST_ID (no permissions?), skipping repo."
      echo ""
      continue
    fi
  fi

  echo ""
done

echo "Done!"