<?php
	$pageroot = ".";
	$pagerealm = "Twilight Members";
	$usertable = "members";
	$newacct = 0;
	require ($pageroot . "/include/auth.php");

	if (!($authdata = get_auth($PHP_AUTH_USER, $PHP_AUTH_PW))) {
		send_auth_headers();
		exit;
	}

	$title = "Members Area";
	require ($pageroot . "/include/header.php");

	echo box ("title", "Members Area");
# Redo u_admin to an access level/bitmask?
	if ($authdata['u_admin'] == 'Y') {
		echo box("para", "Administrative menu<br>\n
- <a href=\"members/post_news.php\">Post news</a>");
	}

	require ($pageroot . "/include/footer.php");
?>
