<?php
	$title = "Recent News";
	$pageroot = ".";
	require ($pageroot . "/include/sql.php");
	require ($pageroot . "/include/header.php");

	box ("title", "Recent News");

	if(sqlAvail) {
		$sqlConn = twsql_connect();

		if($sqlConn) {
			$sqlQuery = "SELECT n_date, n_user, n_news FROM news_main ORDER BY n_date DESC LIMIT $newslimit";
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
			if (($fd = @fopen($pageroot . "/../cache/news.cache", "r"))) {
				echo "<!-- WARNING: MySQL connect failed.  Using cached news data. -->\n";
				fpassthru($fd);
			} else
				newsitem('now','Web Server','There was an error connecting to the MySQL server, and a cached version of the news was not available.');
		}
	} else {
		newsitem('now','Web Server','No SQL server available.');
	}

	require ($pageroot . "/include/footer.php");
?>
