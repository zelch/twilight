<p></p>
<?php
	if ($browser_css) {
		echo ("<div class=footer>\n");
	} else {
		echo ("<table border=0 width=100% bgcolor=\"" .
			$display["base"] . "\">\n<tr><td><center>");
	}
?>
<font size="-2">
FIXME: Something about Copyright here, preferably not to any one person<br>
Quake&reg; and QuakeWorld&reg; are registered trademarks of
<a href="http://www.idsoftware.com/">Id Software, Inc</a>
</font>
<?php
	if ($browser_css) {
		echo ("</div>\n");
	} else {
		echo ("</center></td></tr>\n</table>");
	}
?>
</body>
</html>

