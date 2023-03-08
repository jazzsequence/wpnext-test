<?php
/**
 * move_dir tests
 */

namespace Pantheon\WPNext\SixTwo\MoveDir;

function bootstrap() {
	add_action( 'cmb2_admin_init', __NAMESPACE__ . '\\register_settings_page' );
	// Add action on init to handle button clicks.
	add_action( 'admin_init', __NAMESPACE__ . '\\wpnext62_init' );
}

function register_settings_page() {
	$current = get_site_transient( 'update_core' );
	$wp_version = $current->version_checked; // We're just going to assume this transient is set because otherwise shit is probably broken.
	$prefix = 'wpnext62_';
	$cmb = new_cmb2_box( [
		'id' => $prefix . 'settings',
		'title' => __( '6.2 move_dir() tests', 'wpnext62' ),
		'object_types' => [ 'options-page' ],
		'option_key' => $prefix . 'settings',
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

	// Add button to trigger a move_dir() to /uploads.
	$cmb->add_field( [
		'name' => __( 'Move Dir to Uploads', 'wpnext62' ),
		'id' => $prefix . 'move_to_uploads',
		'type' => 'button',
		'description' => __( 'This should work. A folder should be moved into the uploads directory.', 'wpnext62' ),
		'button_text' => __( 'move_dir to /uploads', 'wpnext62' ),
		'action' => 'move_to_uploads',
	] );

	// Add button to trigger a move_dir() to /wp-content.
	$cmb->add_field( [
		'name' => __( 'Move Dir to WP Content', 'wpnext62' ),
		'id' => $prefix . 'move_to_wp_content',
		'type' => 'button',
		'description' => __( 'This should fail. A folder should not be moved into the wp-content directory.', 'wpnext62' ),
		'button_text' => __( 'move_dir to /wp-content', 'wpnext62' ),
		'action' => 'move_to_wp_content',
	] );

	// Add a button to trigger a move_dir to this plugin's directory.
	$cmb->add_field( [
		'name' => __( 'Move Dir to Plugin', 'wpnext62' ),
		'id' => $prefix . 'move_to_plugin',
		'type' => 'button',
		'description' => __( 'This should fail. A folder should not be moved into the plugin directory because one of the same name would already exist.', 'wpnext62' ),
		'button_text' => __( 'move_dir to plugin', 'wpnext62' ),
		'action' => 'move_to_plugin',
	] );

	// Add a button to clean up all the test directories.
	$cmb->add_field( [
		'name' => __( 'Clean Up', 'wpnext62' ),
		'id' => $prefix . 'clean_up',
		'type' => 'button',
		'description' => __( 'This will remove all the test directories.', 'wpnext62' ),
		'button_text' => __( 'Clean Up', 'wpnext62' ),
		'action' => 'clean_up',
	] );
}

function back_up_test_dir() {
	global $wp_filesystem;
	if ( ! class_exists( 'WP_Filesystem' ) ) {
		require_once ABSPATH . '/wp-admin/includes/file.php';
	}

	WP_Filesystem();
	$source = dirname( __DIR__ ) . '/test-dir';

	$destination = dirname( __DIR__ ) . '/test-dir-backup';
	if ( $source && ! file_exists( $destination ) ) {
		$wp_filesystem->mkdir( $destination );
		copy_dir( $source, $destination );

		// Display a notice to the user that the test dir has been backed up.
		add_action( 'admin_notices', function() {
			?>
			<div class="notice notice-success is-dismissible">
				<p><?php _e( 'The test directory has been backed up.', 'wpnext62' ); ?></p>
			</div>
			<?php
		} );
	}
}

function move_to_uploads() {
	$source = dirname( __DIR__ ) . '/test-dir';
	$destination = wp_upload_dir()['basedir'] . '/test-dir';
	// Back up the test dir first.
	back_up_test_dir();
	if ( ! file_exists( $source . '/testfile.txt' ) ) {
		copy_dir( $source . '-backup', $source );
	}
	$moved = move_dir( $source, $destination );
	if ( $moved ) {
		// Display a notice to the user that the test dir has been moved.
		add_action( 'admin_notices', function() {
			?>
			<div class="notice notice-success is-dismissible">
				<p><?php _e( 'The test directory has been moved to the uploads directory.', 'wpnext62' ); ?></p>
			</div>
			<?php
		} );
	}

	if ( is_wp_error( $moved ) ) {
		// Display a notice that includes the error message.
		add_action( 'admin_notices', function() use ( $moved ) {
			?>
			<div class="notice notice-error is-dismissible">
				<p><?php _e( 'The test directory could not be moved to the uploads directory.', 'wpnext62' ); ?></p>
				<p><?php echo $moved->get_error_message(); ?></p>
			</div>
			<?php
		} );
	}
}

function move_to_wp_content() {
	$source = dirname( __DIR__ ) . '/test-dir';
	$destination = WP_CONTENT_DIR . '/test-dir';
	// Back up the test dir first.
	back_up_test_dir();
	if ( ! file_exists( $source . '/testfile.txt' ) ) {
		copy_dir( $source . '-backup', $source );
	}
	$moved = move_dir( $source, $destination );
	if ( $moved ) {
		// Display a notice to the user that the test dir has been moved.
		add_action( 'admin_notices', function() {
			?>
			<div class="notice notice-success is-dismissible">
				<p><?php _e( 'The test directory has been moved to the wp-content directory.', 'wpnext62' ); ?></p>
			</div>
			<?php
		} );
	}

	if ( is_wp_error( $moved ) ) {
		// Display a notice that includes the error message.
		add_action( 'admin_notices', function() use ( $moved ) {
			?>
			<div class="notice notice-error is-dismissible">
				<p><?php _e( 'The test directory could not be moved to the wp-content directory.', 'wpnext62' ); ?></p>
				<p><?php echo $moved->get_error_message(); ?></p>
			</div>
			<?php
		} );
	}
}

function move_to_plugin() {
	$source = dirname( __DIR__ ) . '/test-dir';
	$destination = dirname( __DIR__ ) . '/test-dir-again';
	// Back up the test dir first.
	back_up_test_dir();
	if ( ! file_exists( $source . '/testfile.txt' ) ) {
		copy_dir( $source . '-backup', $source );
	}
	$moved = move_dir( $source, $destination );

	if ( $moved ) {
		// Display a notice to the user that the test dir has been moved.
		add_action( 'admin_notices', function() {
			?>
			<div class="notice notice-success is-dismissible">
				<p><?php _e( 'The test directory has been moved to the plugin directory.', 'wpnext62' ); ?></p>
			</div>
			<?php
		} );
	}

	if ( is_wp_error( $moved ) ) {
		// Display a notice that includes the error message.
		add_action( 'admin_notices', function() use ( $moved ) {
			?>
			<div class="notice notice-error is-dismissible">
				<p><?php _e( 'The test directory could not be moved to the plugin directory.', 'wpnext62' ); ?></p>
				<p><?php echo $moved->get_error_message(); ?></p>
			</div>
			<?php
		} );
	}
}

// Recreate /test-dir from /test-dir-backup if it no longer exists.
function recreate_test_dir() {
	global $wp_filesystem;
	if ( ! class_exists( 'WP_Filesystem' ) ) {
		require_once ABSPATH . '/wp-admin/includes/file.php';
	}

	WP_Filesystem();
	$source = dirname( __DIR__ ) . '/test-dir-backup';
	$destination = dirname( __DIR__ ) . '/test-dir';
	if ( ! file_exists( $destination ) ) {
		$wp_filesystem->mkdir( $destination );
		copy_dir( $source, $destination );
	}
}

// Function to clean up all the test files and directories.
function clean_up() {
	$paths = [
		dirname( __DIR__ ) . '/test-dir-backup',
		dirname( __DIR__ ) . '/test-dir-again',
		WP_CONTENT_DIR . '/test-dir',
		wp_upload_dir()['basedir'] . '/test-dir',
	];

	foreach ( $paths as $path ) {
		if ( file_exists( $path . '/testfile.txt' ) ) {
			unlink( $path . '/testfile.txt' );
			rmdir( $path );
		}
	}

	// Add a notice to the user that the test files and directories have been cleaned up.
	add_action( 'admin_notices', function() {
		?>
		<div class="notice notice-success is-dismissible">
			<p><?php _e( 'The test files and directories have been cleaned up.', 'wpnext62' ); ?></p>
		</div>
		<?php
	} );
}

// Function to fire on init to check the action and do the thing.
function wpnext62_init() {
	if ( isset( $_GET['action'] ) ) {
		switch ( $_GET['action'] ) {
			case 'move_to_uploads':
				move_to_uploads();
				break;
			case 'move_to_wp_content':
				move_to_wp_content();
				break;
			case 'move_to_plugin':
				move_to_plugin();
				break;
			case 'clean_up':
				clean_up();
				break;
		}
	}

	// Recreate the test dir if it no longer exists.
	recreate_test_dir();
}
