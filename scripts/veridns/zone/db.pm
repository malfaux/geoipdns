require Exporter;
package veridns::zone::db; our @ISA=qw(Exporter);
BEGIN {
use File::Basename;
use lib dirname $0;
}
our @EXPORT = (qw(
vdb_open 
add_zone 
add_rrs 
vdb_close 
get_user 
vdb_tr_start 
vdb_tr_cancel 
vdb_tr_end
update_serial
));

$ENV{DNS_ADMIN} = 'admin' unless defined $ENV{DNS_ADMIN};

use DBI;
use veridns::cfg qw(:cf_);
#use Data::Dumper;
sub vdb_open { DBI->connect($cf_sql_url,$cf_sql_username,$cf_sql_password,{AutoCommit=>1}) || die $DBI::errstr; }
#{
#	my $dbh = DBI->connect($cf_sql_url,$cf_sql_username,$cf_sql_password,{AutoCommit=>1});
#	die $dbh->errstr unless defined $dbh;
#	return $dbh;
#}

sub vdb_tr_start 
{ 
	my ($dbh,$lockit) = @_;
	$dbh->begin_work();
	if (defined $lockit) {
		my $sth = $dbh->prepare("lock table lock_q");
		$sth->execute();
		$sth->finish();
	}
}

sub vdb_tr_cancel { $_[0]->rollback; }
sub vdb_tr_end { return $_[0]->commit; }

sub get_user
{
	my %args = @_;
	my $qs = {
		username=>qq(select id,username,password,active,realm,cleartextpass,ip,ctime,key from users where username=?),
	};
	my $dbh = delete $args{dbh};
	my $qp = (keys %args)[0];
	my $qv = $args{$qp};
	#print "$qp $qv\n";
	my $query = $qs->{$qp};
	return undef unless defined $query;
	my $sth = $dbh->prepare($query);
	#local $sth->{TraceLevel}="3|SQL";
	$sth->bind_param(1,$qv);
	#$sth->bind_param(2,$qv);

	$sth->execute;
	my $rs = $sth->fetchrow_hashref;
	$sth->finish;
	#print Dumper($rs);
	$ENV{AUTHENTICATE_UID} = $rs->{id};
	return $rs;
}

sub add_zone
{
	my %args = @_;
	my $uid = $args{uid};
	my $origin = $args{origin};
	my $dbh = $args{dbh};
	my $sth = $dbh->prepare(q(select uid from zones where origin=?));
	$sth->bind_param(1,$origin);
	$sth->execute;
	my $rs = $sth->fetchrow_hashref;
	$sth->finish;
	return undef if defined $rs->{uid};
	$sth = $dbh->prepare(q/insert into zones(origin,uid,utime) values(?,?,?)/);
	#warn "insert $origin for $uid\n";
	$sth->bind_param(1,$origin);
	$sth->bind_param(2,$uid);
	$sth->bind_param(3,time);
	my $rc = $sth->execute;
	$sth->finish;
	return undef unless $rc;
	$sth = $dbh->prepare(q/select id from zones where origin=?/);
	$sth->bind_param(1,$origin);
	$sth->execute;
	my $rs = $sth->fetchrow_arrayref;
	$sth->finish;
	return $rs->[0];
}
sub update_serial
{
	my $qs = {
		id=>'update zones set utime=? where id=?',
	};
	my %args = @_;
	my $dbh = delete $args{dbh};
	my $now = time;
	my $prm_count = keys %args;
	#safe_die(dbh=>$dbh,msg=>'no query matched for zone serial update') unless defined $query;
	#return undef unless defined $query;
	if ($prm_count > 0) {
		my $qp = (keys %args)[0];
		my $qv = $args{$qp};
		#my $query = $qs->{$args{(keys %args)[0]}};
		my $query = $qs->{$qp};
		warn "qp=$qp,qv=$qv,query=$qs->{$qv}";
		my $sth = $dbh->prepare($query);
		$sth->bind_param(1,$now);
		$sth->bind_param(2,$qv);
		#$sth->execute || safe_die(dbh=>$dbh,msg=>'can\'t update serial for zone!'.$DBI::errstr);
		return undef unless $sth->execute();
		$sth->finish;
	}
	my $sth = $dbh->prepare('insert into xprt_waitq(xprt_to,tstamp,xprt_req_by) values(?,?,?)');
	$sth->bind_param(1,'DNS-AUTH');
	$sth->bind_param(2,$now);
	warn "xprt_req_by $ENV{DNS_ADMIN}/$ENV{AUTHENTICATE_UID}\n";
	$sth->bind_param(3,$ENV{AUTHENTICATE_UID});
	return undef unless $sth->execute();
	$sth->finish();
	return 1;
}
sub add_rrs
{
	my %args = @_;
	my $dbh = $args{dbh};
	my $rrs = $args{rrs};
	my $zid = $args{zid};
	my $count = 0;
	my $sth = $dbh->prepare(q/insert into records(zid,loq,loc,mapname,rrtype,name,data,aux,ttl,rid) values(?,?,?,?,?,?,?,?,?,?)/);
	foreach my $rr (@{$rrs}) {
		$sth->bind_param(1,$zid);
		$sth->bind_param(2,$rr->{loq});
		$sth->bind_param(3,$rr->{loc});
		$sth->bind_param(4,$rr->{mid});
		$sth->bind_param(5,$rr->{rrtype});
		#warn "ON_SAVE: rrtype=\'$rr->{rrtype}\'";
		$sth->bind_param(6,$rr->{name});
		$sth->bind_param(7,$rr->{data});
		$sth->bind_param(8,$rr->{aux});
		$sth->bind_param(9,$rr->{ttl});
		$sth->bind_param(10,$rr->{rid});
		#$sth->execute || safe_die(dbh=>$dbh,msg=>$DBI::errstr);
		return undef unless $sth->execute();
		$count++;
	}
	return $count;
}

sub vdb_close
{
	return (shift)->disconnect;
}
1;
