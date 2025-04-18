<?php

final class WP_Notify_User_Recipient implements WP_Notify_Recipient {

	private $user_id;
	private $user_object;

	public function __construct( $user_id ) {
		$this->user_id = $this->validate( $user_id );
	}

	public function get_user_id() {
		return $this->user_id;
	}

	public function get_user_object() {
		if ( null === $this->user_object ) {
			$this->user_object = new WP_User( $this->user_id );
		}

		return $this->user_object;
	}

	private function validate( $user_id ) {
		if ( ! is_numeric( $user_id )
			|| ! ( ( (int) $user_id ) > 0 ) ) {
			throw WP_Notify_Invalid_Recipient::from_invalid_user_id( $user_id );
		}

		return $user_id;
	}
}
