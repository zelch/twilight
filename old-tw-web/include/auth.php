<?php
	require($pageroot . "/include/sql.php");

	function notauth() {
                header("WWW-Authenticate: Basic realm=\"Twilight members area\"");
                header("HTTP/1.0 401 Unauthorized");


                // Make the access denied message look nice.

                $title = "Access Denied";
                require ($pageroot . "/include/header.php");

                print("This page is for members only. Please log in.\n");

                require ($pageroot . "/include/footer.php");




                exit;
	}

	if(!isset($PHP_AUTH_USER)) {
		notauth();
	} else {
	}
?>
