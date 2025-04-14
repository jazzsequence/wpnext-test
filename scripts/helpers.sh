#!/bin/bash

get_latest_wp_release() {
    # URL of the WordPress News RSS feed
    feed_url="https://wordpress.org/news/category/releases/feed/"
    # URL of Make/core RSS feed
    make_feed_url="https://make.wordpress.org/core/tag/releases/feed/"

    # Fetch the RSS feed
    rss_content=$(curl -s "$feed_url")
    make_rss_content=$(curl -s "$make_feed_url")

    if [ -z "$rss_content" ] && [ -z "$make_rss_content" ]; then
        echo "Failed to fetch content from RSS feeds." >&2
        exit 1
    fi

    # Extract all Beta and Release Candidate items
    all_versions=$(echo "$rss_content" | grep -Eo 'WordPress [0-9]+\.[0-9]+ (Beta|Release Candidate|RC) ?[0-9]*' | sed 's/WordPress //g')
    make_versions=$(echo "$make_rss_content" | grep -Eo 'WordPress [0-9]+\.[0-9]+ (Beta|Release Candidate|RC) ?[0-9]*' | sed 's/WordPress //g')

    # Combine raw versions before normalizing
    combined_raw_versions=$(echo -e "${all_versions}\n${make_versions}")

    # Normalize ALL version strings
    normalized_versions=$(normalize_versions "$combined_raw_versions")

    if [ -z "$normalized_versions" ]; then
        echo "No Beta/RC versions found."
        exit 1
    fi

    # Sort the combined, normalized versions:
    # -k1,1Vr: Sort by version string (field 1), version sort (V), reverse (r) -> newest version first
    # -k2,2n:  Then by priority (field 2), numeric (n) -> RC (1) before Beta (2)
    # -k3,3nr: Then by suffix number (field 3), numeric (n), reverse (r) -> RC4 before RC3, Beta2 before Beta1
    release_version=$(echo "$normalized_versions" | grep . | sort -k1,1Vr -k2,2n -k3,3nr | head -1)

    # normalize_versions uses an internal formatting for RC and beta release priorities. We need to change these back to standard -beta/-RC versions
    formatted_version=$(echo "$release_version" | awk '{
        suffix = ($2 == 1 ? "RC" : "beta");
        # Default suffix number 0 (meaning none found) to 1, otherwise use the found number
        suffix_num = ($3 == "0" ? "1" : $3);
        printf "%s-%s%s\n", $1, suffix, suffix_num
    }')

    # Extract the download link for the latest version using sed
    download_url="https://wordpress.org/wordpress-${formatted_version}.zip"

    # Check if the download URL exists
    if ! curl --head --silent --fail "$download_url" > /dev/null; then
        echo "No download found for version $formatted_version." >&2
        exit 1
    fi

    # Only output the version number
    echo "$formatted_version"
}
 
normalize_versions() {
    source_content=$1

    if [ -z "$source_content" ]; then
        # Return empty string, let caller handle it
        echo ""
        return
    fi

    echo "$source_content" | awk '
    {
        # Match version pattern like X.Y or X.Y.Z at the beginning
        if (match($1, /^[0-9]+\.[0-9]+(\.[0-9]+)?/)) {
            major_minor_patch = substr($1, RSTART, RLENGTH)
        } else {
            next # Skip lines not starting with a version number
        }

        suffix = tolower($2);
        if (suffix == "release") {
            suffix = "rc"; # Normalize to lowercase "rc"
        } else if (suffix == "candidate") {
            # This handles "Release Candidate" where "Candidate" is $3
            # We already processed "Release" as $2, just make sure suffix is rc
            # A bit redundant if grep already works, but safe.
            if (tolower($1) == "release") { # Check if previous word was release
                suffix = "rc"
            } else {
                next; # Skip the standalone "Candidate" line
            }
        } else if (suffix == "beta") {
            suffix = "beta"; # Ensure lowercase
        } else {
            next; # Skip if not beta or rc/release candidate
        }

        # Find the number following Beta/RC if present, otherwise default to 0
        num_candidate = $3 # Check field 3 first
        if (num_candidate ~ /^[0-9]+$/) {
            suffix_number = num_candidate
        } else {
            num_candidate = $4 # Check field 4 (for Release Candidate N)
            if (num_candidate ~ /^[0-9]+$/) {
                suffix_number = num_candidate
            } else {
                suffix_number = "0"; # Default if no number found
            }
        }


        # Assign priority numbers for sorting (RC > beta)
        priority=99 # Default unlikely priority
        if (suffix == "rc") {
            priority = 1;
        } else if (suffix == "beta") {
            priority = 2;
        } else {
            next # Skip if priority was not set (should not happen with checks above)
        }

        # Print normalized version: major_minor_patch priority suffix_number
        printf "%s %d %s\n", major_minor_patch, priority, suffix_number;
    }'
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
