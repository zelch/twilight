<?php
	$title = "Recent News";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	box ("title", "Recent News");

	$newslimit = 5;

	if(sqlAvail) {
		$sqlConn = @mysql_pconnect(sqlHost, sqlUser, sqlPass);

		if($sqlConn) {
			$sqlQuery = "SELECT n_date, n_user, n_news FROM news_main ORDER BY n_date DESC LIMIT $limit;";
			$res = @mysql_db_query(sqlDB, $sqlQuery, $sqlConn);

			if($res) {
				$numrows = @mysql_num_rows($res);
				if($numrows) {
					for($i = 0; $i < $numrows; $i++) {
						list ($n_date, $n_user, $n_news) = mysql_fetch_row($result);
						newsitem(SQLtoNewsDate($n_date), $n_user, $n_news);
					}
				} else {
					newsitem('now','Web Server','ACK! No news!');
				}
			}
		} else {
			newsitem('now','Web Server','There was an error connecting to the MySQL server.');
		}
		mysql_close($sqlConn);
	} else {
		newsitem('now','Web Server','No SQL server available.');
	}

	require ($pageroot . "/include/footer.php");
?>
