<?php

if (ereg( "Konqueror/([0-9].[0-9]([0-9]|beta.*))(\;|\))",$HTTP_USER_AGENT,
		$log_version)) {
	$browser_name="Konqueror";
	$browser_version=$log_version[1];
} elseif (ereg( "MSIE ([0-9].[0-9]{1,2})",$HTTP_USER_AGENT,$log_version)) {
	$browser_name="MSIE";
	$browser_version=$log_version[1];
} elseif (ereg( "Opera ([0-9].[0-9]{1,2})",$HTTP_USER_AGENT,$log_version)) {
	$browser_name="Opera";
	$browser_version=$log_version[1];
} elseif (ereg( "Lynx/([0-9].[0-9]{1,2})",$HTTP_USER_AGENT,$log_version)) {
	$browser_name="Lynx";
	$browser_version=$log_version[1];
} elseif (ereg("Mozilla/([0-9].[0-9]{1,2})",$HTTP_USER_AGENT,$log_version)) {
	$browser_name="Mozilla";
	$browser_version=$log_version[1];
} else {
	$browser_name="Unknown";
	$browser_version="0";
}

if (strstr($HTTP_USER_AGENT,"Win")) {
	$browser_platform="Win";
} else if (strstr($HTTP_USER_AGENT,"Linux")) {
	$browser_platform="Linux";
} else if (strstr($HTTP_USER_AGENT,"Unix")) {
	$browser_platform="Unix";
} else if (strstr($HTTP_USER_AGENT,'Mac')) {
	$browser_platform="Mac";
} else {
	$browser_platform="Unknown";
}
$browser_css = FALSE;
if ($browser_name == "Mozilla") {
	if ((float)$browser_version >= 5.0) {
		$browser_css = TRUE;
	}
} elseif ($browser_name == "MSIE") {
	if ($browser_platform = "Mac") {
		if ((float)$browser_version >= 5.0)
			$browser_css = TRUE;
	} elseif ((float)$browser_version >= 4.0)
		$browser_css = TRUE;
} elseif ($browser_name == "Konqueror") {
	if ((float)$browser_version >= 2.2) {
		if (!ereg ("^2\.2beta.*", $browser_version)) {
			$browser_css = TRUE;
		}	
	}
} elseif ($browser_name == "Opera") {
	if ((float)$browser_version >= 3.60) {
		$browser_css = TRUE;
	}
}
// Used to consider lynx a CSS browser, but the site looks better without it

if ($use_css == "no")
{
	$browser_css = FALSE;
} elseif ($use_css == "yes") {
	$browser_css = TRUE;
}

/*
echo "Agent: $HTTP_USER_AGENT";
echo "<br />Browser: " . $browser_name;
echo "<br />Version: " . $browser_version;
echo "<br />Platform: " . $browser_platform;
echo "<br />CSS: " . (int)$browser_css;
*/
?>
