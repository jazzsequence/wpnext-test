<?php
/**
 * Plugin Name: 6.4 Admin Notice Test
 * Plugin URI: https://dev-wp59-test.pantheonsite.io
 * Description: This plugin adds an admin notice to the WordPress dashboard.
 * Version: 1.0.0
 * Author: Chris Reynolds
 * License: MIT
 */

namespace Pantheon\WPNext\SixFour\AdminNotices;

// Add an admin notice to the WordPress dashboard.
add_action( 'admin_notices', __NAMESPACE__ . '\\do_admin_notice' );

function do_admin_notice() {
	wp_admin_notice(
		__( '6.4 Admin notice' ),
		[
			'type' => 'notice-warning',
			'dismissable' => true,
			'additional_classes' => [ 'pantheon', 'pantheon-notice', '6.4-notice' ],
			'attributes' => [ 'data-slug' => 'pantheon-admin-notice' ]
		]
	);
}