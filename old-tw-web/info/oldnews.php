<?php
	$title = "Older News";
	$pageroot = "..";
	require ($pageroot . "/include/sql.php");
	require ($pageroot . "/include/header.php");

	box ("title", "Older News");

	box ("para", "This page lists all of our older news.&nbsp; Since it\n" .
		"contains the entire history of the project, this page may take\n" .
		"awhile to load.&nbsp; Please be patient.\n"
	);

	if(sqlAvail) {
		$sqlConn = twsql_connect();

		if($sqlConn) {
			$sqlQuery = "SELECT n_date, n_user, n_news FROM news_main ORDER BY n_date DESC IGNORE";
			$res = twsql_query($sqlQuery, $sqlConn);

			if($res) {
				$numrows = @mysql_num_rows($res);
				if($numrows) {
					$j = 2 - $newslimit;
					for($i = 0; $i < $numrows; $i++) {
						list ($n_date, $n_user, $n_news) = mysql_fetch_row($res);
						if ($j++ > 0) {
							newsitem(SQLtoNewsDate($n_date), $n_user, $n_news);
						}
					}
					if ($j < 1) {
						newsitem('now','Web Server','No old news!');
					}
				} else {
					newsitem('now','Web Server','No old news!');
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
