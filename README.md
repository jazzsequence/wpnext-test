# WordPress Release Tester

[![GitHub deployments](https://img.shields.io/github/deployments/jazzsequence/wpnext-test/dev?logo=pantheon&logoColor=yellow&label=deployment&labelColor=black)](https://dev-wpnext-test.pantheonsite.io)
[![Weekly Platform Test](https://github.com/jazzsequence/wpnext-test/actions/workflows/weekly-platform-test.yml/badge.svg)](https://github.com/jazzsequence/wpnext-test/actions/workflows/weekly-platform-test.yml)
[![Shellcheck](https://github.com/jazzsequence/wpnext-test/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/jazzsequence/wpnext-test/actions/workflows/shellcheck.yml)

This is an [empty WordPress upstream](https://github.com/pantheon-systems/empty-wp)-based site with the [Beta Tester](https://wordpress.org/plugins/wordpress-beta-tester/) plugin to facilitate tests for upcoming (alpha, beta, RC) releases of WordPress.

The site includes various plugins to test new functionality or compatibility and scripts to assist in managing updates.

## Getting Started

[![Dev environment](https://img.shields.io/badge/dev-yellow?logo=pantheon&logoColor=yellow&label=wpnext-test&labelColor=black&color=yellow
)](https://dev-wpnext-test.pantheonsite.io)
[![Test environment](https://img.shields.io/badge/test-yellow?logo=pantheon&logoColor=yellow&label=wpnext-test&labelColor=black&color=yellow
)](https://test-wpnext-test.pantheonsite.io)
[![Live environment](https://img.shields.io/badge/live-yellow?logo=pantheon&logoColor=yellow&label=wpnext-test&labelColor=black&color=yellow
)](https://live-wpnext-test.pantheonsite.io)

**Site ID:** `wpnext-test`

### 1. Clone the site repository locally

This project uses GitHub as the source of truth, but some scripts assume WP-CLI is run on the Pantheon site directly. For this reason you'll want to clone from GitHub but add Pantheon as a remote.

```bash
git clone git@github.com:jazzsequence/wpnext-test.git && cd wpnext-test
```

### 2. Add the `pantheon` remote

```bash
site_id=$(terminus site:info --fields=id --format=list)
git remote add pantheon ssh://codeserver.dev."$site_id"@codeserver.dev."$site_id".drush.in:2222/~/repository.git
```

### 3. Set a local `exclude` file

You can ignore files locally but not in the repository. We do this so we're not committing Composer-managed packages to the repository but they will get committed and pushed to Pantheon. To do this, in your IDE open `.git/info/exclude` and add the following lines:

```
# WordPress plugins managed by Composer
vendor/
vendor/composer/
wp-content/plugins/test-reports
wp-content/plugins/games-collector
!wp-content/plugins/games-collector/vendor
wp-content/mu-plugins/cmb2
wp-content/plugins/git-updater
wp-content/mu-plugins/pantheon-mu-plugin
wp-content/plugins/mailpoet
wp-content/plugins/wp-cfm
wp-content/plugins/gutenberg
wp-content/plugins/wordpress-beta-tester
```

### 4. Run Composer install

Many of the dependencies use Composer. It's assumed you have Composer installed locally, if not, you will need to [install that first](https://getcomposer.org/doc/00-intro.md#installation-linux-unix-macos).

```bash
composer install
```

### 5. Start Lando (optional)

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

Since the GitHub repository is intended to be the source of truth, after a Terminus-based update, the code will need to be pushed up to the GitHub repository. This is handled automatically by the update scripts. The `wordpress-update` script -- as well as the [Deploy to Pantheon](https://github.com/jazzsequence/wpnext-test/actions/workflows/deploy-to-pantheon.yml) GitHub action will attempt to check whether code _needs_ to be pushed to Pantheon to prevent double-commits. Additionally, updating certain files (like [actions](https://github.com/jazzsequence/wpnext-test/tree/main/.github/workflows), [scripts](https://github.com/jazzsequence/wpnext-test/tree/main/scripts) or this README) will not trigger a deploy to Pantheon.

#### Usage
```bash
composer wordpress-update
```

### `test`

Prepares and runs the [`pantheon-systems/pantheon-wordpress-upstream-tests`](https://github.com/pantheon-systems/pantheon-wordpress-upstream-tests) Behat test suite against a new `behat` multidev that is branched from a barebones `test-base` multidev environment. The `test-base` and `behat` environments have been tuned to remove the custom plugins added to the base Dev environment and the database is wiped when the tests are initialized.

A WordPress update is run to the latest alpha, beta or RC version of WordPress if the current version does not match the latest.

This script is set to run [weekly](https://github.com/jazzsequence/wpnext-test/actions/workflows/weekly-platform-test.yml) using GitHub Actions internal cron.

#### Usage
```bash
composer test
```

## Using the GitHub Actions manually

The [Weekly Platform Test](https://github.com/jazzsequence/wpnext-test/actions/workflows/weekly-platform-test.yml) (Behat tests), [Deploy to Test or Live](https://github.com/jazzsequence/wpnext-test/actions/workflows/deploy-test-live.yml) and [Deploy to WPNext-Test](https://github.com/jazzsequence/wpnext-test/actions/workflows/deploy-to-pantheon.yml) workflows can all be triggered manually.

### Weekly Platform Test
These tests run on a weekly basis and are triggered by a cron job. They run the `composer test` command to run the Behat tests against the `behat` multidev environment. To trigger manually, navigate to the [Weekly Platform Test action](https://github.com/jazzsequence/wpnext-test/actions/workflows/weekly-platform-test.yml) and click the "Run workflow" button. There are no options for this other than to run against a branch (defaults to `main`).

### Deploy to Test or Live
This workflow will deploy the latest available code to the specified environment (default is `test`). You have the option of creating a backup of the site prior to deploying (default is `yes`). To trigger the deploy from GitHub, navigate to [(Manual) Deploy to Test or Live](https://github.com/jazzsequence/wpnext-test/actions/workflows/deploy-test-live.yml) and click the "Run workflow" button, specifying your selections for branch (default is `main`), environment and backup. This action is not triggered automatically.

### Deploy to WPNext-Test
This workflow is automatically triggered when there are any code changes (excluding GitHub workflow changes, scripts and updates to this README) on the repository. It can be triggered manually by navigating to [Deploy to WPNext-Test](https://github.com/jazzsequence/wpnext-test/actions/workflows/deploy-to-pantheon.yml),clicking the "Run workflow" button and specifying a branch (default is `main`).