<?php
	$title = "Releases";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");

	box ("title", "Releases");

	box ("para", "The currently supported releases of Project Twilignt\n" .
		"will be placed on this page.&nbsp; You can get the source code\n" .
		"if you have a compiler, or a pre-compiled binary for a few\n" .
		"systems.\n"
	);


	box ("sub", "Project Twilight v0.1.0");

	box ("para", "This is our first public release.&nbsp; It's stable and\n" .
		"works rather well for us.&nbsp; Check out the file NEWS for the\n" .
		"differences between this release and Id Software's Quake&reg;\n" .
		"releases.&nbsp; The existing docs apply otherwise.\n"
	);

	box ("line", "<a href=\"twilight-win32-0.1.0.zip\">Win32 binaries</a>\n");
	box ("line", "<a href=\"twilight-0.1.0.zip\">Source code</a>\n");

	require ($pageroot . "/include/footer.php");
?>
