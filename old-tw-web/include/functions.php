<?php
	function email ($person)
	{
		global $userinfo;

		return "<a href=\"mailto:" . spamarmor_url($userinfo[$person]["Email"]) . "\">" .
			$person . "</a>";
	}

	function spamarmor ($address) {
		return ereg_replace("@", " at ", ereg_replace("\.", " dot ", $address));
	}
	function spamarmor_url ($address) {
		return ereg_replace("@", "%40", ereg_replace("\.", "%2e", $address));
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
			echo ("<br />\n");
		}
		boxstart ($style);
		box ($style . "title", $title);
		box ($style . "content", $content);
		boxend ($style);
	}
	function newsitem ($date, $submitter, $content)
	{
		return titlebox ("news", "posted " . $date, $content);
	}

	function SQLtoNewsDate($date)
	{
		$time = explode(' ',$date);
		$webdate = explode('-',$time[0]);
		return strftime ( '%d %b %Y', mktime (0, 0, 0, $webdate[1], $webdate[2], $webdate[0]));
	}

	function htmlify_line ($line) {
		if (ereg ("^  (.*) <(.*@.*)>", $line, $parts)) {
			list($discard, $name, $email) = $parts;
			return sprintf("%s &lt;<a href=\"mailto:%s\">%s</a>&gt;", $name, spamarmor_url($email), spamarmor($email));
		}
	}

?>

