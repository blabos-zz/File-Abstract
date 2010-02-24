#!perl -T

use Test::More tests => 1;

use File::Sample;

my $sample;
ok(
    ($sample = File::Sample->new),
    'Constructed sample object'
);

diag( $sample->test );

diag( "Testing File::Abstract $File::Abstract::VERSION, Perl $], $^X" );
