<?php
	$title = "Links";
	$section = "Links";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	box ("title", "Links");

	box ("para", "If you can think of a link we should have here and\n" .
		"you don't see it, please let us know!\n"
	);

	box ("line", "<a href=\"http://www.open-quake.com/\">OpenQuake</a>\n");

	require ($pageroot . "/include/footer.php");
?>
