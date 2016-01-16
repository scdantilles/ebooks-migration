#!/usr/bin/perl
use v5.22;
use MARC::File::XML(BinaryEncoding => 'utf8', RecordFormat => 'UNIMARC');
use JSON;
use Data::Dumper;
binmode(STDOUT, ":utf8");

# Remove dashes from the ISBNs
sub clean_isbn {
	my $isbn = shift;
	$isbn =~ s/\-//g;
	$isbn;
}

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

my $i = 0; # loop counter
my $c = 0; # number of created entries
my $u = 0; # number of updated entries
my $d = 0; # number of disabled entries

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

	for ($r->field('020')) {
		push $$new{isbns}, {
			isbn       => clean_isbn($_->subfield("a")),
			primary    => 1,
			electronic => 1,
		};
	}

	my $found = 0;
	for my $entry (@$meta) {
		if ($$entry{sfxn} eq $sfxn) {
			$$new{updated} = time();
			$entry = { %$entry, %$new };
			$u++;
			$found = 1;
			last;
		}
	}

	unless ($found) {
		$$new{created} = time();
		push @$meta, $new;
		$c++;
	}
}
$file->close();

# loop over meta.json again to find some entries to disable
for my $entry (@$meta) {
	my $found = 0;
	my $file = MARC::File::XML->in($ARGV[0]);
	while (my $r = $file->next())
	{
		if ($$entry{sfxn} eq $r->subfield('090', "a"))
		{
			$found = 1;
		}
	}
	$file->close();

	unless ($found) {
		$$entry{active} = 0;
		$d++;
	}
}

open my $fh, ">", "meta.json";
print $fh JSON->new->utf8->pretty->encode($meta);
close $fh;

say "----";
say "Looped over $i records";
say "Updated $u entries";
say "Created $c entries";
say "Disabled $d entries";
