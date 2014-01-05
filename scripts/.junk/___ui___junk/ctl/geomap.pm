require Exporter;
package veridns::ui::ctl::geomap; our @ISA=qw(Exporter);
our @EXPORT = (qw(geo_view geo_edit));
use veridns::cfg qw(:cf_);
use XML::Simple;
use Data::Dumper;
sub geo_view2
{

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
}

sub geo_view
{
	my ($params,$template,$session) = @_;
	#my $username = $ENV{'DNS_ADMIN'};
	#my $userdir = $cf_userdir;
	my $cfg = XMLin(
		$cf_userdir."/".$ENV{'DNS_ADMIN'}."/ipmaps.xml",
		GroupTags=>{exceptions=>'except'},
		ForceArray=>['exception','mapit','map']
	);
	unless ( defined $cfg ) {
		#$template->param(nomaps=>1);
		return $template->output;
	}
	#$template->param(geomap_out=>Dumper($cfg));
	my @maplist = ();
	my $mapnum = 0;
	foreach (@{$cfg->{'map'}}) {
		$mapnum+=1;
		push @maplist, $_->{mname};
	}
	#$template->param(num_maps=>$mapnum);
	#$template->param(maplist=>join(',',@maplist));
		
	$template->param('map'=>$cfg->{'map'});
	my $json_dump = JSON->new->utf8(1)->pretty(1)->encode($cfg->{'map'});
	$template->param(json_geoip_maps=>$json_dump);
	return $template->output;
}

sub geo_edit
{
	my ($params,$template,$session) = @_;
	$template->param(test=>"OK_GEOMAPS:EDIT");
	return $template->output;
}


1;
