#!/bin/bash
# shellcheck disable=SC2155
set -e

# Get the multidev argument (if provided)
MULTIDEV_ARG=$1

# Check if MULTIDEV_ARG is set.
if [ -n "$MULTIDEV_ARG" ]; then
    echo "Running tests on multidev $MULTIDEV_ARG. Skipping multidev creation and deletion."
fi

export SKIP_CLEANUP=1 # Change this to 0 to delete the multidev to test.
export TERMINUS_SITE="wpnext-test"
export TERMINUS_ENV=${MULTIDEV_ARG:-behat}  # Use the provided multidev or default to 'behat'
export SITE_ENV="${TERMINUS_SITE}.${TERMINUS_ENV}"
export WORDPRESS_ADMIN_USERNAME=testuser
export WORDPRESS_ADMIN_PASSWORD=$(terminus secret:site:list $TERMINUS_SITE --format=json | jq -r '.testpass.value')

# Don't delete anything if a specific multidev was passed.
if [ -z "$MULTIDEV_ARG" ]; then
    # Check for an existing behat multidev
    PANTHEON_MULTIDEV_JSON=$(terminus multidev:list -n ${TERMINUS_SITE} --format=json)
    if echo "${PANTHEON_MULTIDEV_JSON}" | jq -e --arg TERMINUS_ENV "$TERMINUS_ENV" 'has($TERMINUS_ENV)' > /dev/null; then
        echo "Multidev environment $TERMINUS_ENV exists."
        if [ "$SKIP_CLEANUP" == '1' ]; then
            echo "Cleanup skipped. Leaving the existing $TERMINUS_ENV environment..."
        else
            terminus multidev:delete -y --delete-branch -- "$SITE_ENV"
        fi
    else
        echo "Multidev environment $TERMINUS_ENV does not exist."
    fi
fi

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
