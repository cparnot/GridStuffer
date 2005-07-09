#!/usr/bin/perl -w

my $sleep_duration = 5;

print "starting...\n";
print "sleeping $sleep_duration seconds...\n";

sleep $sleep_duration;

print "creating some stderr...\n";
warn "Warning!! The script is at the point when it is time to create stderr!!\n";

foreach my $filename ( @ARGV ) {
	print "creating a file named $filename...\n";
	`/bin/echo some_contents_for_file_$filename > $filename`;
}

print "done!\n";

exit 0;