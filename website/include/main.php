<?php
# $Id$

require "include/functions.php";
require "include/config.php";
require "include/startpage.php";

function endpage ()
{
	echos ("</div>\n</div>\n");
	echos ("</td>\n</tr></table>\n</body>\n</html>\n");
}

function newsitem ($date, $content)
{
	echos ("<div class=\"news\">\n");
	echos ("<div class=\"newsdate\">\n$date\n</div>\n");
	echos ("<div class=\"newscontent\">\n$content\n</div>\n");
	echos ("</div>");
}

?>

