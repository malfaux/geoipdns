require Exporter;
package veridns::ui::ctl::domain; our @ISA=qw(Exporter);
our @EXPORT=(qw(dom_view dom_edit));

BEGIN {
	use lib '/sysami/.lib';
}
#use sysami::dbh;
use veridns::zone;
use XML::Simple;
use veridns::cfg qw(:cf_);
use veridns::zone::template;
use veridns::zone::db;
use Data::Validate::Domain;
use Data::Validate::IP qw(is_ipv4);
use Data::Dumper;
use JSON;
use POSIX qw(isalnum);
#use Clone qw(clone);

sub dom_view
{
  my ($params,$template,$session) = @_;
	my $template_list = veridns::zone::template->list();
	$template->param(template_list=>$template_list);
	my @mapnames = ();
	my $ipmaps_cfg = XMLin($cf_userdir."/".$ENV{'DNS_ADMIN'}."/ipmaps.xml",
		GroupTags=>{exceptions=>'except'},ForceArray=>['exception','mapit','map'])->{'map'};
	foreach my $gmap (@{$ipmaps_cfg}) {
		my @gmap_names = ();
		my %seen = ();
		foreach my $rule (@{$gmap->{'exceptions'}},@{$gmap->{'mapit'}}) {
			push @gmap_names, $rule->{'to'} unless $seen{$rule->{'to'}};
			$seen{$rule->{'to'}}++;
		}
		push @gmap_names,'nomatch';
		push @mapnames, {mapname=>$gmap->{mname},maplist=>\@gmap_names};
	}
	push @mapnames,{mapname=>'none',maplist=>['none']};
	my $json_dump = JSON->new->utf8(1)->pretty(1)->encode(\@mapnames);
	#my $json_dump = JSON->new->encode(\@mapnames);
	$template->param(json_geoip_maps=>$json_dump);
	
	#my $c_mapnames = clone(\@mapnames);
	#push @$c_mapnames,{'mapname'=>'none'};
	#foreach my $x (@$c_mapnames) { 
	#	delete $x->{'maplist'} if (exists($x->{'maplist'})); 
	#	$x->{map_selected} = '';
	#}
	my $op = $params->{'r'};
	my $dn = $params->{'dn'};
	if (length $dn <= 0) { 
		$dn = undef; 
	} else {
		$template->param(dn=>$dn);
	}
	my $dntmpl = $params->{'template'};
	if (defined $op and !defined $dn) {
		$template->param(have_errors=>1);
		$template->param(errors=>[{emsg=>'you must specify a domain name'},]);
		return $template->output();
	}
	if ($dn and !is_domain($dn,
		{
			domain_allow_underscore=>1,
			domain_private_tld=>qr /^(?:org\.pk|gov\.pk|net\.pk|com\.pk|com\.au|co\.uk)$/,
		})
	) {
		$template->param(have_errors=>1);
		$template->param(errors=>[{emsg=>"invalid domain name: $dn"},]);
		return $template->output();
	}
	if ($op eq 'l') {
		my $rrs = z_hashdump_rrs($dn);
		if (!defined $rrs) {
			$template->param(have_errors=>1);
			$template->param(errors=>[{emsg=>"domain $dn not found. you may add it by selecting 'new domain from template'"},]);
			return $template->output();
		}
		$template->param(have_data=>1);
		$template->param(existent_dn=>1);
		my $next_id = 0;
		foreach my $rr (@$rrs) {
			if ($rr->{rrid} > $next_id) { $next_id = $rr->{rrid}; }
			$rr->{aux} = join(',',@{$rr->{aux}});
		}
		my $json_rr_dump = JSON->new->encode($rrs);
		my $json_rr_summon = JSON->new->decode($json_rr_dump);
		$template->param(json_dns_zone=>$json_rr_dump);
		$template->param(rrs=>$rrs);
		$template->param(rr_last_id=>$next_id);
		return $template->output();
	} elsif ($op eq 'd') {
		my $dbh = vdb_open();
		vdb_tr_start($dbh,1);
		my $zid = z_getid($dn,$dbh);
		$|=1;
		if (defined $zid) {
			my $rc = z_delete($dn,$ENV{DNS_ADMIN},$dbh);
			if (defined $rc) {
				update_serial(dbh=>$dbh);
				vdb_tr_end($dbh);
				vdb_close($dbh);
				$template->param(infos=>[{imsg=>"domain $dn deleted OK (____dbg: zone id = $zid)",}]);
				return $template->output();
			}
		}
		&on_zadd_error($template,$dbh,$dn);
		return $template->output();
	} elsif ($op eq 'n') {
		my $p_dn_template = $params->{'template'};
		if (!defined $p_dn_template or length $p_dn_template <= 0) {
			$template->param(have_errors=>1);
			$template->param(errors=>[{emsg=>"you requested 'new domain from template' but no template was selected"},]);
			return $template->output();
		}
		my $dn_template_ar = veridns::zone::template->load($p_dn_template);
		if (!defined $dn_template_ar or $#{$dn_template_ar} != 0 or !defined $dn_template_ar->[0]) {
			$template->param(have_errors=>1);
			$template->param(errors=>[{emsg=>"can't lookup template $p_dn_template!"},]);
			return $template->output();
		}
		my $dn_template = $dn_template_ar->[0];
		my $next_id = time;
		#warn "mapnames: ".Dumper($c_mapnames)."\n";
		#my $dnbkp = clone $dn_template->{rr};
		foreach my $rr (@{$dn_template->{rr}}) {
			#if (!defined $rr->{mapname}) { $rr->{mapname} = 'none'; $rr->{loc} = 'none';}
			#my $local_mapnames = clone $c_mapnames;
			$rr->{rrid} = ++$next_id;
			#$rr->{'rrtype_'.uc $rr->{type}} = 1;
			#foreach (@$local_mapnames) {
			#	if ($_->{mapname} eq $rr->{mapname}) {
			#		$_->{map_selected} = 'selected';
			#	}
			#}
			#warn Dumper($local_mapnames);
			#$rr->{mapnames} = $local_mapnames;
			foreach my $key (keys %$rr) {
				$rr->{$key}=~s/\$DN\$/$dn/g;
			}
		}
		$template->param(rr_last_id=>$next_id);
		$template->param(have_data=>1);
		#my $json_rr_dump = JSON->new->utf8(1)->pretty(1)->encode($dn_template->{rr});
		my $json_rr_dump = JSON->new->encode($dn_template->{rr});
		$template->param(json_dns_zone=>$json_rr_dump);
		$template->param(rrs=>$dn_template->{rr});
		return $template->output();
	} elsif ($op eq 's') {
		my $fh = undef;
		#open($fh,">",'/sysami/.tmp/json_dump.txt');
		my $rrs_raw = JSON->new->utf8(1)->decode($params->{'zdata'});
		#print $fh Dumper($rrs);
		#close($fh);
		my $rrs = &zone_ok($template,\@mapnames,$params->{'dn'},$rrs_raw);
		unless ($rrs) {
			my $next_id = 0;
			$template->param(have_data=>1);
			$template->param(rrs=>$rrs_raw);
			$template->param(json_dns_zone=>$params->{'zdata'});
			foreach my $rr (@$rrs_raw) {
				$next_id = $rrs_raw->{rrid} if $rrs_raw->{rrid} > $next_id;
			}
			$next_id+=1;
			$template->param(rr_last_id=>$next_id);
			return $template->output();
		}
		#my $zid = $rrs->[0]->{zid};
		my $dbh = vdb_open();
		vdb_tr_start($dbh,1);
		my $zid = z_getid($dn,$dbh);
		$|=1;
		if (defined $zid) {
			#delete the zone first
			my $rc = z_delete($dn,$ENV{DNS_ADMIN},$dbh);
			if (!defined $rc) {
				my $next_id = 0;
				$template->param(have_data=>1);
				$template->param(rrs=>$rrs_raw);
				$template->param(json_dns_zone=>$params->{'zdata'});
				foreach my $rr (@$rrs_raw) {
					$next_id = $rrs_raw->{rrid} if $rrs_raw->{rrid} > $next_id;
	      }
				$next_id+=1;
				$template->param(rr_last_id=>$next_id);
				&on_zadd_error($template,$dbh,$dn);
				return $template->output();
			}
		}
		my $new_zid = add_zone(uid=>$ENV{AUTHENTICATE_UID},origin=>$dn,dbh=>$dbh);
		if (!defined $new_zid) {
				my $next_id = 0;
				$template->param(have_data=>1);
				$template->param(rrs=>$rrs_raw);
				$template->param(json_dns_zone=>$params->{'zdata'});
				foreach my $rr (@$rrs_raw) {
					$next_id = $rrs_raw->{rrid} if $rrs_raw->{rrid} > $next_id;
	      }
				$next_id+=1;
				$template->param(rr_last_id=>$next_id);
			&on_zadd_error($template,$dbh,$dn);
			return $template->output();
		}
		#warn "ADDDDDDDDDDDDDDDDDD RRS";
		my $rr_count = add_rrs(dbh=>$dbh,rrs=>$rrs,zid=>$new_zid);
		if (!defined $rr_count) {
				my $next_id = 0;
				$template->param(have_data=>1);
				$template->param(rrs=>$rrs_raw);
				$template->param(json_dns_zone=>$params->{'zdata'});
				foreach my $rr (@$rrs_raw) {
					$next_id = $rrs_raw->{rrid} if $rrs_raw->{rrid} > $next_id;
	      }
				$next_id+=1;
				$template->param(rr_last_id=>$next_id);
			&on_zadd_error($template,$dbh,$dn);
			return $template->output();
		}
		#warn "FINALIZED!!!!!!!!!!!!!!!";
		update_serial(dbh=>$dbh,id=>$new_zid);
		vdb_tr_end($dbh);
		vdb_close($dbh);
		$template->param(infos=>[{imsg=>"domain $dn saved OK (____dbg: zone id = $new_zid, rr_count=$rr_count)",}]);
		return $template->output();
	}
  return $template->output;
}

sub on_zdel_error
{
	my ($template,$dbh,$dn) = @_;
	$template->param(have_errors=>1);
	$template->param(errors=>[{emsg=>"error deleting zone $dn"}]);
	vdb_tr_cancel($dbh);
	vdb_close($dbh); 
	
}
sub on_zadd_error
{
	my ($template,$dbh,$dn) = @_;
	$template->param(have_errors=>1);
	$template->param(errors=>[{emsg=>"error adding zone $dn"}]);
	vdb_tr_cancel($dbh);
	vdb_close($dbh); 
}
sub dom_edit
{
  my ($params,$template,$session) = @_;
  return $template->output;

}
sub mark_error
{
	my ($rr,$errors,$msg) = @_;
	my $rr_str = "rrid=".$rr->{rrid};
	for my $key (qw(rrname type data rrttl aux mapname loc)) {
		$rr_str = $rr_str.";$key=".$rr->{$key};
	}
	push @$errors,{emsg=>$msg." for RR: ".$rr_str}; 
}

sub zone_ok
{
	my %rr_types = ('A'=>1,'SOA'=>1,'NS'=>1,'MX'=>1,'CNAME'=>1);
	my ($template,$geomaps,$dn,$rrs_in) = @_;
	my $zid = z_getid($dn);
	my @rrs = ();
	my @errors = ();
	my %georecords = ();
	$|=1;
	#warn "domain: $dn";
	foreach my $rr_in (@$rrs_in) {
		#warn "check rr $rr_in->{rrname}";
		#warn "RRTYPE \'$rr_in->{type}\' defined: $rr_types{$rr_in->{type}}";
		if ( (!defined $rr_in->{type}) or (!defined $rr_types{$rr_in->{type}}) ) {
			&mark_error($rr_in,\@errors,'unknown record type ');
		}
		if (!defined $rr_in->{rrname}) {
			&mark_error($rr_in,\@errors,'no RR name given!');
		} else {
			my $check_name = is_domain($rr_in->{rrname},
				{
					domain_allow_underscore=>1,
					domain_private_tld=>qr /^(?:org\.pk|gov\.pk|net\.pk|com\.pk|com\.au|co\.uk)$/,
				}
			);
			unless ($check_name) {
				&mark_error($rr_in,\@errors,'bad RR name: non-RFC conformant name!');
			}
			unless ($rr_in->{rrname}=~/$dn(?:\.){0,1}$/) {
				&mark_error($rr_in,\@errors,"bad RR name: rr name out of $dn namespace definition!");
			}
		}
		if (!defined $rr_in->{data}) {
			&mark_error($rr_in,\@errors,'no RR data defined!');
		}
		if (!defined $rr_in->{rrttl} or !POSIX::isalnum($rr_in->{rrttl}) or $rr_in->{rrttl} < 60 ) {
			&mark_error($rr_in,\@errors,'bad TTL name');
		}
		if ($rr_in->{type} eq 'MX') {
			if (!defined $rr_in->{aux} or !POSIX::isalnum($rr_in->{aux})) {
				&mark_error($rr_in,\@errors,'bad MX priority (aux)');
			}
			my $mxname = $rr_in->{data};
			if (not (defined $mxname and $mxname=~/\.$/)) {
				&mark_error($rr_in,\@errors,'bad MX name, doesn\'t end with a .');
			} else {
				$mxname=~s/\.$//;
				my $check_mx_name = is_domain($mxname,
					{
						domain_allow_underscore=>1,
						domain_private_tld=>qr /^(?:org\.pk|gov\.pk|net\.pk|com\.pk|com\.au|co\.uk)$/,
					}
				);
				unless ($check_mx_name) {
					&mark_error($rr_in,\@errors,'bad MX data: not a hostname');
				}
			}
		}
		if ((defined $rr_in->{type} and $rr_in->{type} eq 'A') and defined $rr_in->{data} and !is_ipv4($rr_in->{data})) {
			&mark_error($rr_in,\@errors,'bad ipv4 address');
		}
		if (defined $rr_in->{type} and $rr_in->{type} eq 'NS') {
			if (defined $rr->{data}) {
				my $check_ns_name = is_domain($rr_in->{data},
				{
					domain_allow_underscore=>1,
					domain_private_tld=>qr /^(?:org\.pk|gov\.pk|net\.pk|com\.pk|com\.au|co\.uk)$/,
				});
				unless ($check_ns_name) {
					&mark_error($rr_in,\@errors,'bad nameserver definition');
				}
			}
		}
		if (defined $rr_in->{type} and $rr_in->{type} eq 'CNAME' and defined $rr_in->{data}) {
			my $cname_data = $rr_in->{data};
			unless ($cname_data=~/\.$/) {
				&mark_error($rr_in,\@errors,'bad CNAME data: doesn\'t end with a .');
			}
			$cname_data=~s/\.$//;
			my $check_cname= is_domain($cname_data,
			{
				domain_allow_underscore=>1,
				domain_private_tld=>qr /^(?:org\.pk|gov\.pk|net\.pk|com\.pk|com\.au|co\.uk)$/,
			});
			unless ($check_cname) {
				&mark_error($rr_in,\@errors,'bad CNAME data: invalid hostname');
			}
		}
		if (defined $rr_in->{type} and $rr_in->{type} eq 'SOA') {
			if (!defined $rr_in->{aux}) {
				&mark_error($rr_in,\@errors,'bad contact e-mail for SOA record: contact not defined');
			}
			my $aux_ = $rr_in->{aux};
			unless ($aux_=~/\.$/) {
				&mark_error($rr_in,\@errors,'bad contact e-mail for SOA record: no . at the end');
			}
			$aux_=~s/\.$//;
			my $check_aux_valid = is_domain($aux_,
			{
				domain_allow_underscore=>1,
				domain_private_tld=>qr /^(?:org\.pk|gov\.pk|net\.pk|com\.pk|com\.au|co\.uk)$/,
			});
			unless ($check_aux_valid) {
				&mark_error($rr_in,\@errors,'bad contact e-mail for SOA record: invalid hostname');
			}
		}
		if (defined $rr_in->{mapname}) {
			if (!defined $rr_in->{loc}) {
				&mark_error($rr_in,\@errors,'map specified without a filter definition');
			}
			my $ok_for_now = 0;
			foreach my $map (@$geomaps) {
				if ($rr_in->{mapname} eq $map->{mapname}) {
					foreach my $filter (@{$map->{maplist}}) {
						if ($rr_in->{loc}  eq $filter) {
							$ok_for_now = 1;
							last;
						}
					}
					last;
				}
			}
			unless ($ok_for_now == 1) {
				&mark_error($rr_in,\@errors,'unknown map or map specified with a bad filter definition');
			}
		} else {
			if (defined $rr_in->{loc}) {
				&mark_error($rr_in,\@errors,'filter definition found withou a map specification');
			}
		}
		#if (defined $errors[0]) { next; }
		my %rr = ();
		#$rr{zid} = (defined $zid) ? $zid : undef;
		$rr{id} = undef;
		$rr{zid} = undef;
		$rr{rrtype} = $rr_in->{type};
		$rr{rid} = z_type_rmap($rr{rrtype});
		$rr{name} = $rr_in->{rrname};
		$rr{ttl} = $rr_in->{rrttl};
		$rr{data} = $rr_in->{data};
		$rr{aux} = [$rr_in->{aux}];
		if (defined $rr_in->{mapname}) { 
			if (lc $rr_in->{mapname} eq 'none') {
				$rr{mapname} = undef;
				$rr{mid} = undef;
				$rr{loq} = 0;
				$rr{loc} = undef;
			} else {
				$rr{mapname} = $rr_in->{mapname};
				$rr{mid} = $rr_in->{mapname};
				$rr{loc} = $rr_in->{loc};
				$rr{loq} = 1;
				$georecords{$rr{name}}->{$rr{mapname}}->{$rr{loc}} = 1;
			}
		} else {
			$rr{loq} = 0;
		}
		push @rrs,\%rr;
	}
	foreach my $rrname (keys %georecords) {
		my @mapnames = keys %{$georecords{$rrname}};
		if ($#mapnames != 0) {
			push @errors,{emsg=>"multiple maps specified for record $rrname"};
		}
		my $filters = $georecords{$rrname}->{$mapnames[0]};
		foreach my $map (@$geomaps) {
			if ($mapnames[0] eq $map->{mapname}) {
				foreach my $defined_filter (@{$map->{maplist}}) {
					if (!defined $georecords{$rrname}->{$mapnames[0]}->{$defined_filter}) {
						push @errors,
							{emsg=>"filter $defined_filter not defined for RR $rrname while map $mapnames[0] enabled for it"};
					}
				}
			}
		}
	}
	if (defined $errors[0]) {
		#warn "WE HAVE ERRORS!\n";
		$template->param(have_errors=>1);
		$template->param(errors=>\@errors);
		undef @rrs;
		return undef;
	}
	#warn "DOMAIN_CHECK_OK!!\n";
	return \@rrs;
}
1;
