<?php
	$display = array (
		background => "#000000" ,
		text => "#ffffff" ,
		logo => "images/twilight.gif" ,
		title_grad => "images/hdrbar.jpg" ,
		base => "#000440" ,
		title => "#00087f" ,
		weblink => "#0080ff"
	);

	$nav_items = array (
		News => "index.php" ,
		Downloads => "files/index.php" ,
		Development => "devel/index.php" ,
		Links => "links.php" ,
		Contact => "contact.php"
	);

	if ($browser_css) {
		echo (
			"<style type=\"text/css\">\n" .
			"<!--\n" .
			"div.header {\n" .
			"	width: 100%;\n" .
			"	background: #000440\n" .
			"		url(" . $display["title_grad"] . ")\n" .
			"		repeat-y\n" .
			"}\n\n" .
			"div.footer {\n" .
			"   width: 100%;\n" .
			"   background: " . $display["base"] . ";\n" .
			"   border: 5px solid " . $display["base"] . ";\n" .
			"   text-align: center\n" .
			"}\n" .
			"\n\n" .
			"div.nav {\n" .
			"	width: 100%;\n" .
			"	background: " . $display["title"] . ";\n" .
			"	padding: 2px;\n" .
			"	color: white;\n" .
			"	font: bolder 110% verdana, sans-serif\n" .
			"}\n" .
			"a {\n" .
			"	color: " . $display["weblink"] . ";\n" .
			"	text-decoration: none\n" .
			"}\n" .
			"\n" .
			"-->\n" .
			"</style>\n"
		);
	}
?>

