#!/bin/bash

###
# Execute the Behat test suite against a prepared Pantheon site environment.
###

set -e

if [ -z "$TERMINUS_SITE" ] || [ -z "$TERMINUS_ENV" ]; then
	echo "TERMINUS_SITE and TERMINUS_ENV environment variables must be set"
	exit 1
fi

if [ -z "$WORDPRESS_ADMIN_USERNAME" ] || [ -z "$WORDPRESS_ADMIN_PASSWORD" ]; then
	echo "WORDPRESS_ADMIN_USERNAME and WORDPRESS_ADMIN_PASSWORD environment variables must be set"
	exit 1
fi
echo "Running tests..."
export BEHAT_PARAMS='{"extensions" : {"Behat\\MinkExtension" : {"base_url" : "http://'$TERMINUS_ENV'-'$TERMINUS_SITE'.pantheonsite.io", "sessions": {"default": {"goutte": null}}}}}'

BEHAT_RUNNING=1 ./vendor/bin/behat -c ./vendor/pantheon-systems/pantheon-wordpress-upstream-tests/behat.yml "$*"
