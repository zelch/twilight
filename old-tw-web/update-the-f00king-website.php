<?php
	header ("Content-type: text/plain");

	if (ereg ("curl", $HTTP_USER_AGENT) || $force == "yes")
	{
		$sec = 120 - time() % (15 * 60);
		touch ("/home/groups/t/tw/twilight/pulse/update-website");
		echo ("Webpulse should happen in $sec seconds\n");
	} else {
		echo ("I'm sorry Dave, but I'm afraid I can't do that.");
	}
?>

