# -*- mode: perl; coding: us-ascii-unix; -*-

package Number::Binary::Convert::IEEE754;

use strict;
use warnings;

use Carp qw< carp croak >;
use Math::Complex ();

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

sub _get_params {
    my $class = shift;

    croak "No format or parameters specified" unless @_;

    my $params = {
                 b         => 2,        # base
                 k         => undef,    # storage width (in bits)
                 p         => undef,    # precision (in bits)
                 t         => undef,    # number of bits in significand
                 w         => undef,    # number of bits in exponent
                 emax      => undef,    # = 2 ** ($w - 1) - 1
                 emin      => undef,    # = 1 - $emax
                 bias      => undef,    # exponent bias
                 byteorder => 'be',     # byte order
                };

    # A call like
    #
    #     Number::Binary::Convert -> encoder("binary64");
    #
    # is equivalent to
    #
    #    Number::Binary::Convert -> encoder(format => "binary64");

    unshift @_, "format" if @_ % 2;

    while (@_) {
        my $param = shift;
        croak "Parameter name is undefined" unless defined $param;

        croak "Missing value for parameter '$param'" unless @_;
        my $value = shift;

        if ($param eq 'format') {
            croak "Value for parameter '$param' is undefined"
              unless defined $value;

            if ($value eq 'half') {
                $value = 'binary16';
            } elsif ($value eq 'single') {
                $value = 'binary32';
            } elsif ($value eq 'double') {
                $value = 'binary64';
            } elsif ($value =~ /^quad(ruple)?$/) {
                $value = 'binary128';
            } elsif ($value =~ /^oct(uple)?$/) {
                $value = 'binary256';
            }

            my ($b, $k, $p, $t, $w);
            if ($value eq 'bfloat16') {
                $b =  2;
                $k = 16;
                $p =  8;
                $t =  7;
                $w =  8;
            } elsif ($value =~ /^msfp([89]|1[01])$/) {
                $b =  2;
                $k = $1;
                $p = $k - 5;
                $t = $p - 1;
                $w =  5;
            } elsif ($value eq 'binary16') {
                $b =  2;
                $k = 16;
                $p = 11;
                $t = 10;
                $w =  5;
            } elsif ($value eq 'binary32') {
                $b =  2;
                $k = 32;
                $p = 24;
                $t = 23;
                $w =  8;
            } elsif ($value eq 'binary64') {
                $b =  2;
                $k = 64;
                $p = 53;
                $t = 52;
                $w = 11;
            } elsif ($value =~ /^binary(\d+)$/) {
                $b =  2;
                $k = $1;
                if ($k < 128 || $k != 32 * sprintf('%.0f', $k / 32)) {
                    croak "Number of bits must be 16, 32, 64, or >= 128 and",
                      " a multiple of 32";
                }
                $p = $k - sprintf('%.0f', 4 * log($k) / log(2)) + 13;
                $t = $p - 1;
                $w = $k - $t - 1;
            } else {
                croak("Invalid value '$value'");
            }

            $params -> {b} = $b;
            $params -> {k} = $k;
            $params -> {p} = $p;
            $params -> {t} = $t;
            $params -> {w} = $w;
            next;
        }

        if ($param =~ /^(b|k|p|t|w|emin|emax|bias)$/) {
            $params -> {$1} = $value;
            next;
        }

        if ($param eq 'byteorder') {
            if ($value =~ /^(big(-endian)?|be)$/i) {
                $params -> {byteorder} = 'be';
                next;
            }
            if ($value =~ /^(little(-endian)?|le)$/i) {
                $params -> {byteorder} = 'le';
                next;
            }
            croak "Invalid value '$value' for parameter '$param'";
        }

        croak "Unknown parameter '$param'";
    }

    croak "At least one of 'p' and 't' must be specified"
      unless defined $params -> {p} || defined $params -> {t};
    $params -> {t} = $params -> {p} - 1 unless defined $params -> {t};
    $params -> {p} = $params -> {t} + 1 unless defined $params -> {p};

    croak "At least one of 'k' and 'w' must be specified"
      unless defined $params -> {k} || defined $params -> {w};
    $params -> {k} = $params -> {w} + $params -> {p} unless defined $params -> {k};
    $params -> {w} = $params -> {k} - $params -> {p} unless defined $params -> {w};

    # We don't compute $emax = 2**($w-1)-1 directly, because it introduces
    # floating point numbers early. E.g., if $w = 65, then 2**(65-1)-1 is
    # 1.84467440737096e+19. The method below gives 18446744073709551615.

    unless (defined $params -> {emax}) {
        my $emax = 0;
        $emax = 2 * $emax + 1 for 2 .. $params -> {w};
        $params -> {emax} = $emax;        # = 2**($w-1)-1
    }

    $params -> {emin} = 1 - $params -> {emax} unless defined $params -> {emin};
    $params -> {bias} = $params -> {emax}     unless defined $params -> {bias};

    return $params;
}

sub encoder {
    my $class = shift;

    my $params = $class -> _get_params(@_);

    my $b    = $params -> {b};
    my $k    = $params -> {k};
    my $t    = $params -> {t};
    my $w    = $params -> {w};
    my $emax = $params -> {emax};
    my $emin = $params -> {emin};
    my $bias = $params -> {bias};

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

    # The encoder subroutine.

    return sub {
        my $x = shift;

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
        $expo = $emax if $expo > $emax;
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

        if ($expo > $emax) {                    # overflow => infinity
            return $sign ? $ninf : $pinf;
        } elsif ($expo < $emin) {               # subnormal number
            $mant *= 2 ** ($t - 1);             # use POSIX::ldexp()?
            $mant = sprintf '%.0f', $mant;      # round to nearest integer
        } else {                                # normal number
            $mant--;                            # remove implicit leading bit
            $mant *= 2 ** $t;                   # use POSIX::ldexp()?
            $mant = sprintf '%.0f', $mant;      # round to nearest integer
            if ($mant >= 2 ** $t) {             # did rounding cause overflow?
                return $sign ? $ninf : $pinf;
            }
        }

        $expo += $bias;                         # add bias

        my $bits = sprintf "%.1b%.*b%.*b", $sign, $w, $expo, $t, $mant;
        return pack "B*", $bits;
    };
}

sub decoder {
    my $class = shift;

    my $params = $class -> _get_params(@_);

    my $b    = $params -> {b};
    my $k    = $params -> {k};
    my $t    = $params -> {t};
    my $w    = $params -> {w};
    my $emax = $params -> {emax};
    my $emin = $params -> {emin};
    my $bias = $params -> {bias};

    # The decoder subroutine.

    return sub {
        my $bytes = shift;

        my $K = $k / 8;

        # Make sure input string has the correct length.

        my $len = length($bytes);
        croak "Input must be a string of $K bytes" unless $len == $K;

        my $bits = unpack "B*", $bytes;
        my $sign = substr $bits, 0, 1;
        my $expo = substr $bits, 1, $w;
        my $mant = substr $bits, $w + 1;

        my $x;

        # The maximum exponent (only ones) is used for Inf and NaN.

        if (index($expo, "0") == -1) {

            # A zero mantissa/significand is used for Inf, a non-zero for NaN.

            if (index($mant, "1") == -1) {  # zero => Inf
                $x = $inf;
            } else {                        # non-zero => NaN
                $x = $nan;
            }

        } else {

            my $m = 0;
            my $e = 0;

            # Pad the mantissa to a multiple of 32 bits. Then convert it to a
            # floating point number in the range 0 <= $x < 1. Start with the
            # smallest components and add increasingly larger components.

            my $nm = length($mant) % 32;
            $mant .= "0" x (32 - $nm) if $nm;

            my @mlongs = unpack "N*", pack "B*", $mant;
            for (my $i = $#mlongs ; $i >= 0 ; $i--) {
                $m += $mlongs[$i];
                $m *= 0.5 ** 32;
            }

            # A zero exponent (zeros only) is used for subnormal numbers.

            if (index($expo, "1") == -1) {
                $e = 2 ** ($w - 1) - 2;
                $x = $m * 0.5 ** $e;
            } else {

                # Pad the exponent to a multiple of 32 bits. Then convert it to
                # an integer. Start with the smallest components and add
                # increasingly larger components.

                my $ne = length($expo) % 32;
                $expo = ("0" x (32 - $ne)) . $expo if $ne;

                #printf "expo: %s\n", $expo;

                my @elongs = unpack "N*", pack "B*", $expo;
                for (my $i = $#elongs ; $i >= 0 ; $i--) {
                    $e += $elongs[$i] * 2 ** (32 * ($#elongs - $i));
                }

                $e -= $bias;            # subtract exponent bias
                $m++;                   # add implicit bit

                $x = $m * ($e > 0 ? 2 ** $e : 0.5 ** -$e);
            }

        }

        return $sign ? -$x : $x;
    };
}

1;
