<?php
	$title = "Developers";
	$pageroot = ".";
	require ($pageroot . "/include/header.php");

	box ("title", "Developers");

	box ("para", "This is a list of the project's developers.&nbsp It is\n" .
		"not a complete list of contributors.&nbsp; If you're looking for\n" .
		"that, go <a href=\"/devel/credits.php\">here</a>.  This is just\n" .
		"a list of people who have commit access to the project.&nbsp; In\n" .
		"other words, it's a list of people you can blame when things go\n" .
		"wrong or expect to have at least a clue what's going on if you\n" .
		"need to know.&nbsp; ;)"
	);

	while (list ($nick, $person) = each ($userinfo)) {
		echo ($nick . "<br>\n");
	}

	require ($pageroot . "/include/footer.php");
?>
