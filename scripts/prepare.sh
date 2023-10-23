#!/bin/bash

###
# Prepare a Pantheon site environment for the Behat test suite, by pushing the
# requested upstream branch to the environment. This script is architected
# such that it can be run a second time if a step fails.
###

set -ex

if [ -z "$TERMINUS_SITE" ] || [ -z "$TERMINUS_ENV" ]; then
	echo "TERMINUS_SITE and TERMINUS_ENV environment variables must be set"
	exit 1
fi

# Only run multidev creation if the TERMINUS_ENV is 'behat'.
if [ "$TERMINUS_ENV" == 'behat' ]; then
	# Create a new environment for this particular test run.
	terminus env:create $TERMINUS_SITE.test-base $TERMINUS_ENV
else
	# If the environment was specified, make sure it exists.
	$env_exists=$(terminus env:info $SITE_ENV )
	if [ -z "$env_exists" ]; then
		echo "Environment $TERMINUS_ENV does not exist."
		exit 1
	fi

	# If it does exist, make sure there are no plugins that the tests don't expect.
	terminus wp $SITE_ENV -- plugin delete --all
	terminus wp $SITE_ENV -- plugin install akismet hello-dolly
fi

terminus env:wipe $SITE_ENV --yes

###
# Get all necessary environment details.
###
PANTHEON_GIT_URL=$(terminus connection:info $SITE_ENV --field=git_url)
PANTHEON_SITE_URL="$TERMINUS_ENV-$TERMINUS_SITE.pantheonsite.io"
PREPARE_DIR="/tmp/$TERMINUS_ENV-$TERMINUS_SITE"
BASH_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

###
# Switch to SFTP mode so the site can install plugins and themes
###
terminus connection:set -n $SITE_ENV sftp
