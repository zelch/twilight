<?php
	$title = "Mailing Lists";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	box ("title", "Subscription to " . $sub_list);

	if ($sub_email) {
		mail (
			$sub_list . "-request@fwsoftware.com",
			"Automated subscription request ($sub_email)",
			"subscribe $sub_list $sub_email\n" .  ($sub_digest == "on" ? "set $sub_list DIGEST\n" : ""),
			"From: " . $sub_email
		);

		box ("para", "Request sent, " . $sub_email . " should be getting\n" .
			"a confirmation message soon."
		);
	} else {
		box ("para", "No email address specified, no action taken.");
	}

	box ("para", "Click <a href=\"/lists.php\">here</a> to continue.\n");

	require ($pageroot . "/include/footer.php");
?>
