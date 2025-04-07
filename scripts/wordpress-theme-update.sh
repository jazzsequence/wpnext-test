#!/usr/bin/env bash

source scripts/helpers.sh

TYPE="theme"

terminus wp -- $TERMINUS_SITE.dev $TYPE update --all

# Commit the changes and capture output
COMMIT_OUTPUT=$(terminus env:commit $TERMINUS_SITE.dev --message="Updating WordPress ${TYPE}s" 2>&1)

# Print output for debugging/logging
echo "$COMMIT_OUTPUT"

if echo "$COMMIT_OUTPUT" | grep -q "There is no code to commit"; then
    echo "Nothing to commit"
else
    # Wait for the workflow to finish
    terminus build:workflow:wait $TERMINUS_SITE.dev --max=30

    maybe_switch_to_git_mode $TERMINUS_OR_LANDO

    merge_updates_from_pantheon_to_github $TYPE
fi
