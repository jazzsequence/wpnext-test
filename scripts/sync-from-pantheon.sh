#!/usr/bin/env bash
# shellcheck disable=SC1094

# Pull whatever is committed on Pantheon (pantheon/master) back into GitHub main.
# Used when Pantheon dev is on a different WordPress version than the repo but
# there is no newer WordPress to install, so wordpress-update.sh doesn't run.

set -e

source scripts/helpers.sh

merge_updates_from_pantheon_to_github core
