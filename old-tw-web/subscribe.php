<?php
	$title = "Mailing Lists";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	box ("title", "Subscription to " . $sub_list);

	if ($sub_email) {
		mail (
			$sub_list . "-request@lists.sourceforge.net" ,
			"subscribe" .  ($sub_digest == "on"? " digest ": " nodigest "),
			"--",
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
