<?php

/**
 * Plugin Name: Horror Ipsum Generator
 * Description: A horror-themed Lorem Ipsum generator inside a Gutenberg block for adding spooky filler text.
 * Version: 1.0.1
 * Author: Chris Reynolds
 * Author URI: https://www.chrisreynolds.io
 * License: MIT
 * License URI: https://opensource.org/licenses/MIT
 * GitHub Plugin URI: jazzsequence/horror-ipsum
 * Primary Branch: main
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

function horror_ipsum_texts() {
	$ipsum = file_get_contents( plugin_dir_path( __FILE__ ) . 'assets/json/quotes.json' );
	return apply_filters( 'horror_ipsum_text', json_decode( $ipsum, true ) );
}

// Register the block script.
function horror_ipsum_register_block() {
	wp_register_script(
		'horror-ipsum-block',
		plugins_url( 'assets/js/block.js', __FILE__ ),
		['wp-blocks', 'wp-element', 'wp-block-editor'],
		filemtime( plugin_dir_path( __FILE__ ) . 'assets/js/block.js' )
	);

	// Localize the script to pass PHP data to JavaScript.
	wp_localize_script(
		'horror-ipsum-block',
		'horrorLipsumData',
		[ 'texts' => horror_ipsum_texts() ]
	);

	register_block_type(
		'horror-ipsum/random-paragraph', 
		['editor_script' => 'horror-ipsum-block']
	);
}
add_action( 'init', 'horror_ipsum_register_block' );

// Enqueue the CSS for the block.
function horror_ipsum_enqueue_styles()
{
	wp_enqueue_style(
		'horror-ipsum-style',
		plugins_url( 'assets/css/style.css', __FILE__ ),
		[],
		filemtime( plugin_dir_path( __FILE__ ) . 'assets/css/style.css' )
	);
}
add_action( 'enqueue_block_editor_assets', 'horror_ipsum_enqueue_styles' );
