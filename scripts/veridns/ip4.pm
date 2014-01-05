require Exporter;
package veridns::ip4; our @ISA = qw(Exporter);

# Convert a 32 bit "network" number to a list of bits.
sub num2bits
{
  my $n = shift;
  return split //, unpack 'B*', pack 'N', $n;
}


# Convert a list of bits to a 32 bit "network" number.
sub bits2num
{
  my $bits = shift;
  my $n = join '', @$bits;
  return unpack 'N', pack 'B*', '0' x (32 - length $n) . $n;
}


# Convert a 32 bit "network" number to an IPv4 quad.
sub num2ip
{
  my $n = shift;
  return join '.', unpack 'C*', pack 'N', $n;
}


# Convert an IPv4 quadto a 32 bit "network" number.
sub ip2num
{
  my $ip = shift;
  return unpack "N", pack "C*", split /\./, $ip;
}


# Split a chunk into (a minimal number of) CIDR blocks.
sub do_chunk
{
  my ($chunks, $fbits, $lbits) = @_;
  my (@prefix, $idx1, $idx2, $size);

  # Find common prefix.  After that, next bit is 0 for $fbits and 1 for
  # $lbits is 1.  A split a this point guarantees the longest suffix.
  $idx1 = 0;
  $idx1++
    while ($idx1 <= $#$fbits and $$fbits[$idx1] eq $$lbits[$idx1]);
  @prefix = @$fbits[0 .. $idx1 - 1];

  $idx2 = $#$fbits;
  $idx2--
    while ($idx2 >= $idx1 and $$fbits[$idx2] eq '0' and $$lbits[$idx2] eq '1');

  # Split if $fbits and $lbits disagree on the length of the chunk.
  if ($idx2 >= $idx1)
  {
    $size = $#$fbits - $idx1;
    do_chunk ($chunks, $fbits, [ @prefix, (split //, '0' . '1' x $size) ]);
    do_chunk ($chunks, [ @prefix, (split //, '1' . '0' x $size) ], $lbits);
  }
  else
  {
    $size = $#$fbits - $idx2;
    push @$chunks, [ (bits2num [ @prefix, (split //, '0' x $size) ]), @$fbits - $size ];
  }
}

sub ip4_tocidr {
	my (@chunks, @fbits, @lbits);
	@fbits = num2bits ip2num $_[0];
	@lbits = num2bits ip2num $_[1];
#@ARGV == 2
#  or die ("Usage:  " . (basename $0) . " <first IP> <last IP>\n");

#@fbits = num2bits ip2num $ARGV[0];
#@lbits = num2bits ip2num $ARGV[1];
	do_chunk \@chunks, \@fbits, \@lbits;
	return \@chunks;
## Format the results for use with Postfix.
#for (@chunks)
#{
#  my ($n, $m) = @$_;
#  print +(num2ip $n), "/$m\n";
#}
}
our @EXPORT = (qw(ip4_tocidr num2ip ip2num));
1;
