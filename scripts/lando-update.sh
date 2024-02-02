#!/bin/bash

wp="lando wp"

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

echo "Updating WordPress Core..."
$wp core update --version=latest --force
git add .
git commit -m "Updating WordPress core"

echo "Pushing changes to Pantheon..."
git push origin master
