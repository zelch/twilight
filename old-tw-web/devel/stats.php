<?php
	$title = "Stats";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");

	box ("title", "Project Stats");

	function print_loc ($line)
	{
		echo (ereg_replace ("^(.*[^ ]) (.*)$",
				"<tr><td>\\1</td><td>\\2</td></tr>", $line)
		);
	}

	box ("para", "This page includes information on the current state of\n" .
		"the project.&nbsp; Some of it may even be useful information.\n"
	);

	if (file_exists ($pageroot . "/../cvs-snap/loc")) {
		box ("sub", "Code counts");

		box ("para", "Ever wonder how many source code files there are in\n" .
			"the project?&nbsp; You could find out for yourself, but now\n" .
			"you don't have to!&nbsp; Here are the numbers, just because:\n"
		);

		echo ("<table>");

		$loc = file ($pageroot . "/../cvs-snap/loc");
		array_walk ($authors, 'print_loc');
	}

	require ($pageroot . "/include/footer.php");
?>
