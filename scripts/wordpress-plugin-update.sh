#!/usr/bin/env bash

terminus wp -- wp59-test.dev plugin update --all
terminus build:workflow:wait wp59-test.dev --max=15

# Commit the changes
terminus env:commit wp59-test.dev --message="Updating WordPress plugins"

# Wait for the workflow to finish
terminus build:workflow:wait wp59-test.dev --max=30

read -p "Switch back to git mode? (y or n): " -r GIT_MODE

if [ $GIT_MODE == "y" ]; then
  echo "Switching back to git mode."
  terminus connection:set wp59-test.dev git
elif [ $GIT_MODE == "n" ]; then
  echo "Staying on SFTP mode."
  exit 0
else
  echo "Invalid option. Please try again."
  exit 1
fi

# Pull the changes
git pull