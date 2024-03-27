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