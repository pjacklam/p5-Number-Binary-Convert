# -*- mode: perl; coding: us-ascii-unix; -*-

use strict;
use warnings;

use Test::More tests => 20;

use Math::Complex ();

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

# Test the encoder/decoder in Number::Binary::Convert::binary32

{
    require Number::Binary::Convert;

    my $enc = Number::Binary::Convert -> encoder("binary32");
    my $dec = Number::Binary::Convert -> decoder("binary32");

    cmp_ok($dec -> ("\xbf\x80\x00\x00"), "==", -1,
           '$dec -> ("\xbf\x80\x00\x00")');
    is($enc -> (-1), "\xbf\x80\x00\x00",
           '$enc -> (-1)');

    cmp_ok($dec -> ("\x00\x00\x00\x00"), "==", 0,
           '$dec -> ("\x00\x00\x00\x00")');
    is($enc -> (0), "\x00\x00\x00\x00",
           '$enc -> (0)');

    cmp_ok($dec -> ("\x3f\x80\x00\x00"), "==", 1,
           '$dec -> ("\x3f\x80\x00\x00")');
    is($enc -> (1), "\x3f\x80\x00\x00",
           '$enc -> (1)');

    cmp_ok($dec -> ("\xff\x80\x00\x00"), "==", -$inf,
           '$dec -> ("\xff\x80\x00\x00")');
    is($enc -> (-$inf), "\xff\x80\x00\x00",
           '$enc -> (-Inf)');

    cmp_ok($dec -> ("\x7f\x80\x00\x00"), "==", $inf,
           '$dec -> ("\x7f\x80\x00\x00")');
    is($enc -> ($inf), "\x7f\x80\x00\x00",
           '$enc -> (Inf)');
}

# Test the encoder/decoder in Number::Binary::Convert::IEEE754

{
    require Number::Binary::Convert::IEEE754;

    my $enc = Number::Binary::Convert::IEEE754 -> encoder("binary32");
    my $dec = Number::Binary::Convert::IEEE754 -> decoder("binary32");

    cmp_ok($dec -> ("\xbf\x80\x00\x00"), "==", -1,
           '$dec -> ("\xbf\x80\x00\x00")');
    is($enc -> (-1), "\xbf\x80\x00\x00",
           '$enc -> (-1)');

    cmp_ok($dec -> ("\x00\x00\x00\x00"), "==", 0,
           '$dec -> ("\x00\x00\x00\x00")');
    is($enc -> (0), "\x00\x00\x00\x00",
           '$enc -> (0)');

    cmp_ok($dec -> ("\x3f\x80\x00\x00"), "==", 1,
           '$dec -> ("\x3f\x80\x00\x00")');
    is($enc -> (1), "\x3f\x80\x00\x00",
           '$enc -> (1)');

    cmp_ok($dec -> ("\xff\x80\x00\x00"), "==", -$inf,
           '$dec -> ("\xff\x80\x00\x00")');
    is($enc -> (-$inf), "\xff\x80\x00\x00",
           '$enc -> (-Inf)');

    cmp_ok($dec -> ("\x7f\x80\x00\x00"), "==", $inf,
           '$dec -> ("\x7f\x80\x00\x00")');
    is($enc -> ($inf), "\x7f\x80\x00\x00",
           '$enc -> (Inf)');
}
