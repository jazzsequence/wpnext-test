<?php
/**
 * Plugin Name: 6.8 Test
 * Description: Test  Menu thingie for Rest API
 * Version: 1.0
 * Author: Chris Reynolds
 * Author URI: https://chrisreynolds.io
 * License: MIT
 */
add_filter( 'rest_menu_read_access', '__return_true' );

add_filter( 'wp_prevent_unsupported_mime_type_uploads', '__return_false' );