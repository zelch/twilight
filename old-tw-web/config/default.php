<?php
	$display = array (
		background => "#000000" ,
		text => "#FFFFFF" ,
		title_img => "images/twilight.gif" ,
		titlebar_img => "images/hdrbar.jpg" ,
		titlebar => "#000440" ,
		nav => "#00087f" ,
		nav_link => "#0080ff"
	);

	$nav_items = array (
		Home => "index.php" ,
		Devel => "devel/index.php"
	);

	if ($browser_css) {
		echo (
			"<style type=\"text/css\">\n" .
			"<!--\n" .
			"/* title header */\n" .
			"div.header {\n" .
			"	width: 100%;\n" .
			"	background: #000440\n" .
			"		url(" . $display["titlebar_img"] . ")\n" .
			"		repeat-y\n" .
			"}\n" .
			"\n\n" .
			"/* navigation bar */\n" .
			"div.nav {\n" .
			"	width: 100%;\n" .
			"	background: " . $display["nav"] . ";\n" .
			"	padding: 2px;\n" .
			"	color: white;\n" .
			"	font: bolder 110% verdana, sans-serif\n" .
			"}\n" .
			"a.nav {\n" .
			"	color: " . $display["nav_link"] . ";\n" .
			"	text-decoration: none\n" .
			"}\n" .
			"\n" .
			"-->\n" .
			"</style>\n"
		);
	}
?>

