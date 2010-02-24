package File::Abstract;

use warnings;
use strict;

use Data::Dumper;

=head1 NAME

File::Abstract - The great new File::Abstract!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 $HEADER_FMT

=cut

our $HEADER_FMT;

=head1 $RECORD_FMT

=cut

our $RECORD_FMT;


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use File::Abstract;

    my $foo = File::Abstract->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 test

=cut

sub test {
    my $self = shift;
    
    return Dumper($self, {
        'header_template'       => $self->header_template,
        'header_fields'         => $self->header_fields,
        'header_size'           => $self->header_size,
        'record_template'       => $self->record_template,
        'record_fields'         => $self->record_fields,
        'record_size'           => $self->record_size,
    });
}

sub header_template {
    return join '', map { values %{$_} } @{$HEADER_FMT};
}

sub header_fields {
    return [map { keys %{$_} } @{$HEADER_FMT}];
}

sub header_size {
    return length pack header_template;
}

sub record_template {
    return join '', map { values %{$_} } @{$RECORD_FMT};
}

sub record_fields {
    return [map { keys %{$_} } @{$RECORD_FMT}];
}

sub record_size {
    return length pack record_template;
}

sub import {
    no strict;
    *{caller() . '::bless'}
        = sub {
            my ($atts, $class) = @_;
            
            my $base_atts = {
                '_fh' => undef,
            };
            
            bless({%{$atts}, %{$base_atts}}, $class);
        }
    ;
    our @EXPORT = qw(bless);
}


=head1 AUTHOR

Blabos de Blebe, C<< <blabos at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-abstract at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Abstract>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Abstract


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Abstract>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Abstract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Abstract>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Abstract/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Blabos de Blebe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of File::Abstract
