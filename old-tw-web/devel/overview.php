<?php
	$title = "Overview";
	$section = "Development";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");

	box ("title", "Overview of Project Twilight");

	box ("para", "There are many sites purporting to provide\n" .
		"&quot;tutorials&quot; to help you hack the Quake&reg; engine,\n" . 
		"but most of them unfortunately don't teach much at all.&nbsp;\n" .
		"Something better is needed.&nbsp; This was the original reason\n" .
		"for Project Twilight to exist.&nbsp; It still does this, but it\n" .
		"also provides an open door and a waiting invitation for anyone\n " .
		"willing to learn who wants the best damned Quake&reg; engine we\n" .
		"can make.\n"
	);

	box ("para", "Coders should find the project's advancements to be\n" .
		"very well documented and easy to follow.&nbsp; We aim to lower\n" .
		"the bar of entry enough that a developer can simply read the\n" .
		"documentation of the major changes we've made and hop right in.\n"
	);


	box ("sub", "Keeping things simple and open");

	box ("para", "Ambitious projects like ours run the risk of losing\n" .
		"sight of their goals as the details become a distraction.&nbsp;\n" .
		"We are not immune.&nbsp; In order to combat this problem, we\n" .
		"will try to keep the code as simple as possible.&nbsp; Ideally,\n" .
		"this means one codebase for all developers.&nbsp; Quake&reg;\n" .
		"wasn't written that way back in 1996, but then again they had\n" .
		"various types of hardware on dos systems to consider.\n"
	);

	box ("para", "And if simplicity is important in our code, it is even\n" .
		"more important in overall the structure of the project.&nbsp;\n" .
		"There are many other projects with at least as many ambitions as\n" .
		"we have which have not managed to realize their goals.&nbsp; The\n" .
		"project must remain open and equal to all or it can not succeed.\n"
	);


	box ("sub", "Simple DirectMedia Layer - an obvious choice");

	box ("para", "If our developers are going to be using more than one\n" .
		"operating system, we have to have a way for the code to compile\n" .
		"for all of us.&nbsp; If we try to support all of those platforms\n" .
		"individually, the less active developers will constantly be\n" .
		"trying to catch up just to keep their platforms able to compile.\n" .
		"SDL gives us support for all of the major platforms that\n" .
		"developers have asked us about and is easily ported to others.\n"
	);

	box ("para", "More importantly, it gives us a way to write code once\n" .
		"which gives us video and input for all of these platforms.&nbsp;\n" .
		"SDL also supports other features that may prove useful to us\n " .
		"such as sound and networking.&nbsp; These should be investivated\n" .
		"at some point.\n"
	);


	box ("sub", "Software rendering");

	box ("para", "One of the features we have lost at least for now is\n" .
		"software rendering.&nbsp; Very few projects have kept the old\n" .
		"8-bit renderer, simply because it is 8-bit and half of it is\n" .
		"Pentium-optimized 486 assembly.&nbsp; The projects which have\n" .
		"kept the old code have left it virtually untouched.&nbsp; A\n" .
		"software renderer would be nice, but not if it's going to hold\n" .
		"everything else back.\n"
	);

	box ("para", email ("LordHavoc") . " has modified the old software\n" .
		"renderer to get rid of the 8-bit color limit.&nbsp; It'd be nice\n" .
		"to see this renderer in our engine at some point, but at this\n" .
		"early stage nobody has volunteered to work on that project since\n" .
		"there are so many other things that need to be done.\n"
	);

	box ("sub", "Long term plans");

	box ("para", "Many of the long term plans for this project have not\n" .
		"been hammered out yet.&nbsp; We know that simply making another\n" .
		"custom engine is not going to keep us busy for long.&nbsp; A\n" .
		"third tree will probably be developed alongside Quake&reg; and\n" .
		"QuakeWorld&reg;.&nbsp; This is necessary because only so much\n" .
		"can be done within the constraints of compatibility.&nbsp; Not\n" .
		"much can be said about that yet except that it <strong>WILL\n" .
		"</strong> kick ass.\n"
	);

	box ("para", "As for the existing code, it'll probably start to need\n" .
		"slightly more resources than it used to for the new features we\n" .
		"will offer.&nbsp; It should be worth it, and if you have a P166\n" .
		"and a Voodoo2, you should not have any problems.&nbsp; It should\n" .
		"not require a 1.2GHz processor and a GeForce 3 Ultra just to\n" .
		"have a good game on dm4.&nbsp; We realize this.\n"
	);

	require ($pageroot . "/include/footer.php");
?>

