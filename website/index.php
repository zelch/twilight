<?php
# $Id$

require "include/main.php";

startpage ("News");

newsitem ("Saturday, 8 August 2005",
		"Mercury has released 0.2.1, and Win32 binaries are up."
		. "  The changelog is, not small."
);

newsitem ("Saturday, 12 July 2003",
		"Mercury has released 0.2.02, and Win32 binaries are up."
		. "  This allows the sound loader to deal with 0 length wavs."
);

newsitem ("Friday, 11 July 2003",
		"Mercury has released 0.2.01, and Win32 binaries are up."
		. "  This fixes a win32 bug that kept some people from running"
		. "Twilight, among a few other things."
);

newsitem ("Wednesday, 9 July 2003",
		"Mercury has released 0.2.00, and Win32 binaries are up, just in "
		. "time for QExpo!  Have at 'em everyone, and don't forget to "
		. "report bugs..."
);

newsitem ("Friday, 31 December 2002",
		"We now have win32 binaries!"
);	

newsitem ("Thursday, 30 December 2002",
		"Ok! Twilight 0.2.0-RC2 has been released!  " .
		"Please pound on it and report ANY bugs that are found, thanks."
);	

newsitem ("Friday, 1 November 2002",
		"Ah, yes, something to direct people to! So this is where it was " .
		"hiding.."
);	

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

