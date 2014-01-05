require Exporter;
package veridns::cmdline_args; @ISA=qw(Exporter);

sub getarg
{
	my ($opts,$arg) = @_;
	if (!exists $opts->{$arg}) { return wantarray?():undef }
	if (!defined $opts->{arg}) { return wantarray?(1):1 }
	if (ref $opts->{$arg} and ref $opts->{$arg} eq 'ARRAY') {
		return wantarray?@{$opts->{$arg}}:$opts->{$arg};
	}
	return wantarray?($opts->{$arg}):$opts->{$arg};
}
sub parse_cmdline
{
	my %opts = ();
	for my $p (@_) {
		print "parse $p\n";
		my ($k,$v) = split /=/,$p;
		my @values = (defined $v)?split /,/,$v:();
		if ($#values > 0) {
			$opts{$k} = \@values;
		} else {
			$opts{$k} = $v;
		}
	}
	return \%opts;
}

our @EXPORT = (qw(parse_cmdline getarg));
1;
