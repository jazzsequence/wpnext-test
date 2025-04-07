#!/usr/bin/env bash

terminus wp -- $TERMINUS_SITE.dev theme update --all
terminus build:workflow:wait $TERMINUS_SITE.dev --max=15

# Commit the changes
terminus env:commit $TERMINUS_SITE.dev --message="Updating WordPress themes"

# Wait for the workflow to finish
terminus build:workflow:wait $TERMINUS_SITE.dev --max=30
