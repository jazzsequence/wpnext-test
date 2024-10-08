#!/bin/bash

get_latest_wp_release() {
    # URL of the WordPress News RSS feed
    feed_url="https://wordpress.org/news/category/releases/feed/"

    # Fetch the RSS feed
    rss_content=$(curl -s "$feed_url")

    # Extract all Beta and RC versions, removing "WordPress" prefix
    all_versions=$(echo "$rss_content" | grep -Eo 'WordPress [0-9]+\.[0-9]+ (Beta|RC) ?[0-9]*' | sed 's/WordPress //g')

    # Normalize version strings for sorting
    normalized_versions=$(echo "$all_versions" | awk '
    {
        split($1, parts, "[ .]");
        major_minor = parts[1] "." parts[2];
        if ($2 ~ /Beta|RC/) {
            suffix = tolower($2);
            suffix_number = ($3 ~ /^[0-9]+$/) ? $3 : "0";
            printf "%s %s %d\n", major_minor, suffix, suffix_number;
        }
    }')

    # Sort the versions: first by major.minor version, then RC > Beta, and then the suffix number
    latest_version=$(echo "$normalized_versions" | sort -k1,1Vr -k2,2 -k3,3nr | head -1)

    # Convert the normalized version back to the expected format without leading zero
    formatted_version=$(echo "$latest_version" | awk '{ printf "%s-%s%s\n", $1, $2, ($3 == "0" ? "" : $3) }')

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
