#!/usr/bin/perl
use v5.22;
use MongoDB;
use Data::Dumper;
use LWP::Simple;
use XML::Simple;
binmode(STDOUT, ":utf8");

my $client     = MongoDB->connect('mongodb://localhost');
my $collection = $client->ns('ebooks.meta');
my $num = $collection->count();
say "Connecting mongodb, containing $num entries.";
say "----";

my $i = 0; # loop counter
my $u = 0; # number of updated entries

# loop over the meta collection to add the PPN
my $results = $collection->find()->result;
while (my $entry = $results->next()) {
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
	$collection->replace_one({ sfxn => $$entry{sfxn} }, $entry);
	$u++;
}

say "----";
say "Looped over $i entries";
say "Updated $u entries";
