<?php
	function SQLtoNewsDate($date)
	{
		$time = explode(' ',$date);
		$webdate = explode('-',$time);
		return strftime ( '%d %b %Y', mktime (0, 0, 0, $webdate[1], $webdate[2], $webdate[0]));
	}

	function email ($person)
	{
		global $userinfo;

		return "<a href=\"mailto:" . $userinfo[$person]["Email"] . "\">" .
			$person . "</a>";
	}

	function boxstart ($style)
	{
		global $browser_css;
		global $display;

		if ($browser_css) {
			echo ("<div class=\"" . $style . "\">\n");
		} else {
			echo ("<table " . $display[$style] . ">\n<tr><td>\n");
			if ($display[$style . "pre"]) {
				echo ($display[$style . "pre"] . "\n");
			}
		}
	}

	function boxend ($style)
	{
		global $browser_css;
		global $display;

		if ($browser_css) {
			echo ("\n</div>\n");
		} else {
			if ($display[$style . "post"]) {
				echo ($display[$style . "post"] . "\n");
			}
			echo ("\n</td></tr>\n</table>\n");
		}
	}

	function box ($style, $content) {
		boxstart ($style);
		echo ($content);
		boxend ($style);
	}

	function titlebox ($style, $title, $content)
	{
		global $browser_css;

		if (!$browser_css) {
			echo ("<p>\n");
		}
		boxstart ($style);
		box ($style . "title", $title);
		box ($style . "content", $content);
		boxend ($style);
		if (!$browser_css) {
			echo ("</p>\n");
		}
	}

	function newsitem ($date, $submitter, $content)
	{
		titlebox ("news", "posted " . $date . " by " . email($submitter),
			$content);
	}
?>

