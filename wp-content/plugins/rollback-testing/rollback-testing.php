<?php
/**
 * Rollback Update Testing
 *
 * @package rollback-update-testing
 * @author Andy Fragen <andy@thefragens.com>
 * @license MIT
 */

/**
 * Plugin Name:       Rollback Update Testing
 * Plugin URI:        https://gist.github.com/afragen/80b68a6c8826ab37025b05d4519bb4bf
 * Description:       This plugin is used for Rollback Update Failure feature plugin testing to simulate a failure.
 * Version:           0.2
 * Author:            Andy Fragen
 * License:           MIT
 * Requires at least: 5.2
 * Requires PHP:      5.6
 * Gist Plugin URI:   https://gist.github.com/afragen/80b68a6c8826ab37025b05d4519bb4bf
 */

add_filter( 'rollback_update_testing', '__return_true' );

add_filter( 'upgrader_install_package_result', function() {
    return new WP_Error( 'simulated_error', 'Simulated Error' );
});
