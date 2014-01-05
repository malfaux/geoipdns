package sysami::dbh;

BEGIN {
	use lib '/sysami/.bin';
	use lib '/sysami/.lib';
}

my $dbh;
use veridns::cfg qw(:cf_);
#use Data::Dumper;
sub vdb_open { DBI->connect($cf_sql_url,$cf_sql_username,$cf_sql_password,{AutoCommit=>1}) || die $DBI::errstr; }

sub new {
	unless (defined $dbh) {
		$dbh = DBI->connect($cf_sql_url,$cf_sql_username,$cf_sql_password,{AutoCommit=>1}) || die $DBI::errstr;
	}
	die "no database connection" unless $dbh;
	return $dbh;
}

sub close {
	$dbh->disconnect();
	undef $dbh;
}

sub DESTROY {
	&close();
}

1;
