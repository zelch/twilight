<?php
	require ($pageroot . "/include/browser-detect.php");

	if ($browser_css) {
		echo ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" " .
			"\"http://www.w3.org/TR/html4/strict.dtd\">");
	} else {
		echo ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 " .
			"Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">");
	}
	echo ("<html>\n<head>\n<title>Project Twilight: " . $title . "</title>\n");
	require ($pageroot . "/config/default.php");
	require ($pageroot . "/include/functions.php");

	echo ("</head>\n");
	if ($browser_css) {
		echo ("<body>");
	} else {
		echo ("<body " . $display["body"] . ">\n");
	}

	// Ugh, browser stupidity forces us to use tables here
	echo ("<table width=\"100%\" cellpadding=\"5\" cellspacing=\"0\" " .
		"border=\"0\">\n");
	if ($browser_css) {
		echo ("<tr><td colspan=\"2\" class=\"header\">\n");
	} else {
		echo ("<tr><td colspan=\"2\"" . $display["header"] .">\n");
	}
	echo ("<img width=\"403\" height=\"82\" src=\"" . $display["logo"] .
		"\" alt=\"Project Twilight\">\n</td></tr>\n");
	if ($browser_css) {
		echo ("<tr><td class=\"side\">\n");
	} else {
		echo ("<tr valign=\"top\"><td " . $display["side"] . ">\n");
	}
	boxstart ("nav");

	while (list ($sect, $sub) = each ($nav_items)) {
		box ("tnav", $sect);
		while (list ($ssect, $url) = each ($sub)) {
			if ($ssect == $title) {
				echo ("- " . $ssect . "<br>\n");
			} else {
				echo ("- <a href=\"" . $url . "\">" . $ssect . "</a><br>\n");
			}
		}
	}
	boxend ("nav");

	box ("plugs",
		"<a href=\"http://sourceforge.net\">" .
		"<img width=\"88\" height=\"31\" " .
		"src=\"http://sourceforge.net/sflogo.php?group_id=31385\" " .
		($browser_css ? "class=\"noborder\"" : "border=\"0\"") . 
		" alt=\"SourceForge\"></a><br>\n" .
		
		"<a href=\"http://www.opengl.org\">" .
		"<img width=\"88\" height=\"39\" " .
		($browser_css ? "class=\"noborder\"" : "border=\"0\"") . 
		"src=\"/images/opengl.gif\" alt=\"OpenGL\"></a><br>\n"
		
	);

	echo ("</td><td valign=\"top\">\n");
?>

