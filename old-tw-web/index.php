<?php
	$page = "News";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	newsitem ("23 Jul 2001", "Knghtbrd", "The SourceForge guys have " .
		"imported the twilight CVS branch for us - thanks moorman! " .
		"The -commits list got 29 fresh messages logging all of my changes" .
		"to the code before having it imported this morning.  The devel " .
		"stuff for the website is next."
	);

	newsitem ("22 Jul 2001", "Knghtbrd", "The website will now be updated " .
		"automatically shortly after someone commits changes.  Stub pages " .
		"for the main site sections are now up."
	);

	newsitem ("22 Jul 2001", "Knghtbrd", "The website is finally online!  " .
		"Well, sortof anyway.  The index page is all there is right now, " .
		"but from here things should start to happen fast.  Watch this " .
		"space for updates");

	box ("plugs",
		"<a href=\"http://sourceforge.net\"> <img width=\"88\" height=\"31\"" .
			"src=\"http://sourceforge.net/sflogo.php?group_id=31385\" " .
			"border=\"0\" alt=\"SourceForge\"></a>" .
		"<a href=\"http://www.opengl.org\"><img src=\"images/opengl.gif\" " .
			"alt=\"OpenGL\" border=\"0\"></a>"
		
	);

	require ($pageroot . "/include/footer.php");
?>
