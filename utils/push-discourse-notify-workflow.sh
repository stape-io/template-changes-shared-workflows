#!/bin/zsh

# Script to push the updated discourse-notify-and-readme-sync.yml (Copilot Models ->
# Copilot CLI migration, see .github/workflows/discourse-notify.yml) to .github/workflows/
# in the default branch of each repo listed in discourse-notify-repos.json.
# Updates the file only if already present; does not create it and touches no other file.
#
# Generate discourse-notify-repos.json first by running ./fetch-discourse-notify-repos.sh

set -uo pipefail

PROGRESS_FILE="discourse-notify-repos.json"
WORKFLOWS_SOURCE_DIR="../gtm-templates-specific-workflows/.github/workflows"
WORKFLOWS_TARGET_PATH=".github/workflows"
WORKFLOW_FILE="discourse-notify-and-readme-sync.yml"

# Keep base64 handling consistent across GNU and BSD/macOS variants.
b64_encode() {
  base64 | tr -d '\n'
}

LOCAL_FILE="${WORKFLOWS_SOURCE_DIR}/${WORKFLOW_FILE}"
REMOTE_PATH="${WORKFLOWS_TARGET_PATH}/${WORKFLOW_FILE}"

if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "❌ Local file not found: $LOCAL_FILE"
  exit 1
fi

TOTAL=$(jq 'length' "$PROGRESS_FILE")
echo "Total repos: $TOTAL"
echo ""

encoded=$(b64_encode < "$LOCAL_FILE")

for i in $(seq 0 $((TOTAL - 1))); do
  REPO=$(jq -r ".[$i].repo" "$PROGRESS_FILE")

  echo "=== Processing $REPO ==="

  # Only update; skip repos where the file doesn't already exist (nothing to migrate).
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
        -f message="chore: migrate discourse-notify to Copilot CLI (GitHub Models retired)" \
        -f content="$encoded" \
        -f sha="$sha" \
        --silent 2>/dev/null; then
      echo "  ✅ Updated ${REMOTE_PATH}"
    else
      echo "  ❌ Failed to update ${REMOTE_PATH}"
    fi

  else
    echo "  ⚠️  ${REMOTE_PATH} not found in ${REPO}, skipping (not creating new files)."
  fi

  echo ""
done

echo "Done!"
