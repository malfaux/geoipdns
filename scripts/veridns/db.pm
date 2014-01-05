package veridns::db;
use veridns::ip4;
use Number::Interval;
use veridns::cfg qw(:cf_);
use LWP::Simple;
use Text::CSV_XS;
use Tie::Handle::CSV;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use Storable;
use XML::Simple;
use File::Basename;
use Data::Dumper;

use base qw(Exporter);
our %EXPORT_TAGS = ( 'upd_' => [ qw(ipdb_rebuild_master ipdb_update_master ipdb_update_slaves ipdb_update_user ipdb_get_handle ipdb_compile) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'upd_'} } );

sub ipdb_compile
{
	my ($xml,$ipdb) = @_;
	my $cfg = XMLin($xml,GroupTags=>{exceptions=>'except'},ForceArray=>['exception','mapit','map']);
	#my $cfg = XMLin($xml,GroupTags=>{exceptions=>'exception'},ForceArray=>['exception','mapit','map'],KeyAttr=>{'map'=>'name'});
	print Dumper($cfg);
	die "nodata\n" unless $cfg;
	die "nodb\n" unless $ipdb;
	my $out = delete $cfg->{out};
	print "out $out\n";
	if (!defined $out) {
		my $folder = dirname($xml);
		$out = $folder."/loc.data";
	} else {
		unless ($out=~/^\//) {
			$out = dirname($xml)."/".$out;
			print "dumptoout $out\n";
		}
	}
	my $fh = undef;
	open($fh,">",$out);
	die "nofile\n" unless defined $fh;
	my $username = delete $cfg->{user};
	$username="" unless defined $username and length $username > 0;
	#die "nouser\n" unless defined $username;
	#my @exceptions = @{$cfg->{exceptions}}; #{to=>,from=>} hashrefs
	#my @mapnames = keys %{$cfg->{map}};
	#my @maps = @{$cfg->{'map'}};
	foreach my $map (@{$cfg->{map}}) {
		#print "process $mapname\n";
		#my @mapits = $map->{mapit};
		my $mapname = $map->{mname};
		if ((!defined $mapname) or (length $mapname <= 0)) {
			if ($#{@{$cfg->{map}}} > 0) {
				die "can't use anonymous maps in a multi-map configuration!\n";
			}
			$mapname="";
		}
		#my @maps = @{$cfg->{map}->{$mapname}->{mapit}};
		my $rs = [];
		foreach my $mapit (@{$map->{mapit}}) {
			#my @inputs = split /,/,$map->{from};
			foreach my $input (split /,/,$mapit->{from}) {
				if ($input=~/^\d{1,3}\./) {
					print "map_ip $input to $mapit->{to}\n";
					#push @rs, &ip2db($input);
					my $ipc = &ip2db($input);
					$ipc->{to} = $mapit->{to};
					$ipc->{cc} = $mapname;
					push @{$rs}, $ipc;
					#my $rs = [ $ipc ];
					#foreach my $e (@exceptions) {
					#	$rs = &chk_except_match($rs,$e);
					#}
				} else {
					print "map_country $input to $mapit->{to}\n";
					#@rs = @{$ipdb->{ccmaps}->{$input}};
					my $ips = $ipdb->{$input};
					foreach my $ipc (@{$ips}) {
						$ipc->{to} = $mapit->{to};
						$ipc->{cc} = $mapname;
						#my $iprs = &chk_except_match($ipc,\@exceptions);
						push @{$rs}, $ipc;
					}
				}
			}
		}
		foreach my $e (@{$map->{exceptions}}) {
			print "check exception $e->{from},$e->{to} against mapid $mapname\n";
			my $hash = &ip2db($e->{from});
			$e->{ipstra} = $hash->{ipstra};
			$e->{ipstrb} = $hash->{ipstrb};
			$e->{ipa} = $hash->{ipa};
			$e->{ipb} = $hash->{ipb};
			$rs = &chk_except_match($rs,$e);
			$e->{cc} = $mapname;
			push @{$rs}, $e;
		}
		while ( (my $ipm = pop @{$rs})) {
			my $chunks = ip4_tocidr($ipm->{ipstra}, $ipm->{ipstrb});
			foreach my $chunk (@$chunks) {
				my ($n,$m) = @$chunk;
				print "$ipm->{ipstra} $ipm->{ipstrb} $ipm->{to} ", +(num2ip $n),"/$m\n";
				print $fh "\%$ipm->{to}:",+(num2ip $n),":$m:$ipm->{cc}:$username\n";
				#print +(num2ip $n),":$m\n";
				#print $fh "\%$ipm->{to}:$ipm->{ipstra}:$ipm->{ipstrb}:$ipm->{cc}:$username\n";
			}
		}
	}
	close($fh);
}

sub chk_except_match
{
	my ($targets,$e) = @_;
	my @newtgts = ();
	my $exception = new Number::Interval(Min=>$e->{ipa}, Max=>$e->{ipb});
	while ( (my $t = pop @{$targets})) {
		#print "process $t->{ipa}, $t->{ipb} against $e->{ipa}, $e->{ipb}\n";
	#foreach my $e (@{$ex}) {
		my $target = new Number::Interval(Min=>$t->{ipa}, Max=>$t->{ipb});
		my $status = $target->intersection($exception);
		if (!$status) {
			push @newtgts,$t;
			next;
		}
		#next unless $status;
		print "chk_except_match: {$t->{ipstra}, $t->{ipstrb}}, {$e->{ipstra}, $e->{ipstrb}}\n"; 
		if ($target->min() > $t->{ipa}) {
			my $ipa = $t->{ipa};
			my $ipstra = &ntoa($ipa);
			my $ipb = $target->min()-1;
			my $ipstrb = &ntoa($ipb);
			my $newt = { ipa=>$ipa,ipb=>$ipb,ipstra=>$ipstra,ipstrb=>$ipstrb,to=>$t->{to},cc=>$t->{cc},};
			print "chk_except_match: new_tgt_left: $newt->{ipstra}, $newt->{ipstrb}\n";
			push @newtgts, $newt;
		}
		if ($target->max() < $t->{ipb}) {
			my $ipa = $target->max()+1;
			my $ipb = $t->{ipb};
			my $ipstra = &ntoa($ipa);
			my $ipstrb = &ntoa($ipb);
			my $newt = {ipa=>$ipa,ipb=>$ipb,ipstra=>$ipstra,ipstrb=>$ipstrb,to=>$t->{to},cc=>$t->{cc}};
			print "chk_except_match: new_tgt_right: $newt->{ipstra}, $newt->{ipstrb}\n";
			push @newtgts, $newt;
		}
	}
	return \@newtgts;
}
sub ip2db
{
	my $slash32=4294967295;
	my ($net,$mask) = split /\//,$_[0];
	if (!defined $mask) { $mask = 32; }
	if ($mask > 32 || $mask < 1) { die "badipmask\n"; }
	my @bytes = split /\./,$net;
	my $i = 24;
	my $n = 0;
	foreach (@bytes) {
		if ($_ > 255 || $_ < 0) { die "noip\n"; }
		$n+=$_<<$i;
		$i-=8;
	}
	my $netmask = 0;
	for (my $i = 0; $i < $mask; $i++) {
		$netmask|=1<<(31-$i);
	}
	my $network = $n & $netmask;
	my $hmin = $network;
	my $broadcast = $network | ((~$netmask) & $slash32);
	my $hmax = $broadcast;
	if ($mask == 31) {
		$hmax = $broadcast;
		$hmin = $network;
	}
	if ($mask == 32) {
		$hmax = $hmin = $network;
	}
	my $hash = {
		ipstra=>&ntoa($hmin),
		ipstrb=>&ntoa($hmax),
		ipa=>$hmin,
		ipb=>$hmax,
	};
	return $hash;
	#print Dumper($hash);
	#print "network $network: ".join ".",unpack("CCCC",pack("N",$network)),"\n";
#join ".",unpack("CCCC",pack("N",shift));
	
}
sub ntoa
{
	return join ".",unpack("CCCC",pack("N",shift));
}

sub ipdb_get_handle
{
	return veridns::db::instance->new()->load();
}
#check if we need to download new version of zipped csv ipmap

sub ipdb_rebuild_master
{
	print "REBUILD_MASTER: __start\n";
	unzip $cf_geoip_cc_dumpfile => $cf_geoip_cc_srcfile or die "unzip_error: $UnzipError";
	my $csv_parser = Text::CSV_XS->new();
	my $csvfh = Tie::Handle::CSV->new($cf_geoip_cc_srcfile,header=>0,csv_parser=>$csv_parser);
	die "no csv handler $!\n" unless defined $csvfh;
	my $ipdb = veridns::db::instance->new();
	#@(ipstra ipstrb ipa ipb cc country)
	while (my $csv_entry = <$csvfh>) {
		$ipdb->add_entry(
			$csv_entry->[4],
			{ipstra=>$csv_entry->[0],ipstrb=>$csv_entry->[1],ipa=>$csv_entry->[2],ipb=>$csv_entry->[3],}
		);
	}
	$ipdb->save();
	print "REBUILD_MASTER: __end\n";
	undef $csv_parser;
	close $csvfh;
	return $ipdb;
}

sub ipdb_update_master
{
	my %args = @_;
	my $ipdb = undef;
	my $updated = 0;
	if (defined $args{force_download}) {
		unlink $cf_geoip_cc_dumpfile if -f $cf_geoip_cc_dumpfile;
	}
	my $rc = LWP::Simple::mirror($cf_geoip_cc_dlurl,$cf_geoip_cc_dumpfile);
	if ($rc == RC_OK) {
		print "ipdb: mirroring done\n";
		$updated = 1;
	} elsif ($rc == RC_NOT_MODIFIED) {
		print "ipdb: resource not modified, mirroring skipped\n";
		$ipdb = veridns::db::instance->new()->load();
	} else {
		die "error mirroring ipdb archive (HTTP_CODE=$rc) $cf_geoip_cc_dlurl ==>> $cf_geoip_cc_dumpfile\n";
	}
	if ( ($rc == RC_OK ) || (defined ($args{force_rebuild})) ) { 
		print "rebuilding master db\n";
		$ipdb = &ipdb_rebuild_master();
	}
	#return ($ipdb,$updated);
	return wantarray?($ipdb,$updated):$ipdb;
	#return veridns::db::instance->new()->load();
	#return undef;
	#return veridns::db::instance->new()->load();
}

#check if users modified their geoip maps. if so, rebuild them
#return an array of users that have geoip maps updated
sub ipdb_update_slaves
{
	my %args = @_;
	#my $ipdb = shift;
	my $ipdb = $args{ipdb_handle};
	if (!defined $ipdb) {
		$ipdb = veridns::db::instance->new();
		die "no ipdb handle\n" unless defined $ipdb;
		$ipdb->load();
	}
	my @mods = ();
	opendir(DH,$cf_geoip_dns_userdir) or die "can't open dns userdir: $!\n";
	my @users = grep { !/^\./ && -d $cf_geoip_dns_userdir."/".$_ } readdir(DH);
	closedir(DH);
	if (defined $args{force_update}) {
		print "ipdb_update_user: forced update\n";
		foreach my $u (@users) {
			print "ipdb_update_user($user)\n";
			&ipdb_update_user($u,$ipdb);
			push @mods, $u;
		}
		return wantarray?@mods:\@mods;
	}
	foreach my $user (@users) {
		my $uid = (stat($cf_geoip_dns_userdir."/".$user))[1];
		my $xml = $cf_geoip_dns_userdir."/".$user."/".$cf_geoip_umap_in;
		my $cdb_in = $cf_geoip_dns_userdir."/".$user."/".$cf_geoip_umap_out;
		if ( !-f $xml) {
			unlink "$cdb_in" if -f $cdb_in;
			next;
		}
		my @umapin_stats = stat($xml);
		my @cdbin_stats = stat($cdb_in);
		if ( (!defined $cdbin_stats) || ($umapin_stats[9] < $cdbin_stats[9]) ) {
			print "chk_umap_update: umap_update($xml,$cdb_in,$ipdb)\n";
			#&umap_update($uid,$xml,$cdb_in,$ipdb);
			&ipdb_update_user($user,$ipdb);
			push @mods, $user;
		}
	}
	return wantarray?@mods:\@mods;
}

sub get_countries
{
	my $continent = shift;
	my @countries = ();
	foreach my $cc (keys %{$cf_countries}) {
		if ($cf_countries->{$cc}->{ccode} eq $continent) { push @countries, $cc; }
		return wantarray?@countries:\@countries;
	}
}
#sub 
#dump the ipmaps in tinydns format ready for cdb rebuild
sub ipdb_update_user
{
	my ($user,$ipdb) = @_;
	#my ($uid,$xml,$cdbin,$ipdb) = @_;
	my $uid = (stat($cf_geoip_dns_userdir."/".$user))[1];
	my $xml = $cf_geoip_dns_userdir."/".$user."/".$cf_geoip_umap_in;
	my $cdbin = $cf_geoip_dns_userdir."/".$user."/".$cf_geoip_umap_out;
	my $xml_ref = XMLin($xml,ForceArray=>1);
	my $fh = undef;
	open($fh,">",$cdbin) or die "can't open file for writing ($cdbin): $!\n";
	my $maps = $xml_ref->{ipmap};
	foreach my $map (@{$maps}) {
		if ($map->{maptype} eq "continent") {
			my @continents = split /,/,$map->{from};
			foreach my $c (@continents) {
				my @cc = &get_countries($c);
				while (my $cc1 = pop @cc) { push @countries, $cc1; }
			}
		} else {
			@countries = split /,/,$map->{from};
		}
		foreach my $cc (@countries) {
			my $ips = $ipdb->{ccmaps}->{$cc};
			foreach my $class (@{$ips}) {
				print $fh "\%$map->{to}:$class->{ipstra}:$class->{ipstrb}:$uid\n";
			}
		}
	}
	close($fh);
}

1;


package veridns::db::instance;
use Storable;
use veridns::cfg qw(:cf_);
sub new
{
	my $self = shift;
	my $class = ref $self || $self;
	my $this = {
		ccmaps=>{},
	};
	bless $this,$class;
	return $this;
	return bless $this,$class;
}

sub add_entry
{
	my ($this, $cc, $entry) = @_;
	my $this = shift;
	if (!defined $this->{ccmaps}->{$cc}) { $this->{ccmaps}->{$cc} = []; }
	push @{$this->{ccmaps}->{$cc}}, $entry;
}

sub save
{
	if ( -f $cf_geoip_cc_storable) { unlink $cf_geoip_cc_storable; }
	print "ipdb::save store_to=$cf_geoip_cc_storable\n";
	store ((shift)->{ccmaps},$cf_geoip_cc_storable);
}

sub load
{
	if (!-f $cf_geoip_cc_storable) { return undef; }
	return (shift)->{ccmaps} = retrieve $cf_geoip_cc_storable;
}

sub rem_entry
{

}
1;
