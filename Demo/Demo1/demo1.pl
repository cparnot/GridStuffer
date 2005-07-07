#!/usr/bin/perl -w

my $script_name = $0;

print "running $script_name with arguments: ".join(", ",@ARGV)."\n";

print "working directory:\n".`pwd`;
print "files:\n".`ls`;

exit 0;