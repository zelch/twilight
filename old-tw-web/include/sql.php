<?php
	if(file_exists($pageroot . "/../web-private/sql.conf")) {
		include($pageroot . "/../web-private/sql.conf");
	} else {
		define('sqlAvail',	0);
	}

# These are all simplified (at least for now), since we only use
# one SQL server and one database for everything
function twsql_connect()
{
	static $sqlConn = NULL;

	# Essentially what mysql_pconnect does, but we might as well
	# take a bit more load off the servers.

	if (!$sqlConn)
		$sqlConn = @mysql_pconnect(sqlHost, sqlUser, sqlPass);

	return $sqlConn;
}

function twsql_query($query, $dbh = 'NO_PARAM')
{
	if ($dbh == 'NO_PARAM')
		$dbh = twsql_connect();

	return @mysql_db_query(sqlDB, $query, $dbh);
}
?>
