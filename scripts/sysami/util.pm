package sysami::util;
sub run_editor
{
    die "no EDITOR defined in environment. please fix" unless defined $ENV{EDITOR};
	my ($file,$cleanup_on_error) = @_;
	my @cmd_args=($ENV{'EDITOR'}, $file);
	my $rc = system(@cmd_args);
	if ($rc == 0) {
		return 1;
	}
	if ($cleanup_on_error) {
		unlink $file;
	}
	return wantarray?():undef;
}
1;
