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

		uinfo => "width=\"100%\" bgcolor=\"#000fb5\" cellspacing=\"1\"" ,
		uinfonick => "valign=\"top\"" ,
		uinfodata => "width=\"100%\" bgcolor=\"#000440\"" ,

		nav => "bgcolor=\"#000430\" width=\"100%\" valign=\"top\"" ,
		navpre => "<font size=\"-1\">" ,
		navpost => "</font>" ,

		tnav => "valign=\"top\" width=\"100%\" bgcolor=\"#00087f\"" ,
		tnavpre => "<font face=\"verdana, arial\"><strong>" ,
		tnavpost => "</strong></font>" ,

		plugs => "width=\"100%\"" ,
		plugspre => "<center>" ,
		plugspost => "</center>" ,

		news => "width=\"100%\" bgcolor=\"#000fb5\" cellspacing=\"1\"" ,
		newstitle => "width=\"100%\" bgcolor=\"#000fb5\"" ,
		newstitlepre => "<div align=right><font face=\"verdana,arial\" " .
				"size=\"-1\">" ,
		newstitletablepost => "</font></div>" ,
		newscontent => "width=\"100%\" bgcolor=\"#000440\"" ,
		newscontentpre => "<font face=\"verdana, arial\">" ,
		newscontentpost => "</font>" ,

		subscr => "width=\"95%\" align=\"center\" bgcolor=\"#000fb5\" " .
			"cellspacing=\"1\"" ,
		subscrtitle => "width=\"100%\" bgcolor=\"#000fb5\"" ,
		subscrtitlepre => "<font face=\"verdana,arial\" size=\"-1\">" ,
		subscrtitletablepost => "</font>" ,
		subscrcontent => "width=\"100%\" bgcolor=\"#000440\"" ,
		subscrcontentpre => "<font face=\"verdana, arial\">" ,
		subscrcontentpost => "</font>" ,

		title => "width=\"100%\"" ,
		titlepre => "<font face=\"verdana,arial\" size=\"+3\"><strong>" ,
		titlepost => "</strong></font>" . ($browser_name == lynx ?
			"<hr>\n" : "<img width=\"100%\" height=\"1\" " .
			"src=\"/images/whitepix.gif\" alt=\"\">\n<img width=\"100%\" " .
			"height=\"10\" src=\"/images/clearpix.gif\" alt=\"\">") ,

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

div.uinfo {
	border: solid 2px #000fb5;
	background: #000fb5;
	margin: 10px;
}

div.uinfonick {
	border-left: solid 3px #000fb5;
	vertical-align: top;
}

div.uinfodata {
	background: #000440;
	border-left: solid 5px #000440;
}

div.nav {
	font: bolder 90% verdana, sans-serif;
}

div.tnav {
	font: bolder 110% verdana, sans-serif;
	background: #00087f;
}

div.news {
	margin: 10px;
	background: #000440;
	border: solid 2px #000fb5;
}
div.newstitle {
	background: #000fb5;
	padding: 1px 5px;
	text-align: right;
	font: bolder 90% verdana, sans-serif;
}
div.newscontent {
	margin: 5px;
}

div.subscr {
	margin: 10px;
	background: #000440;
	border: solid 2px #000fb5;
}
div.subscrtitle {
	background: #000fb5;
	padding: 1px 5px;
	font: bolder 90% verdana, sans-serif;
}
div.subscrcontent {
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
		Information => array (
			"Recent News" => "/index.php"
		) ,
		Downloads => array (
			"Downloads" => "/files/index.php"
		) ,
		Development => array (
			"Development" => "/devel/index.php" ,
			"Overview" => "/devel/overview.php" ,
			"Credits" => "/devel/credits.php"
		) ,
		Links => array (
			"Links" => "/links.php"
		) ,
		Contact => array (
			"Mailing Lists" => "/lists.php" ,
			"Developers" => "/people.php"
		)
	);

	$userinfo = array (
		"|Rain|" => array (
			"Name" => "Ben Winslow" ,
			"Email" => "rain@bluecherry.net"
		) ,
		"LordHavoc" => array (
			"Name" => "Forest Hale" ,
			"Email" => "lordhavoc@users.sourceforge.net" ,
			"Web" => "http://darkplaces.gamevisions.com/"
		) ,
		"Knghtbrd" => array (
			"Name" => "Joseph Carter" ,
			"Email" => "knghtbrd@debian.org"
		) ,
		"digiman" => array (
			"Name" => "Victor Luchits" ,
			"Email" => "digiman@users.sourceforge.net"
		) ,
		"Mercury" => array (
			"Name" => "Zephaniah E. Hull" ,
			"Email" => "warp@whitestar.soark.net"
		) ,
		"zinx" => array (
			"Name" => "Zinx Verituse" ,
			"Email" => "zinx@magenet.net"
		)
	);

	// Add yourself above!
	
?>

