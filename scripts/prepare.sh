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

function set_plugin_start_state() {
	local EXCLUDE="akismet,hello-dolly"

	echo "Deleting all plugins from $SITE_ENV and adding only akismet and hello-dolly. This is a destructive operation so I hope you know what you're doing..."
	terminus wp "$SITE_ENV" -- plugin delete --all --exclude="$EXCLUDE"
	terminus wp "$SITE_ENV" -- plugin install akismet hello-dolly
}

# Only run the next commands if WordPress is installed.
if ! terminus wp -- "$SITE_ENV" core is-installed; then
	# Check if there are more than 2 plugins installed.
	if [ "$(terminus wp -- "$SITE_ENV" plugin list --field=name | wc -l)" -gt 2 ]; then
		echo "WordPress core is not installed, but there are plugins installed. Deleting plugins."
		set_plugin_start_state
	fi

	echo "WordPress core is not installed. We're assuming this is from a previous run that did not complete. Skipping plugin deletion step."
else
	# If it does exist, make sure there are no plugins that the tests don't expect.
	set_plugin_start_state
fi

# Check number of plugins, redo set_plugin_start_state as necessary.
PLUGIN_COUNT=$(terminus wp -- "$SITE_ENV" plugin list --field=name | wc -l)
for i in {1..10}; do
	if [ "$PLUGIN_COUNT" -ne 2 ]; then
		echo "There are $PLUGIN_COUNT plugins installed. Resetting to known state."
		set_plugin_start_state
		PLUGIN_COUNT=$(terminus wp -- "$SITE_ENV" plugin list --field=name | wc -l)
	else
		echo "There are exactly 2 plugins installed. ✅"
		break
	fi
done

terminus env:wipe "$SITE_ENV" --yes

# Modify plugins.feature to use the iframe link for plugin installation and add a check
echo "Modifying plugins.feature to use the 'press' step instead of 'follow'..."
sed -i 's/When I follow "Install Now"/When I press "Install Now"/' vendor/pantheon-systems/pantheon-wordpress-upstream-tests/features/plugins.feature

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
