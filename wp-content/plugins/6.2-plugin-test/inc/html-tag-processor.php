<?php
/**
 * WP_HTML_Tag_Processor tests
 */

namespace Pantheon\WPNext\SixTwo\HTML_Tag_Processor;

function bootstrap() {
	add_action( 'cmb2_admin_init', __NAMESPACE__ . '\\register_settings_page' );
}

function register_settings_page() {
	$current = get_site_transient( 'update_core' );
	$wp_version = $current->version_checked; // We're just going to assume this transient is set because otherwise shit is probably broken.
	$prefix = 'wpnext62_';
	$cmb = new_cmb2_box( [
		'id' => $prefix . 'tag-processor',
		'title' => __( '6.2 WP_HTML_Tag_Processor tests', 'wpnext62' ),
		'object_types' => [ 'options-page' ],
		'option_key' => $prefix . 'tag-processor',
		'parent_slug' => 'options-general.php',
		'save_button' => __( 'Nothing to save here', 'wpnext62' ),
	] );

	$cmb->add_field( [
		'name' => __( 'WP Version', 'wpnext62' ),
		'id' => $prefix . 'wp_version',
		'type' => 'text',
		'default' => $wp_version,
		'attributes' => [
			'readonly' => 'readonly',
		],
	] );

	$cmb->add_field( [
		'name' => __( 'HTML Tag Processor', 'wpnext62' ),
		'id' => $prefix . 'html_tag_processor',
		'type' => 'html-tag-processor-test',
	] );
}
