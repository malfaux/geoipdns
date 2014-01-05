require Exporter;
package veridns::ui::ctl::template; our @ISA=qw(Exporter);
our @EXPORT = (qw(tmpl_view tmpl_edit));
use Data::Dumper;
use veridns::cfg qw(:cf_);
use veridns::zone::template;
use veridns::zone;
use veridns::cfg qw(:cf_);
use veridns::zone::db;
use XML::Simple;
use POSIX qw(isalnum);
use JSON;
$|=1;
sub tmpl_view
{
	my ($params,$template,$session) = @_;
	my $rs = $params->{'dn'};
	my $op = $params->{'r'};
	my $templates = veridns::zone::template->load();
	$template->param(tmpl_list=>veridns::zone::template->load()) if (defined $templates);
	$template->param(json_dns_zone=>'""');
	$template->param('json_geoip_maps'=>'""');
	$template->param('rr_last_id'=>0);
	return $template->output() unless defined $rs;
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
  $template->param(json_geoip_maps=>$json_dump);
  
	if ($op eq 'l') {
		my $t = veridns::zone::template->load($rs);
		my $tname = delete $t->[0]->{tname};
		my $rrs = $t->[0]->{rr};
		$template->param(tname=>delete $t->[0]->{tname});
		$template->param(have_data=>1);
		$template->param(existent_dn=>1);
		$template->param(dn=>$tname);
    my $next_id = 0;
    foreach my $rr (@$rrs) {
      if ($rr->{rrid} > $next_id) { $next_id = $rr->{rrid}; }
      #$rr->{aux} = join(',',@{$rr->{aux}});
    }
		my $json_rr_dump = "[]";
		if (defined $rrs) {
    	$json_rr_dump = JSON->new->encode($rrs);
		}
    $template->param(json_dns_zone=>$json_rr_dump);
    $template->param(rrs=>$rrs);
    $template->param(rr_last_id=>$next_id);
    return $template->output();
	} elsif ($op eq 'n') {
		warn "NEW TEMPLATE: $rs\n";
		$template->param(infos=>[{imsg=>"new template $rs OKOK",}]);
		$template->param(have_data=>1);
		$template->param(existent_dn=>0);
		$template->param(dn=>$rs);
		$template->param(json_dns_zone=>"[]");
		$template->param(rr_last_id=>0);
		return $template->output();
	} elsif ($op eq 'd') {

	} elsif ($op eq 's') {
		my $rrs_raw = JSON->new->utf8(1)->decode($params->{'zdata'});
		my $rrs = &zone_ok($template,\@mapnames,$params->{'dn'},$rrs_raw);
		open($fh,">","/sysami/.data/$ENV{DNS_ADMIN}/templates/$params->{dn}");
#		print $fh Dumper($rrs_raw);
#		print $fh "\n__DECODED__\n";
#		print $fh Dumper($rrs);
#		print $fh "\n__XML___\n";
		print $fh XMLout({rr=>$rrs},RootName=>'template',SuppressEmpty=>1);
		close($fh);
		$template->param(infos=>[{imsg=>"domain $dn saved OK (____dbg: zone id = $new_zid, rr_count=$rr_count)",}]);
		return $template->output();
	}
	die();
}

sub tmpl_edit
{
	return $_[1]->output();
}



sub zone_ok
{
	my %rr_types = ('A'=>1,'SOA'=>1,'NS'=>1,'MX'=>1,'CNAME'=>1);
	my ($template,$geomaps,$dn,$rrs_in) = @_;
	#my $zid = z_getid($dn);
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
			}
		}
		if ((defined $rr_in->{type} and $rr_in->{type} eq 'A') and defined $rr_in->{data} and !is_ipv4($rr_in->{data})) {
			&mark_error($rr_in,\@errors,'bad ipv4 address');
		}
		if (defined $rr_in->{type} and $rr_in->{type} eq 'CNAME' and defined $rr_in->{data}) {
			my $cname_data = $rr_in->{data};
			unless ($cname_data=~/\.$/) {
				&mark_error($rr_in,\@errors,'bad CNAME data: doesn\'t end with a .');
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
		$rr{rrid} = $rr_in->{rrid};
		#$rr{zid} = undef;
		$rr{type} = $rr_in->{type};
		#$rr{rid} = z_type_rmap($rr{rrtype});
		$rr{rrname} = $rr_in->{rrname};
		$rr{rrttl} = $rr_in->{rrttl};
		$rr{data} = $rr_in->{data};
		$rr{aux} = $rr_in->{aux};
		$rr{aux} = undef if $rr{aux} == '';
		if (defined $rr_in->{mapname}) { 
			if (lc $rr_in->{mapname} eq 'none') {
				$rr{mapname} = undef;
				$rr{mid} = undef;
				$rr{loq} = undef; #was 0 for database
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
sub mark_error
{
	my ($rr,$errors,$msg) = @_;
	my $rr_str = "rrid=".$rr->{rrid};
	for my $key (qw(rrname type data rrttl aux mapname loc)) {
		$rr_str = $rr_str.";$key=".$rr->{$key};
	}
	push @$errors,{emsg=>$msg." for RR: ".$rr_str}; 
}

1;
