<?php
	function email ($person)
	{
		global $userinfo;

		return "<a href=\"mailto:" . spamarmor($userinfo[$person]["Email"]) . "\">" .
			$person . "</a>";
	}

	function spamarmor ($address) {
		srand ((double) microtime() * 1000000);
		switch (rand(0, 4)) {
			case 0:
				return ereg_replace("@", "[at]", $address);
			case 1:
				return ereg_replace("@", "SPAM@SPAM", $address);
			case 2:
				return strrev($address);
			case 3:
				return ereg_replace("@", ".nospam@nospam.", $address);
			case 4:
				return ereg_replace("@", " at ", $address);
		}
	}

	function boxstart ($style)
	{
		global $browser_css;
		global $display;

		if ($browser_css) {
			echo ("<div class=\"" . $style . "\">\n");
		} else {
			echo ("<table " . $display[$style] . ">\n<tr " .
				$display[$style . "tr"] . "><td " .
				$display[$style . "td"] . ">\n");
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
			echo ("<br>\n");
		}
		boxstart ($style);
		box ($style . "title", $title);
		box ($style . "content", $content);
		boxend ($style);
	}
	function newsitem ($date, $submitter, $content)
	{
		return titlebox ("news", "posted " . $date . " by " . email($submitter),
			$content);
	}

	function SQLtoNewsDate($date)
	{
		$time = explode(' ',$date);
		$webdate = explode('-',$time[0]);
		return strftime ( '%d %b %Y', mktime (0, 0, 0, $webdate[1], $webdate[2], $webdate[0]));
	}
?>

