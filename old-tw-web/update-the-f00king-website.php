<?php
	header ("Content-type: text/plain");

	if (ereg ("curl", $HTTP_USER_AGENT) || $force == "yes")
	{
		$sec = 160 - $time() % 160;
		touch ("/home/groups/t/tw/twilight/pulse/update-website");
		echo ("Webpulse should happen in $sec\n");
	} else {
		echo ("I'm sorry Dave, but I'm afraid I can't do that.");
	}
?>

