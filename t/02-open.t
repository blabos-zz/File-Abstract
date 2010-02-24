#!perl -T

use warnings;
use strict;

use Test::More tests => 12;

use File::Sample;

my $sample = File::Sample->new;

ok(
    (not $sample->open_file('t/sample/non_exists.bin')),
    'Opening file "t/sample/non_exists.bin"'
);

ok(
    ($sample->open_file('t/sample/read-test.bin')),
    'Opening file "t/sample/read-test.bin"'
);

ok(
    ($sample->length == 5),
    'Checking length'
);

my $size = $sample->header_size + $sample->length * $sample->record_size;
ok(
    ($sample->size == $size),
    'Checking size'
);

unlink 't/sample/create-test.bin';
ok(
    ($sample->new_file('t/sample/create-test.bin')),
    'Creating file "t/sample/create-test.bin"'
);

ok(
    (-f 't/sample/create-test.bin'),
    'Created file "t/sample/create-test.bin"'
);

ok(
    ($sample->size == $sample->header_size),
    'Checking size'
);

ok(
    ($sample->length == 0),
    'Checking length'
);

unlink 't/sample/create-test.bin';

ok(
    ($sample->new_file('t/sample/create-test.bin')),
    'Creating file "t/sample/create-test.bin"'
);

ok(
    ($sample->length == 0),
    'Checking size of a new file'
);
unlink 't/sample/create-test.bin';

ok(
    ($sample->open_or_new_file('t/sample/read-test.bin')),
    'Creating file "t/sample/read-test.bin"'
);

ok(
    ($sample->length == 5),
    'Re-checking size'
);

diag("Testing create, open and sizes of binary files");