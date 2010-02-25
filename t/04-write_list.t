#!perl -T

use warnings;
use strict;

use Test::More tests => 14;

use File::Sample;
use Data::Dumper;

unlink 't/sample/write-test.bin';

my $sample = File::Sample->new;
$sample->open_or_new_file('t/sample/write-test.bin');

my @record_list = ();
my $rec_ref;

# First record/append
for (my $i = 0; $i < 10; $i++) {
    push @record_list, {'foo' => 123 + $i / 10.0, 'bar' => 780 + $i};
}

ok(
    ($sample->write_record_list(0, \@record_list)),
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

delete @{$rec_ref}{keys %{$rec_ref}};
$sample->read_record(0, $rec_ref);

ok(
    (abs($rec_ref->{'foo'} - 123.0) < 0.0000000001),
    'Checking foo for first record'
);

ok(
    ($rec_ref->{'bar'} == 780),
    'Checking bar for first record'
);

delete @{$rec_ref}{keys %{$rec_ref}};
$sample->read_record(9, $rec_ref);

ok(
    (abs($rec_ref->{'foo'} - 123.9) < 0.0000000001),
    'Checking foo for last record'
);

ok(
    ($rec_ref->{'bar'} == 789),
    'Checking bar for last record'
);


## Re-checking
@record_list = ();
for (my $i = 10; $i > 0; $i--) {
    push @record_list, {'foo' => 123 + $i / 10.0, 'bar' => 780 + $i};
}

ok(
    ($sample->write_record_list(0, \@record_list)),
    'Re-writing ten records'
);

delete @{$rec_ref}{keys %{$rec_ref}};
$sample->read_record(0, $rec_ref);

ok(
    (abs($rec_ref->{'foo'} - 124.0) < 0.0000000001),
    'Re-checking foo for first record'
);

ok(
    ($rec_ref->{'bar'} == 790),
    'Re-checking bar for first record'
);

delete @{$rec_ref}{keys %{$rec_ref}};
$sample->read_record(9, $rec_ref);

ok(
    (abs($rec_ref->{'foo'} - 123.1) < 0.0000000001),
    'Re-checking foo for last record'
);

ok(
    ($rec_ref->{'bar'} == 781),
    'Re-checking bar for last record'
);


## Before -1
ok(
    (not $sample->write_record_list(-1, \@record_list)),
    'Writing ten records from record -1'
);


## After last
ok(
    (not $sample->write_record_list(11, \@record_list)),
    'Writing ten records from record 11'
);

unlink 't/sample/write-test.bin';


diag("Testing writing some records")