#!/bin/bash

export TERMINUS_SITE=wp59-test
export TERMINUS_ENV=behat
export SITE_ENV="${TERMINUS_SITE}.${TERMINUS_ENV}"
export WORDPRESS_ADMIN_USERNAME=testuser
export WORDPRESS_ADMIN_PASSWORD=$(terminus secret:site:list wp59-test --format=json | jq -r '.testpass.value')

BEHAT_PATH="./vendor/pantheon-systems/pantheon-wordpress-upstream-tests"

# Prepare the tests
"$BEHAT_PATH"/prepare.sh

# Run the tests
"$BEHAT_PATH"/test.sh

# Clean up the tests
"$BEHAT_PATH"/cleanup.sh
