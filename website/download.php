<?php
# $Id$

require "include/main.php";

startpage ("Download");


echo ("Here is the current release of Project: Twilight\n");

echo ("<div class=\"files\">\n");
foreach (glob("$webspace/release/*.zip") as $filename)
{
	$filename = basename($filename);
	$url = "$urlbase/release/$filename";
	echo ("<br><a href=\"$url\">$filename</a>\n");
}
echo ("</div>");

echo ("This page isn't done yet...<br>\n");
echo ("So go <a href=\"/twilight/release/\">here</a> for now.\n");

endpage ();

?>

