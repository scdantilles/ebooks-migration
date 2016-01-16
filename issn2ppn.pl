#!/usr/bin/perl
use v5.22;
use JSON;
use Data::Dumper;
use LWP::Simple;
use XML::Simple;
binmode(STDOUT, ":utf8");

my $json;
{
  local $/;
  open my $fh, "<", "meta.json";
  $json = <$fh>;
  $json eq "" and $json = "[]";
  close $fh;
}
my $meta = JSON->new->utf8->decode($json);
my $num = @$meta;
say "Openned existing meta.json, containing $num entries.";
say "----";

my $i = 0; # loop counter
my $u = 0; # number of updated entries

# loop over meta.json again to find some entries to disable
for my $entry (@$meta) {
	$i++;
	say "TITLE: ", $$entry{title};
	for my $isbn (@{$$entry{isbns}}) {
		say "  ISBN: ", $$isbn{isbn};
		my $result = get("http://www.sudoc.fr/services/isbn2ppn/" . $$isbn{isbn});
		my $xml = XMLin($result, ForceArray => [ 'result' ]);
		$$isbn{ppns} = [];
		for my $ppn (@{$$xml{query}{result}})
		{
			say "    PPN: " . $$ppn{ppn};
			push $$isbn{ppns}, $$ppn{ppn};
		}
	}
	$u++;
}

open my $fh, ">", "meta.json";
print $fh JSON->new->utf8->pretty->encode($meta);
close $fh;

say "----";
say "Looped over $i entries";
say "Updated $u entries";
