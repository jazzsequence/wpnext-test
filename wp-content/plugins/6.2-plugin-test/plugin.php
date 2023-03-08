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

function bootstrap_62() {
	// Require CMB2 from /vendor.
	require __DIR__ . '/vendor/cmb2/cmb2/init.php';
	require_once __DIR__ . '/inc/move-dir.php';

	MoveDir\bootstrap();

	add_action( 'cmb2_render_button', __NAMESPACE__ . '\\cmb2_render_callback_for_button', 10, 5 );
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

add_action( 'plugins_loaded', __NAMESPACE__ . '\\bootstrap_62' );