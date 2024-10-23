#!/bin/bash

get_latest_wp_release() {
    # URL of the WordPress News RSS feed
    feed_url="https://wordpress.org/news/category/releases/feed/"

    # Fetch the RSS feed
    rss_content=$(curl -s "$feed_url")

    # Extract all Beta and Release Candidate versions, removing "WordPress" prefix
    all_versions=$(echo "$rss_content" | grep -Eo 'WordPress [0-9]+\.[0-9]+ (Beta|Release Candidate|RC) ?[0-9]*' | sed 's/WordPress //g')

    # Normalize version strings for sorting
    normalized_versions=$(echo "$all_versions" | awk '
    {
        split($1, parts, "[ .]");
        major_minor = parts[1] "." parts[2];
        suffix = tolower($2);
        if (suffix == "release") {
            suffix = "rc";
        } else if (suffix == "candidate") {
            next; # Skip the "Candidate" line from splitting "Release Candidate"
        }
        suffix_number = ($3 ~ /^[0-9]+$/) ? $3 : "0";

        # Assign priority numbers for sorting (rc > beta)
        if (suffix == "rc") {
            priority = 1;
        } else if (suffix == "beta") {
            priority = 2;
        }

        # Print normalized version: major_minor priority suffix_number
        printf "%s %d %s\n", major_minor, priority, suffix_number;
    }')

    # Sort the versions: first by major.minor version, then by priority (RC > Beta), and then by suffix number
    latest_version=$(echo "$normalized_versions" | sort -k1,1Vr -k2,2n -k3,3nr | head -1)

    # Convert the normalized version back to the expected format
    formatted_version=$(echo "$latest_version" | awk '{ suffix = ($2 == 1 ? "rc" : "beta"); printf "%s-%s%s\n", $1, suffix, ($3 == "0" ? "1" : $3) }')

    if [ -n "$formatted_version" ]; then
        echo "$formatted_version"
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
	local CONTAINER_NAME=${APP_NAME//-/}
	# Check if there are any running containers for the container
	running_containers=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -c "$CONTAINER_NAME")
	echo "Checking if $APP_NAME is running..."

	if [ "$running_containers" -gt 0 ]; then
		echo "$APP_NAME is running."
	else
		echo "Starting $APP_NAME..."
		lando start
	fi
}
