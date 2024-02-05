<?php

/**
 * Pantheon mu-plugin customizations to the WP Font Library.
 *
 * @package pantheon
 */

namespace Pantheon\Fonts;

/**
 * Modify the fonts directory.
 *
 * By default, this is set to true, so we can override the default fonts directory from wp-content/fonts to wp-content/uploads/fonts.
 *
 * Use the filter to set to false and use the default WordPress behavior (committing fonts to your repository and pushing from dev -> test -> live).
 *
 * @param bool $modify Whether to modify the fonts directory.
 */
define( 'PANTHEON_MODIFY_FONTS_DIR', apply_filters( 'pantheon_modify_fonts_dir', true ) );

if ( PANTHEON_MODIFY_FONTS_DIR ) {
	// Use the new fonts_dir filter added in WordPress 6.5. See https://github.com/WordPress/gutenberg/pull/57697.
	if ( ! class_exists( 'WP_Font_Library' ) ) {
		require WP_PLUGIN_DIR . '/gutenberg/lib/experimental/fonts/font-library/class-wp-font-library.php';
	}
	$defaults = \WP_Font_Library::fonts_dir();
	pantheon_wp_fonts_dir( apply_filters( 'fonts_dir', $defaults ) );
	add_filter( 'fonts_dir', 'pantheon_wp_fonts_dir' );
}

/**
 * Define a custom font directory for the WP Font Library.
 */
function pantheon_wp_fonts_dir( $defaults ) {
	var_dump( $defaults ); exit;
	$wp_upload_dir = wp_get_upload_dir();
	$uploads = $wp_upload_dir['basedir'];

	/**
	 * Filter the fonts directory.
	 *
	 * By default, this is set to wp-content/uploads/fonts. Use this filter to set the fonts directory to any other location.
	 */
	$fonts_dir = apply_filters( 'pantheon_wp_fonts_dir', $uploads . '/fonts' );
	return $fonts_dir;
}
