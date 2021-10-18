# -*- mode: perl; coding: us-ascii-unix; -*-

package Number::Binary::Convert::binary128;

use strict;
use warnings;

use Carp qw< carp croak >;
use Math::Complex ();

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

my $k    =  128;        # storage width (in bits)
my $p    =  113;        # precision (in bits)
my $t    =  112;        # number of bits in significand
my $w    =   15;        # number of bits in exponent
my $emax = 16383;       # = 2 ** (w - 1) - 1;
my $emin = -16382;      # = 1 - $emax;
my $bias = 16383;       # = emax

my $K    = $k / 8;      # storage width in bytes

# negative infinity

my $ninf = pack "B*", "1"                             # sign
                    . ("1" x $w)                      # exponent
                    . ("0" x $t);                     # significand

# positive infinity

my $pinf = pack "B*", "0"                             # sign
                    . ("1" x $w)                      # exponent
                    . ("0" x $t);                     # significand

# quiet (non-signaling) NaN as on x86 and ARM

my $qnan = pack "B*", "0"                             # sign
                    . ("1" x $w)                      # exponent
                    . "1" . ("0" x ($t - 2)) . "1";   # significand

# signaling NaN as on x86 and ARM

#my $snan = pack "B*", "0"                             # sign
#                    . ("1" x $w)                      # exponent
#                    . "0" x ($t - 1) . "1";           # significand

# zero

my $zero = pack "B*", "0" x $k;

my $encoder = sub {
    croak "Encoder input is missing" unless @_;

    my $x = shift;
    croak "Encoder input is undefined" unless defined $x;

    return $qnan if $x != $x;
    return $pinf if $x == $inf;
    return $ninf if $x == -$inf;
    return $zero if $x == 0;

    # Normal and subnormal numbers.

    my $sign = $x < 0 ? 1 : 0;
    my $mant = abs($x);
    my $expo = 0;

    # Approximate the mantissa and exponent in base 2. Use POSIX::frexp()?

    $expo = int(log($mant) / log(2));
    $expo =  $emax if $expo >  $emax;
    $expo = $emin if $expo < $emin;
    $mant *= $expo > 0 ? 0.5 ** $expo : 2 ** -$expo;

    # Refine the approximation to the exact values.

    while ($mant >= 2 && $expo <= $emax) {
        $mant *= 0.5;
        $expo++;
    }

    while ($mant < 1 && $expo >= $emin) {
        $mant *= 2;
        $expo--;
    }

    # Encode as infinity, normal number or subnormal number?

    if ($expo > $emax) {                # overflow => infinity
        return $sign ? $ninf : $pinf;
    } elsif ($expo < $emin) {           # subnormal number
        $mant *= 2 ** ($t - 1);         # use POSIX::ldexp()?
        $mant = sprintf '%.0f', $mant;  # round to nearest integer
    } else {                            # normal number
        $mant--;                        # remove implicit leading bit
        $mant *= 2 ** $t;               # use POSIX::ldexp()?
        $mant = sprintf '%.0f', $mant;  # round to nearest integer
        if ($mant >= 2 ** $t) {         # did rounding cause overflow?
            return $sign ? $ninf : $pinf;
        }
    }

    $expo += $bias;                     # add bias

    my $signbit = "$sign";

    my $mantbits = '';
    while ($mant > 0) {
        my $part = $mant % 16777216;
        $mant = ($mant - $part) / 16777216;
        if ($mant) {
            $mantbits = sprintf("%024b", $part) . $mantbits;
        } else {
            $mantbits = sprintf("%b", $part) . $mantbits;
        }
    }

    $mantbits = ("0" x ($t - length($mantbits))) . $mantbits;

    my $expobits = sprintf "%b", $expo;
    $expobits = ("0" x (15 - length($expobits))) . $expobits;

    my $bin = $signbit . $expobits . $mantbits;
    return pack "B*", $bin;
};

my $decoder = sub {
    croak "Decoder input is missing" unless @_;

    my $in = shift;
    croak "Decoder input is undefined" unless defined $in;

    my $len = length($in);
    croak "input must be a string of $K bytes" unless $len == $K;

    # Split bit string into sign, exponent, and mantissa/significand.

    #
    #  |----- 15 ----||----- 16 -----|
    # seeeeeeeeeeeeeeemmmmmmmmmmmmmmmm      most significant byte
    #
    # |------------- 32 -------------|
    # mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm      second most significant byte
    #
    # ...

    my @in = unpack "N*", $in;
    my $sign =  $in[0] >> 31;                   # 1 bit
    my $expo = ($in[0] >> 16) & 0x00007fff;     # 15 bits
    my $mant =  $in[0]        & 0x0000ffff;     # 16 bits
    for (1 .. 3) {
        $mant *= 2 ** 32;                       # use POSIX::ldexp?
        $mant += $in[$_];
    }

    my $x;

    $expo -= $bias;                     # subtract bias

    if ($expo < $emin) {                # zero and subnormals
        if ($mant == 0) {               # zero
            $x = 0;
        } else {                        # subnormals
            $x = 2 ** $emin * (0.5 ** $t * $mant);
        }
    } elsif ($expo > $emax) {           # inf and nan
        if ($mant == 0) {               # inf
            $x = $inf;
        } else {                        # nan
            $x = $nan;
        }
    } else {                            # normals
        #$x = 2 ** ($expo - $t) * (2 ** $t + $mant);
        $x = 2 ** $expo * (1 + 0.5 ** $t * $mant);
    }

    return $sign ? -$x : $x;
};

sub encoder { $encoder; }
sub decoder { $decoder; }

1;
