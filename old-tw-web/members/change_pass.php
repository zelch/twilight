<?
	$pageroot = "..";
	$pagerealm = "Twilight Members";
	$usertable = "members";
	$newacct = 0;
	$title = "Members Area: Change Password";
	
	require ($pageroot . "/include/auth.php");

	if (!($authdata = get_auth($PHP_AUTH_USER, $PHP_AUTH_PW)) || $authdata['u_admin'] != 'Y') {
		send_auth_headers();
		exit;
	}

	require ($pageroot . "/include/header.php");
	echo box ("title", "Password Change");

	if ($action == "Submit") {
		if ($newpass1 == $newpass2) {
			if (!($myauthdata = set_auth_password($PHP_AUTH_USER, $PHP_AUTH_PW, $newpass1))) {
				echo titlebox("subscr", "Error", "The attempt to change your password failed.");
			} else {
				echo titlebox("subscr", "Success",
					"Your Password has been changed. " .
					"<a href=\"/members/\">Go back to the members page</a> " .
					"(you will need to log in again)."
				);
			}
			require ($pageroot . "/include/footer.php");
			exit;
		} else {
			echo titlebox ("subscr", "Error", 
				"The two passwords you entered did not match. Password not changed.");
		}
	}



	# Yes, I'm well aware this is ugly.
	echo titlebox("subscr", "Change your password",
		"<form method=\"post\" action=\"change_pass.php\" name=\"passchange\">\n" .
# funny how their attempts to decrease <table> use results in the opposite.
		($browser_css ? "<table width=\"80%\" style=\"text-align: center\"><tr><td align=\"center\">" : "") .
		"<table " . ($browser_css ? "" : " align=\"center\"") . ">\n" .
		"<tr><td>New Password:&nbsp;</td><td>\n" .
		"<input type=\"password\" name=\"newpass1\" size=\"30\" /></td></tr>\n" .
		"<tr><td>Again:&nbsp;</td><td>\n" .
		"<input type=\"password\" name=\"newpass2\" size=\"30\" /></td></tr>\n" .
		"<tr><td><input type=\"submit\" name=\"action\" value=\"Submit\" /></td></tr>\n" .
		"</table>" .
		($browser_css ? "</td></tr></table>" : "") .
		"</form>\n"
	);

	require ($pageroot . "/include/footer.php");

?>
