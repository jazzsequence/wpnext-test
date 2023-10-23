<?php
/**
 * Plugin Name: Pantheon
 * Plugin URI: https://pantheon.io/
 * Description: Building on Pantheon's and WordPress's strengths, together.
 * Version: 1.2.0
 * Author: Pantheon
 * Author URI: https://pantheon.io/
 *
 * @package pantheon
 */
$_mu_plugins = [
	'pantheon-mu-plugin/pantheon.php',
];

foreach ( $_mu_plugins as $mu_plugin ) {
	require_once $mu_plugin;
}
