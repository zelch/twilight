<?php
	require ("config/default.php");
	require ("include/browser-detect.php");

	if ($browser_css) {
		echo ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\"" .
			"\"http://www.w3.org/TR/html4/strict.dtd\">");
	} else {
		echo ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 " .
			"Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">");
	}
	echo ("<html>\n<head>\n<title>Project Twilight: " . $page . "</title>\n");
	if ($browser_css) {
		require ("config/default.css");
	}

	echo ("</head>\n<body bgcolor=". $display["background"] . " text=" .
			$display["text"] . ">");

	if ($browser_css) {
		echo ("<div class=header>\n<img src=\"" . $display["title_img"] .
			"\" alt=\"Project Twilight\">\n</div>\n");
	} else {
		echo ("<table border=0 width=100% bgcolor=#000440>\n" .
			"<tr><td><img src=\"" . $display["title_img"] .
			"\" alt=\"Project Twilight\"></td></tr>\n</table>");
	}
	$nav_ref = 0
?>
<div class=nav>
<?php
	while (list ($title, $url) = each ($nav_items)) {
		if ($nav_ref) {
			echo (" | ");
		}
		$nav_ref++;
		if ($title == $page) {
			echo ($title);
		} else {
			echo ("<a class=\"nav\" href=\"" . $url . "\">" . $title . "</a>");
		}
	}
?>
</div>
