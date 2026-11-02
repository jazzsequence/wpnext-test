#!/usr/bin/env bash
# shellcheck disable=SC1094

source scripts/helpers.sh

wp_version=$(get_latest_wp_release)
TYPE="core"

echo "Updating WordPress $TYPE to $wp_version..."
terminus wp -- "$TERMINUS_SITE".dev $TYPE update --version=nightly --force

# `wp core update` runs over SSH and does not start a Pantheon workflow, so there
# is nothing for `workflow:wait` to wait on. Pantheon detects SFTP file changes
# asynchronously, and committing before the scan catches up reports "There is no
# code to commit" even though the update succeeded. Poll the diffstat until the
# changed files show up instead.
wait_for_uncommitted_changes() {
    local site_env=$1
    local timeout=${DIFFSTAT_TIMEOUT:-300}
    local interval=${DIFFSTAT_INTERVAL:-10}
    local waited=0
    local changed

    while [ "$waited" -lt "$timeout" ]; do
        # A clean env returns [{"file": 0}] rather than [], so only count rows
        # whose `file` is an actual path.
        changed=$(terminus env:diffstat "$site_env" --format=json 2>/dev/null \
            | jq '[.[]? | select((.file | tostring) != "0")] | length' 2>/dev/null || echo 0)

        if [ "${changed:-0}" -gt 0 ]; then
            echo "Detected ${changed} uncommitted file change(s) on ${site_env}."
            return 0
        fi

        sleep "$interval"
        waited=$((waited + interval))
    done

    echo "No uncommitted changes detected on ${site_env} after ${timeout}s; the site may already be up to date." >&2
    return 1
}

# Not fatal on timeout: the site may genuinely already be on this version, and
# `env:commit` below reports "There is no code to commit" in that case.
wait_for_uncommitted_changes "$TERMINUS_SITE".dev || true

# Commit the changes and capture output
COMMIT_OUTPUT=$(terminus env:commit "$TERMINUS_SITE".dev --message="Updating WordPress ${TYPE} to ${wp_version}" 2>&1)

# Print output for debugging/logging
echo "$COMMIT_OUTPUT"

if echo "$COMMIT_OUTPUT" | grep -q "There is no code to commit"; then
    echo "Nothing to commit"
else
    # Wait for the workflow to finish
    terminus workflow:wait "$TERMINUS_SITE".dev --max=30

    maybe_switch_to_git_mode "$TERMINUS_OR_LANDO"

    merge_updates_from_pantheon_to_github $TYPE
fi