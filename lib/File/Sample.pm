package File::Sample;

use warnings;
use strict;

use parent 'File::Abstract';

sub new {
    my $class   = shift;
    my $args    = shift || {};
    my $atts    = {
        'header' => [
            {'version'  => 'l'},
            {'copy'     => 'Z20'},
        ],
    };
    
    return bless $atts, $class;
}

1; # End of File::Sample
