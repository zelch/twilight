<?php
# $Id$

require "include/main.php";

startpage ("Download");


echo ("<p>Here is the current release of Project: Twilight.</p>\n");

echo ("<div class=\"files\">\n");
foreach (glob("$webspace/release/*.zip") as $filename)
{
	$filename = basename($filename);
	$url = "$urlbase/release/$filename";
	echo ("<a href=\"$url\">$filename</a><br>\n");
}
echo ("</div>");

echo ("<p>Older releases can be found <a href=\"$urlbase/release/archive\">"
		. "here</a></p>\n");

echo ("<p>Other files which might come in handy:</p>\n");
echo ("<div class=\"files\">\n");
foreach (glob("$webspace/file/*.zip") as $filename)
{
	$filename = basename($filename);
	$url = "$urlbase/file/$filename";
	echo ("<a href=\"$url\">$filename</a><br>\n");
}
echo ("</div>");

?>

