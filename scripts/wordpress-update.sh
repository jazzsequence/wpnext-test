#!/usr/bin/env bash
# shellcheck disable=SC1094

source scripts/helpers.sh

wp_version=$(get_latest_wp_release)
TYPE="core"

echo "Updating WordPress $TYPE to $wp_version..."
# get_latest_wp_release resolves a nightly build identifier (e.g. "7.2-alpha-63903"),
# which is not itself a downloadable package -- WP-CLI only knows how to fetch nightly
# builds via the literal "nightly" keyword (it maps that to
# https://wordpress.org/nightly-builds/wordpress-latest.zip). $wp_version is still
# used below for logging and the commit message, and for comparing against
# `wp core version` in the calling workflow.
terminus wp -- "$TERMINUS_SITE".dev $TYPE update --version=nightly --force

# Wait for the update to be done done
terminus workflow:wait "$TERMINUS_SITE".dev --max=15

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