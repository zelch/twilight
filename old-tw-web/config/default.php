<?php
	$display = array (
		logo => "images/twilight.gif" ,
		body => "text=\"#ffffff\" bgcolor=\"#000000\"" .
				"alink=\"#0080ff\" vlink=\"#0080ff\" link=\"#0080ff\"",

		headertable => "width=\"100%\" bgcolor=\"#000440\"" ,

		footertable => "width=\"100%\" bgcolor=\"#000440\"" ,
		footerpre => "<center><font size=\"-2\">" ,
		footerpost => "</font></center>",

		navtable => "width=\"100%\" bgcolor=\"#00087f\"" ,
		navpre => "<font face=\"verdana, arial\" size=\"+1\">" ,
		navpost => "</font>"
	);

	$nav_items = array (
		News => "index.php" ,
		Downloads => "files/index.php" ,
		Development => "devel/index.php" ,
		Links => "links.php" ,
		Contact => "contact.php"
	);

	if ($browser_css) {
		?>
<style type="text/css">
<!--
body {
   background: #000000;
   color: #ffffff;
   font: 100% verdana, sans-serif
}

a {
	color: #0080ff;
	text-decoration: none
}


div.header {
	width: 100%;
	background: #000440
		url(images/hdrbar.jpg)
		repeat-y
}

div.footer {
   width: 100%;
   background: #000440;
   border: 5px solid #000440;
   text-align: center;
   font-size: 80%
}

div.nav {
	width: 100%;
	background: #00087f;
	padding: 2px;
	color: white;
	font: bolder 110% verdana, sans-serif
}

-->
</style>
		<?php
	}
?>

