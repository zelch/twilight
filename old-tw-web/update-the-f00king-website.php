<?php
	header ("Content-type: text/plain");

	if (ereg ("curl", $HTTP_USER_AGENT) || $force == "yes")
	{
		echo ("Requesting webpulse.\n");
		touch ("/home/groups/t/tw/twilight/pulse/update-website");
	} else {
		echo ("I'm sorry Dave, but I'm afraid I can't do that.");
	}
?>

