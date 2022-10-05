<?php

$_mu_plugins = [
	'pantheon-mu-plugin/pantheon.php',
];

foreach ( $_mu_plugins as $mu_plugin ) {
	require_once $mu_plugin;
}
