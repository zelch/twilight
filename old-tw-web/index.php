<?php
	$page = "News";
	require ("include/header.php");

	titlebox ("news", "posted now by Knghtbrd", "Place useful content here");
	titlebox ("news", "posted before now by Knghtbrd",
			"Older content here");

	box ("plugs",
		"<a href=\"http://sourceforge.net\"> <img width=\"88\" height=\"31\"" .
			"src=\"http://sourceforge.net/sflogo.php?group_id=31385\" " .
			"border=\"0\" alt=\"SourceForge\"></a>" .
		"<a href=\"http://www.opengl.org\"><img src=\"images/opengl.gif\" " .
			"alt=\"OpenGL\" border=\"0\"></a>"
		
	);

	require ("include/footer.php");
?>
