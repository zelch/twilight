<?php
	if(file_exists($pageroot . "/../webprivate/sql.conf")) {
		include($pageroot . "/../web-private/sql.conf");
	} else {
		define('sqlAvail',	0);
	}
?>
