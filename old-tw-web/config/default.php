<?php
	$display = array (
		logo => "/images/twilight.gif" ,
		body => "text=\"#ffffff\" bgcolor=\"#000000\"" .
				"alink=\"#0080ff\" vlink=\"#0080ff\" link=\"#0080ff\"",
		basefont => "face=\"verdana, arial\"" ,

		headertable => "width=\"100%\" bgcolor=\"#000440\"" ,

		footertable => "width=\"100%\" bgcolor=\"#000440\"" ,
		footerpre => "<center><font face=\"verdana, arial\" size=\"-2\">" ,
		footerpost => "</font></center>",

		navtable => "width=\"100%\" bgcolor=\"#000fb5\"" ,
		navpre => "<font face=\"verdana, arial\" size=\"+1\"><strong>" ,
		navpost => "</strong></font>" ,

		plugstable => "width=\"100%\"" ,
		plugspre => "<center>" ,
		plugspost => "</center>" ,

		newstable => "width=\"100%\" bgcolor=\"#00087f\" cellspacing=\"1\"" ,
		newstitletable => "width=\"100%\" bgcolor=\"#00087f\"" ,
		newstitlepre => "<div align=right><font face=\"verdana,arial\" " .
				"size=\"-1\">" ,
		newstitletablepost => "</font></div>" ,
		newscontenttable => "width=\"100%\" bgcolor=\"#000440\"" ,
		newscontentpre => "<font face=\"verdana, arial\">" ,
		newscontentpost => "</font>" ,

		titletable => "width=\"100%\"" ,
		titlepre => "<font face=\"verdana,arial\" size=\"+3\"><strong>" ,
		titlepost => "</strong></font><img width=\"100%\" height=\"1\" " .
			"src=\"/images/whitepix.gif\" alt=\"------\">\n<img " .
			"width=\"100%\" height=\"10\" src=\"/images/clearpix.gif\" " .
			"alt=\"\">" ,

		paratable => "width=\"100%\" cellspacing=\"10\"" ,
		parapre => "<font face=\"verdana,arial\">" ,
		parapost => "</font>" ,
		
		subtable => "width=\"100%\" cellspacing=\"10\"" ,
		subpre => "<img width=\"100%\" height=\"5\" " .
			"src=\"/images/clearpix.gif\" alt=\"\">" .
			"<font face=\"verdana,arial\" size=\"+2\"><strong>" ,
		subpost => "</strong></font>"
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
	background: #000440
		url(/images/hdrbar.jpg)
		repeat-y;
}

div.footer {
   width: 100%;
   background: #000440;
   margin-top: 10px;
   border-top: 5px solid #000440;
   border-bottom: 5px solid #000440;
   text-align: center;
   font-size: 80%;
}

div.nav {
	width: 100%;
	background: #000fb5;
	border-bottom: solid 2px #000fb5;
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

div.title {
	border-bottom: 1px solid #ffffff;
	padding-top: 10px;
	font: bolder 200% verdana, sans-serif;
}

div.para {
	padding: 10px 0px;
}

div.sub {
	padding-top: 30px;
	font: bolder 150% verdana, sans-serif;
}

-->
</style>
		<?php
	}

	$nav_items = array (
		News => "/index.php" ,
		Downloads => "/files/index.php" ,
		Development => "/devel/index.php" ,
		Links => "/links.php" ,
		Contact => "/contact.php"
	);
?>

