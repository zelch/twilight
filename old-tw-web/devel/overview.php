<?php
	$page = "Development";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");

	box ("title", "Overview of Project Twilight");

	box ("para", "There are many sites purporting to provide\n" .
		"&quot;tutorials&quot; to help you hack the Quake&reg; engine.\n" . 
		"But the word tutorial implies learning something, and most of\n" .
		"these sites don't even try to teach.  Something better was and\n" .
		"is needed.  Project Twilight's original purpose is to provide\n " .
		" this.  It's an open door and a waiting invitation for anyone\n " .
		"who is interested and willing to learn.\n"
	);

	box ("para", "Interested hackers should find the project extremely\n" .
		"well documented and easy to follow.  We aim to make the code\n" .
		"easy enough for a developer to read what has been done and be\n" .
		"able to repeat the process from scratch or dive right in to the\n" .
		"CVS tree.\n"
	);


	box ("sub", "Keeping things simple and open");

	box ("para", "Ambitious projects like ours run the risk of losing\n" .
		"sight of their goals as the details become a distraction.  We\n" .
		"are not immune.  In order to combat this problem, we will try to\n" .
		"keep the code as simple as possible.  Ideally, this means one\n" .
		"codebase for all developers.  Quake&reg; wasn't written that way\n" .
		"back in 1996, but then again they had various types of hardware\n" .
		"on dos systems to consider.\n"
	);

	box ("para", "And if simplicity is important in our code, it is even\n" .
		"more important in overall the structure of the project.  There\n" .
		"are many other projects with at least as many ambitions as we\n".
		"have which have not managed to realize their goals.  The project\n" .
		"must remain open to everyone equally or it can not succeed.\n"
	);


	box ("sub", "Simple DirectMedia Layer - an obvious choice");

	box ("para", "If our developers are going to be using more than one\n" .
		"operating system, we have to have a way for the code to compile\n" .
		"for all of us.  If we try to support all of those platforms\n" .
		"individually, the less active developers will constantly be\n" .
		"trying to catch up just to keep their platforms able to compile.\n" .
		"SDL gives us support for all of the major platforms that\n" .
		"developers have asked us about and is easily ported to others."
	);

	box ("para", "More importantly, it gives us a way to write code once\n" .
		"which gives us video and input for all of these platforms.  SDL\n" .
		"also supports other features that may prove useful to us such as\n" .
		"sound and networking.  These should be investivated at some point.\n"
	);


	box ("sub", "Software rendering");

	box ("para", "One of the features we have lost at least for now is\n" .
		"software rendering.  Very few projects have kept the old 8-bit\n" .
		"renderer, simply because it is 8-bit and half of it is Pentium\n" .
		"optimized assembly.  The projects which have kept the old code\n" .
		"have left it virtually untouched.  A software renderer would be\n" .
		"nice, but not if it's going to hold everything else back.\n"
	);

	box ("para", "<a href=\"mailto:lordhavoc@users.sourceforge.net\">\n" .
		"LordHavoc</a> modified the old software renderer such that the\n" .
		"8 bit color limit is gone.  It'd be nice to see this renderer in\n" .
		"our engine at some point, but at this stage nobody has made it\n" .
		"their priority.\n"
	);

	box ("sub", "Long term plans");

	box ("para", "The long term plans for this project are still being\n" .
		"hammered out.  We know that simply making our own Quake&reg; and\n" .
		"QuakeWorld&reg; binaries is not going to keep us busy for very\n" .
		"long.  And there really is only so much that can be improved in\n" .
		"Id's original game before we hit bugs that we simply can't work\n" .
		"around anymore.  A third tree is likely.  The only thing that we\n" .
		"can be sure of at this point is that it <strong>WILL</strong>\n" .
		"kick ass."
	);

	box ("para", "As for the original game, it'll still be supported.  It\n" .
		"may take slightly better hardware than it used to.  If you have\n" .
		"a P166 and a Voodoo2, everything should just work.  It shouldn't\n" .
		"take a Thunderbird and a GeForce3 just to play dm4 for awhile!"
	);

	require ($pageroot . "/include/footer.php");
?>

