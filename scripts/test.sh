#!/bin/bash

export TERMINUS_SITE=wp59-test
export TERMINUS_ENV=behat
export SITE_ENV="${TERMINUS_SITE}.${TERMINUS_ENV}"
export WORDPRESS_ADMIN_USERNAME=testuser
export WORDPRESS_ADMIN_PASSWORD=$(terminus secret:site:list wp59-test --format=json | jq -r '.testpass.value')

# Check for an existing behat multidev
PANTHEON_MULTIDEV_JSON=$(terminus multidev:list -n ${TERMINUS_SITE} --format=json)
if echo "${PANTHEON_MULTIDEV_JSON}" | jq -e --arg TERMINUS_ENV "$TERMINUS_ENV" 'has($TERMINUS_ENV)' > /dev/null; then
    echo "Multidev environment $TERMINUS_ENV exists."
	terminus multidev:delete -y --delete-branch -- $SITE_ENV
else
    echo "Multidev environment $TERMINUS_ENV does not exist."
fi

BEHAT_PATH="./vendor/pantheon-systems/pantheon-wordpress-upstream-tests"

echo "Setting up the test environment..."
terminus wp -- "$SITE_ENV" plugin delete --all
terminus wp -- "$SITE_ENV" plugin install akismet hello-dolly
terminus wp -- "$SITE_ENV" plugin list

# Prepare the tests
echo "Preparing tests..."
"$BEHAT_PATH"/prepare.sh

# Run the tests
echo "Running tests..."
./scripts/behat-test.sh

# Clean up the tests
echo "Cleaning up tests..."
"$BEHAT_PATH"/cleanup.sh
