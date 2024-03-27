#!/bin/bash

source scripts/helpers.sh

wp="lando wp"
wp_version=$(get_latest_wp_release)

echo "Starting Lando..."
lando start

echo "Updating Plugins..."
$wp plugin update --all
git add wp-content/plugins
git commit -m "Updating WordPress plugins"

echo "Updating Themes..."
$wp theme update --all
git add wp-content/themes
git commit -m "Updating WordPress themes"

set -e
echo "Updating WordPress Core to $wp_version..."
$wp core update --version=$wp_version --force
git add .
git commit -m "Updating WordPress core $wp_version"
set +e

echo "Pushing changes to Pantheon..."
git push origin master

terminus env:deploy wp59-test.test --note="Updating WordPress core, plugins, and themes"
terminus env:deploy wp59-test.live --note="Updating WordPress core, plugins, and themes"