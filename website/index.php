<?php
# $Id$

require "include/main.php";

startpage ("News");

newsitem ("Tuesday, 25 June 2002",
		"The website (such that it is) has been converted to PHP.  " .
		"It's still not classifyable as a real website, but at least it's " .
		"now a mockup written in PHP rather than XHTML.  there is ".
		"still not one whit of non-CSS support yet, sorry."
);

newsitem ("Thursday, 20 June 2002",
		"The template for the new website looks non-sucky finally!  " .
		"That's right, after many many long hours of fucking around with " .
		"Mozilla, GIMP, vim, and an armload of reference manuals and " .
		"websites, Knghtbrd is finally satisfied.  This looks nifty " .
		"enough."
);

newsitem ("Wednesday, 19 June 2002",
		"Something nifty happened on or about this time.  Really it " .
		"did!"
);

endpage ();

?>

