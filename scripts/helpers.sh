#!/bin/bash

get_latest_wp_release() {
	# URL of the WordPress News RSS feed
	feed_url="https://wordpress.org/news/category/releases/feed/"

	# Fetch the RSS feed
	rss_content=$(curl -s "$feed_url")

	# Look for patterns that match version numbers followed by either Beta or RC, considering the required format
	latest_version=$(echo "$rss_content" | grep -Eo 'WordPress [0-9]+\.[0-9]+( RC[0-9]+| Beta[0-9]+)' | head -1)

	if [ -n "$latest_version" ]; then
		# Format the version string to match the expected format for RCs and Betas
		version_formatted=$(echo $latest_version | sed -E 's/WordPress ([0-9]+\.[0-9]+) (RC|Beta)([0-9]+)/\1-\2\3/')

		echo $version_formatted
	else
		echo "No Beta/RC versions found."
		exit 1
	fi
}

get_lando() {
	# Make sure .lando.yml exists in the root directory.
	if [ ! -f .lando.yml ]; then
		echo "No .lando.yml file found in the root directory."
		exit 1
	fi

	local APP_NAME=$(sed -n 's/^name: //p' .lando.yml)
	echo "Checking if $APP_NAME is running..."

	# Check if the Lando app is running.
	app_status=$(lando list --format=json | jq -r ".[] | select(.name == \"$APP_NAME\") | .status")

	if [ "$app_status" != "Running" ]; then
		echo "Starting $APP_NAME..."
		lando start
	else
		echo "$APP_NAME is running."
	fi
}
