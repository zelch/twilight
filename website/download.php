<?php
# $Id$

require "include/main.php";

startpage ("Download");

echo ("Here is the current release of Project: Twilight\n");

foreach ($glob("$webspace/release/*.zip") as $filename)
{
	echo $filename
}

echo ("This page isn't done yet...<br>\n");
echo ("So go <a href=\"/twilight/release/\">here</a> for now.\n");

endpage ();

?>

