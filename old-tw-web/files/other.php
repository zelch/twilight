<?php
	$title = "Other Files";
	$pageroot = "..";
	require ($pageroot . "/include/header.php");

	box ("title", "Other Files");

	box ("para", "Because Project Twilight is based on the Quake&reg;\n" .
		"source code, it should work with all of the mods, levels, and\n" .
		"mission packs you know so well.&nbsp; However, we realize there\n" .
		"are some people who have been living under a rock for the past\n" .
		"several years and may not have everything you need.&nbsp; While\n" .
		"we can't provide everything you could ever want here, we do\n" .
		"have a few things you might need.\n"
	);


/*
// FIXME: Package the vmodel pak and upload it

	box ("sub", "Replacement view models");

	box ("para", "Project Twilight uses an effect called interpolation\n" .
		"on its models by default.&nbsp; You can turn it off, though the\n" .
		"game looks better if you have it turned on.&nbsp; The only flaw\n" .
		"with using it is that some models were animated with shortcuts\n" .
		"to keep the polycounts low, and look bad with it.&nbsp; See the\n" .
		"Id nailgun as an example.&nbsp; Here are replacements for some\n" .
		"models which need them.\n"
	);

	box ("line", "<a href=\"vmdl-lerp.zip\">Replacements for Id's view\n" .
		"models</a>\n"
	);

	box ("para", "Please note that we do not at this time have support\n" .
		"for loading *.pak, though the feature is planned.&nbsp; You'll\n" .
		"have to rename this to the next available pak#.pak in your id1\n" .
		"directory for now.\n"
	);
*/

	box ("sub", "Demos");

	box ("para", "These demos are the ones we use as our performance\n" .
		"testing.&nbsp; They're chosen because they are stress most older\n" .
		"hardware and can even slow down newer hardware a bit.\n"
	);

	box ("line", "[NQ] <a href=\"bigass1.zip\">bigass1</a>\n");
	box ("line", "[QW] <a href=\"overkill.zip\">overkill</a>\n");


	box ("sub", "Essential game data");

	box ("para", "Project Twilight requires that you have a set of game\n" .
		"data in order to play.&nbsp; Quake&reg; can be had most places\n" .
		"for US$10 or less but you've gotta find it first.&nbsp; Here's\n" .
		"some game data you may freely download until then.\n"
	);

	box ("line", "<a href=\"idsw106.zip\">Quake&reg; Shareware 1.06</a>\n");
	box ("line", "WANTED: TC's which do not require an id1 directory\n");


	box ("sub", "Progs");

	box ("para", "In order to run a QuakeWorld&reg; server, you need a\n" .
		"file called qwprogs.dat, even if you're not running a mod.&nbsp;\n" .
		"Here are a couple.\n"
	);

	box ("line", "<a href=\"qwprogs.zip\">Id's qwprogs.dat</a>\n");
	box ("line", "<a href=\"kteam221.zip\">Kombat Teams 2.21 Teamplay</a>\n");
	box ("line", "<a href=\"kt222ffa.zip\">Kombat Teams 2.22\n" .
		" Free-for-all</a>\n"
	);

	require ($pageroot . "/include/footer.php");
?>
