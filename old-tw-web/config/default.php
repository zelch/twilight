<?php
	$display = array (
		logo => "images/twilight.gif" ,
		body => "text=\"#ffffff\" bgcolor=\"#000000\"" .
				"alink=\"#0080ff\" vlink=\"#0080ff\" link=\"#0080ff\"",
		basefont => "face=\"verdana, arial\"" ,

		headertable => "width=\"100%\" bgcolor=\"#000440\"" ,

		footertable => "width=\"100%\" bgcolor=\"#000440\"" ,
		footerpre => "<center><font face=\"verdana, arial\" size=\"-2\">" ,
		footerpost => "</font></center>",

		navtable => "width=\"100%\" bgcolor=\"#00087f\"" ,
		navpre => "<font face=\"verdana, arial\" size=\"+1\">" ,
		navpost => "</font>" ,

		plugstable => "width=\"100%\"" ,
		plugspre => "<center>" ,
		plugspost => "</center" ,

		newstable => "width=\"100%\" bgcolor=\"#00087f\" cellspacing=\"1\"" ,
		newstitletable => "width=\"100%\" bgcolor=\"#00087f\"" ,
		newstitlepre => "<div align=right><font face=\"verdana,arial\" " .
				"size=\"-1\">" ,
		newstitletablepost => "</font></div>" ,
		newscontenttable => "width=\"100%\" bgcolor=\"#000440\"" ,
		newscontentpre => "<font face=\"verdana, arial\">" ,
		newscontentpost => "</font>"
	);

	if ($browser_css) {
		?>
<style type="text/css">
<!--
body {
   background: #000000;
   color: #ffffff;
   font: 100% verdana, sans-serif;
}

a {
	color: #0080ff;
	text-decoration: none;
}


div.header {
	width: 100%;
	background: #000440 url(images/hdrbar.jpg) repeat-y;
}

div.footer {
   width: 100%;
   background: #000440;
   border-top: 5px solid #000440;
   border-bottom: 5px solid #000440;
   text-align: center;
   font-size: 80%;
}

div.nav {
	width: 100%;
	background: #00087f;
	border-bottom: solid 2px #00087f;
	color: white;
	font: bolder 110% verdana, sans-serif;
}

div.news {
	margin: 10px;
	background: #000440;
	border: solid 1px #00087f;
}
div.newstitle {
	background: #00087f;
	padding: 1px 5px;
	text-align: right;
	font: 90% verdana, sans-serif;
}
div.newscontent {
	margin: 5px;
}

div.plugs {
	margin: 5px;
	text-align: center;
}

-->
</style>
		<?php
	}

	$nav_items = array (
		News => "index.php" ,
		Downloads => "files/index.php" ,
		Development => "devel/index.php" ,
		Links => "links.php" ,
		Contact => "contact.php"
	);
?>

