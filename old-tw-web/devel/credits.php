<?php
	$title = "Credits";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");

	box ("title", "Project Credits");

	box ("para", "The list of contributors to Project Twilight is always\n" .
		"growing.&nbsp; This list is probably inaccurate, so if you feel\n" .
		"you should be here and aren't, let us know.&nbsp; There are a\n" .
		"probably couple of people who should be here, and a few people\n" .
		"who are here and don't even know it yet.\n"
	);

	$authors = file ($pageroot . "/../cvs-snap/twilight/AUTHORS");

	function print_author ($item, $key)
	{
		static $endofheader = false;
		if ($endofheader) {
			box ("line", htmlify_line ($item));
		}
		if (ereg ("^[[:space:]]*$", $item1)) {
			$endofheader = true;
		}
	}

	array_walk ($authors, 'print_author');

	require ($pageroot . "/include/footer.php");
?>
