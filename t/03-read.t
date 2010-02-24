#!perl -T

use warnings;
use strict;

use Test::More tests => 8;

use File::Sample;
use Data::Dumper;

my $sample = File::Sample->new;
$sample->open_file('t/sample/read-test.bin');

my $rec_ref = {};


## First record
ok(
    ($sample->read_record(0, $rec_ref)),
    'Getting the first record'
);

ok(
    (abs($rec_ref->{'foo'} - 1.23) <= 0.0000000001),
    'Checking foo value for first record'
);

ok(
    ($rec_ref->{'bar'} == 10),
    'Checking bar value for first record'
);


## 5th record
delete @{$rec_ref}{keys %{$rec_ref}};
ok(
    ($sample->read_record(4, $rec_ref)),
    'Getting the 5th record'
);

ok(
    (abs($rec_ref->{'foo'} - 5.67) <= 0.0000000001),
    'Checking foo value for 5th record'
);

ok(
    ($rec_ref->{'bar'} == 50),
    'Checking bar value for 5th record'
);


## -1th record
delete @{$rec_ref}{keys %{$rec_ref}};
ok(
    (not $sample->read_record(-1, $rec_ref)),
    'Getting the -1th record'
);


## 6th record (out of range)
delete @{$rec_ref}{keys %{$rec_ref}};
ok(
    (not $sample->read_record(5, $rec_ref)),
    'Getting the 6th record'
);


diag("Testing reading a record")