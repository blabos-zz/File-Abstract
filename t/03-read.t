#!perl -T

use warnings;
use strict;

use Test::More tests => 12;

use File::Sample;

my $sample = File::Sample->new;
$sample->open('t/sample/read-test.bin');

my @records;


## First record
@records = ();
ok(
    ($sample->read(\@records, 1, 0)),
    'Getting the first record'
);

ok(
    (abs($records[0]->{'foo'} - 1.23) < 0.0000000001),
    'Checking foo value for first record'
);

ok(
    ($records[0]->{'bar'} == 10),
    'Checking bar value for first record'
);


## 5th record
@records = ();
ok(
    ($sample->read(\@records, 1, 4)),
    'Getting the 5th record'
);

ok(
    (abs($records[0]->{'foo'} - 5.67) < 0.0000000001),
    'Checking foo value for 5th record'
);

ok(
    ($records[0]->{'bar'} == 50),
    'Checking bar value for 5th record'
);


## -1th record
ok(
    (not $sample->read(\@records, 1, -1)),
    'Getting the -1th record'
);


## 6th record (out of range)
ok(
    (not $sample->read(\@records, 1, 5)),
    'Getting the 11th record'
);


## Getting invalid ranges
ok(
    (not $sample->read(\@records, 1, -10)),
    'Getting the offset -10'
);

ok(
    (not $sample->read(\@records, 15, 5)),
    'Getting invalid counts'
);

ok(
    (not $sample->read(\@records, 10, 2)),
    'Getting out of range'
);


## Getting records
$sample->read(\@records, 5);

ok(
    (scalar(@records) == $sample->length),
    'Getting 5 records'
);


diag("Testing reading a record")