<?php
/**
 * Plugin Name: 6.2 Plugin Test
 * Description: Test plugin for 6.2
 * Version: 1.0
 * Author: Chris Reynolds
 * Author URI: https://chrisreynolds.io
 * License: MIT
 */

namespace Pantheon\WPNext\SixTwo;

use WP_HTML_Tag_Processor;

function bootstrap_62() {
	// Require CMB2 from /vendor.
	require __DIR__ . '/vendor/cmb2/cmb2/init.php';
	require_once __DIR__ . '/inc/move-dir.php';
	require_once __DIR__ . '/inc/html-tag-processor.php';

	MoveDir\bootstrap();
	HTML_Tag_Processor\bootstrap();

	add_action( 'cmb2_render_button', __NAMESPACE__ . '\\cmb2_render_callback_for_button', 10, 5 );
	add_action( 'cmb2_render_html-tag-processor-test', __NAMESPACE__ . '\\cmb2_render_callback_for_html_tag_processor_test', 10, 5 );
}

function cmb2_render_callback_for_button( $field, $escaped_value, $object_id, $object_type, $field_type_object ) {
	$button_text = $field->args()['button_text'];
	$action = [ 'action' => $field->args()['action'] ];
	$page = [ 'page' => 'wpnext62_settings' ];
	?>
	<a href="<?php echo esc_url( add_query_arg( array_merge( $action, $page ), admin_url( 'options-general.php' ) ) ); ?>" class="button">
		<?php echo $button_text; ?>
	</a><br />
	<p><?php echo $field->args()['description']; ?></p>
	<?php
}

function cmb2_render_callback_for_html_tag_processor_test() {
	ob_start();
	?>
	<div class="html-tag-processor-test">
		<p>Test</p>
		<p>Test</p>
		<p>Test</p>
		<img src="https://placekitten.com/300/200" alt="Kitten" />
		<figure>
			<img src="https://placekitten.com/300/200" alt="Kitten" />
			<figcaption>Inner HTML is not editable yet, so this caption be changed.</figcaption>
		</figure>
		<picture>
			<source srcset="https://placekitten.com/600/400?image=1" media="(min-width: 600px)" />
			<img src="https://placekitten.com/300/200?image=1" alt="Kitten" />
		</picture>
	</div>
	<?php
	$html_before = ob_get_clean();
	$html_after = new WP_HTML_Tag_Processor( $html_before );

	while ( $html_after->next_tag( [ 'tag_name' => 'p' ] ) ) {
		$html_after->add_class( 'lead' );
	}

	// Since we just looped through all the markup, we need to instantiate the Tag Processor again so we can do other stuff. This probably isn't super efficient but it's a fun experiment.
	$html_after = new WP_HTML_Tag_Processor( $html_after->get_updated_html() );

	$query = [
		'tag_name' => 'img'
	];

	while ( $html_after->next_tag( $query ) ) {
		$html_after->add_class( 'img-responsive' );
		$html_after->set_attribute( 'alt', 'Placed Kitten' );
	}

	if ( $html_after->next_tag( [ 'tag_name' => 'figure' ] ) ) {
		$html_after->add_class( 'figure' );
		if ( $html_after->next_tag( $query ) ) {
			$html_after->add_class( 'figure-img' );
			$html_after->set_attribute( 'alt', 'Placed Kitten' );
		}
	}
	if ( $html_after->next_tag( [ 'tag_name' => 'figcaption' ] ) ) {
		$html_after->add_class( 'figure-caption' );
	}

	$css = 'overflow: auto; word-wrap: break-word; white-space: pre-wrap; border: 1px solid #ccc; padding: 1em;';
	?>
	<p>Source before:</p>
	<pre style="<?php echo esc_attr( $css ); ?>">
<?php echo esc_html( $html_before ); ?>
	</pre>
	<p>Source after:</p>
	<pre style="<?php echo esc_attr( $css ); ?>">
<?php echo esc_html( $html_after->get_updated_html() ); ?>
	</pre>
	<?php
}

add_action( 'plugins_loaded', __NAMESPACE__ . '\\bootstrap_62' );