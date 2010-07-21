#!perl -T

use warnings;
use strict;

use Test::More tests => 14;

use File::Sample;

use Data::Dumper;

unlink 't/sample/write-test.bin';

my $sample = File::Sample->new;
$sample->open('t/sample/write-test.bin');

my @records;

# First record/append
@records = ();
for (my $i = 0; $i < 10; $i++) {
    push @records, {'foo' => 123 + $i / 10.0, 'bar' => 780 + $i};
}

ok(
    ($sample->write(\@records)),
    'Writing ten records'
);

ok(
    ($sample->length == 10),
    'Checking length'
);

ok(
    ($sample->size == 168),
    'Checking size'
);

@records = ();
$sample->read(\@records);

ok(
    (abs($records[0]->{'foo'} - 123.0) < 0.0000000001),
    'Checking foo for first record'
);

ok(
    ($records[0]->{'bar'} == 780),
    'Checking bar for first record'
);

ok(
    (abs($records[9]->{'foo'} - 123.9) < 0.0000000001),
    'Checking foo for last record'
);

ok(
    ($records[9]->{'bar'} == 789),
    'Checking bar for last record'
);


## Re-checking
@records = ();
for (my $i = 10; $i > 0; $i--) {
    push @records, {'foo' => 123 + $i / 10.0, 'bar' => 780 + $i};
}

ok(
    ($sample->write(\@records)),
    'Re-writing ten records'
);

@records = ();
$sample->read(\@records);

ok(
    (abs($records[0]->{'foo'} - 124.0) < 0.0000000001),
    'Re-checking foo for first record'
);

ok(
    ($records[0]->{'bar'} == 790),
    'Re-checking bar for first record'
);

ok(
    (abs($records[9]->{'foo'} - 123.1) < 0.0000000001),
    'Re-checking foo for last record'
);

ok(
    ($records[9]->{'bar'} == 781),
    'Re-checking bar for last record'
);


## Before -1
ok(
    (not $sample->write(\@records, -1)),
    'Writing ten records from record -1'
);


## After last
ok(
    (not $sample->write(\@records, 11)),
    'Writing ten records from record 11'
);

unlink 't/sample/write-test.bin';


diag("Testing writing some records")