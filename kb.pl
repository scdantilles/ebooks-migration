#!/usr/bin/perl
use v5.22;
use MARC::File::XML(BinaryEncoding => 'utf8', RecordFormat => 'UNIMARC');
use MongoDB;
use Data::Dumper;
binmode(STDOUT, ":utf8");

# Remove dashes from the ISBNs
sub clean_isbn {
	my $isbn = shift;
	$isbn =~ s/\-//g;
	$isbn;
}

my $client     = MongoDB->connect('mongodb://localhost');
my $collection = $client->ns('ebooks.meta');
my $num = $collection->count();
say "Connecting mongodb, containing $num entries.";

my $i = 0; # loop counter
my $c = 0; # number of created entries
my $u = 0; # number of updated entries
my $d = 0; # number of disabled entries
my $t = ""; # target service

my $file = MARC::File::XML->in($ARGV[0]);

# We loop over the records in the MARC file to create or update entries
while (my $r = $file->next())
{
	$i++;
	my $sfxn = $r->field('090') ? $r->field('090')->subfield("a") : undef;

	continue unless defined $sfxn;

	my $new = {};
	$$new{isbns}    = [];
	$$new{active}   = "1";
	$$new{title}    = $r->subfield('245', "a") if ($r->subfield('245', "a"));
	$$new{author}   = $r->subfield('100', "a") if ($r->subfield('100', "a"));
	$$new{pub_date} = $r->subfield('260', "c") if ($r->subfield('260', "c"));
	$$new{sfxn}     = $r->subfield('090', "a") if ($r->subfield('090', "a"));
	$$new{openurl}  = "http://" . $r->subfield('856', "u") if ($r->subfield('856', "u"));
	$$new{target}   = (split(':', $r->subfield('866', "x")))[0] if ($r->subfield('866', "x"));

	$t = $$new{target};

	for ($r->field('020')) {
		push $$new{isbns}, {
			isbn       => clean_isbn($_->subfield("a")),
			primary    => 1,
			electronic => 1,
		};
	}

	my $entry = $collection->find_one({ sfxn => "$sfxn" });
	if ($entry)
	{
		$$new{updated} = time();
		$collection->replace_one({ sfxn => "$sfxn" }, { %$entry, %$new });
		$u++;
	}

	unless ($entry) {
		$$new{created} = time();
		$collection->insert($new);
		$c++;
	}
}
$file->close();

# Loop over the meta collection to find some entries to disable
my $results = $collection->find({ target => "$t" })->result;
while (my $entry = $results->next()) {
	my $found = 0;
	my $file = MARC::File::XML->in($ARGV[0]);
	RECORD: while (my $r = $file->next())
	{
		if ($$entry{sfxn} eq $r->subfield('090', "a"))
		{
			$found = 1;
			last RECORD;
		}
	}
	$file->close();

	unless ($found) {
		$collection->update_one(
			{ sfxn => $$entry{sfxn} },
			{ '$set' => { active => 0 } }
		);
		$d++;
	}
}

say "----";
say "Looped over $i records of target $t";
say "Updated $u entries";
say "Created $c entries";
say "Disabled $d entries";
