<?
	$pageroot = "..";
	$pagerealm = "Twilight Members";
	$usertable = "members";
	$newacct = 0;
	
	require ($pageroot . "/include/auth.php");

	if (!($authdata = get_auth($PHP_AUTH_USER, $PHP_AUTH_PW)) || $authdata['u_admin'] != 'Y') {
		send_auth_headers();
		exit;
	}

	if ($action == "Post") {
		$query = sprintf("INSERT INTO news_main (n_date, n_user, n_news) VALUES ('%s', '%s', '%s');", strftime("%Y-%m-%d %H:%M:%S"), $authdata['u_username'], $newspost);
		twsql_query($query);
		header("Location: http://$HTTP_HOST/");
		exit;
	} else if ($action == "Preview")
		$newspost = stripslashes($newspost);

	$title = "Members Area: Post News";
	require ($pageroot . "/include/header.php");

	echo box ("title", "Post News");

	if ($action == "Preview") {
		echo newsitem(strftime("%Y-%m-%d"), $authdata['u_username'], $newspost);
	}

	# Yes, I'm well aware this is ugly.
	echo boxstart("para");
	echo "<form method=\"post\" name=\"newsform\">\n";
	echo "<input type=\"hidden\" name=\"textchanged\" value=\"" . ($action == "Preview" ? "1" : "0") . "\">\n";
	echo newsitem("Now", $authdata['u_username'], "<textarea name=\"newspost\" rows=5 cols=70 onFocus=\"if (newsform.textchanged.value == 0) { newsform.textchanged.value = 1; newsform.newspost.value = ''; }\">" .
		($newspost == "" ? "Enter news item here." : $newspost) .
		"</textarea><br />
<input type=\"submit\" name=\"action\" value=\"Post\">
<input type=\"submit\" name=\"action\" value=\"Preview\">
\n");
	echo "</form>\n";
	echo boxend("para");

	require ($pageroot . "/include/footer.php");

?>