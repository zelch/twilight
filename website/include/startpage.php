<?php
# $Id$

function startpage_doctype ($title, $strict)
{
	echo ("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
	if ($strict)
	{
		echo ("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" SYSTEM \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n");
	}
	else
	{
		echo ("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" SYSTEM \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n");
	}
}

function startpage_heading ($title)
{
	global $css_avail;

	echo ("<html>\n<head>\n");
	echo ("<title>Project: Twilight - $title</title>");
	if ($css_avail)
	{
		echo ("<link rel=\"StyleSheet\" type=\"text/css\" " .
			"href=\"style/default.css\" title=\"Default\" />");
	}
	echo ("</head>\n");

	if ($css_avail)
	{
		echo ("<body>\n");
	}
	else
	{
		# FIXME: add support for non-CSS
		echo ("<body>\n");
	}

	echo ("<div class=\"heading\">\n");
	echo ("<img alt=\"Project: Twilight\" src=\"image/title.gif\" />\n");
	echo ("</div>\n");

	# *sigh* Still need tables for proper layout
	echo ("<table cellspacing=\"0\" cellpadding=\"0\" border=\"0\" " .
		"width=\"100%\" class=\"layout\">\n<tr>\n");
}

function startpage_nav ($title)
{
	global $css_avail;
	global $navsection;

	# FIXME: add support for non-CSS
	# Nav sidebar
	echo ("<td class=\"layout\" valign=\"top\" width=\"200\">\n");
	echo ("<div class=\"nav\">\n");

	while (list ($key, $val) = each ($navsection))
	{
		if ($key == $title)
		{
			echo ("<img alt=\"$key\" border=\"0\" " .
					"src=\"image/$key-actnav.png\" />\n");
		}
		else
		{
			/* Verdana bold, 16pt, white on #172b3f */
			echo ("<a href=\"$val\"><img alt=\"$key\" border=\"0\" " .
					"src=\"image/$key-nav.png\" /></a>\n");
		}
	}

	echo ("</div>\n</td>\n");
}

function startpage ($title)
{
	global $css_avail;

	startpage_doctype ($title, $css_avail);
	startpage_heading ($title);
	startpage_nav ($title);

	/* Main page content */
	echo ("<td class=\"layout\" valign=\"top\">\n<div class=\"page\">\n");

	# Page title image
	# Courier New bold, 48pt, white on black
#	echo ("<img alt=\"$title\" src=\"image/$title-title.png\" />\n");

	echo ("<div class=\"content\">");
}

?>

