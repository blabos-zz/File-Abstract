#!perl -T

use warnings;
use strict;

use Test::More tests => 12;

use File::Sample;
use Data::Dumper;

unlink 't/sample/write-test.bin';

my $sample = File::Sample->new;
$sample->open_or_new_file('t/sample/write-test.bin');

my %data;
my $rec_ref = {};


## First record/append
@data{qw(foo bar)} = qw(123.456 7890);
ok(
    ($sample->write_record(0, \%data)),
    'Writing the first record'
);

ok(
    ($sample->size == 60),
    'Checking for size'
);

ok(
    ($sample->length == 1),
    'Checking for length'
);

delete @{$rec_ref}{keys %{$rec_ref}};
$sample->read_record(0, $rec_ref);

ok(
    (abs($rec_ref->{'foo'} - 123.456) < 0.0000000001),
    'Checking foo for first record'
);

ok(
    ($rec_ref->{'bar'} == 7890),
    'Checking bar for first record'
);


## Re-checking
@data{qw(foo bar)} = qw(9.87 6543210);
ok(
    ($sample->write_record(0, \%data)),
    'Re-writing the first record'
);

ok(
    ($sample->size == 60),
    'Re-checking for size'
);

ok(
    ($sample->length == 1),
    'Re-checking for length'
);

delete @{$rec_ref}{keys %{$rec_ref}};
$sample->read_record(0, $rec_ref);

ok(
    (abs($rec_ref->{'foo'} - 9.87) < 0.0000000001),
    'Re-checking foo for first record'
);

ok(
    ($rec_ref->{'bar'} == 6543210),
    'Re-checking bar for first record'
);


## -1th record
ok(
    (not $sample->write_record(-1, \%data)),
    'Writing the -1th record'
);


## 11th record (out of range)
ok(
    (not $sample->write_record(11, \%data)),
    'Writing the 11th record'
);

unlink 't/sample/write-test.bin';


diag("Testing writing a record")