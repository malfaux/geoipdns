package veridns::zone::template;
BEGIN {
use File::Basename;
use lib dirname $0;
}
$ENV{DNS_ADMIN} = 'admin';

use veridns::cfg qw(:cf_);
use XML::Simple;
use Storable;
sub load
{
	my ($pkg,$tfile) = @_;
	if (defined $tfile) {
		if ($tfile=~/\//) { return wantarray? () : undef; }
		my $out = XMLin($cf_userdir."/".$ENV{'DNS_ADMIN'}."/templates/$tfile");
		$out->{tname} = $tfile;
		if (!defined $out) { return wantarray? () : undef; }
		return [$out];
	}
	opendir($dh,$cf_userdir."/".$ENV{'DNS_ADMIN'}."/templates/");
	if (!defined $dh) { return wantarray?():undef;}
	my @template_files= grep { !/^\./ && -f $cf_userdir."/".$ENV{'DNS_ADMIN'}."/templates/$_" } readdir($dh);
	close($dh);
	my @d1 = ();
	foreach my $tmpl_f (@template_files) {
		my $t_xml = XMLin($cf_userdir."/".$ENV{'DNS_ADMIN'}."/templates/$tmpl_f");
		next unless defined $t_xml;
		#my $dnstmpl = { tmpl_tname=>$t_xml->{},tmpl_fname=>$tmpl_f,};
		my $dnstmpl = { tmpl_fname=>$tmpl_f,};
		push @d1, $dnstmpl;
	}
	return \@d1;
}

sub save
{
	my ($pkg,$fn,$data) = @_;
	my $xml = XMLout($data);
	open($fh,">",$cf_userdir."/".$ENV{'DNS_ADMIN'}."/templates/$fn");
	print $fh $xml;
	close $fh;
}
sub list
{
	opendir($dh,$cf_userdir."/".$ENV{'DNS_ADMIN'}."/templates/");
	if (!defined $dh) { return wantarray?():undef;}
	my @template_files= grep { !/^\./ && -f $cf_userdir."/".$ENV{'DNS_ADMIN'}."/templates/$_" } readdir($dh);
	close $dh;
	my @out = ();
	foreach my $tmpl_f (@template_files) {
		my $t_xml = XMLin($cf_userdir."/".$ENV{'DNS_ADMIN'}."/templates/$tmpl_f");
		next unless defined $t_xml;
		push @out,{tfile=>$tmpl_f,tname=>$tmpl_f};
	}
	return \@out;
}

1;
