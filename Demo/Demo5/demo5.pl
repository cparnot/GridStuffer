#!/usr/bin/perl -w

my $sleep_duration = 5;

warn "starting...\n";
warn "sleeping $sleep_duration seconds...\n";

sleep $sleep_duration;

my $a = $ARGV[0];
my $b = $ARGV[1];

warn "calculating $a/$b...\n";

my $c=$a/$b;
print "$c\n";

warn "done!\n";

exit 0;