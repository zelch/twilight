<?php
	$display = array (
		logo => "/images/twilight.gif" ,
		body => "text=\"#ffffff\" bgcolor=\"#000000\"" .
				"alink=\"#0080ff\" vlink=\"#0080ff\" link=\"#0080ff\"",
		basefont => "face=\"verdana, arial\"" ,

		header => "width=\"100%\" bgcolor=\"#000430\"" ,

		footer => "width=\"100%\" bgcolor=\"#000430\"" ,
		footerpre => "<center><font face=\"verdana, arial\" size=\"-2\">" ,
		footerpost => "</font></center>",

		nav => "bgcolor=\"#000430\" width=\"15%\" valign=\"top\"" ,
		navpre => "<font face=\"verdana, arial\" size=\"+1\"><strong>" ,
		navpost => "</strong></font>" ,

		snav => "valign=\"top\"" ,
		snavpre => "<font size=\"-1\">" ,
		snavpost => "</font>" ,

		plugs => "width=\"100%\"" ,
		plugspre => "<center>" ,
		plugspost => "</center>" ,

		news => "width=\"100%\" bgcolor=\"#00087f\" cellspacing=\"1\"" ,
		newstitle => "width=\"100%\" bgcolor=\"#00087f\"" ,
		newstitlepre => "<div align=right><font face=\"verdana,arial\" " .
				"size=\"-1\">" ,
		newstitletablepost => "</font></div>" ,
		newscontent => "width=\"100%\" bgcolor=\"#000440\"" ,
		newscontentpre => "<font face=\"verdana, arial\">" ,
		newscontentpost => "</font>" ,

		title => "width=\"100%\"" ,
		titlepre => "<font face=\"verdana,arial\" size=\"+3\"><strong>" ,
		titlepost => "</strong></font><img width=\"100%\" height=\"1\" " .
			"src=\"/images/whitepix.gif\" alt=\"------\">\n<img " .
			"width=\"100%\" height=\"10\" src=\"/images/clearpix.gif\" " .
			"alt=\"\">" ,

		para => "width=\"100%\" cellspacing=\"10\"" ,
		parapre => "<font face=\"verdana,arial\">" ,
		parapost => "</font>" ,
		
		sub => "width=\"100%\" cellspacing=\"10\"" ,
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


td.header {
	background: #000430
		url(/images/border.jpg)
		repeat-y;
}

td.footer {
	background: #000430
		url(/images/border.jpg)
		repeat-y;
	margin-top: 10px;
	text-align: center;
	font-size: 80%;
}

td.side {
	width: 15%;
	background: #000430
		url(/images/border.jpg)
		repeat-y;
	vertical-align: top;
	color: white;
}

div.nav {
	font: bolder 110% verdana, sans-serif;
}

div.snav {
	font: bolder 90% verdana, sans-serif;
}

div.news {
	margin: 10px;
	background: #000440;
	border: solid 2px #00087f;
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
	} else {
		?>
<style type="text/css">
<!--
a {
	// No harm in TRYING to get rid of the underline, is there?
	color: #0080ff;
	text-decoration: none;
}		
-->
</style>
		<?php
	}

	$nav_items = array (
		News => array (
			News => "/index.php"
		) ,
		Downloads => array (
			Downloads => "/files/index.php"
		) ,
		Development => array (
			Development => "/devel/index.php" ,
			Overview => "/devel/overview.php" ,
			Credits => "/devel/credits.php"
		) ,
		Links => array (
			Links => "/links.php"
		) ,
		Contact => array (
			Contact => "/contact.php"
		)
	);

	$userinfo["Knghtbrd"]["name"] = "Joseph Carter";
	$userinfo["Knghtbrd"]["email"] = "knghtbrd@debian.org";
	$userinfo["zinx"]["name"] = "Zinx Verituse";
	$userinfo["zinx"]["email"] = "zinx@magenet.net";
	$userinfo["LordHavoc"]["name"] = "Forest Hale";
	$userinfo["LordHavoc"]["email"] = "lordhavoc@users.sourceforge.net";
	$userinfo["Vic"]["name"] = "Victor Luchits";
	$userinfo["Vic"]["email"] = "digiman@users.sourceforge.net";

	// Add yourself above!
	
?>

