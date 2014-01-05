require Exporter;
package veridns::zone; our @ISA=qw(Exporter);
BEGIN {
use File::Basename;
use lib dirname $0;
}
$ENV{DNS_ADMIN} = 'admin' unless defined $ENV{DNS_ADMIN};

our @EXPORT = (qw(z_import z_export2 z_dump z_dump_rrs mark_dirty mark_clean z_delete z_list z_hashdump_rrs z_chkzone z_getid z_type_rmap z_hashdump_rrs_compact));
#use Data::Dumper;
use JSON::XS;
use veridns::cfg qw(:cf_);
use veridns::safety;
use veridns::zone::db;
sub RR_T {0x00}
sub RR_READ { 0x1 }
sub RR_WRITE {0x2}
sub RR_CHK {0x3}

my $now;
my $rid_rmap = { 'SOA'=>'Z','A'=>'+','CNAME'=>'C','MX'=>'@',NS=>'&','PTR'=>'^','TXT'=>'\'', };
sub z_type_rmap { return $rid_rmap->{$_[0]};}
my $rr_handlers = {
	'Z' => ['SOA',\&cdb2soa,\&soa2cdb],
	'+' => ['A',\&cdb2a,\&a2cdb],
	'C' => ['CNAME',\&cdb2cname,\&cname2cdb],
	'@' => ['MX',\&cdb2mx,\&mx2cdb],
	'&' => ['NS',\&cdb2ns,\&ns2cdb],
	'^' => ['PTR',\&cdb2ptr,\&ptr2cdb],
	'\'' => ['TXT',\&cdb2txt,\&txt2cdb],
};



sub check_loq
{
	if (defined $_[1]) {
		$_[0]->{loq} = 1;
		$_[0]->{loc} = $_[1];
		$_[0]->{uid} = $_[3];
		$_[0]->{mid} = $_[2];
	} else {
		$_[0]->{loq} = 0;
	}
}
#Zfqdn:mname:rname:ser:ref:ret:exp:min:ttl:timestamp:lo
sub cdb2soa 
{
	#print "cdb2soa:\n";
	my ($rr,$user,$name,$fields) = @_;
	$rr->{data} = $fields->[0];
	$rr->{aux} = [ $fields->[1] ];
	$rr->{ttl} = $fields->[7];
	&check_loq($rr,$fields->[9],$fields->[10],$fields->[11]);
	return $rr;
}

#Zveridns.com:a.dns-auth.veridns.com.:dns-admin.nox.twinbyte.com.::::::14400::::
sub soa2cdb
{
	my $rr = shift;
	#print STDERR "SOA $rr->{name} SER=$now\n";
	if ($rr->{loq}) {
		#print STDERR 'Z'.$rr->{name}.':'.$rr->{data}.':'.$rr->{aux}->[0].':'.$now.':::::'.$rr->{ttl}.'::'.$rr->{loc}.':'.$rr->{mid}.':'.$rr->{uid}."\n";
		return 'Z'.$rr->{name}.':'.$rr->{data}.':'.$rr->{aux}->[0].':'.$now.':::::'.$rr->{ttl}.'::'.$rr->{loc}.':'.$rr->{mid}.':'.$rr->{uid}."\n";
	}else {
		#print STDERR 'Z'.$rr->{name}.':'.$rr->{data}.':'.$rr->{aux}->[0].':'.$now.':::::'.$rr->{ttl}."\n";
		return 'Z'.$rr->{name}.':'.$rr->{data}.':'.$rr->{aux}->[0].':'.$now.':::::'.$rr->{ttl}."\n";
	}
}

sub cdb2a
{
	my ($rr,$user,$name,$fields) = @_;
	$rr->{data} = $fields->[0];
	$rr->{ttl} = $fields->[1];
	&check_loq($rr,$fields->[3],$fields->[4],$fields->[5]);
	return $rr;
}

sub a2cdb
{
	my $rr = shift;
	if ($rr->{loq}) {
		return '+'.$rr->{name}.':'.$rr->{data}.':'.$rr->{ttl}.'::'.$rr->{loc}.':'.$rr->{mid}.':'.$rr->{uid}."\n";
	} else {
		return '+'.$rr->{name}.':'.$rr->{data}.':'.$rr->{ttl}."\n";
	}
}
sub cdb2cname
{
	my ($rr,$user,$name,$fields) = @_;
	$rr->{data} = $fields->[0];
	$rr->{ttl} = $fields->[1];
	warn "CNAME: check_loq: $fields->[3],$fields->[4],$fields->[5]\n";
	&check_loq($rr,$fields->[3],$fields->[4],$fields->[5]);
	return $rr;
}

sub cname2cdb
{
	my $rr = shift;
	if ($rr->{loq}) {
		return 'C'.$rr->{name}.':'.$rr->{data}.':'.$rr->{ttl}.'::'.$rr->{loc}.':'.$rr->{mid}.':'.$rr->{uid}."\n";
	} else {
		return 'C'.$rr->{name}.':'.$rr->{data}.':'.$rr->{ttl}."\n";
	}
}
#@veridns.com::lo0.no-mx.com.:0:14400
sub cdb2mx
{
	my ($rr,$user,$name,$fields) = @_;
	$rr->{data} = $fields->[1];
	$rr->{aux} = [ $fields->[2] ];
	$rr->{ttl} = $fields->[3];
	&check_loq($rr,$fields->[5],$fields->[6],$fields->[7]);
	return $rr;
}

sub mx2cdb
{
	my $rr = shift;
	if ($rr->{loq}) {
		return '@'.$rr->{name}.'::'.$rr->{data}.':'.$rr->{aux}->[0].':'.$rr->{ttl}.'::'.$rr->{loc}.':'.$rr->{mid}.':'.$rr->{uid}."\n";
	} else {
		return '@'.$rr->{name}.'::'.$rr->{data}.':'.$rr->{aux}->[0].':'.$rr->{ttl}."\n";
	}
}
#&veridns.com::a.dns-auth.veridns.com.:14400
sub cdb2ns
{
	my ($rr,$user,$name,$fields) = @_;
	$rr->{data} = $fields->[1];
	$rr->{ttl} = $fields->[2];
	&check_loq($rr,$fields->[4],$fields->[5],$fields->[6]);
	return $rr;
}

sub ns2cdb
{
	my $rr = shift;
	if ($rr->{loq}) {
		return '&'.$rr->{name}.'::'.$rr->{data}.':'.$rr->{ttl}.'::'.$rr->{loc}.':'.$rr->{mid}.':'.$rr->{uid}."\n";
	} else {
		return '&'.$rr->{name}.'::'.$rr->{data}.':'.$rr->{ttl}."\n";
	}
}
sub cdb2ptr
{
	my ($rr,$user,$name,$fields) = @_;
	$rr->{data} = $fields->[0];
	$rr->{ttl} = $fields->[1];
	&check_loq($rr,$fields->[3],$fields->[4],$fields->[5]);
	return $rr;
}

sub ptr2cdb
{
	my $rr = shift;
	if ($rr->{loq}) {
		return '^'.$rr->{name}.':'.$rr->{data}.':'.$rr->{ttl}.'::'.$rr->{loc}.':'.$rr->{mid}.':'.$rr->{uid}."\n";
	} else {
		return '^'.$rr->{name}.':'.$rr->{data}.':'.$rr->{ttl}."\n";
	}
}
sub cdb2txt
{
	my ($rr,$user,$name,$fields) = @_;
	$rr->{data} = $fields->[0];
	$rr->{ttl} = $fields->[1];
	&check_loq($rr,$fields->[3],$fields->[4],$fields->[5]);
	return $rr;
}

sub txt2cdb
{
	my $rr = shift;
	if ($rr->{loq}) {
		return '\''.$rr->{name}.':'.$rr->{data}.':'.$rr->{ttl}.'::'.$rr->{loc}.':'.$rr->{mid}.':'.$rr->{uid}."\n";
	} else {
		return '\''.$rr->{name}.':'.$rr->{data}.':'.$rr->{ttl}."\n";
	}
}
sub z_dump
{
	local $|=1;
	my ($dbh,$datafile) = @_;
	my $fh = undef;
	my $sth = $dbh->prepare(q/select username from users where active=1/);
	$sth->execute;
	my @users = ();
	while (my $rs = $sth->fetchrow_hashref) {
		push @users, $rs->{username};
	}
	$sth->finish;
	open($fh,">$datafile") or die $!.": $datafile";
	foreach my $folder (@users) {
		if ( -f "$cf_userdir/$folder/loc.data") {
			print "sync $cf_userdir/$folder/loc.data";
			my $loch = undef;
			open ($loch,'<',"$cf_userdir/$folder/loc.data") or die $!;
			while (<$loch>) {
				print $fh $_;
			}
			close $loch;
		}
	}
	$q = q/select r.rid as rrtype,r.name,r.data,r.aux,r.ttl,r.loc,r.loq,r.mapname as mid,u.username as uid from records r,users u,zones z where z.id=r.zid and z.uid=u.id and u.active=1/;
	$sth = $dbh->prepare($q);
	$sth->execute || die $DBI::errstr;
	while (my $rr = $sth->fetchrow_hashref) {
		my $buf = $rr_handlers->{$rr->{rrtype}}->[RR_WRITE]($rr);
		print $fh $buf;
	}
	$sth->finish;
	close $fh;

}

sub mark_dirty
{
	my ($user, $dbh) = @_;
	my $sth = $dbh->prepare(q/update users set dirty=dirty+1 where username=?/);
	$sth->bind_param(1,$user);
	my $rc = $sth->execute();
	$sth->finish;
	return undef unless defined $rc;
}
sub mark_clean
{
	my ($user, $dbh) = @_;
	my $sth = $dbh->prepare(q/update users set dirty=0 where username=?/);
	$sth->bind_param(1,$user);
	my $rc = $sth->execute();
	$sth->finish;
	return undef unless defined $rc;

}
sub z_delete
{
	my ($zone,$user,$dbh) = @_;
	my $q = q/select zones.id from zones,users where users.username=? and users.id=zones.uid and zones.origin=?/;
	my $sth = $dbh->prepare($q);
	$sth->bind_param(1,$user);
	$sth->bind_param(2,$zone);
	$sth->execute;
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return undef unless defined $row and defined $row->{id};
	$q = q/delete from records where zid=?/;
	$sth= $dbh->prepare($q);
	$sth->bind_param(1,$row->{id});
	my $rc = $sth->execute();
	$sth->finish();
	return undef unless $rc;
	$q = q/delete from zones where id=?/;
	$sth = $dbh->prepare($q);
	$sth->bind_param(1, $row->{id});
	$rc = $sth->execute();
	$sth->finish;
	return undef unless $rc;
	return $row->{id};
}

sub z_dump_rrs
{
	my $zone = shift;
	return undef unless $zone;
	my $buf = undef;
	my $dbh = vdb_open();
	die "no dbh\n" unless defined $dbh;
  my $q = q/select r.rid as rrtype,r.name,r.data,r.aux,r.ttl,r.loc,r.loq,r.mapname as mid,u.username as uid from records r,users u,zones z where u.username=? and u.id=z.uid and z.origin=? and z.id=r.zid and u.active=1/;
	my $sth = $dbh->prepare($q);
	$sth->bind_param(1,$ENV{'DNS_ADMIN'});
	$sth->bind_param(2,$zone);
	$sth->execute();
	while (my $rr = $sth->fetchrow_hashref) {
		$buf .= $rr_handlers->{$rr->{rrtype}}->[RR_WRITE]($rr);
	}
	$sth->finish();
	$dbh->disconnect();
	return $buf;
}
sub z_list
{
	my $pattern = $_[0];
	$dbh = vdb_open();
	my $sth = $dbh->prepare('select origin from zones where origin like \'%'.$pattern.'%\'');
	$sth->execute;
	my @res = ();
	while (my $row = $sth->fetchrow_arrayref) {
		push @res, $row->[0];
	}
	#warn "NUM ROWS AGAIN " . scalar @$rows;
	$sth->finish();
	$dbh->disconnect();
	#if scalar @$rows == -1: return wantarray?():undef;
	return \@res;
}
	
sub z_getid
{
	my ($zone,$dbh) = @_;
	my $close_on_return = 0;
	if (!defined $dbh) {
		$dbh = vdb_open();
		return undef unless $dbh;
		$close_on_return = 1;
	}
	
	my $q = "select zones.id from zones,users where users.username=\'".$ENV{DNS_ADMIN}."\' and users.id=zones.uid and zones.origin=\'$zone\'";
	my $sth = $dbh->prepare($q);
	$sth->execute();
	my $zone = $sth->fetchrow_hashref();
	$sth->finish();
	$dbh->disconnect() if $close_on_return == 1;
	if (defined $zone) { return $zone->{id}; }
	return wantarray? () : undef;
	#return undef unless $zone;
	#return $zone->{id};
}
sub z_chkzone
{
	my $zone = shift;
	my $dbh = vdb_open();
	my $q = "select origin from zones,users where users.username=\'".$ENV{DNS_ADMIN}."\' and users.id=zones.uid";
	if (defined $zone and length($zone) > 0) {
		$q = $q." and zones.origin like \'%$zone%\'";
	} 
	my $sth = $dbh->prepare($q);
	#$sth->bind_param(1,$ENV{'DNS_ADMIN'});
	$sth->execute();
	my @rs = ();
	while (my $rr = $sth->fetchrow_hashref) {
		push @rs, $rr;
		warn "fetchrow: $rr->{origin}";
	}
	$sth->finish();
	$dbh->disconnect();
	return \@rs;
	
}
#<rr type="A" rrname="$DN$" data="202.83.164.51" mapname="ntc-maps" loc="pakistan"/>
#sub z_jsondump_rrs
#{
#	my $records = z_hashdump_rrs($_[0]);
#	my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
#	return $coder->encode($records);
#}
sub z_hashdump_rrs_compact
{
	my $zone = shift;
	my $dbh = vdb_open();
  my $q = q/select r.id as rrid,r.rrtype as type,r.name as rrname,r.data,r.aux,r.ttl as rrttl,r.loc,r.mapname as mapname from records r,users u,zones z where u.username=? and u.id=z.uid and z.origin=? and z.id=r.zid and u.active=1/;
	my $sth = $dbh->prepare($q);
	$sth->bind_param(1,$ENV{'DNS_ADMIN'});
	$sth->bind_param(2,$zone);
	$sth->execute();
	my %rs = ();
	while (my $rr = $sth->fetchrow_hashref) {
		my $rrname = $rr->{rrname};
		$rrname=~s/\.?$zone\.?$//;
		if (length($rrname) == 0) { $rrname = '.';}
		warn "RRNAME $rrname";
		$rs{$rr->{type}}{$rrname}{rttable} = $rr->{mapname};
		$rs{$rr->{type}}{$rrname}{payload} = () unless exists($rs{$rr->{type}}{$rrname}{payload});
		push @{$rs{$rr->{type}}{$rrname}{payload}}, [$rr->{loc},$rr->{data},$rr->{rrttl},$rr->{aux}[0]];
	}
	#if ($#rs < 0 ) { return wantarray?():undef;}
	return \%rs;
}

sub z_hashdump_rrs
{
	my $zone = shift;
	my $dbh = vdb_open();
  my $q = q/select r.id as rrid,r.rrtype as type,r.name as rrname,r.data,r.aux,r.ttl as rrttl,r.loc,r.mapname as mapname from records r,users u,zones z where u.username=? and u.id=z.uid and z.origin=? and z.id=r.zid and u.active=1/;
	my $sth = $dbh->prepare($q);
	$sth->bind_param(1,$ENV{'DNS_ADMIN'});
	$sth->bind_param(2,$zone);
	$sth->execute();
	my @rs = ();
	while (my $rr = $sth->fetchrow_hashref) {
		push @rs, $rr;
	}
	#warn "PUSH $#rs rrs";
	if ($#rs < 0 ) { return wantarray?():undef;}
	return \@rs;
}
sub z_export2
{
	local $|=1;
	my $lfh = undef;
	open ($lfh, '>', "/sysami/.data/local.data") or die "can't open local data\n";
	$now = time;
	my ($dbh) = @_;
	my $q = q/select * from servers s, servermap m, users u where u.username=? and u.id=m.uid and s.id=m.sid and s.enabled=1/;
	my $sth = $dbh->prepare($q);
	$sth->bind_param(1,$ENV{'DNS_ADMIN'});
	$sth->execute;
	my @pipes = ();
	my @servers = ();
	while (my $rs = $sth->fetchrow_hashref) {
		my $pipe = undef;
		open ($pipe,"|/var/service/vdns/bin/updateremote $rs->{ipv4addr}") or die "can't open pipe to $rs->{ipv4addr}: $!\n";	
		#push @pipes,$pipe;
		push @pipes, {'pipe'=>$pipe,'srv'=>$rs->{ipv4addr}};
		push @servers, $rs->{ipv4addr};
	}
	$sth->finish();
	if (-f "$cf_userdir/$ENV{DNS_ADMIN}/loc.data") {
		print "EXPORT loc.data : $cf_userdir/$ENV{DNS_ADMIN}/loc.data\n";
		my $fh = undef;
		open ($fh, "<", "$cf_userdir/$ENV{DNS_ADMIN}/loc.data") or die "can't open loc.data file for user $ENV{DNS_ADMIN}\n";
		while (<$fh>) {
			foreach my $pipe (@pipes) {
				my $pfh = $pipe->{'pipe'};
				print $pfh $_ || die "error writing loc.data to pipe $pipe->{srv}\n";
			}
			print $lfh $_;
		}
		close($fh);
	} else {
		print "EXPORT loc.data: $cf_userdir/$ENV{DNS_ADMIN}/loc.data NOT_FOUND\n";
	}
	$q = q/select r.rid as rrtype,r.name,r.data,r.aux,r.ttl,r.loc,r.loq,r.mapname as mid,u.username as uid from records r,users u,zones z where u.username=? and z.uid=u.id and z.id=r.zid and u.active=1/;
	$sth = $dbh->prepare($q);
	$sth->bind_param(1,$ENV{'DNS_ADMIN'});
	$sth->execute || die $DBI::errstr;
	while (my $rr = $sth->fetchrow_hashref) {
		my $buf = $rr_handlers->{$rr->{rrtype}}->[RR_WRITE]($rr);
		foreach my $pipe (@pipes) { 
			my $pfh = $pipe->{'pipe'}; 
			print $pfh $buf || die "can't write to pipe $pipe->{srv} !\n"; 
		}
		print $lfh $buf;
	}
	$sth->finish;
	foreach my $p (@pipes) { 
		my $pfh = $p->{'pipe'};
		my $answer = <$pfh>;
		#my $answer = <$p->{'pipe'}>;
		$answer=~s/[\r\n]*//mg;
		#chomp $answer;
		#die "error: $answer" unless $answer=~/^200/;
		print "$p->{srv} : $answer\n";
		#close $p->{'pipe'} ; 
		close $pfh;
	}
	foreach my $server (@servers) {
		my $pipe = undef;
		open ($pipe,"/var/service/vdns/bin/commitall $server|") or die "can't open pipe to $server: $!\n";	
		my $answer = <$pipe>;
		chomp $answer;
		print "$server : $answer\n";
	}
	close $lfh;
}
sub z_export___DONT_USE___
{
	local $|=1;
	$now = time;
	my ($dbh) = @_;
	my $lpipe = undef;
	my $fh = undef;
	#my $q = q/select * from servers where active=1/;
	my $q = q/select * from servers s, servermap m, users u where u.username=? and u.id=m.uid and s.id=m.sid/;
	my $sth = $dbh->prepare($q);
	$sth->bind_param(1,$ENV{'DNS_ADMIN'});
	$sth->execute;
	my @pipes = ();
	my @servers = ();
	while (my $rs = $sth->fetchrow_hashref) {
		my $pipe = undef;
		open ($pipe,"|/var/service/vdns/bin/updateremote $rs->{ipv4addr}") or die "can't open pipe to $rs->{ipv4addr}: $!\n";	
		push @pipes,$pipe;
		push @servers, $rs->{ipv4addr};
	}
	$sth->finish;
	my $sth = $dbh->prepare(q/select username from users where active=1/);
	$sth->execute;
	my @users = ();
	while (my $rs = $sth->fetchrow_hashref) {
		push @users, $rs->{username};
	}
	$sth->finish;
	open($lpipe,'|/var/service/vdns/bin/vdnsdb /var/service/vdns/tmp/data.tmp /var/service/vdns/tmp/data.cdb') or die $!;
	#push @pipes, $pipe;
	open($fh,">$cf_geoip_dns_root/data") or die $!.": $cf_geoip_dns_root/data";
	#push @pipes,$fh;
	#opendir(DH,$cf_userdir) or die $!;
	#my @folders = grep { !/^\./ && -d $cf_userdir."/".$_ } readdir(DH);
	#closedir(DH);
	foreach my $folder (@users) {
		if ( -f "$cf_userdir/$folder/loc.data") {
			print "sync $cf_userdir/$folder/loc.data";
			my $loch = undef;
			open ($loch,'<',"$cf_userdir/$folder/loc.data") or die $!;
			while (<$loch>) {
				foreach my $pipe (@pipes) {
					print $pipe $_ || die "error writing to pipe!\n";
				}
				print $fh $_;
				print $lpipe $_ || die "error writing to local pipe!\n";
				#print $pipe $_;
				#print $fh $_;
			}
			close $loch;
		}
	}
	$q = q/select r.rid as rrtype,r.name,r.data,r.aux,r.ttl,r.loc,r.loq,r.mapname as mid,u.username as uid from records r,users u,zones z where z.id=r.zid and z.uid=u.id and u.active=1/;
	$sth = $dbh->prepare($q);
	$sth->execute || die $DBI::errstr;
	while (my $rr = $sth->fetchrow_hashref) {
		my $buf = $rr_handlers->{$rr->{rrtype}}->[RR_WRITE]($rr);
		foreach my $pipe (@pipes) { print $pipe $buf; }
		print $fh $buf;
		print $lpipe $buf;
	}
	$sth->finish;
	foreach my $p (@pipes) { 
		my $answer = <$pipe>;
		#die "error: $answer" unless $answer=~/^200/;
		print "PREPARE: $answer\n";
		close $p ; 
	}
	foreach my $server (@servers) {
		my $pipe = undef;
		open ($pipe,"/var/service/vdns/bin/commitall $server|") or die "can't open pipe to $server: $!\n";	
		my $answer = <$pipe>;
		chomp $answer;
		print "$server : $answer\n";
	}
	close $lpipe;
	close $fh;
	print "commit_local:\n";
	rename "/var/service/vdns/tmp/data.cdb", "/var/service/vdns/root/data.cdb" or die "can't commit local: $!\n";
}

sub z_import
{
	my ($zone,$user,$file,$dbh) = @_;
	my @rrs = ();
	my $fh = undef;
	open($fh,'<',$file) or die "$!\n";
	#vdb_tr_start($dbh) || die "can't start transaction:$DBI::errstr\n";
	my $zid = add_zone(dbh=>$dbh,uid=>$user->{id},origin=>$zone);
	safe_die(dbh=>$dbh,msg=>"zone: $zone.$DBI::errstr") unless defined $zid and $zid > 0;
	while (<$fh>) {
		chomp;
		my ($id,@fields) = split /:/;
		my ($rr_type,$origin) = ($id=~/(.)(.*)/);
		unless (defined $rr_handlers->{$rr_type}) {
			#warn "no handler for line $_\n";
			next;
		}
		my $rr = {
			id=>undef,
			zid=>undef,
			rid=>$rr_type,
			rrtype=>$rr_handlers->{$rr_type}->[RR_T],
			name=>$origin,
			data=>undef,
			aux=>[],
			ttl=>undef,
			loq=>0,
			loc=>undef,
			mid=>undef,
			uid=>undef,
		};
		$rr_handlers->{$rr_type}->[RR_READ]($rr,$user,$origin,\@fields);
		#print Dumper($rr);
		push @rrs,$rr;
	}
	my $rc = add_rrs(dbh=>$dbh,zid=>$zid,rrs=>\@rrs);
	safe_die(dbh=>$dbh,msg=>"error adding records to zone $origin") unless $rc == $#rrs+1;
	update_serial(dbh=>$dbh,id=>$zid);
	#vdb_tr_end($dbh);
}
1;
