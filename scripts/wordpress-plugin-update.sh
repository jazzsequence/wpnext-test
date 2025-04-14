#!/usr/bin/env bash
# shellcheck disable=SC1094,SC2154

source scripts/helpers.sh

TYPE="plugin" # Set the update type (plugin, theme, core)

# Default commit message if parsing fails or no updates occur
COMMIT_MESSAGE="Updating WordPress ${TYPE}s"
UPDATED_LIST="" # Variable to hold the list of updated items

echo "Attempting to update ${TYPE}s on $TERMINUS_SITE.dev..."

# Run the update command and capture its output
UPDATE_OUTPUT=$(terminus wp -- "$TERMINUS_SITE".dev "$TYPE" update --all 2>&1)
UPDATE_EXIT_CODE=$?

# Check if the update command itself indicated an error
if [ $UPDATE_EXIT_CODE -ne 0 ]; then
    # Note: Non-zero exit code from `wp update` doesn't always mean failure.
    # Consider if you want to exit or just warn.
    echo "Warning: Terminus WP update command finished with a non-zero exit code ($UPDATE_EXIT_CODE)."
    exit "$UPDATE_EXIT_CODE"
fi

# Display the raw update output for logging purposes
echo "$UPDATE_OUTPUT"

# Wait for update to finish
# This ensures filesystem changes are likely settled before commit attempt.
terminus workflow:wait "$TERMINUS_SITE".dev --max=15

# Parse the update output to build a dynamic commit message including versions
# Grep for lines indicating an update in the WP-CLI table summary
UPDATED_PLUGINS_LINES=$(echo "$UPDATE_OUTPUT" | grep -E '^[[:space:]]*\|.*\|.*\|.*\|[[:space:]]*Updated[[:space:]]*\|$')

if [ -n "$UPDATED_PLUGINS_LINES" ]; then
    # Use awk to extract name (field 2) and new_version (field 4)
    # Format as: Name (Version)
    PLUGIN_DETAILS=$(printf "%s" "$UPDATED_PLUGINS_LINES" | awk -F'|' '{
        gsub(/^[ \t]+|[ \t]+$/, "", $2); # Trim name
        gsub(/^[ \t]+|[ \t]+$/, "", $4); # Trim new_version
        if ($2 != "" && $4 != "") {
            print $2 " (" $4 ")" # Output formatted string
        }
    }')

    if [ -n "$PLUGIN_DETAILS" ]; then
        # Join the formatted lines with ", " using tr and sed
        UPDATED_LIST=$(echo "$PLUGIN_DETAILS" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g') # Ensure space after comma

        # Check if UPDATED_LIST was successfully created
        if [ -n "$UPDATED_LIST" ]; then
            COMMIT_MESSAGE="Update ${TYPE}s: $UPDATED_LIST" # Make message type-dynamic
            echo "Identified updated ${TYPE}s: $UPDATED_LIST"
        else
             echo "Could not join ${TYPE} details (tr/sed result empty), using default commit message."
        fi
    else
        echo "Could not extract ${TYPE} name/version details using awk, using default commit message."
    fi
else
    # Check if the output explicitly says nothing was updated
    if echo "$UPDATE_OUTPUT" | grep -q -i "No ${TYPE}s updated"; then
         echo "WP-CLI reported no ${TYPE}s needed updating."
    else
         echo "No updated ${TYPE}s found in the output table, using default commit message."
    fi
fi

# Commit the changes and capture output
echo "Attempting to commit changes with message: '$COMMIT_MESSAGE'"
COMMIT_OUTPUT=$(terminus env:commit "$TERMINUS_SITE".dev --message="$COMMIT_MESSAGE" 2>&1)

# Print commit output for logging
echo "$COMMIT_OUTPUT"

# Process the commit result
if echo "$COMMIT_OUTPUT" | grep -q "There is no code to commit"; then
    echo "Nothing to commit."
else
    terminus workflow:wait "$TERMINUS_SITE".dev --max=30 
    maybe_switch_to_git_mode "$TERMINUS_OR_LANDO"
    merge_updates_from_pantheon_to_github "$TYPE"
fi
