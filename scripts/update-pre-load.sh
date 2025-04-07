#!/bin/bash
set -e

dir=$(pwd)/scripts

export TERMINUS_SITE="wpnext-test"

echo "Logging into Terminus. If this fails, make sure you're logged into terminus first."
terminus auth:login

read -p "Use Terminus or Lando? (t or l): " -r TERMINUS_OR_LANDO
if [ $TERMINUS_OR_LANDO == "t" ]; then
  echo "Updating WordPress with Terminus."
elif [ $TERMINUS_OR_LANDO == "l" ]; then
  echo "Updating WordPress with Lando."
  bash ${dir}/lando-update.sh
  exit 0
else
  echo "Invalid option. Please try again."
  exit 1
fi

# Switch to SFTP mode
terminus connection:set $TERMINUS_SITE.dev sftp

read -p "Enter the type of update you would like to perform (c or core, p or plugin, t or theme): " -r UPDATE_TYPE

# Run the script based on the update type.
if [ $UPDATE_TYPE == "c" ] || [ $UPDATE_TYPE == "core" ]; then
  echo "Updating WordPress core..."
  bash ${dir}/wordpress-update.sh
elif [ $UPDATE_TYPE == "p" ] || [ $UPDATE_TYPE == "plugin" ]; then
  echo "Updating WordPress plugins..."
  bash ${dir}/wordpress-plugin-update.sh
elif [ $UPDATE_TYPE == "t" ] || [ $UPDATE_TYPE == "theme" ]; then
  echo "Updating WordPress themes..."
  bash ${dir}/wordpress-theme-update.sh
else
  echo "Invalid update type. Please try again."
  exit 1
fi
