<?php
# $Id$

function echos ($text)
{
	echo preg_replace ("/  /", "&nbsp; ", $text);
}

?>

