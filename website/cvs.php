<?php
# $Id$

require "include/main.php";

startpage ("CVS");

echo ("There are multiple ways to access Twilight CVS:<ul>\n");
echo ("<li>The icculus.org CVS <a href=\"http://cvs.icculus.org/horde/chora/cvs.php?rt=twilight\">web interface<\a>.\n");
echo ("<li>Anonymous CVS: cvs -z3 -d:pserver:anonymous@cvs.icculus.org:/cvs/cvsroot/twilight/ co twilight\n");
echo ("<li>Private CVS: cvs -z3 -d<user>@cvs.icculus.org:/cvs/cvsroot/twilight/ co twilight\n");
echo ("</ul>\n");

endpage ();

?>

