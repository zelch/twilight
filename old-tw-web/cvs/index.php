<?php
	$title = "CVS Snapshots";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");
	require ($pageroot . "/include/files.php");

	box ("title", "CVS Snapshots");

	box ("para", "We make nightly snapshots of our code to make it easier\n" .
		"for you to download since checking them out of CVS can take\n" .
		"awhile, especially if you're using a modem.&nbsp; Please note\n" .
		"that these snapshots include source code.&nbsp; You'll need a\n" .
		"compiler in order to make use of them.\n"
	);

	// FIXME: check for ./*.zip and show the file's mtime
	flink ("twilight-current.zip");

	require ($pageroot . "/include/footer.php");
?>
