#!/usr/bin/env bash

terminus wp -- wp59-test.dev theme update --all

# Commit the changes
terminus env:commit wp59-test.dev --message="Updateing WordPress themes"

# Wait for the workflow to finish
terminus build:workflow:wait wp59-test.dev --max=30

# Switch back to Git mode
terminus connection:set wp59-test.dev git

# Pull the changes
git pull