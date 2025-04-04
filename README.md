# WordPress Release Tester

This is an [empty WordPress upstream](https://github.com/pantheon-systems/empty-wp)-based site with the [Beta Tester](https://wordpress.org/plugins/wordpress-beta-tester/) plugin to facilitate tests for upcoming (alpha, beta, RC) releases of WordPress.

The site includes various plugins to test new functionality or compatibility and scripts to assist in managing updates.

## Getting Started

**Site ID:** `wpnext-test`

### 1. Clone the site repository locally

```bash
terminus local:clone wpnext-test && cd ~/pantheon-local-copies/wpnext-test
```

### 2. Set a local `exclude` file

You can ignore files locally but not in the repository. We do this so we're not committing Composer-managed packages to the repository but they will get committed and pushed to Pantheon. To do this, in your IDE open `.git/info/exclude` and add the following lines:

```
# WordPress plugins managed by Composer
vendor/
wp-content/plugins/wordpress-importer
wp-content/plugins/test-reports
wp-content/plugins/games-collector
!wp-content/plugins/games-collector/vendor
wp-content/mu-plugins/cmb2
wp-content/plugins/git-updater
wp-content/mu-plugins/pantheon-mu-plugin
```

### 3. Run Composer install

Many of the dependencies use Composer. It's assumed you have Composer installed locally, if not, you will need to [install that first](https://getcomposer.org/doc/00-intro.md#installation-linux-unix-macos).

```bash
composer install
```

### 4. Start Lando (optional)

The project includes a `.lando.example-yml` file as well for local development using Lando. Your mileage may vary with your specific Lando configuration. However, if your Terminus account has access to the site, you should be able to run `lando start` (assuming [Lando is installed](https://lando.dev/download/)) to get a local environment, and then `lando pull -c none -f dev -d dev` to pull files and database from Pantheon.

## Using the built-in tools

There are four main commands that are added to the Composer config to help with tests.

### `check-latest-wp`

This command will check the latest version of WordPress, including beta and RC versions. It's used by `wordpress-update` to determine which version of WordPress is available. It does not look for nightly releases.

#### Usage
```bash
composer check-latest-wp
```

#### Example return output
```
> source ./scripts/helpers.sh && get_latest_wp_release
6.8-RC1
```

### `deploy`

Runs the `scripts/deploy.sh` script. This is a shortcut for deploying the latest changes on the Dev environment to Test and Live.

#### Usage
```bash
composer deploy
```

### `wordpress-update`

This command will update WordPress core, plugins or themes to to the latest version. This can be run either by using Terminus or locally with Lando and a prompt will appear to ask for your method of updating when you run the command.

#### Updating via Lando

If updating with Lando, you can update plugins, themes, or WordPress core to the latest alpha, beta or RC version (or all three) by specifying at the next prompt. It will use `lando wp` commands to pull down the changes and then automatically commit those changes to your local environment and push them to the Dev environment.

#### Updating via Terminus

If updating with Terminus, the behavior is mostly the same. Rather than installing the changes locally first, the script will run `terminus wp` commands to update the plugin, theme or latest alpha, beta or RC version of WordPress core. One notable difference with the Terminus option is that there is not (currently) support for running updates on all three things in one command -- plugins, themes and core updates are handled separately. Once the updates are applied on the Dev environment, the script will commit the updates and pull the changes down locally.

#### Usage
```bash
composer wordpress-update
```

### `test`

Prepares and runs the [`pantheon-systems/pantheon-wordpress-upstream-tests](https://github.com/pantheon-systems/pantheon-wordpress-upstream-tests) Behat test suite against a new `behat` multidev that is branched from a barebones `test-base` multidev environment. The `test-base` and `behat` environments have been tuned to remove the custom plugins added to the base Dev environment and the database is wiped when the tests are initialized.

A WordPress update is run to the latest alpha, beta or RC version of WordPress if the current version does not match the latest.

#### Usage
```bash
composer test
```
