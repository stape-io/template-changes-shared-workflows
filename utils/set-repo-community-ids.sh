#!/bin/zsh

# Script to add COMMUNITY_TOPIC_ID and COMMUNITY_POST_ID to
# .github/community-config.json in each repo from repos-and-community-ids.json.

set -uo pipefail

PROGRESS_FILE="repos-and-community-ids.json"
CONFIG_PATH=".github/community-config.json"

# Keep base64 handling consistent across GNU and BSD/macOS variants.
b64_encode() {
  base64 | tr -d '\n'
}

b64_decode() {
  if base64 --decode </dev/null >/dev/null 2>&1; then
    base64 --decode
  else
    base64 -D
  fi
}

TOTAL=$(jq '.created | length' "$PROGRESS_FILE")
echo "Total repos in 'created': $TOTAL"
echo ""

# Iterate through all repos listed in progress.json and sync config values.
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

  # If config already exists, merge/update values; otherwise create a new file.
  if existing=$(gh api -H "Accept: application/vnd.github+json" "repos/${REPO}/contents/${CONFIG_PATH}" 2>/dev/null); then
    raw_content=$(printf '%s' "$existing" | jq -r '.content // empty' 2>/dev/null | tr -d '\n')
    sha=$(printf '%s' "$existing" | jq -r '.sha // empty' 2>/dev/null)

    if [[ -z "$sha" ]]; then
      echo "  ❌ Could not parse file metadata from GitHub API response, skipping repo."
      echo ""
      continue
    fi

    current_content=$(printf '%s' "$raw_content" | b64_decode 2>/dev/null || true)

    if printf '%s' "$current_content" | jq -e . >/dev/null 2>&1; then
      current_topic=$(printf '%s' "$current_content" | jq -r '.COMMUNITY_TOPIC_ID // empty')
      current_post=$(printf '%s' "$current_content" | jq -r '.COMMUNITY_POST_ID // empty')

      if [[ -n "$current_topic" && -n "$current_post" ]]; then
        echo "  community-config.json already has both values, skipping."
        echo ""
        continue
      fi

      new_content=$(printf '%s' "$current_content" | jq --argjson topic "$TOPIC_ID" --argjson post "$POST_ID" \
        '.COMMUNITY_TOPIC_ID = $topic | .COMMUNITY_POST_ID = $post')
    else
      echo "  Existing ${CONFIG_PATH} is not valid JSON, overwriting it."
      new_content=$(jq -n \
        --argjson topic "$TOPIC_ID" \
        --argjson post "$POST_ID" \
        '{COMMUNITY_TOPIC_ID: $topic, COMMUNITY_POST_ID: $post}')
    fi

    encoded=$(printf '%s' "$new_content" | b64_encode)

    if gh api "repos/${REPO}/contents/${CONFIG_PATH}" \
      --method PUT \
      -f message="chore: update community config" \
      -f content="$encoded" \
      -f sha="$sha" \
      --silent 2>/dev/null; then
      echo "  ✅ Updated ${CONFIG_PATH}"
    else
      echo "  ❌ Failed to update ${CONFIG_PATH}, skipping repo."
    fi
  else
    new_content=$(jq -n \
      --argjson topic "$TOPIC_ID" \
      --argjson post "$POST_ID" \
      '{COMMUNITY_TOPIC_ID: $topic, COMMUNITY_POST_ID: $post}')
    encoded=$(printf '%s' "$new_content" | b64_encode)

    if gh api "repos/${REPO}/contents/${CONFIG_PATH}" \
      --method PUT \
      -f message="chore: add community config" \
      -f content="$encoded" \
      --silent 2>/dev/null; then
      echo "  ✅ Created ${CONFIG_PATH}"
    else
      echo "  ❌ Failed to create ${CONFIG_PATH}, skipping repo."
    fi
  fi

  # Remove old repo-level variables after values are moved to config file.
  for var in COMMUNITY_TOPIC_ID COMMUNITY_POST_ID; do
    if gh variable get "$var" --repo "$REPO" &>/dev/null; then
      if gh variable delete "$var" --repo "$REPO" 2>/dev/null; then
        echo "  ✅ Deleted repo variable $var"
      else
        echo "  ❌ Failed to delete repo variable $var"
      fi
    fi
  done

  echo ""
done

echo "Done!"
