# -*- mode: perl; coding: us-ascii-unix; -*-

package Number::Binary::Convert;

use strict;
use warnings;

use Carp qw< carp croak >;

our $VERSION = 0.001;

my $config;

=pod

=encoding UTF-8

=head1 NAME

Number::Binary::Convert - convert numbers to/from binary formats

=head1 SYNOPSIS

    use Number::Binary::Convert;

    # Create an encoder for the binary128 (quad precision) format
    # and encode the approximate value of pi.

    my $enc = Number::Binary::Convert -> encoder("binary128");
    my $bytes = $enc -> (3.1415926535897932384626433832795029);

    # Create a decoder for the binary32 (single precision) format
    # and decode the closest approximation of pi.

    my $dec = Number::Binary::Convert -> decoder("binary32");
    my $val = $dec -> ("\x40\x49\x0f\xdb");

    # Use the generic IEEE754 encoder/decoder for formats that do not
    # have a separate module. E.g.,

    my $enc = Number::Binary::Convert -> encoder("IEEE754::binary160");

    # which is equivalent to

    my $enc = Number::Binary::Convert::IEEE754 -> encoder("binary160");

=head1 DESCRIPTION

This module is a front-end for creating encoder and decoder functions for
converting numbers to and from various binary formats.

=head1 METHODS

=over 4

=item encoder()

Returns an encoder function for the specified format.

    my $enc = Number::Binary::Convert -> encoder("binary16");

=cut

sub encoder {
    my $class = shift;
    croak "Missing format for encoder()" unless @_;

    my $fmt = shift;
    croak "Undefined format for encoder()" unless defined $fmt;

    my @a = split /::/, $fmt;           # module components
    my @b = ();                         # format components
    my @tried = ();                     # remember what we have tried to load

    while (@a) {
        my $mod = "Number::Binary::Convert" . join "", map "::$_", @a;
        my $fmt = join "::", @b;

        if ($config -> {debug}) {
            printf <<"EOF", $mod, length($fmt) ? qq|"$fmt"| : $fmt;
DEBUG:
DEBUG: Trying
DEBUG:
DEBUG:     require %s;
DEBUG:     return $mod -> encoder(%s);
DEBUG:
EOF
        }

        eval "require $mod";
        return $mod -> encoder() unless $@;

        push @tried, [ $mod, $fmt ];
        if ($config -> {debug}) {
            printf "DEBUG: Unable to load module '%s'\n", $mod;
        }

        unshift @b, pop @a;
    }

    my $msg = "Not able to load any of the following modules\n";
    for my $i (0 .. $#tried) {
        $msg .= "    $tried[$i][0]\n";
    }
    croak $msg;
}

=pod

=item decoder()

Returns a decoder function for the specified fmt.

    my $dec = Number::Binary::Convert -> decoder("binary16");

=cut

sub decoder {
    my $class = shift;
    my $fmt = shift;

    my @a = split /::/, $fmt;           # module components
    my @b = ();                         # format components
    my @tried = ();                     # remember what we have tried to load

    while (@a) {
        my $mod = "Number::Binary::Convert" . join "", map "::$_", @a;
        my $fmt = join "::", @b;

        if ($config -> {debug}) {
            printf <<"EOF", $mod, length($fmt) ? qq|"$fmt"| : $fmt;
DEBUG:
DEBUG: Trying
DEBUG:
DEBUG:     require %s;
DEBUG:     return $mod -> decoder(%s);
DEBUG:
EOF
        }

        eval "require $mod";
        return $mod -> decoder() unless $@;

        push @tried, [ $mod, $fmt ];
        if ($config -> {debug}) {
            printf "DEBUG: Unable to load module '%s'\n", $mod;
        }

        unshift @b, pop @a;
    }

    my $msg = "Not able to load any of these modules\n";
    for my $i (0 .. $#tried) {
        $msg .= "    $tried[$i][0]\n";
    }
    croak $msg;
}

sub import {
    my $class = shift;

    while (@_) {
        my $param = shift;

        if ($param eq 'debug') {
            croak "No argument for parameter '$param'" unless @_;
            $config -> {debug} = !!shift;
            next;
        }
    }
}

=pod

=back

=head1 LIMITATION

=over 4

=item byteorder

Only big-endian byteorder is supported.

=item base

Only binary (base 2) formats are supported.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-number-binary-convert at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Number-Binary-Convert>
(requires login). We will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Binary::Convert

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/pjacklam/p5-Number-Binary-Convert>

=item * MetaCPAN

L<https://metacpan.org/release/Number-Binary-Convert>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Number-Binary-Convert>

=item * CPAN Testers PASS Matrix

L<http://pass.cpantesters.org/distro/A/Number-Binary-Convert.html>

=item * CPAN Testers Reports

L<http://www.cpantesters.org/distro/A/Number-Binary-Convert.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Number-Binary-Convert>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Peter John Acklam.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Peter John Acklam E<lt>pjacklam (at) gmail.comE<gt>.

=cut

1;
