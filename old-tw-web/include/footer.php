<?php
	if ($browser_css) {
		echo ("</td></tr>\n<tr><td colspan=\"2\" class=\"footer\">\n");
	} else {
		echo ("</td></tr>\n<tr><td colspan=\"2\" " . $display["footer"] .
			">\n");
		echo ($display["footerpre"]);
	}
	echo (
		"Contributions to Project Twilight are Copyright &copy; by their " .
		"submitters.<br>" .
		"See <a href=\"/devel/credits.php\">credits</a> for details</a><br>" .
		"Quake&reg; and QuakeWorld&reg; are Copyright &copy; 1996-1997 by " .
		"<a href=\"http://www.idsoftware.com/\">Id Software, Inc</a><br>" .
		"Quake&reg; and QuakeWorld&reg; are registered trademarks " .
		"of <a href=\"http://www.idsoftware.com/\">Id Software, Inc</a>"
	);
	if (!$browser_css) {
		echo ($display["footerpost"]);
	}
	echo ("</td></tr>\n</table>\n");
?>
</body>
</html>

