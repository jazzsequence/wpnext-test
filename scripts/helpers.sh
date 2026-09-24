#!/bin/bash

get_latest_wp_release() {
    local api_url="https://api.wordpress.org/core/version-check/1.7/?channel=development&locale=en_US"
    local response
    response=$(curl -s "$api_url")

    if [ -z "$response" ]; then
        echo "Failed to fetch a response from the WordPress.org version-check API ($api_url)." >&2
        exit 1
    fi

    local dev_version
    dev_version=$(echo "$response" | jq -r '[.offers[]? | select(.response == "development")][0].version // empty')

    if [ -z "$dev_version" ]; then
        # Fail loudly rather than silently falling back to a different channel or a stale value
        echo "The WordPress.org version-check API did not return a 'development' channel offer for channel=development. This is unexpected for a site configured to track that channel -- refusing to guess a fallback version. Response was:" >&2
        echo "$response" >&2
        exit 1
    fi

    # Only output the version number (e.g. "7.2-alpha-63903"). 
    # Note: this is a nightly build identifier, not a downloadable package name.
    echo "$dev_version"
}

get_lando() {
	# Make sure .lando.yml exists in the root directory.
	if [ ! -f .lando.yml ]; then
		echo "No .lando.yml file found in the root directory."
		exit 1
	fi

    # shellcheck disable=SC2155
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

merge_updates_from_pantheon_to_github() {
    local TYPE=$1

    # Pull down the latest `main` from GitHub
    git checkout main && git pull

    # Check if pantheon/master is different than origin/main
    if ! git fetch pantheon master || ! git fetch origin main; then
        echo "Failed to fetch from Pantheon or GitHub." >&2
        exit 1
    fi

    if git diff --quiet origin/main..pantheon/master; then
        echo "No changes found between pantheon/master and origin/main."
        exit 0
    else
        echo "Changes found between pantheon/master and origin/main."
    fi

    # Fetch updates from Pantheon
    git fetch pantheon

    # Checkout a new branch
    git checkout -b "$TYPE"-updates pantheon/master

    # Rebase Pantheon's changes onto main.
    git rebase main

    # Checkout main after pulling updates
    git checkout main

    # Merge the updates from Pantheon into GitHub
    git merge "$TYPE"-updates --ff-only

    # Push to GitHub.
    git push origin main # Assumes `origin` is GitHub

    # Delete the "$TYPE"-updates branch
    git branch -D "$TYPE"-updates
}

maybe_switch_to_git_mode() {
    local TERMINUS_OR_LANDO=${TERMINUS_OR_LANDO:-''}

    if [ "$TERMINUS_OR_LANDO" = 'l' ]; then
    read -p "Switch back to git mode? (y or n): " -r GIT_MODE

    if [ "$GIT_MODE" == "y" ]; then
        echo "Switching back to git mode."
        terminus connection:set "$TERMINUS_SITE".dev git
    elif [ "$GIT_MODE" == "n" ]; then
        echo "Staying on SFTP mode."
        exit 0
    else
        echo "Invalid option. Please try again."
        exit 1
    fi
    else
    # Terminus assumed, switch back to git so we can push to GitHub
    echo "Switching back to git mode."
    terminus connection:set "$TERMINUS_SITE".dev git
    fi    
}
