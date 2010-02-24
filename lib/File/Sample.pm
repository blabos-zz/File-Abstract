package File::Sample;

use warnings;
use strict;

use File::Abstract;
use parent 'File::Abstract';

$File::Abstract::HEADER_FMT = [
    {'version'      => 'l'},        # Version:              4 bytes
    {'copy'         => 'Z40'},      # Copyright:           40 bytes
    {'timestamp'    => 'l'},        # Unix timestamp:       4 bytes
];

$File::Abstract::RECORD_FMT = [
    {'foo'      => 'd'},        # Foo:          8 bytes
    {'bar'      => 'l'},        # Bar           4 bytes
];

sub new {
    my $class   = shift;
    my $args    = shift || {};
    my $atts    = {
        'sample_att' => undef,
    };
    
    return bless($atts, $class);
}

1; # End of File::Sample
