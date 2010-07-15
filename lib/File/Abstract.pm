package File::Abstract;

use warnings;
use strict;
use bytes;


our $VERSION    = '1.0000';
our $HEADER_FMT = [];
our $RECORD_FMT = [];


sub header_fmt {
    my $self = shift;
    return $self->{'_hdr_fmt'};
}

sub header_fields {
    my $self = shift;
    return $self->{'_hdr_fields'};
}

sub header_size {
    my $self = shift;
    return $self->{'_hdr_size'};
}

sub record_fmt {
    my $self = shift;
    return $self->{'_rec_fmt'};
}

sub record_fields {
    my $self = shift;
    return $self->{'_rec_fields'};
}

sub record_size {
    my $self = shift;
    return $self->{'_rec_size'};
}

sub meta_info {
    my $self    = shift;
    my $sum     = 0;
    my $output  = '';
    
    $output
        .= sprintf(
            "\n%27s\n\n%20s\t%10s\t%10s\t%10s\t%10s\n",
            'HEADER',
            'FIELD',
            'FORMAT',
            'SIZE (BYTES)',
            'OFFSET DEC',
            'OFFSET HEX',
        );
    
    foreach my $field (@{$HEADER_FMT}) {
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
    
    $output
        .= sprintf(
            "\n%27s\n\n%20s\t%10s\t%10s\t%10s\t%10s\n",
            'RECORD',
            'FIELD',
            'FORMAT',
            'SIZE (BYTES)',
            'OFFSET DEC',
            'OFFSET HEX',
        );
    
    foreach my $field (@{$RECORD_FMT}) {
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


##############################################################################
## Private methods                                                          ##
##############################################################################

##
## Overhides core::bless to automatically merge the private attributes
## provided by File::Abstract with the private attributes created by user.
##
sub import {
    no strict;
    *{caller() . '::bless'}
        = sub {
            my ($atts, $class) = @_;
            
            ## Default private attributes.
            my $base_atts = {
                'header'        => {},
                '_filename'     => '',
                '_fh'           => undef,
                '_size'         => undef,
                '_length'       => undef,
                '_blk_size'     => 4096,
                '_hdr_fmt'      => _header_fmt,
                '_hdr_fields'   => _header_fields,
                '_hdr_size'     => _header_size,
                '_rec_fmt'      => _record_fmt,
                '_rec_fields'   => _record_fields,
                '_rec_size'     => _record_size,
            };
            
            ## Private attributes cleanup.
            foreach my $field ($base_atts->{'_hdr_fields'}) {
                $base_atts->{'header'}->{$field} = 0;
            }
            
            ## Merges user private attributes with my own private attributes.
            ## Skips header for now.
            foreach my $attribute (keys %{$atts}) {
                next if $attribute eq 'header';
                
                $base_atts->{$attribute}
                    = defined $atts->{$attribute}
                    ? $atts->{$attribute}
                    : 0;
            }
            
            ## Merges/copy header values when provided by user.
            if (exists $atts->{'header'}) {
                foreach my $field ($base_atts->{'_hdr_fields'}) {
                    $base_atts->{'header'}->{$field}
                        = exists $atts->{'header'}{$field}
                        ? $atts->{'header'}{$field}
                        : 0;
                }
            }
            
            bless($base_atts, $class);
        }
    ;
    our @EXPORT = qw(bless);
    use strict;
}


##
## Destructor.
##
sub DESTROY {
    my $self = shift;
    
    $self->close;
}


##
## Builds and return the pack-style string of header format.
##
sub _header_fmt {
    return join '', map { values %{$_} } @{$HEADER_FMT};
}


##
## Builds and return the ordered list of header fields.
##
sub _header_fields {
    return map { keys %{$_} } @{$HEADER_FMT};
}


##
## Calculates and return the header size.
##
sub _header_size {
    return core::length pack _header_fmt;
}


##
## Builds and return the pack-style string of record format.
##
sub _record_fmt {
    return join '', map { values %{$_} } @{$RECORD_FMT};
}


##
## Builds ad return the ordered list of record fields.
##
sub _record_fields {
    return map { keys %{$_} } @{$RECORD_FMT};
}


##
## Calculates and return the record size.
##
sub _record_size {
    return core::length pack _record_fmt;
}


# Return to normal character mode.
no bytes;


# End of File::Abstract
42;

#__END__

=head1 NAME

File::Abstract - Easy access to records of binary files

=head1 VERSION

Current stable version is 1.0000

=cut

=head1 SYNOPSIS

This module abstracts the access to records in binary files. You need to
extend it by creating a sub-class which will specify the formats of header and
records using strings according to the documentation of the pack and unpack
functions.

See perldoc -f pack and perldoc -f unpack for more details about the syntaxe
of pack functions.

See sub-section L</"Examples"> for more details about how to properly create
the sub-classes of File::Abstract.

    package Sample;
    
    use parent 'File::Abstract';
    
    $File::Abstract::HEADER_FMT = [
        {'ver'  => 'l'  },  # An integer (4 bytes)
        {'copy' => 'Z40'},  # A null-terminated string (40 bytes)
        {'time' => 'l'  },  # Another integer (4bytes)
    ];
    
    $File::Abstract::RECORD_FMT = [
        {'foo'  => 'd'  },  # A double (8 bytes)
        {'bar'  => 'l'  },  # An integer (4 bytes)
    ];
    
    sub new {
        my $class   = shift;
        my $args    = shift || {};
        my $atts    = {
            'my_specifc_attribite' => 'some value',
        };
        
        return bless($atts, $class);
    }
    
    42;

=head1 DESCRIPTION

This module was created as a tool for ease manipulation of binary files. We
needed read, write and update arbitrary binary files, and sometimes we needed
explore them before, until discover its internal data format.

We begin using directly the functions pack and unpack and soon we understood
that almost all files shared some characteristics, as a fixed size header
(optional) and a list of fixed size records. Both header and records was
composed by fields. Theese fields in turn varied in quantity and sizes, but
also each had its fixed size.

        Header Fields
       /      |      \
    +-------------------+
    | ver | copy | time | ------> Header
    +-------------------+
    | foo 1   |   bar 1 |\
    +-------------------+ \
    | foo 2   |   bar 2 |  \
    +-------------------+   +---> Records
    |  ...    |    ...  |  /
    +-------------------+ /
    | foo N   |   bar N |/
    +-------------------+
       \             /
        Record Fields

We decided then encapsulate the maximum number of shared characteristics into
a generic module and extend it as needed.

This module was created as a tool for ease manipulation of binary files, thus
it was designed to be easily understood and extended, with a well defined and
concise interface. It definitively NO cares about perfornace, the main goal
is ease of use. You was advised!

=head2 HEADER_FMT and RECORD_FMT

HEADER_FMT is an array reference. Each element of this array is a header field
positioned in the exact order that it is into file. Each element is composed
by a hash reference where the key is the field name and the value is a string
in pack-style indicating the type and size of field.

For some file formats there is no header.

RECORD_FMT is an array reference with the same characteristics that
HEADER_FMT.

In some rare cases there are formats that has no records.

=head2 Caution

When retrieving header or record fields, you will get exactly what you have
placed into HEADER_FMT and RECORD_FMT. Pay special attention with typos.

In other hand when you update data, only the fields that match exactly with
those into HEADER_FMT and RECORD_FMT will be updated and all those fields that
weren't explicitly provided will be filled with its default values. Any other
will be discarded. Again, you must pay special attention with typos.

=head2 Examples

=head3 Header without records

Supose we need manipulate a binary file which contains the fields:

=over

=item version

A 32-bit integer.

=item vendor

A string with at most 20 characters.

=item price

A double float point value.

=back

We can resolve this with the code below:

    package OnlyHeader;
    
    use parent 'File::Abstract';
    
    $File::Abstract::HEADER_FMT = [
        {'version'  => 'l'  },  # An integer (4 bytes)
        {'vendor'   => 'Z20'},  # A null-terminated string (20 bytes)
        {'price'    => 'd'  },  # A double float point
    ];
    
    # Constructor
    sub new {
        my $class   = shift;
        my $atts    = {};
        
        return bless($atts, $class);
    }
    
    42;

We can then instantiate a object to read and write values:

    my $file = OnlyHeader->new;
    
    $file->open('filename.dat');
    
    my $data;
    $file->read_header($data);
    say $data->{'vendor'}, ' sold me the version ',
        $data->{'version'},' by only $',
        $data->{'price'}, $/;
    
    $data->write_header({
        'version'   => 175,
        'vendor'    => 'Blabos Inc',
        'price'     => 1234.56,
    });
    
    $file->close;

=head3 Records without header

Eventually we need to some help with a list of unread books:

=over

=item title

A string with at most 40 characters.

=item pages

An integer.

=item return_date

A timestamp.

=back

We can create a package like this:

    package UnreadBooks;
    
    use parent 'File::Abstract';
    
    $File::Abstract::RECORD_FMT = [
        {'title'        => 'Z40'},  # A null-padded string
        {'pages'        => 'l'  },  # An integer (4 bytes)
        {'return_date'  => 'l'  },  # A timestamp (integer with 4 bytes)
    ];
    
    sub new {
        my $class   = shift;
        my $atts    = {};
        
        return bless($atts, $class);
    }

And use it like this:

    my ($file, @records);
    
    $file = UnreadBooks->new;
    $file->open('MyUnreadBooks.bin');
    $file->read(\@records);
    
    say 'Title: ', $_->{'title'} foreach @records; 
    
    $file->close;

=head3 Full header and records

Now supose we have a tiny contact list with my debtors:

Globally:

=over

=item version

An integer.

=item max_contacts

Another integer.

=item total_amount

A double float point.

=back

Each record:

=over

=item name

A string with at most 80 characters.

=item address

Another string with alt most 80 characters.

=item amount

A double float point.

=back

We can do something like this:

    package Contacts;
    
    use parent 'File::Abstract';
    
    $File::Abstract::HEADER_FMT = [
        {'version'      => 'l'  },  # An integer (4 bytes)
        {'max_contacts' => 'l'  },  # Another integer (4bytes)
        {'total_amount' => 'l'  },  # A double float point (8 bytes)
    ];
    
    $File::Abstract::RECORD_FMT = [
        {'name'         => 'Z80'},  # A null-padded string
        {'address'      => 'Z80'},  # Another null-padded string
        {'amount'       => 'd'  },  # A double float point
    ];
    
    sub new {
        my $class   = shift;
        my $atts    = {};
        
        return bless($atts, $class);
    }
    
    42;

And then use it like this:

    my $file = Contacts->new;
    
    $file->open('contacts.raw');
    
    my $data;
    $file->read_header($data);
    
    my $contact = {
        'name'      => 'John Smith',
        'address'   => 'Some Place Street',
        'amount'    => 1234.56,
    }
    
    $data->{'amount'} += $contact->{'amount'};
    
    $file->append([$contact]);
    $file->write_header($header);
    
    $file->close;


=cut

=head1 METHODS

=head2 open($filename)

Open the file specified in $filename for read and write. If the file do not
exist, this method will create a new empty file. Return true or false to
indicate success or fail.

=head2 close()

Close the file currently opened.

=head2 read(\@records,[$count,[$offset]])

Retrieves records from the file currently opened and copy them into @records.
The number of records to retrieve may be specified by parameter $count
(default is all records). An offset to the first record may be informed
by parameter $offset (Default is no offset). The first record has position 0.

=head2 write(\@records,[$offset])

Writes all records from @records into the file currently opened. An offset to
where the first record will be stored may be informed by parameter $offset,
increasing the file if needed (Default is no offset. Must be less than or
equals to file length).

=head2 append(\@records,[$offset])

Appends all records from @records at the end of the file currently opened.

=head2 read_header(\%header)

Extracts the header of the file currently opened and copy it into %header.

=head2 write_header(\%header)

Overwrites the file header with the values into %header. Values whose keys are
not listed in $HEADER_FMT will be discarded.

=head2 header_fmt()

Returns the full pack-style string that represents the header format.

=head2 header_size()

Returns the size in bytes of header.

=head2 header_fields()

Returns an ordered list with all keys (field names) of header.

=head2 record_fmt()

Returns the full pack-style string that represents the record format.

=head2 record_size()

Returns the size in bytes of a single record.

=head2 record_fields()

Returns an ordered list with all keys (field names) of a single record. 

=head2 meta_info()

Returns a formated string with all meta information about sizes, types and
positions of all header and record fields.

=head2 size()

Return the size in bytes of this file.

=head2 length()

Return the number of records of this file. 

=cut







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


sub read_header {
    my $self = shift;
    
    my $raw_data;
    
    return 0 unless seek $self->{'_fh'}, 0, 0;
    return 0 unless read $self->{'_fh'}, $raw_data, $self->{'_header_size'};
    
    @{$self->{'header'}}{@{$self->{'_header_fields'}}}
        = unpack($self->{'_header_template'}, $raw_data);
    
    return 1;
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
        or $offset >= $self->{'_length'} ) {
        
        my $last = $offset + $count - 1;
        Carp::carp
            "Range $offset..$last is out of valid range 0.."
            . ($self->{'_length'} - 1);
        return ();
    }
    
    if (($count + $offset) > $self->{'_length'}) {
        $count = $self->{'_length'} - $offset;
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
    
    $self->_make_default_header unless keys %{$self->{'header'}};
    
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
#    else {
#        Carp::carp
#            "Failed to write record to file '", $self->{'_filename'}, "'";
#    }
    
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
        unless (($bytes_expected % $self->{'_block_size'})) {
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
#    else {
#        Carp::carp
#            "Failed to write records to file '", $self->{'_filename'}, "'";
#    }
    
    return $retval;
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
