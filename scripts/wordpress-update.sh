#!/usr/bin/env bash

source scripts/helpers.sh

wp_version=$(get_latest_wp_release)

echo "Updating WordPress core to $wp_version..."
terminus wp -- $TERMINUS_SITE.dev core update --version=$wp_version --force
terminus build:workflow:wait $TERMINUS_SITE.dev --max=15

# Commit the changes
terminus env:commit $TERMINUS_SITE.dev --message="WordPress core update $wp_version"

# Wait for the workflow to finish
terminus build:workflow:wait $TERMINUS_SITE.dev --max=30

maybe_switch_to_git_mode $TERMINUS_OR_LANDO
