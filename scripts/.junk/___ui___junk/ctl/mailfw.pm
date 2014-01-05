package veridns::ui::ctl::mailfw;
use base qw/Exporter/;

our @EXPORT = (qw(mailfw_do));

$|=1;
sub mailfw_do
{
	my ($params,$template,$session) = @_;
	my $pipe = undef;
	$buf="committing changes to servers ...\n";
	open($pipe,'/sysami/.bin/zexport|');
	unless ($pipe) {
		$buf=$buf."error reading results!\n";
		exit(0);
	}
	$buf=$buf."reading results, pipe=$pipe...\n";
	while (<$pipe>) {
		$buf = $buf.$_;
	}
	$buf.="OK_DONE\n";
	close($pipe);
	$template->param(export_output=>$buf);
	return $template->output();
}

1;
