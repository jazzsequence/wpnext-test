#!/bin/bash
# shellcheck disable=SC1094

source scripts/helpers.sh

wp="lando wp"
wp_version=$(get_latest_wp_release)

get_lando

update_plugins() {
	echo "Updating Plugins..."
	$wp plugin update --all
	git add wp-content/plugins/*
	git commit -m "Updating WordPress plugins"
}

update_themes() {
	echo "Updating Themes..."
	$wp theme update --all
	git add wp-content/themes/*
	git commit -m "Updating WordPress themes"
}

update_core() {
	echo "Updating WordPress Core..."
	$wp core update --version="$wp_version" --force
	git add .
	git commit -m "Updating WordPress core $wp_version"
}

update_all() {
	update_core
	update_plugins
	update_themes
}

read -p "Enter the type of update you would like to perform (c or core, p or plugin, t or theme, a or all): " -r UPDATE_TYPE

# Run the script based on the update type.
if [ "$UPDATE_TYPE" == "c" ] || [ "$UPDATE_TYPE" == "core" ]; then
  update_core
elif [ "$UPDATE_TYPE" == "p" ] || [ "$UPDATE_TYPE" == "plugin" ]; then
  update_plugins
elif [ "$UPDATE_TYPE" == "t" ] || [ "$UPDATE_TYPE" == "theme" ]; then
  update_themes
elif [ "$UPDATE_TYPE" == "a" ] || [ "$UPDATE_TYPE" == "all" ]; then
  echo "Updating WordPress core, plugins, and themes..."
  update_all
else
  echo "Invalid update type. Please try again."
  exit 1
fi

echo "Pushing changes to GitHub..."
git push origin master

terminus workflow:wait "$TERMINUS_SITE".dev

terminus env:deploy "$TERMINUS_SITE".test --note="Updating WordPress core, plugins, and themes"
terminus env:deploy "$TERMINUS_SITE".live --note="Updating WordPress core, plugins, and themes"