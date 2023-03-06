#!/usr/bin/env bash

terminus wp -- wp59-test.dev core update

# Commit the changes
terminus env:commit wp59-test.dev --message="WordPress core update"

# Switch back to Git mode
terminus connection:set wp59-test.dev git

# Pull the changes
git pull