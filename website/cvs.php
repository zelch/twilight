<?php
# $Id$

require "include/main.php";

startpage ("CVS");

echo ("There are multiple ways to access Twilight CVS:<ul>\n");
echo ("<li>The icculus.org CVS <a href=\"http://cvs.icculus.org/cvs/twilight\">web interface</a>.\n");
echo ("<li>Anonymous CVS: <code>cvs -z3 -d:pserver:anonymous@cvs.icculus.org:/cvs/cvsroot/twilight/ login</code> (password: anonymous) followed by <code>cvs -z3 -d:pserver:anonymous@cvs.icculus.org:/cvs/cvsroot/twilight/ co twilight</code>\n");
echo ("<li>Private CVS: cvs -z3 -d<user>@cvs.icculus.org:/cvs/cvsroot/twilight/ co twilight\n");
echo ("<li>ViewCVS: <a href=\"http://cvs.icculus.org/cvs/twilight/twilight/\">Web interface</a>\n");
echo ("</ul>\n");

endpage ();

?>

