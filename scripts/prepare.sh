#!/bin/bash

###
# Prepare a Pantheon site environment for the Behat test suite, by pushing the
# requested upstream branch to the environment. This script is architected
# such that it can be run a second time if a step fails.
###

# shellcheck disable=SC2034
# shellcheck disable=SC1094

set -e

source scripts/helpers.sh

if [ -z "$TERMINUS_SITE" ] || [ -z "$TERMINUS_ENV" ]; then
	echo "TERMINUS_SITE and TERMINUS_ENV environment variables must be set"
	exit 1
fi

# Set up test-base.
wp_version=$(get_latest_wp_release)
remote_wp_version=$(terminus wp -- "$TERMINUS_SITE".test-base core version)
env_exists=$(terminus env:info "$SITE_ENV" || echo "")

echo "Latest WordPress version is $wp_version. The version installed on $TERMINUS_SITE.test-base is $remote_wp_version."

# Set FTP mode.
terminus connection:set "$TERMINUS_SITE".test-base sftp -y

# Only update to the latest release if we're not already on the latest version
if [ "$wp_version" != "$remote_wp_version" ]; then
	echo "WordPress is not the latest version. Updating to $wp_version..."
	terminus wp -- "$TERMINUS_SITE".test-base core update --version="$wp_version" --force
	terminus env:commit "$TERMINUS_SITE".test-base --message="WordPress core update $wp_version"
	terminus workflow:wait "$TERMINUS_SITE".test-base --max=30
fi

# Never run this directly on dev.
if [ "$TERMINUS_ENV" == 'dev' ] || [ "$TERMINUS_ENV" == 'master' ]; then
	echo "You cannot run this script on the dev environment."
	exit 1
fi


if [ -z "$env_exists" ]; then
	echo "Environment $TERMINUS_ENV does not exist."

	# Create a new environment for this particular test run.
	terminus env:create "$TERMINUS_SITE".test-base "$TERMINUS_ENV"

else
	echo "Environment $TERMINUS_ENV already exists. Skipping multidev creation."
fi

terminus connection:set "$SITE_ENV" sftp -y

PLUGINS_LIST="6.2-plugin-test 6.4-admin-notice-test 6.5-interactivity-test menu-locations-api classic-editor core-rollback-disable-pantheon-font-handling games-collector gutenberg horror-ipsum jetpack mailpoet wp-native-php-sessions pantheon-advanced-page-cache pantheon-hud rollback-update-failure rollback-testing test-reports woocommerce wordpress-beta-tester wp-cfm wp-feature-notifications wp-redis wordpress-seo"

# Only run the next commands if WordPress is installed.
if ! terminus wp -- "$SITE_ENV" core is-installed; then
	echo "WordPress core is not installed. We're assuming this is from a previous run that did not complete. Skipping plugin deletion step."
else
	# If it does exist, make sure there are no plugins that the tests don't expect.
	echo "Deleting all plugins from $SITE_ENV and adding only akismet and hello-dolly. This is a destructive operation so I hope you know what you're doing..."
	terminus wp "$SITE_ENV" -- plugin delete "$PLUGINS_LIST"
	terminus wp "$SITE_ENV" -- plugin install akismet hello-dolly
fi

terminus env:wipe "$SITE_ENV" --yes

# Modify plugins.feature to use the iframe link for plugin installation and add a check
echo "Modifying plugins.feature to use the iframe link for plugin installation..."
sed -i 's/When I follow "Install Now"/When I click on the element with id "plugin_install_from_iframe"/' vendor/pantheon-systems/pantheon-wordpress-upstream-tests/features/plugins.feature

###
# Get all necessary environment details.
###
PANTHEON_GIT_URL=$(terminus connection:info "$SITE_ENV" --field=git_url)
PANTHEON_SITE_URL="$TERMINUS_ENV-$TERMINUS_SITE.pantheonsite.io"
PREPARE_DIR="/tmp/$TERMINUS_ENV-$TERMINUS_SITE"
BASH_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

# Wait for the install screen to become available (max ~100s)
echo "Waiting for WordPress install screen to become available..."
for i in {1..10}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$PANTHEON_SITE_URL/wp-admin/install.php")
  echo "Attempt $i: HTTP status $STATUS"
  if [ "$STATUS" = "200" ]; then
    echo "✅ Install page is ready."
    break
  fi
  sleep 10
  if [ "$i" -eq 10 ]; then
    echo "❌ Timed out waiting for /wp-admin/install.php to become available."
    exit 1
  fi
done
