<?php
	$title = "IRC Channel";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	box ("title", "IRC Channel");

	box ("para", "Many of the Project Twilight contributors hang out in\n" .
		"the project's IRC channel on the " .
		"<a href=\"http://www.openprojects.net/\">OpenProjects</a> IRC\n" .
		"network.&nbsp; You are welcome and encouraged to join us there\n" .
		"by connecting to irc.openprojects.net and joining the #twilight\n" .
		"channel."
	);


	box ("sub", "Channel rules");

	box ("para", "We don't have many rules.&nbsp; We don't allow any sort\n" .
		"of warez discussion in the channel.&nbsp; If we want the license\n" .
		"on our code to be respected, we must respect others' licenses as\n" .
		"well&nbsp; We realize that Quake&reg; and commercial products\n" .
		"relating to it are becoming rare, and will be happy to help you\n" .
		"find and purchase copies if you like.\n"
	);

	box ("para", "We also ask that you occasionally remind the group of\n" .
		"developers who clearly do not get enough sleep when they should\n" .
		"get some rest, some food, and a shower.&nbsp; Remember that you\n" .
		"are talking to programmers and chances are fairly good that they\n" .
		"need all three.&nbsp; You'll learn who needs your reminders soon\n" .
		"enough, we are fairly sure. ;)\n"
	);

	box ("para", "Seriously, try not to be excessively annoying or too\n" .
		"easily annoyed, and everything will go smoothly.&nbsp; We're all\n" .
		"here because we want to be and because we love this game.\n"
	);


	box ("sub", "IRC clients");

	box ("para", "If you need an irc client, we recommend you try these:\n");

	box ("line", "[Win32] <a href=\"http://www.mirc.com/\">mIRC</a>\n");
	box ("line", "[Mac] <a href=\"http://www.ircle.com/\">Ircle</a>\n");
	box ("line", "[Unix] <a href=\"http://www.epicsol.org/\">EPIC</a>\n");
	box ("line", "[Unix] <a href=\"http://www.bitchx.org/\">BitchX</a>\n");
	box ("line", "[Unix] <a href=\"http://www.xchat.org/\">xchat</a>\n");

	require ($pageroot . "/include/footer.php");
?>
