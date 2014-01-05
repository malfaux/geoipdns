require Exporter;
package veridns::safety; our @ISA=qw(Exporter);

our @EXPORT =(qw(safe_die));
sub safe_die
{
	my %args = @_;
	my $dbh = $args{dbh};
	$dbh->rollback;
	$dbh->disconnect;
	($package, $filename, $line) = caller;
	die $args{msg}.",caller: $package (filename=$filename,line=$line)\n";
}
1;
