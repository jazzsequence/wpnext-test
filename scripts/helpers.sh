#!/bin/bash

get_latest_wp_release() {
    # URL of the WordPress News RSS feed
    feed_url="https://wordpress.org/news/category/releases/feed/"

    # Fetch the RSS feed
    rss_content=$(curl -s "$feed_url")

    # Extract all Beta and RC versions, removing "WordPress" prefix
    all_versions=$(echo "$rss_content" | grep -Eo 'WordPress [0-9]+\.[0-9]+ (Beta|RC) ?[0-9]*' | sed 's/WordPress //g' | sort -V -r)

    # Loop through the versions to select the highest version,
    # prioritizing RC over Beta for the same version number
    latest_version=""
    latest_major_minor=""

    while IFS= read -r version; do
        major_minor=$(echo "$version" | grep -Eo '^[0-9]+\.[0-9]+')
        if [ -z "$latest_version" ] || [ "$major_minor" != "$latest_major_minor" ]; then
            latest_version="$version"
            latest_major_minor="$major_minor"
        elif [[ "$version" == *"RC"* && "$latest_version" == *"Beta"* && "$major_minor" == "$latest_major_minor" ]]; then
            latest_version="$version"
        fi
    done <<< "$all_versions"

    if [ -n "$latest_version" ]; then
        # Properly format the version for WP-CLI, converting "Beta" to "beta" and "RC" to "rc"
        version_formatted=$(echo "$latest_version" | sed -E 's/ (Beta|RC) ?([0-9]*)/-\L\1\2/' | tr '[:upper:]' '[:lower:]')

        echo "$version_formatted"
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
