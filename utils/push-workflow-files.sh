#!/bin/zsh

# Script to push gallery-status.yml and discourse-notify-and-readme-sync.yml
# to .github/workflows/ in the default branch of each repo listed under
# "created[].repo" in repos-and-community-ids.json.
# Creates the file if absent; updates it if already present.

set -uo pipefail

PROGRESS_FILE="repos-and-community-ids.json"
WORKFLOWS_SOURCE_DIR="../gtm-templates-specific-workflows/.github/workflows"
WORKFLOWS_TARGET_PATH=".github/workflows"

WORKFLOW_FILES=(
  "gallery-status.yml"
  "discourse-notify-and-readme-sync.yml"
)

# Keep base64 handling consistent across GNU and BSD/macOS variants.
b64_encode() {
  base64 | tr -d '\n'
}

TOTAL=$(jq '.created | length' "$PROGRESS_FILE")
echo "Total repos in 'created': $TOTAL"
echo ""

for i in $(seq 0 $((TOTAL - 1))); do
  REPO=$(jq -r ".created[$i].repo" "$PROGRESS_FILE")

  echo "=== Processing $REPO ==="

  for WORKFLOW_FILE in "${WORKFLOW_FILES[@]}"; do
    LOCAL_FILE="${WORKFLOWS_SOURCE_DIR}/${WORKFLOW_FILE}"
    REMOTE_PATH="${WORKFLOWS_TARGET_PATH}/${WORKFLOW_FILE}"

    if [[ ! -f "$LOCAL_FILE" ]]; then
      echo "  ❌ Local file not found: $LOCAL_FILE, skipping."
      continue
    fi

    encoded=$(b64_encode < "$LOCAL_FILE")

    # Check if the file already exists on the default branch to obtain its SHA.
    if existing=$(gh api \
        -H "Accept: application/vnd.github+json" \
        "repos/${REPO}/contents/${REMOTE_PATH}" 2>/dev/null); then

      sha=$(printf '%s' "$existing" | jq -r '.sha // empty')

      if [[ -z "$sha" ]]; then
        echo "  ❌ Could not parse SHA for ${REMOTE_PATH}, skipping."
        continue
      fi

      if gh api "repos/${REPO}/contents/${REMOTE_PATH}" \
          --method PUT \
          -f message="chore: update ${WORKFLOW_FILE}" \
          -f content="$encoded" \
          -f sha="$sha" \
          --silent 2>/dev/null; then
        echo "  ✅ Updated ${REMOTE_PATH}"
      else
        echo "  ❌ Failed to update ${REMOTE_PATH}"
      fi

    else
      if gh api "repos/${REPO}/contents/${REMOTE_PATH}" \
          --method PUT \
          -f message="chore: add ${WORKFLOW_FILE}" \
          -f content="$encoded" \
          --silent 2>/dev/null; then
        echo "  ✅ Created ${REMOTE_PATH}"
      else
        echo "  ❌ Failed to create ${REMOTE_PATH}"
      fi
    fi
  done

  echo ""
done

echo "Done!"
