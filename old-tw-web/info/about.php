<?php
	$title = "About";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");

	box ("title", "About Project Twilight");

	box ("para", "Project Twilight began when " . email("Knghtbrd") . "\n" .
		"realized that there were many talented developers who wanted to\n" .
		"work on one of the projects based on the Quake&reg; source code,\n" .
		"but couldn't.&nbsp; The barrier to entry was high for the mature\n" .
		"projects, and the others were usually very messy code.&nbsp;\n" . 
		"But while Project Twilight was originally conceived to be a\n" .
		"stepping stone to working on one of the more mature projects, it\n" .
		"is quickly becoming a mature project of its own.\n"
	);

	box ("sub", "Where we came from");

	box ("para", "We are very much aware of our roots and we will honor\n" .
		"them by continuing to support the community which has given life\n" .
		"to our project.&nbsp; We will maintain and extend both NetQuake\n" .
		"and QuakeWorld&reg; engines if for no other reason than simply\n" .
		"that we can and should.&nbsp; Many projects support only one of\n" .
		"them or only on one platform.&nbsp; Using the SDL library, we\n" .
		"can support Win32, Linux, MacOS, and even more."
	);

	box ("sub", "Where we are going");

	box ("para", "As important as NQ/QW are to where we came from, if\n" .
		"that's where we're going then it's going to be a very short\n" .
		"trip.&nbsp; The game was released five years ago and it was\n" .
		"complete then.&nbsp; We can add a few tweaks to it, make it look\n" .
		"nicer, easier to play for some people, but beyond that we're\n" .
		"limited by a vast installed base of users who may or may not\n" .
		"choose to upgrade to our engine.&nbsp; We can either try to work\n" .
		"around that and end up running in circles, or we can decide that\n" .
		"we're going to do our own thing and not worry about what we're\n" .
		"compatible with.\n"
	);

	box ("para", "The choice for us is pretty clear.&nbsp; We're going to\n" .
		"have to break compatibility in order to add the things we\n" .
		"want.&nbsp; For it we will gain an inventory system, skeletal\n" .
		"models, improved download ability both inside and outside of the\n" .
		"game, cleaner network play, improved physics, game code which is\n" .
		"easier to modify and can change more of the game experience, and\n" .
		"that's just the stuff we've talked about for now.&nbsp; More\n" .
		"ideas and suggestions pop up every day.\n"
	);

	box ("sub", "Keeping things simple");

	box ("para", "Ambitious projects like ours run the risk of losing\n" .
		"sight of their goals as the details become a distraction.&nbsp;\n" .
		"We're not immune, so we'll try to keep the code as simple as\n" .
		"possible in order to minimize the problem.&nbsp; Quake&reg;\n" .
		"obviously wasn't written that way, but then again it was written\n" .
		"in 1996 for dos.&nbsp; To any coder, that's enough said.\n"
	);

	box ("para", "That simplicity is even more important in the structure\n" .
		"of the project itself.&nbsp; Other projects exist with the same\n" .
		"lofty ambitions we have which have been working at them a lot\n" .
		"longer and harder with less to show for their efforts.&nbsp; Our\n" .
		"project's contributors are all on equal footing and there are no\n" .
		"bad ideas.&nbsp; Bad implementations maybe, but it's possible to\n" .
		"fix that.&nbsp; As long as we remember that, we'll be okay.\n"
	);
	
	require ($pageroot . "/include/footer.php");
?>

