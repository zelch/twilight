<?php
	$title = "Bug Tracking";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");

	box ("title", "Bug Tracking");

	box ("para", "Project Twilight does not yet have a convenient\n" .
		"bug-tracking system online.&nbsp; For now, just send your bugs\n" .
		"to <a href=\"mailto:twilight-devel@lists.sourceforge.net\">\n" .
		"twilight-devel@lists.sourceforge.net</a>, we'll get them.&nbsp;\n" .
		"Better bug-tracking is coming, we promise.&nbsp; Hopefully soon.\n"
	);

	require ($pageroot . "/include/footer.php");
?>
