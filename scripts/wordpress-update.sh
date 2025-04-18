#!/usr/bin/env bash
# shellcheck disable=SC1094

source scripts/helpers.sh

wp_version=$(get_latest_wp_release)
TYPE="core"

echo "Updating WordPress $TYPE to $wp_version..."
terminus wp -- "$TERMINUS_SITE".dev $TYPE update --version="$wp_version" --force

# Wait for the update to be done done
terminus workflow:wait "$TERMINUS_SITE" --max=15

# Commit the changes and capture output
COMMIT_OUTPUT=$(terminus env:commit "$TERMINUS_SITE".dev --message="Updating WordPress ${TYPE} to ${wp_version}" 2>&1)

# Print output for debugging/logging
echo "$COMMIT_OUTPUT"

if echo "$COMMIT_OUTPUT" | grep -q "There is no code to commit"; then
    echo "Nothing to commit"
else
    # Wait for the workflow to finish
    terminus workflow:wait "$TERMINUS_SITE".dev --max=30

    maybe_switch_to_git_mode "$TERMINUS_OR_LANDO"

    merge_updates_from_pantheon_to_github $TYPE
fi