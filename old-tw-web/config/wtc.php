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

		uinfo => "width=\"100%\" bgcolor=\"#404040\" cellspacing=\"1\"" ,
		uinfonicktr => "valign=\"top\"" ,
		uinfodata => "width=\"100%\" bgcolor=\"#202020\"" ,

		nav => "bgcolor=\"#000430\" width=\"100%\"" ,
		navpre => "",
		navpost => "",

		side => "bgcolor=\"#000430\" width=\"1%\"",

		tnav => "width=\"100%\" bgcolor=\"#4f4f4f\"" ,
		tnavpre => "<font face=\"verdana, arial\"><strong>" ,
		tnavpost => "</strong></font>" ,

		plugs => "width=\"100%\"" ,
		plugspre => "<center>" ,
		plugspost => "</center>" ,

		news => "width=\"100%\" bgcolor=\"#404040\" cellspacing=\"1\"" ,
		newstitle => "width=\"100%\" bgcolor=\"#404040\"" ,
		newstitlepre => "<div align=\"right\"><font face=\"verdana,arial\" " .
				"size=\"-1\">" ,
		newstitlepost => "</font></div>" ,
		newscontent => "width=\"100%\" bgcolor=\"#202020\"" ,
		newscontentpre => "<font face=\"verdana, arial\">" ,
		newscontentpost => "</font>" ,

		subscr => "width=\"95%\" align=\"center\" bgcolor=\"#404040\" " .
			"cellspacing=\"1\"" ,
		subscrtitle => "width=\"100%\" bgcolor=\"#404040\"" ,
		subscrtitlepre => "<font face=\"verdana,arial\" size=\"-1\">" ,
		subscrtitlepost => "</font>" ,
		subscrcontent => "width=\"100%\" bgcolor=\"#202020\"" ,

		title => "width=\"100%\"" ,
		titlepre => "<font face=\"verdana,arial\" size=\"+3\"><strong>" ,
		titlepost => "</strong></font>" . ($browser_name == lynx ?
			"<hr>\n" : "<img width=\"100%\" height=\"1\" " .
			"src=\"/images/whitepix.gif\" alt=\"\" />\n<img width=\"100%\" " .
			"height=\"10\" src=\"/images/clearpix.gif\" alt=\"\" />") ,

		para => "width=\"100%\" cellspacing=\"10\"" ,
		parapre => "<font face=\"verdana,arial\">" ,
		parapost => "</font>" ,
		
		line => "width=\"100%\" cellspacing=\"0\"" ,
		linepre => "<font face=\"verdana,arial\">&nbsp; &nbsp; " ,
		linepost => "</font>" ,

		sub => "width=\"100%\" cellspacing=\"10\"" ,
		subpre => "<img width=\"100%\" height=\"5\" " .
			"src=\"/images/clearpix.gif\" alt=\"\" />" .
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
	background: #181818;
}

td.footer {
	background: #181818;
	margin-top: 10px;
	text-align: center;
	font-size: 80%;
}

td.side {
	width: 15%;
	background: #181818;
	vertical-align: top;
	color: white;
}

div.uinfo {
	padding: 2px;
	background: #404040;
	margin: 10px;
}

div.uinfonick {
	padding-left: 3px;
	vertical-align: top;
}

div.uinfodata {
	background: #202020;
	padding-left: 5px;
}

div.nav {
	font: bolder 90% verdana, sans-serif;
}

div.tnav {
	font: bolder 110% verdana, sans-serif;
	background: #4f4f4f;
}

div.news {
	margin: 10px;
	background: #202020;
	border: solid 2px #404040;
}
div.newstitle {
	background: #404040;
	padding: 1px 5px;
	text-align: right;
	font: bolder 90% verdana, sans-serif;
}
div.newscontent {
	margin: 5px;
}

div.subscr {
	margin: 10px;
	background: #202020;
	border: solid 2px #404040;
}
div.subscrtitle {
	background: #404040;
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

div.line {
	padding-left: 2em;
}

div.sub {
	padding-top: 30px;
	font: bolder 150% verdana, sans-serif;
}

img.noborder {
	border: none;
}

-->
</style>
		<?php
	} else if (!$no_output) {
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

?>
