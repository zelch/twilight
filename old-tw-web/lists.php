<?php
	$title = "Mailing Lists";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	function listsub ($listname)
	{
		titlebox ("subscr", "Subscribe to " . $listname,
			"<form method=\"post\" action=\"/subscribe.php\">\n" .
			"<table" . ($browser_css ? "" : " align=\"center\"") . ">\n" .
			"<tr><td>Email:&nbsp;</td><td>\n" .
			"<input type=\"text\" name=\"sub_email\" size=\"30\" /></td>\n" .
			"<td>&nbsp;&nbsp;<input type=\"submit\" name=\"sub_button\"\n" .
			"value=\"Subscribe\" /></td></tr>\n" .
			"<tr><td><input type=\"hidden\" name=\"sub_list\"\n" .
			"value=\"" . $listname . "\" />\n</td><td colspan=\"2\">\n" .
			"<input type=\"checkbox\" name=\"sub_digest\" />\n" .
			" Messages in digest format\n</td></tr></table></form>\n"
		);
	}

	box ("title", "Mailing Lists");

	box ("para", "Most of the important discussion about Project Twilight\n" .
		"happens in email on one of the project's mailing lists.&nbsp;\n" .
		"These lists are open to the public and those of you interested\n" .
		"are encouraged to subscribe.\n"
	);


	box ("sub", "twilight-announce");

	box ("para", "This list is only used for announcement purposes and\n" .
		"is read-only.&nbsp; Everyone is encouraged to subscribe if they\n" .
		"are interested in news about the project.&nbsp; Posts here will\n" .
		"be more formal than the website news.&nbsp; It is intended for\n" .
		"release announcements and that sort of thing.\n"
	);

	listsub ("twilight-announce");


	box ("sub", "<a href=\"mailto:twilight-devel@lists.sourceforge.net\">" .
		"twilight-devel</a>"
	);

	box ("para", "This is the primary list used for discussion about the\n" .
		"development of the project.&nbsp; The list is open to anyone and\n" .
		"any discussion related to the project will be considered to be\n" .
		"on-topic.&nbsp; It's expected that discussion will be somewhat\n" .
		"technical, but non-coders shouldn't have a problem following\n" .
		"things.&nbsp; Traffic on twilight-devel is expected to vary from\n" .
		"light and moderate depending on what we're doing at the time.\n"
	);

	listsub ("twilight-devel");


	box ("sub", "twilight-commits");

	box ("para", "This list is where the action is.&nbsp; You should be\n" .
		"expecting traffic from this list to be HIGH as an email is sent\n" .
		"to this list every time someone submits a change to the project,\n" .
		"even if the change is just to the website.&nbsp; General posts\n" .
		"are not welcome to this list, though it is open to everyone.  If\n" .
		"you need to send something to the list, please send it to\n" .
		"<a href=\"mailto:twilight-devel@lists.sourceforge.net\">\n" .
		"twilight-devel</a>.&nbsp; This list is the fastest place to find\n" .
		"out about new changes that may not yet be documented or released\n" .
		"yet.\n"
	);

	listsub ("twilight-commits");

	require ($pageroot . "/include/footer.php");
?>
