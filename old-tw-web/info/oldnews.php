<?php
	$title = "Older News";
	$pageroot = "..";
	require ($pageroot . "/include/sql.php");
	require ($pageroot . "/include/header.php");

	box ("title", "Older News");

	if(sqlAvail) {
		$sqlConn = twsql_connect();

		if($sqlConn) {
			$sqlQuery = "SELECT n_date, n_user, n_news FROM news_main ORDER BY n_date DESC IGNORE " .  $newslimit - 1 . " LINES";
			$res = twsql_query($sqlQuery, $sqlConn);

			if($res) {
				$numrows = @mysql_num_rows($res);
				if($numrows) {
					for($i = 0; $i < $numrows; $i++) {
						list ($n_date, $n_user, $n_news) = mysql_fetch_row($res);
						newsitem(SQLtoNewsDate($n_date), $n_user, $n_news);
					}
				} else {
					newsitem('now','Web Server','ACK! No news!');
				}
			}
			mysql_close($sqlConn);
		} else {
			newsitem('now','Web Server','SQL server is temporarily offline, please try again later.\n');
		}
	} else {
		newsitem('now','Web Server','No SQL server available.');
	}

	require ($pageroot . "/include/footer.php");
?>
