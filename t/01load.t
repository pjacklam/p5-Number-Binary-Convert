# -*- mode: perl; coding: us-ascii-unix; -*-

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('Number::Binary::Convert');
    use_ok('Number::Binary::Convert::binary32');
    use_ok('Number::Binary::Convert::binary64');
    use_ok('Number::Binary::Convert::binary128');
    use_ok('Number::Binary::Convert::IEEE754');
};
