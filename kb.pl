#!/usr/bin/perl
use v5.22;
use MARC::File::XML(BinaryEncoding => 'utf8', RecordFormat => 'UNIMARC');
use JSON;
binmode(STDOUT, ":utf8");

my $json;
{
  local $/;
  open my $fh, "<", "meta.json";
  $json = <$fh>;
  $json eq "" and $json = "[]";
  close $fh;
}
my $meta = decode_json($json);
my $num = @$meta;
say "Openned existing meta.json, containing $num entries.";

my $i = 0; # loop counter
my $c = 0; # number of created entries
my $u = 0; # number of updated entries

my $file = MARC::File::XML->in($ARGV[0]);

# We loop over the records in the MARC file to create or update entries
while (my $r = $file->next())
{
	$i++;
	my $sfxn = $r->field('090') ? $r->field('090')->subfield("a") : undef;

	continue unless defined $sfxn;

	my $new = {
		title    => $r->field('245') ? $r->field('245')->subfield("a") : undef,
		pub_date => $r->field('260') ? $r->field('260')->subfield("c") : undef,
		isbns    => [ {
			isbn => $r->field('020') ? $r->field('020')->subfield("a") : undef,
			primary => 1,
			electronic => 1,
		} ],
		author   => $r->field('100') ? $r->field('100')->subfield("a") : undef,
		sfxn     => $r->field('090') ? $r->field('090')->subfield("a") : undef,
		openurl  => $r->field('856') ? "http://" . $r->field('856')->subfield("u") : undef,
		target   => $r->field('866') ? (split(':', $r->field('866')->subfield("x")))[0] : undef,
	};

	my $found = 0;
	for my $entry (@$meta) {
		if ($$entry{sfxn} eq $sfxn) {
			$$new{updated} = time();
			$entry = $new;
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

# TODO loop over meta.json again to find some entries to disable

open my $fh, ">", "meta.json";
print $fh to_json($meta, {pretty => 1});
close $fh;

say "----";
say "Looped over $i records";
say "Updated $u records";
say "Created $c records";
