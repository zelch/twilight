<?
$pageroot = "..";
require ($pageroot . "/include/sql.php");

if (sqlAvail) {
	if (($sqlConn = twsql_connect())) {
		$sqlQuery = "UPDATE downloads SET downloads=downloads + 1 WHERE filename='" . urlencode(substr($PATH_INFO, 1)) . "';";
		twsql_query($sqlQuery, $sqlConn);
	}
}
header("Location: http://$SERVER_NAME:$SERVER_PORT/releases$PATH_INFO");
?>