package File::Abstract;

use warnings;
use strict;

use Data::Dumper;

=head1 NAME

File::Abstract - The great new File::Abstract!

=head1 VERSION

=cut

our $VERSION = '0.03';

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

sub DESTROY {
    my $self = shift;
    
    eval { $self->close_file };
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

sub show_header_fmt {
    my $self = shift;
    return "\n                           HEADER\n\n"
        . $self->meta_info($HEADER_FMT);
}

sub show_record_fmt {
    my $self = shift;
    return "\n                           RECORD\n\n"
        . $self->meta_info($RECORD_FMT, 1);
}


sub meta_info {
    my $self        = shift;
    my $format_ref  = shift;
    my $is_record   = shift || 0;
    my $sum         = $is_record ? $self->{'_header_size'} : 0;
    
    my $output
        = sprintf(
            "%20s\t%10s\t%10s\t%10s\t%10s\n",
            'FIELD',
            'FORMAT',
            'SIZE (BYTES)',
            'OFFSET DEC',
            'OFFSET HEX',
        );
    
    foreach my $field (@{$format_ref}) {
        my ($key, $value) = %{$field};
        
        $output
            .= sprintf(
                "%20s\t%10s\t%10d\t%10d\t%10X\n",
                $key,
                $value,
                length(pack($value)),
                $sum,
                $sum,
            );
        
        $sum += length(pack $value);
    }
    
    return $output;
}


sub size {
    my $self = shift;
    return $self->{'_size'};
}

sub length {
    my $self = shift;
    return $self->{'_length'};
}




sub open_file {
    my ($self, $filename)   = @_;
    my $retval              = 1;
    
    eval {
        open $self->{'_fh'}, '+<', $filename
            or Carp::croak "Cannot open file '$filename'";
        
        binmode $self->{'_fh'};
        
        $self->{'_filename'}
            = $filename;
            
        $self->{'_size'}
            = -s $filename;
        
        $self->{'_length'}
            = ($self->{'_size'} - $self->{'_header_size'})
            / $self->{'_record_size'};
    };
    if ($@) {
        Carp::carp $@;
        $retval = 0;
    }
    
    return $retval;
}

sub new_file {
    my ($self, $filename)   = @_;
    my $retval              = 0;
    
    eval {
        open $self->{'_fh'}, '>', $filename
            or Carp::carp "Cannot create file '$filename'";
        
        $self->write_header;
        
        close $self->{'_fh'};
        
        $self->{'_size'}    = $self->{'_header_size'};
        $self->{'_length'}  = 0;
    };
    if ($@) {
        Carp::croak $@;
    }
    else {
        $retval = 1;
    }
    
    return $retval;
}

sub open_or_new_file {
    my ($self, $filename)   = @_;
    my $retval              = 0;
    
    eval {
        $self->new_file($filename) unless (-f $filename);
        $retval = $self->open_file($filename);
    };
    if ($@) {
        Carp::croak $@;
    }
    
    return $retval;
}

sub close_file {
    my $self = shift;
    
    eval { close $self->{'_fh'} if $self->{'_fh'} }
}


sub read_record {
    my $self    = shift;
    my $index   = shift;
    my $ret_ref = shift;
    
    my $retval = 0;
    
    if ($index >= 0 and $index < $self->{'_length'}) {
        my $pos
            = $self->{'_header_size'}
            + $index * $self->{'_record_size'};
        
        eval {
            $retval = $self->_read_record($pos, $ret_ref);
        };
        Carp::carp $@ if $@;
    }
    else {
        Carp::carp
            "Index $index out of range (0.." . ($self->{'_length'} - 1) . ")";
        $retval = 0;
    }
    
    return $retval;
}

sub read_record_list {
    my $self    = shift;
    my $count   = shift || 1;
    my $offset  = shift || 0;
    
    my @records = ();
    
    if (   $count <= 0
        or $count > $self->{'_length'}
        or $offset < 0
        or $offset >= $self->{'_length'}
        or $count > ($self->{'_length'} - $offset) ) {
        
        my $last = $offset + $count - 1;
        Carp::carp
            "Range $offset..$last is out of valid range 0.."
            . ($self->{'_length'} - 1);
        return ();
    }
    
    my $pos = $self->{'_header_size'} + $offset * $self->{'_record_size'};
    eval{
        return 0 unless seek $self->{'_fh'}, $pos, 0;
        
        for (1 .. $count) {
            my (%record, $data);
            
            Carp::croak "Cannot read record " . ($count + $offset - 1)
                unless read $self->{'_fh'}, $data, $self->{'_record_size'};
            
            @record{@{$self->{'_record_fields'}}}
                = unpack($self->{'_record_template'}, $data);
            
            push @records, \%record;
        }
    };
    if ($@) {
        Carp::carp $@;
        return ();
    }
    
    return @records;
}


sub write_header {
    my $self = shift;
    
    my $raw_data;
    
    return 0 unless seek $self->{'_fh'}, 0, 0;
    
    $self->_make_default_header unless keys %{$self->{header}};
    
    $raw_data
        = pack(
            $self->{'_header_template'},
            map(
                defined $_ ? $_ : 0,
                @{$self->{'header'}}{@{$self->{'_header_fields'}}}
            )
        );
    
    return print {$self->{'_fh'}} $raw_data;
}


sub write_record {
    my $self    = shift;
    my $index   = shift;
    my $record  = shift;
    
    my $retval = 0;
    
    my $pos
        = $self->{'_header_size'}
        + $index * $self->{'_record_size'};
    
    if ($index >= 0 and $index < $self->{'_length'}) {
        eval {
            $retval = $self->_write_record($pos, $record);
        };
        Carp::carp $@ if $@;
    }
    elsif ($index == $self->{'_length'}) {
        $retval = $self->append_record($pos, $record);
    }
    else {
        Carp::carp
            "Index $index out of range (0.." . ($self->{'_length'} - 1) . ")";
        $retval = 0;
    }
    
    return $retval;
}

sub append_record {
    my $self    = shift;
    my $pos     = shift;
    my $record  = shift;
    
    my $retval;
    
    eval {
        $retval = $self->_write_record($pos, $record);
    };
    if ($@) {
        Carp::carp $@;
    }
    
    return $retval;
}

sub write_record_list {
    my $self            = shift;
    my $index           = shift;
    my $record_list_ref = shift;
    
    my $retval = 0;
    
    my $pos
        = $self->{'_header_size'}
        + $index * $self->{'_record_size'};
    
    if ($index >= 0 and $index <= $self->{'_length'}) {
        eval {
            $retval = $self->_write_record_list($pos, $record_list_ref);
        };
        Carp::carp $@ if $@;
    }
    else {
        Carp::carp
            "Offset $index out of range (0.." . ($self->{'_length'} - 1) . ")";
        $retval = 0;
    }
    
    return $retval;
}



sub _read_record {
    my ($self, $pos, $ret_hash_ref) = @_;
    my $raw_data;
    
    return 0 unless seek $self->{'_fh'}, $pos, 0;
    return 0 unless read $self->{'_fh'}, $raw_data, $self->{'_record_size'};
    
    @{$ret_hash_ref}{@{$self->{'_record_fields'}}}
        = unpack($self->{'_record_template'}, $raw_data);
    
    return 1;
}

sub _make_default_header {
    my $self = shift;
    
    foreach my $field (@{$self->{'_header_fields'}}) {
        $self->{'header'}->{$field} = 0;
    }
}


sub _write_record {
    my ($self, $pos, $record) = @_;
    
    return 0 unless seek $self->{'_fh'}, $pos, 0;
    
    my $raw_data    = '';
    my $retval      = 0;
    
    $raw_data
        = pack(
            $self->{'_record_template'},
            map(
                defined $_ ? $_ : 0,
                @{$record}{@{$self->{'_record_fields'}}}
            )
        );
    
    $retval = print {$self->{'_fh'}} $raw_data;
    
    if ($pos == $self->{'_size'}) {
        $self->{'_size'}    += $self->{'_record_size'};
        $self->{'_length'}  += 1;
    }
    else {
        Carp::carp
            "Failed to write record to file '", $self->{'_filename'}, "'";
    }
    
    return $retval;
}

sub _write_record_list {
    my $self            = shift;
    my $pos             = shift;
    my $record_list_ref = shift;
    
    return 0 unless seek $self->{'_fh'}, $pos, 0;
    
    my $raw_data        = '';
    my $bytes_expected  = 0;
    my $retval          = 0;
    
    foreach my $record (@{$record_list_ref}) {
        $raw_data
            .= pack(
                $self->{'_record_template'},
                map(
                    defined $_ ? $_ : 0,
                    @{$record}{@{$self->{'_record_fields'}}}
                )
            );
        
        $self->{'_length'}++;
        $bytes_expected += $self->{'_record_size'};
        
        ## Block write
        unless ($bytes_expected % $self->{'_block_size'}) {
            $retval = print {$self->{'_fh'}} $raw_data;
            
            unless ($retval) {
                Carp::carp "Failed to write records to file '";
                return 0;
            }
            
            $raw_data = '';
        }
    }
    
    $retval = print {$self->{'_fh'}} $raw_data;
    
    if (($pos + $bytes_expected) >= $self->{'_size'}) {
        $self->{'_size'}
            = $pos + $bytes_expected;
        
        $self->{'_length'}
            = ($self->{'_size'} - $self->{'_header_size'})
            / $self->{'_record_size'}
    }
    else {
        Carp::carp
            "Failed to write records to file '", $self->{'_filename'}, "'";
    }
    
    return $retval;
}




sub import {
    no strict;
    *{caller() . '::bless'}
        = sub {
            my ($atts, $class) = @_;
            
            my $base_atts = {
                'header'                => {},
                '_filename'             => '',
                '_fh'                   => undef,
                '_size'                 => undef,
                '_block_size'           => 4096,
                '_header_template'      => header_template,
                '_header_fields'        => header_fields,
                '_header_size'          => header_size,
                '_record_template'      => record_template,
                '_record_fields'        => record_fields,
                '_record_size'          => record_size,
            };
            
            foreach (@{$base_atts->{'_header_fields'}}) {
                $base_atts->{'header'}->{$_} = 0;
            }
            
            foreach (keys %{$atts->{'header'}}) {
                $base_atts->{'header'}->{$_}
                    = defined $atts->{'header'}->{$_}
                    ? $atts->{'header'}->{$_}
                    : 0;
            }
            
            foreach (keys %{$atts}) {
                next if $_ eq 'header';
                
                $base_atts->{$_}
                    = defined $atts->{$_}
                    ? $atts->{$_}
                    : 0;
            }
            
            bless($base_atts, $class);
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
