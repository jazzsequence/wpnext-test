#!/usr/bin/env bash

source scripts/helpers.sh

wp_version=$(get_latest_wp_release)

set -e
echo "Updating WordPress core to $wp_version..."
terminus wp -- wp59-test.dev core update --version=$wp_version --force
terminus build:workflow:wait wp59-test.dev --max=15
set +e

# Commit the changes
terminus env:commit wp59-test.dev --message="WordPress core update $wp_version"

# Wait for the workflow to finish
terminus build:workflow:wait wp59-test.dev --max=30

# Switch back to Git mode
terminus connection:set wp59-test.dev git

# Pull the changes
git pull