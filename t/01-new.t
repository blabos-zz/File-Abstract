#!perl -T

use Test::More tests => 1;

use File::Sample;

my $sample;
ok(
    ($sample = File::Sample->new),
    'Constructed sample object'
);

diag( "Testing object creation" );
