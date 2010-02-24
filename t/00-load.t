#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Abstract' ) || print "Bail out!
";
}

diag( "Testing File::Abstract $File::Abstract::VERSION, Perl $], $^X" );
