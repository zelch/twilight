<?php
	require($pageroot . "/include/sql.php");

	function notauth() {
		global $pagerealm, $usertable, $newacct;
		header("WWW-Authenticate: Basic realm=\"" . $pagerealm . "\"");
                header("HTTP/1.0 401 Unauthorized");

                // Make the access denied message look nice.

                $title = "Access Denied";
                require ($pageroot . "/include/header.php");

		box("para", "This page requires authorization. Please log in. \n");

		if($newacct) {
			//create new account form here
		}

                require ($pageroot . "/include/footer.php");

                exit;
	}

	if(sqlAvail) {
		if(!isset($PHP_AUTH_USER)) {
			notauth();
		} else {
		}
	} else {
		$title = "Authorization system error";
		require ($pageroot . "/include/header.php");
		box("para", "There is no SQL server available to authenticate users. Please try back later.\n");
		require ($pageroot . "/include/footer.php");
		exit;
	}
?>
