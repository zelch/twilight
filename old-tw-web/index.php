<?php
	$title = "Recent News";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	box ("title", "Recent News");

    newsitem ("02 Aug 2001", "Knghtbrd", "We've got a bit nicer logo now\n" .
		"thanks to some ideas given by everyone and my stubborn refusal\n" .
		"to let gimp have the last laugh with the old one.&nbsp; I'm sure\n" .
		"we can all agree the last one sucked.&nbsp; Thanks to everyone\n" .
		"for their patience as I muddle through PHP, CSS, and my attempts\n" .
		"at graphics desing.&nbsp; As a side bonus, Konqueror users will\n" .
		"find the page does not look totally retarded now, though it does\n" .
		"lack CSS.&nbsp; Complain upstream, and give them\n" .
		"<a href=\"http://twilight.sf.net/index.php?use_css=yes\">this\n" .
		"URL</a> as an example of valid CSS their browser breaks on, and\n" .
		"please let me know the first version that doesn't break anymore!\n"
	);

	newsitem ("29 Jul 2001", "Knghtbrd", "We still need a logo to replace\n" .
		"the one at the top of this page. &nbsp;Send me email if you want\n" .
		"to do one.  The new website layout I've been working on is now\n" .
		"up, if you couldn't tell.&nbsp; ;)&nbsp; I am also happy to\n" .
		"report that the engine compiles on win32 in VC++ 4 and 6 thanks\n" .
		"to " . email (LordHavoc) . " and " . email (digiman) . ".&nbsp\n" .
		email (zinx) . " made the code use auto* for Linux people,\n" .
		"although with today being the last day of\n" .
		"<a href=\"http://qexpo.condemned.com/\">QExpo</a>, it is\n" .
		" doubtful that we'll have binaries ready for download in time.\n" .
		"&nbsp;If you haven't had a look at the QExpo site, you have no\n" .
		"idea what you're missing.\n"
	);

	newsitem ("23 Jul 2001", "Knghtbrd", "The SourceForge guys have\n" .
		"imported the twilight CVS branch for us - thanks\n" .
		"<a href=\"mailto:moorman@users.sourceforge.net\">moorman\n" .
		"</a>!&nbsp; The -commits list got 29 fresh messages logging all\n" .
		"of my changes to the code before having it imported this \n" .
		"morning.&nbsp; The devel stuff for the website is next.\n"
	);

	newsitem ("22 Jul 2001", "Knghtbrd", "The website will now be updated\n" .
		"automatically shortly after someone commits changes.&nbsp; Stub\n" .
		"pages for the main site sections are now up.\n"
	);

	newsitem ("22 Jul 2001", "Knghtbrd", "The website is finally\n" .
		"online!&nbsp; Well, sortof anyway.&nbsp; The index page is all\n" .
		"there is right now, but from here things should start to happen\n" .
		"fast.&nbsp; Watch this space for updates.\n");

	require ($pageroot . "/include/footer.php");
?>
