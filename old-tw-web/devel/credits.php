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
		if (ereg ("^  .*$", $item)) {
			box ("line", htmlify_line ($item));
		}
	}

	array_walk ($authors, 'print_author');

	box ("para", "But none of this would have been possible without the\n" .
		"fine work of the people who brought us Quake&reg; in the first\n" .
		"place, and they deserve at least as much credit for Project\n" .
		"Twilight as any of us listed above.&nbsp; Thanks guys, you have\n" .
		"truly created a legendary game and we all owe you a great deal\n" .
		"for the countless hours of splotches and splatters.\n"
	);

	$thanks = file ($pageroot . "/../cvs-snap/twilight/THANKS");

	function print_quakeguys ($item, $key)
	{
		if (ereg ("^      (.*)  +(.*)$", $item)) {
			echo (ereg_replace ("^      (.*)  +(.*)$",
				"<tr><td>\\1</td><td>\\2</td></tr>\n",
				$item)
			);
		}
	}

	// FIXME: is legal XHTML 1.0 ?
	echo ("<center><table width=\"90%\"");
	array_walk ($thanks, 'print_quakeguys');
	echo ("</table></center>");

	require ($pageroot . "/include/footer.php");
?>
