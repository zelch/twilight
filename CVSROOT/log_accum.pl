#! /usr/bin/perl
# -*-Perl-*-

#
# Perl filter to handle the log messages from the checkin of files in
# a directory.  This script will group the lists of files by log
# message, and mail a single consolidated log message at the end of
# the commit.
#
# This file assumes a pre-commit checking program that leaves the
# names of the first and last commit directories in a temporary file.
#
# Contributed by David Hampton <hampton@cisco.com>
#
# hacked greatly by Greg A. Woods <woods@planix.com>

# Usage: log_accum.pl [-d] [-s] [-M module] [[-m mailto] ...] [[-R replyto] ...] [-f logfile]
#	-d		- turn on debugging
#	-m mailto	- send mail to "mailto" (multiple)
#	-R replyto	- set the "Reply-To:" to "replyto" (multiple)
#	-M modulename	- set module name to "modulename"
#	-f logfile	- write commit messages to logfile too
#	-s		- *don't* run "cvs status -v" for each file
#	-w		- show working directory with log message
#	-r		- put rcsids and delta info in mail message
#	-F fromdomain	- domain to use in email From: line.
#	-h		- turn on X-CVS header lines in mail message

#
#	Configurable options
#

$MAILER	       = "/usr/sbin/sendmail";

#
#	End user configurable options.
#

# Constants (don't change these!)
#
$STATE_NONE    = 0;
$STATE_CHANGED = 1;
$STATE_ADDED   = 2;
$STATE_REMOVED = 3;
$STATE_LOG     = 4;

$LAST_FILE     = "/tmp/#cvs.lastdir";

$CHANGED_FILE  = "/tmp/#cvs.files.changed";
$ADDED_FILE    = "/tmp/#cvs.files.added";
$REMOVED_FILE  = "/tmp/#cvs.files.removed";
$LOG_FILE      = "/tmp/#cvs.files.log";
$BRANCH_FILE   = "/tmp/#cvs.files.branch";
$SUMMARY_FILE  = "/tmp/#cvs.files.summary";

$FILE_PREFIX   = "#cvs.files";

@mos = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec);

#
#	Subroutines
#

sub cleanup_tmpfiles {
    local($wd, @files);

    $wd = `pwd`;
    chdir("/tmp") || die("Can't chdir('/tmp')\n");
    opendir(DIR, ".");
    push(@files, grep(/^$FILE_PREFIX\..*\.$id$/, readdir(DIR)));
    closedir(DIR);
    foreach (@files) {
	unlink $_;
    }
    unlink $LAST_FILE . "." . $id;

    chdir($wd);
}

sub write_logfile {
    local($filename, @lines) = @_;

    open(FILE, ">$filename") || die("Cannot open log file $filename.\n");
    print FILE join("\n", @lines), "\n";
    close(FILE);
}

sub append_to_logfile {
    local($filename, @lines) = @_;

    open(FILE, ">$filename") || die("Cannot open log file $filename.\n");
    print FILE join("\n", @lines), "\n";
    close(FILE);
}

sub format_names {
    local($dir, $tag, @files) = @_;
    local(@lines, $tagtext, $indent1, $indent2);

    if ($tag ne "") {
	$tagtext = "\tTag: $tag"
    } else {
	$tagtext = "";
    }
    $indent1 = "      ";
    $indent2 = "  ";
    $lines[0] = "$indent1$dir:$tagtext";

    if ($debug) {
	print STDERR "format_names(): dir = ", $dir, "; files = ", join(":", @files), ".\n";
    }
    $lines[++$#lines] = "$indent1$indent2";
    foreach $file (@files) {
	if (length($lines[$#lines]) + length($file) > 65) {
	    $lines[++$#lines] = "$indent1$indent2";
	}
	$lines[$#lines] .= $file . " ";
    }

    @lines;
}

sub format_lists {
    local(@lines) = @_;
    local(@text, @files, $lastdir, $tag, $gettag);

    if ($debug) {
	print STDERR "format_lists(): ", join(":", @lines), "\n";
    }
    @text = ();
    @files = ();
    $tag = "";
    $gettag = 0;
    $lastdir = shift @lines;	# first thing is always a directory
    if ($lastdir !~ /.*\/$/) {
	die("Damn, $lastdir doesn't look like a directory!\n");
    }
    foreach $line (@lines) {
	if ($line eq "Tag:") {
	    $gettag = 1;
	    next;
	} elsif ($gettag) {
	    $tag = $line;
	    $gettag = 0;
	} elsif ($line =~ /.*\/$/) {
	    push(@text, &format_names($lastdir, $tag, @files));
	    $lastdir = $line;
	    $tag = "";
	    @files = ();
	} else {
	    push(@files, $line);
	}
    }
    push(@text, &format_names($lastdir, $tag, @files));

    @text;
}

sub append_names_to_file {
    local($filename, $dir, @files) = @_;

    if (@files) {
	open(FILE, ">>$filename") || die("Cannot open file $filename.\n");
	print FILE $dir, "\n";
	print FILE join("\n", @files), "\n";
	close(FILE);
    }
}

sub read_line {
    local($line);
    local($filename) = @_;

    open(FILE, "<$filename") || die("Cannot open file $filename.\n");
    $line = <FILE>;
    close(FILE);
    chop($line);
    $line;
}

sub append_line {
    local($filename, $line) = @_;
    open(FILE, ">>$filename") || die("Cannot open file $filename.\n");
    print(FILE $line, "\n");
    close(FILE);
}

sub read_logfile {
    local(@text);
    local($filename, $leader) = @_;

    open(FILE, "<$filename");
    while (<FILE>) {
	chop;
	push(@text, $leader.$_);
    }
    close(FILE);
    @text;
}

sub find_branches {
    local(@lines) = @_;

    $tag = "";
    $hastag = 0;
    $gettag = 0;
    $lastdir = shift @lines;	# first thing is always a directory
    if ($lastdir !~ /.*\/$/) {
	die("Damn, $lastdir doesn't look like a directory!\n");
    }
    foreach $line (@lines) {
	if ($line eq "Tag:") {
	    $hastag = 1;
	    $gettag = 1;
	    next;
	} elsif ($gettag) {
	    $tag = $line;
	    $gettag = 0;
	}
    }
    if ($hastag) {
	$taglist{$tag} = $tag;
    } else {
	$taglist{"trunk"} = "trunk";
    }
}

#
# do an 'cvs -Qn status' on each file in the arguments, and extract info.
#
sub change_summary {
    local($out, @filenames) = @_;
    local(@revline);
    local($file, $rev, $rcsfile, $line);

    while (@filenames) {
	$file = shift @filenames;

	if ("$file" eq "") {
	    next;
	}

	if ("$file" eq "Tag:") {
	    shift @filenames;
	    next;
	}

	open(RCS, "-|") || exec 'cvs', '-Qn', 'status', $file;

	$rev = "";
	$delta = "";
	$rcsfile = "";


	while (<RCS>) {
	    if (/^[ \t]*Repository revision/) {
		chop;
		@revline = split(' ', $_);
		$rev = $revline[2];
		$rcsfile = $revline[3];
		$rcsfile =~ s,^$cvsroot/,,;
		$rcsfile =~ s/,v$//;
	    }
	}
	close(RCS);

	if ($rev ne '' && $rcsfile ne '') {
	    open(RCS, "-|") || exec 'cvs', '-Qn', 'log', "-r$rev", $file;
	    while (<RCS>) {
		if (/^date:/) {
		    chop;
		    $delta = $_;
		    $delta =~ s/^.*;//;
		    $delta =~ s/^[\s]+lines://;
		}
	    }
	    close(RCS);
	}

	&append_line($out, sprintf("%-13s%-12s%s", $rev, $delta, $rcsfile));
    }
}


sub build_header {
    local($header);
    local($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    $header = sprintf("Module name:\t%s\nRepository:\t%s\nChanges by:\t%s\t%02d %s %04d %02d:%02d:%02d UTC",
		      $modulename,
		      $dir,
		      $login,
		      $mday,  $mos[$mon], $year + 1900,
		      $hour, $min, $sec);
}

sub mail_notification {
    local(@text) = @_;
    local($tag, $tagprinted);

    print "Mailing the commit message to $mailto...\n";

    $tagprinted = 0;
    open(MAIL, "| $MAILER $mailto");
    print MAIL "From: $login\@$fromdomain\n";
    print MAIL "To: " . $mailto . "\n";
    if ($replyto ne '') {
	print MAIL "Reply-To: " . $replyto . "\n";
    }
    print MAIL "Subject: CVS Update: " . $modulename . " (branch: ";
    foreach $tag (sort keys %taglist) {
	if ($tagprinted) {
	    print MAIL ", ";
	}
	print MAIL $tag;
	$tagprinted = 1;
    }
    print MAIL ")\n";
	
    if ($longmailheader) {
	print MAIL "X-CVS-Notice: This email was automatically generated by a CVS checkin\n";
	if ($replyto ne '') {
	    print MAIL "X-CVS-Problems: Send problems to $replyto\n";
	}
	print MAIL "X-CVS-Version: $cvsvers\n";
	print MAIL "X-CVS-Host: $hostname running $osname\n";
    }
    print MAIL "\n";
    print MAIL join("\n", @text), "\n";
    close(MAIL);
}

sub write_commitlog {
    local($logfile, @text) = @_;

    open(FILE, ">>$logfile");
    print FILE join("\n", @text), "\n";
    close(FILE);
}

#
#	Main Body
#

# Initialize basic variables
#
$debug = 0;
$id = getpgrp();		# note, you *must* use a shell which does setpgrp()
$state = $STATE_NONE;
#$login = getlogin || (getpwuid($<))[0] || "nobody";
$login = (getpwuid($<))[0] || "nobody";
chop($hostname = `hostname`);
chop($domainname = `domainname`);
if ($domainname !~ '^\..*') {
    $domainname = '.' . $domainname;
}

$hostdomain = $hostname . $domainname;

$fromdomain = "$hostdomain";

chop($osname = `uname -sr`);
chop($cvsvers = `cvs -v | fgrep client`);

$cvsroot = $ENV{'CVSROOT'};
$do_status = 1;			# moderately useful
$show_wd = 0;			# useless in client/server
$modulename = "";
$rcsidinfo = 0;
$longmailheader = 0;

# parse command line arguments (file list is seen as one arg)
#
while (@ARGV) {
    $arg = shift @ARGV;

    if ($arg eq '-d') {
	$debug = 1;
	print STDERR "Debug turned on...\n";
    } elsif ($arg eq '-m') {
	if ($mailto eq '') {
	    $mailto = shift @ARGV;
	} else {
	    $mailto = $mailto . ", " . shift @ARGV;
	}
    } elsif ($arg eq '-R') {
	if ($replyto eq '') {
	    $replyto = shift @ARGV;
	} else {
	    $replyto = $replyto . ", " . shift @ARGV;
	}
    } elsif ($arg eq '-M') {
	$modulename = shift @ARGV;
    } elsif ($arg eq '-F') {
	$fromdomain = shift @ARGV;
    } elsif ($arg eq '-s') {
	$do_status = 0;
    } elsif ($arg eq '-w') {
	$show_wd = 1;
    } elsif ($arg eq '-f') {
	($commitlog) && die("Too many '-f' args\n");
	$commitlog = shift @ARGV;
    } elsif ($arg eq '-r') {
	$rcsidinfo = 1;
    } elsif ($arg eq '-h') {
	$longmailheader = 1;
    } else {
	($donefiles) && die("Too many arguments!  Check usage.\n");
	$donefiles = 1;
	@files = split(/ /, $arg);
    }
}
($mailto) || die("No mail recipient specified (use -m)\n");

#if ($replyto eq '') {
#    $replyto = $login;
#}

# for now, the first "file" is the repository directory being committed,
# relative to the $CVSROOT location
#
@path = split('/', $files[0]);

# XXX There are some ugly assumptions in here about module names and
# XXX directories relative to the $CVSROOT location -- really should
# XXX read $CVSROOT/CVSROOT/modules, but that's not so easy to do, since
# XXX we have to parse it backwards.
# XXX 
# XXX Fortunately it's relatively easy for the user to specify the
# XXX module name as appropriate with a '-M' via the directory
# XXX matching in loginfo.
#
if ($modulename eq "") {
    $modulename = $path[0];	# I.e. the module name == top-level dir
}
if ($#path == 0) {
    $dir = ".";
} else {
    $dir = join('/', @path);
}
$dir = $dir . "/";

if ($debug) {
    print STDERR "module - ", $modulename, "\n";
    print STDERR "dir    - ", $dir, "\n";
    print STDERR "path   - ", join(":", @path), "\n";
    print STDERR "files  - ", join(":", @files), "\n";
    print STDERR "id     - ", $id, "\n";
}

# Check for a new directory first.  This appears with files set as follows:
#
#    files[0] - "path/name/newdir"
#    files[1] - "-"
#    files[2] - "New"
#    files[3] - "directory"
#
if ($files[2] =~ /New/ && $files[3] =~ /directory/) {
    local(@text);

    @text = ();
    push(@text, &build_header());
    push(@text, "");
    push(@text, $files[0]);
    push(@text, "");

    while (<STDIN>) {
	chop;			# Drop the newline
	push(@text, $_);
    }

    &mail_notification($mailto, @text);

    exit 0;
}

# Check for an import command.  This appears with files set as follows:
#
#    files[0] - "path/name"
#    files[1] - "-"
#    files[2] - "Imported"
#    files[3] - "sources"
#
if ($files[2] =~ /Imported/ && $files[3] =~ /sources/) {
    local(@text);

    @text = ();
    push(@text, &build_header());
    push(@text, "");
    push(@text, $files[0]);
    push(@text, "");

    while (<STDIN>) {
	chop;			# Drop the newline
	push(@text, $_);
    }

    &mail_notification(@text);

    exit 0;
}

# Iterate over the body of the message collecting information.
#
while (<STDIN>) {
    chop;			# Drop the newline

    if (/^Revision\/Branch:/) {
	s,^Revision/Branch:,,;
	push (@branch_lines, split);
	next;
    }

    if (/^In directory/) {
	if ($show_wd) {		# useless in client/server mode
	    push(@log_lines, $_);
	    push(@log_lines, "");
	}
	next;
    }

    if (/^Modified Files/) { $state = $STATE_CHANGED; next; }
    if (/^Added Files/)    { $state = $STATE_ADDED;   next; }
    if (/^Removed Files/)  { $state = $STATE_REMOVED; next; }
    if (/^Log Message/)    { $state = $STATE_LOG;     next; }

    if ($state != $STATE_LOG) {
	s/^[ \t\n]+//;		# delete leading whitespace
    }
    s/[ \t\n]+$//;		# delete trailing whitespace
    
    if ($state == $STATE_CHANGED) { push(@changed_files, split); }
    if ($state == $STATE_ADDED)   { push(@added_files,   split); }
    if ($state == $STATE_REMOVED) { push(@removed_files, split); }
    if ($state == $STATE_LOG)     { push(@log_lines,     $_); }
}

# Strip leading and trailing blank lines from the log message.  Also
# compress multiple blank lines in the body of the message down to a
# single blank line.
#
while ($#log_lines > -1) {
    last if ($log_lines[0] ne "");
    shift(@log_lines);
}
while ($#log_lines > -1) {
    last if ($log_lines[$#log_lines] ne "");
    pop(@log_lines);
}
for ($i = $#log_lines; $i > 0; $i--) {
    if (($log_lines[$i - 1] eq "") && ($log_lines[$i] eq "")) {
	splice(@log_lines, $i, 1);
    }
}

if ($debug) {
    print STDERR "Searching for log file index...";
}
# Find an index to a log file that matches this log message
#
for ($i = 0; ; $i++) {
    local(@text);

    last if (! -e "$LOG_FILE.$i.$id"); # the next available one
    @text = &read_logfile("$LOG_FILE.$i.$id", "");
    last if ($#text == -1);	# nothing in this file, use it
    last if (join(" ", @log_lines) eq join(" ", @text)); # it's the same log message as another
}
if ($debug) {
    print STDERR " found log file at $i.$id, now writing tmp files.\n";
}

# Spit out the information gathered in this pass.
#
&append_names_to_file("$CHANGED_FILE.$i.$id", $dir, @changed_files);
&append_names_to_file("$ADDED_FILE.$i.$id",   $dir, @added_files);
&append_names_to_file("$REMOVED_FILE.$i.$id", $dir, @removed_files);
&append_names_to_file("$BRANCH_FILE.$i.$id",  $dir, @branch_lines);
&write_logfile("$LOG_FILE.$i.$id", @log_lines);
if ($rcsidinfo) {
    &change_summary("$SUMMARY_FILE.$i.$id", @changed_files);
}

# Check whether this is the last directory.  If not, quit.
#
if ($debug) {
    print STDERR "Checking current dir against last dir.\n";
}
$_ = &read_line("$LAST_FILE.$id");

if ($_ ne $cvsroot . "/" . $files[0]) {
    if ($debug) {
	print STDERR sprintf("Current directory %s is not last directory %s.\n", $cvsroot . "/" .$files[0], $_);
    }
    exit 0;
}
if ($debug) {
    print STDERR sprintf("Current directory %s is last directory %s -- all commits done.\n", $files[0], $_);
}

#
#	End Of Commits!
#

# This is it.  The commits are all finished.  Lump everything together
# into a single message, fire a copy off to the mailing list, and drop
# it on the end of the Changes file.
#

#
# Produce the final compilation of the log messages
#
@text = ();
@status_txt = ();
push(@text, &build_header());
push(@text, "");

for ($i = 0; ; $i++) {
    last if (! -e "$LOG_FILE.$i.$id"); # we're done them all!
    @lines = &read_logfile("$LOG_FILE.$i.$id", "  ");
    if ($#lines >= 0) {
	push(@text, "Log message:");
	push(@text, @lines);
	push(@text, "");
    }
    @lines = &read_logfile("BRANCH_FILE.$i.$id", "");
    if ($#lines >= 0) {
	push (@text, "Branch:");
	push(@text, &format_lists(@lines));
    }
    @lines = &read_logfile("$CHANGED_FILE.$i.$id", "");
    if ($#lines >= 0) {
	push(@text, "Modified files:");
	push(@text, &format_lists(@lines));
	&find_branches(@lines);
    }
    @lines = &read_logfile("$ADDED_FILE.$i.$id", "");
    if ($#lines >= 0) {
	push(@text, "Added files:");
	push(@text, &format_lists(@lines));
	&find_branches(@lines);
    }
    @lines = &read_logfile("$REMOVED_FILE.$i.$id", "");
    if ($#lines >= 0) {
	push(@text, "Removed files:");
	push(@text, &format_lists(@lines));
	&find_branches(@lines);
    }
    if ($rcsidinfo) {
	if (-e "$SUMMARY_FILE.$i.$id") {
	    @lines = &read_logfile("$SUMMARY_FILE.$i.$id", "  ");
	    if ($#lines >= 0) {
		push(@text, "  ");
		push(@text, "  Revision      Changes    Path");
		push(@text, @lines);
	    }
	}
    }
    if ($#text >= 0) {
	push(@text, "");
    }
    if ($do_status) {
	local(@changed_files);

	@changed_files = ();
	push(@changed_files, &read_logfile("$CHANGED_FILE.$i.$id", ""));
	push(@changed_files, &read_logfile("$ADDED_FILE.$i.$id", ""));
	push(@changed_files, &read_logfile("$REMOVED_FILE.$i.$id", ""));

	if ($debug) {
	    print STDERR "main: pre-sort changed_files = ", join(":", @changed_files), ".\n";
	}
	sort(@changed_files);
	if ($debug) {
	    print STDERR "main: post-sort changed_files = ", join(":", @changed_files), ".\n";
	}

	foreach $dofile (@changed_files) {
	    if ($dofile =~ /\/$/) {
		next;		# ignore the silly "dir" entries
	    }
	    if ($debug) {
		print STDERR "main(): doing 'cvs -nQq status -v $dofile'\n";
	    }
	    open(STATUS, "-|") || exec 'cvs', '-nQq', 'status', '-v', $dofile;
	    while (<STATUS>) {
		chop;
		push(@status_txt, $_);
	    }
	}
    }
}

# Write to the commitlog file
#
if ($commitlog) {
    &write_commitlog($commitlog, @text);
}

if ($#status_txt >= 0) {
    push(@text, @status_txt);
}

# Mailout the notification.
#
&mail_notification(@text);

# cleanup
#
if (! $debug) {
    &cleanup_tmpfiles();
}

exit 0;

