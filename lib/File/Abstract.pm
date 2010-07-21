package File::Abstract;

use warnings;
use strict;
use bytes;

use Carp;
use Data::Dumper;


our $VERSION    = '0.9000';
our $HEADER_FMT = [];
our $RECORD_FMT = [];


sub open {
    my ($self, $filename)   = @_;
    my $status              = 1;
    
    unless (-f $filename) {
        if($status = CORE::open($self->{'_fh'}, '>', $filename)) {
            binmode $self->{'_fh'};
            $self->_write_header;
            CORE::close($self->{'_fh'});
        }
    }
    
    if ($status && CORE::open($self->{'_fh'}, '+<', $filename)) {
        binmode $self->{'_fh'};
        
        $self->{'_size'} = -s $filename;
        
        $self->{'_length'}
            = ($self->{'_size'} - $self->{'_hdr_size'})
            / $self->{'_rec_size'};
        
        $self->{'_filename'} = $filename;
    }
    
    return $status;
}

sub close {
    my $self = shift;
    
    return CORE::close($self->{'_fh'});
}

sub read {
    my ($self, $records, $count, $offset) = @_;
    my $status  = 0;
    
    if (ref $records ne 'ARRAY') {
        Carp::carp('Invalid record list. Must be an Array Reference.');
        return 0;
    }
    
    $count  ||= $self->{'_length'};
    $offset ||= 0;
    
    if ($count < 0 || $offset < 0 || ($offset + $count) > $self->{'_length'}){
        Carp::carp('Record indexes (' . $offset . ' .. '
            . ($offset + $count - 1) . ') out of range (0 .. '
            . ($self->{'_length'} - 1) . ')');
        return 0;
    }
    
    my $pos = $self->{'_hdr_size'} + $offset * $self->{'_rec_size'};
    
    unless (seek($self->{'_fh'}, $pos, 0)) {
        Carp::carp('Cannot seek to position ' . $pos);
        return 0;
    }
    
    my $buffer      = '';
    my $bytes       = $self->{'_rec_size'} * $count;
    my $bread       = 0;
    my $template    = $self->{'_rec_fmt'} x $count;
    
    unless (($bread = read($self->{'_fh'}, $buffer, $bytes)) == $bytes) {
        Carp::carp('Cannot read ' . ($bytes - $bread)
            . ' bytes from file ' . $self->{'_filename'});
        return 0;
    }
    
    my @values  = unpack($template, $buffer);
    my $nfields = scalar(@{$self->{'_rec_fields'}});
    
    unless (scalar(@values) == $count * $nfields) {
        Carp::carp('Error retrieving data from file '
            . $self->{'_filename'});
        return 0;
    }
    else {
        for my $i (0 .. $count - 1) {
            @{$records->[$i]}{@{$self->{'_rec_fields'}}}
                = @values[ ($i * $nfields) .. (($i + 1) * $nfields) ];
        }
        
        return 1;
    }
}

sub write {
    my ($self, $records, $offset) = @_;
    my $status  = 0;
    my $count   = 0;
    
    if (ref $records ne 'ARRAY') {
        Carp::carp('Invalid record list. Must be an Array Reference.');
        return 0;
    }
    
    $count  = @{$records};
    $offset ||= 0;
    
    if ($offset < 0 || $offset > $self->{'_length'}){
        Carp::carp('Record indexes (' . $offset . ' .. '
            . ($offset + $count - 1) . ') out of range (0 .. '
            . ($self->{'_length'} - 1) . ')');
        return 0;
    }
    
    my $pos = $self->{'_hdr_size'} + $offset * $self->{'_rec_size'};
    
    unless (seek($self->{'_fh'}, $pos, 0)) {
        Carp::carp('Cannot seek to position ' . $pos);
        return 0;
    }
    
    my $template
        = $self->{'_rec_fmt'} x $count;
    
    my @values
        = map(
            defined $_ ? $_ : 0,
            map(
                @$_{@{$self->{'_rec_fields'}}},
                @{$records}
            )
        );
    
    $status = print {$self->{'_fh'}} pack($template, @values);
    
    if ($status) {
        $self->{'_length'}
            = $offset + $count;
        $self->{'_size'}
            = $self->{'_hdr_size'}
            + ($self->{'_length'} * $self->{'_rec_size'});
    }
    
    return $status;
}

sub append {
    my ($self, $records);
    
    return $self->write($records, $self->{'_length'});
}

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
## Overhides CORE::bless to automatically merge the private attributes
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
                '_blk'          => '',
                '_hdr_fmt'      => _header_fmt(),
                '_hdr_fields'   => _header_fields(),
                '_hdr_size'     => _header_size(),
                '_rec_fmt'      => _record_fmt(),
                '_rec_fields'   => _record_fields(),
                '_rec_size'     => _record_size(),
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
    
    $self->close if $self->{'_fh'};
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
    return [map { keys %{$_} } @{$HEADER_FMT}];
}


##
## Calculates and return the header size.
##
sub _header_size {
    return CORE::length pack _header_fmt;
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
    return [map { keys %{$_} } @{$RECORD_FMT}];
}


##
## Calculates and return the record size.
##
sub _record_size {
    return CORE::length pack _record_fmt;
}


##
## Writes header into the file currently opened.
##
sub _write_header {
    my $self = shift;
    
    my $data
        = pack(
            $self->{'_hdr_fmt'},
            map(
                defined $_ ? $_ : 0,
                @{$self->{'header'}}{$self->{'_hdr_fields'}}
            )
        );
    
    return print {$self->{'_fh'}} $data;
}


# Return to normal character mode.
no bytes;


# End of File::Abstract
42;

__END__

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

=head2 append(\@records)

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
