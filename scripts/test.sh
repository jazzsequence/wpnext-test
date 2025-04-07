#!/bin/bash
# shellcheck disable=SC2155
set -e

# Get the multidev argument (if provided)
MULTIDEV_ARG=$1

# Check if MULTIDEV_ARG is set.
if [ -n "$MULTIDEV_ARG" ]; then
    echo "Running tests on multidev $MULTIDEV_ARG. Skipping multidev creation and deletion."
fi

export SKIP_CLEANUP=0 # Change this to 0 to delete the multidev to test.
export TERMINUS_SITE="wpnext-test"
export TERMINUS_ENV=${MULTIDEV_ARG:-behat}  # Use the provided multidev or default to 'behat'
export SITE_ENV="${TERMINUS_SITE}.${TERMINUS_ENV}"
export WORDPRESS_ADMIN_USERNAME=testuser
export WORDPRESS_ADMIN_PASSWORD=$(terminus secret:site:list $TERMINUS_SITE --format=json | jq -r '.testpass.value')

BEHAT_PATH="./vendor/pantheon-systems/pantheon-wordpress-upstream-tests"

# Prepare the tests
echo "Preparing tests..."
./scripts/prepare.sh

# Run the tests
./scripts/behat-test.sh

# Cleanup the tests
if [ -z "$MULTIDEV_ARG" ] && [ "$SKIP_CLEANUP" != '1' ]; then
    echo "Cleaning up tests..."
    "$BEHAT_PATH/cleanup.sh"
else
    terminus connection:set -n "$SITE_ENV" git
fi
