<?php
	require($pageroot . "/include/sql.php");

function send_auth_headers() {
	global $pagerealm, $usertable, $newacct, $pageroot, $display;
	header("WWW-Authenticate: Basic realm=\"" . $pagerealm . "\"");
	header("HTTP/1.0 401 Unauthorized");

	// Make the access denied message look nice.

	$title = "Access Denied";
	require ($pageroot . "/include/header.php");
	echo box("title", "Access Denied");
	echo box("para", "This page requires authorization. Please log in. \n");

	if($newacct) {
		//create new account form here
	}

	require ($pageroot . "/include/footer.php");
}

function get_auth($user, $pass) {
	global $usertable;

	if (!$user)
		return NULL;

	$query = "SELECT u_key, u_admin, u_username, u_fullname, u_email, u_web, 1 as auth FROM $usertable " . 
		"WHERE u_username='$user' " .
		"AND (u_password='" . crypt("$pass","$user") . "' " . 
		"OR u_password='" . md5("$pass") . "');";

	if (($sqlConn = twsql_connect())) {
		if (($sqlResult = twsql_query($query, $sqlConn))) {
			list($authdata['u_key'], $authdata['u_admin'],
			$authdata['u_username'], $authdata['u_fullname'],
			$authdata['u_email'], $authdata['u_web'], $auth) = mysql_fetch_row($sqlResult);
			if ($auth == 1)
				return $authdata;
		}
	}
	return NULL;
}
?>
