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

# Prepare the tests
echo "Preparing tests..."
"$BEHAT_PATH"/prepare.sh

# Copy the test to run locally...
echo "Copying test script..."
cp "$BEHAT_PATH/test.sh" ./scripts/behat-test.sh || exit 1
# Modify the temporary script file to include the sessions configuration
echo "Modifying test script..."
sed -i '' -e 's|"base_url" : "http://'"$TERMINUS_ENV"'-'"$TERMINUS_SITE"'.pantheonsite.io"}|&,"sessions": {"default": {"goutte": null}}}|' ./scripts/behat-test.sh || exit 1

# Run the tests
echo "Running tests..."
./scripts/behat-test.sh

# Clean up the tests
echo "Cleaning up tests..."
"$BEHAT_PATH"/cleanup.sh
# Delete the local copy of the test script.
[ -f ./behat-test.sh ] && rm ./scripts/behat-test.sh || echo "No local copy found to delete."
