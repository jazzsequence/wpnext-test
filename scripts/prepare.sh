#!/bin/bash

###
# Prepare a Pantheon site environment for the Behat test suite, by pushing the
# requested upstream branch to the environment. This script is architected
# such that it can be run a second time if a step fails.
###

set -e

source scripts/helpers.sh

if [ -z "$TERMINUS_SITE" ] || [ -z "$TERMINUS_ENV" ]; then
	echo "TERMINUS_SITE and TERMINUS_ENV environment variables must be set"
	exit 1
fi

# Set up test-base.
wp_version=$(get_latest_wp_release)
remote_wp_version=$(terminus wp -- $TERMINUS_SITE.test-base core version)
env_exists=$(terminus env:info $SITE_ENV)

# Set FTP mode.
terminus connection:set $TERMINUS_SITE.test-base sftp -y

# Only update to the latest release if we're not already on the latest version
echo "Checking installed WordPress version on $TERMINUS_SITE.test-base..."
if [ "$wp_version" != "$remote_wp_version" ]; then
	terminus wp -- $TERMINUS_SITE.test-base core update --version=$wp_version --force
	terminus env:commit $TERMINUS_SITE.test-base --message="WordPress core update $wp_version"
	terminus build:workflow:wait $TERMINUS_SITE.test-base --max=30
fi

# Only run multidev creation if the TERMINUS_ENV is 'behat'.
if [ "$TERMINUS_ENV" == 'behat' ]; then
	if [ -z "$env_exists" ]; then
		echo "Environment $TERMINUS_ENV does not exist."

		# Create a new environment for this particular test run.
		terminus env:create $TERMINUS_SITE.test-base $TERMINUS_ENV
	fi
else
	# If the environment was specified, make sure it exists.
	if [ -z "$env_exists" ]; then
		echo "Environment $TERMINUS_ENV does not exist."

		# Create a new environment for this particular test run.
		terminus env:create $TERMINUS_SITE.test-base $TERMINUS_ENV
	fi

	# Never run this directly on dev.
	if [ "$TERMINUS_ENV" == 'dev' ] || [ "$TERMINUS_ENV" == 'master' ]; then
		echo "You cannot run this script on the dev environment."
		exit 1
	fi
fi

terminus connection:set $SITE_ENV sftp
# If it does exist, make sure there are no plugins that the tests don't expect.
echo "Deleting all plugins from $SITE_ENV and adding only akismet and hello-dolly. This is a destructive operation so I hope you know what you're doing..."
terminus wp $SITE_ENV -- plugin delete --all
terminus wp $SITE_ENV -- plugin install akismet hello-dolly

terminus env:wipe $SITE_ENV --yes

###
# Get all necessary environment details.
###
PANTHEON_GIT_URL=$(terminus connection:info $SITE_ENV --field=git_url)
PANTHEON_SITE_URL="$TERMINUS_ENV-$TERMINUS_SITE.pantheonsite.io"
PREPARE_DIR="/tmp/$TERMINUS_ENV-$TERMINUS_SITE"
BASH_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
