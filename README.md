# NAME

Number::Binary::Convert - convert numbers to/from binary formats

# SYNOPSIS

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

# DESCRIPTION

This module is a front-end for creating encoder and decoder functions for
converting numbers to and from various binary formats.

# METHODS

- encoder()

    Returns an encoder function for the specified format.

        my $enc = Number::Binary::Convert -> encoder("binary16");

- decoder()

    Returns a decoder function for the specified fmt.

        my $dec = Number::Binary::Convert -> decoder("binary16");

# LIMITATION

- byteorder

    Only big-endian byteorder is supported.

- base

    Only binary (base 2) formats are supported.

# BUGS

Please report any bugs or feature requests to
`bug-number-binary-convert at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Number-Binary-Convert](https://rt.cpan.org/Ticket/Create.html?Queue=Number-Binary-Convert)
(requires login). We will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Binary::Convert

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Number-Binary-Convert](https://github.com/pjacklam/p5-Number-Binary-Convert)

- MetaCPAN

    [https://metacpan.org/release/Number-Binary-Convert](https://metacpan.org/release/Number-Binary-Convert)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Number-Binary-Convert](http://cpanratings.perl.org/d/Number-Binary-Convert)

- CPAN Testers PASS Matrix

    [http://pass.cpantesters.org/distro/A/Number-Binary-Convert.html](http://pass.cpantesters.org/distro/A/Number-Binary-Convert.html)

- CPAN Testers Reports

    [http://www.cpantesters.org/distro/A/Number-Binary-Convert.html](http://www.cpantesters.org/distro/A/Number-Binary-Convert.html)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Number-Binary-Convert](http://matrix.cpantesters.org/?dist=Number-Binary-Convert)

# LICENSE AND COPYRIGHT

Copyright 2021 Peter John Acklam.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

Peter John Acklam &lt;pjacklam (at) gmail.com>.
