<?php
	require ("include/browser-detect.php");

	if ($browser_css) {
		echo ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\"" .
			"\"http://www.w3.org/TR/html4/strict.dtd\">");
	} else {
		echo ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 " .
			"Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">");
	}
	echo ("<html>\n<head>\n<title>Project Twilight: " . $page . "</title>\n");
	require ("config/default.php");
	require ("include/functions.php");

	echo ("</head>\n");
	if ($browser_css) {
		echo ("<body>");
	} else {
		echo ("<body " . $display["body"] . ">\n");
	}

	box ("header", "<img src=\"" . $display["logo"] .
					"\" alt=\"Project Twilight\">");

	$nav_ref = 0;
	$nav_str = "";
	while (list ($title, $url) = each ($nav_items)) {
		if ($nav_ref) {
			$nav_str .= " | ";
		}
		$nav_ref++;
		if ($title == $page) {
			$nav_str .= $title . "\n";
		} else {
			$nav_str .= "<a href=\"" . $url . "\">" . $title . "</a>\n";
		}
	}
	box ("nav", $nav_str);

?>
