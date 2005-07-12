#!/usr/bin/perl -w

my $sleep_duration = 5;

warn "starting...\n";
warn "sleeping $sleep_duration seconds...\n";

sleep $sleep_duration;

warn "reading stdin...\n";
my $text;
{
	local $/;               # Slurp the whole stdin
		$text = <>;
}
warn "initial stdin:\n$text\n";

warn "removing aeiou from stdin...\n";
$text =~ s/[aeiou]//g;

warn "printing result to stdout\n";

print $text;

warn "done!\n";

exit 0;