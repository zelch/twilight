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
	flink ("twilight-0.1.0.zip");
	flink ("twilight-current.zip");

	box ("para", "Some of our users on platforms such as Win32 don't have\n" .
		"access to compilers and other tools which would make testing the\n" .
		"CVS snapshots listed above possible.&nbsp; Here are binaries of\n" .
		"recent CVS snapshots to help with testing.&nbsp; Fair warning,\n" .
		"this code has not been thuroughly tested yet and several of the\n" .
		"new features are probably not documented at the moment.\n"
	);

	flink ("twilight-win32-20020425.zip");

	require ($pageroot . "/include/footer.php");
?>
