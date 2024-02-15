<?php

/**
 * Plugin Name: Disable Pantheon Font Handling
 * Plugin URI: https://pantheon.io/
 * Description: Disables Pantheon's override of WordPress default font handling.
 * Version: 1.0.0
 * Author: Chris Reynolds
 */

add_action( 'init', function() {
	add_filter( 'pantheon_modify_fonts_dir', '__return_false' );
} );