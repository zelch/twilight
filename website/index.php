<?php
# $Id$

require "include/main.php";

startpage ("News");

newsitem ("Sunday, 7 July 2002",
		"The website is now in CVS properly, with webpulse script.  " .
		"Knghtbrd apologizes for the delay in getting the new site up and " .
		"running, and thanks everyone for their patience.  He's got a todo " .
		"list that would scare most anyone and this website comprises but " .
		"half a dozen items on it.  Coming soon, download pages and CVS " .
		"snapshots."
);

newsitem ("Tuesday, 25 June 2002",
		"The website (such that it is) has been converted to PHP.  " .
		"It's still not classifyable as a real website, but at least it's " .
		"now a mockup written in PHP rather than XHTML.  there is ".
		"still not one whit of non-CSS support yet, sorry."
);

endpage ();

?>

