<?php
	function box ($style, $content)
	{
		global $browser_css;
		global $display;

		if ($browser_css) {
			echo ("<div class=\"" . $style . "\">\n");
		} else {
			echo ("<table " . $display[$style . "table"] . ">\n<tr><td>\n");
			if ($display[$style . "pre"]) {
				echo ($display[$style . "pre"] . "\n");
			}
		}

		echo ($content);

		if ($browser_css) {
			echo ("\n</div>\n");
		} else {
			if ($display[$style . "post"]) {
				echo ($display[$style . "post"] . "\n");
			}
			echo ("\n</td></tr>\n</table>\n");
		}
	}
?>
