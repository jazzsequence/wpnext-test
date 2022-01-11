<?php

if ( ! function_exists( 'jazzsequence_blox_support' ) ) :
	function jazzsequence_blox_support()  {

		// Adding support for core block visual styles.
		add_theme_support( 'wp-block-styles' );

		// Enqueue editor styles.
		add_editor_style( 'style.css' );
	}
	add_action( 'after_setup_theme', 'jazzsequence_blox_support' );
endif;

/**
 * Enqueue scripts and styles.
 */
function jazzsequence_blox_scripts() {
	// Enqueue theme stylesheet.
	wp_enqueue_style( 'jazzsequence-blox-style', get_template_directory_uri() . '/style.css', array(), wp_get_theme()->get( 'Version' ) );
}

add_action( 'wp_enqueue_scripts', 'jazzsequence_blox_scripts' );
