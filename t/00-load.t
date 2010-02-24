#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'File::Abstract' ) || print "Bail out!";
    use_ok( 'File::Sample' ) || print "Bail out!";
}

diag( "Testing File::Abstract $File::Abstract::VERSION, Perl $], $^X" );
