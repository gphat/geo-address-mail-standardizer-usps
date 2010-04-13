package Geo::Address::Mail::Standardizer::USPS;
use Moose;

with 'Geo::Address::Mail::Standardizer';

our $VERSION = '0.01';

use Geo::Address::Mail::Standardizer::Results;

# Defined in C2 - "Secondary Unit Designators"
my %range_designators = (
    APARTMENT   => 'APT',
    BUILDING    => 'BLDG',
    DEPARTMENT  => 'DEPT',
    FLOOR       => 'FL',
    FLR         => 'FL',
    HANGAR      => 'HNGR',
    KEY         => 'KEY',
    LOT         => 'LOT',
    PIER        => 'PIER',
    ROOM        => 'RM',
    SLIP        => 'SLIP',
    SPACE       => 'SPC',
    STOP        => 'STOP',
    SUITE       => 'STE',
    TRAILER     => 'TRLR',
    UNIT        => 'UNIT'
);

# Defined in C2 - "Secondary Unit Designators", does not require secondary
# RANGE to follow.
my %designators = (
    BASEMENT    => 'BSMT',
    FRONT       => 'FRNT',
    LOBBY       => 'LBBY',
    LOWER       => 'LOWR',
    OFFICE      => 'OFC',
    PENTHOUSE   => 'PH',
    REAR        => 'REAR',
    SIDE        => 'SIDE',
);

sub standardize {
    my ($self, $address) = @_;

    my $newaddr = $address->clone;
    my $results = Geo::Address::Mail::Standardizer::Results->new(
        standardized_address => $newaddr
    );

    $self->_uppercase($newaddr, $results);
    $self->_remove_punctuation($newaddr, $results);
    $self->_replace_designators($newaddr, $results);

    return $results;
}

# Make everything uppercase 212
sub _uppercase {
    my ($self, $addr, $results) = @_;

    # We won't mark anything as changed here because I personally don't think
    # the user cares if uppercasing is the only change.
    my @fields = qw(company name street street2 city state state country);
    foreach my $field (@fields) {
        $addr->$field(uc($addr->$field));
    }
}

# Remove punctuation, none is really needed.  222
sub _remove_punctuation {
    my ($self, $addr, $results) = @_;

    my @fields = qw(company name street street2 city state state country);
    foreach my $field (@fields) {
        my $val = $addr->$field;
        next unless defined($val);

        if($val ne $addr->$field) {
            $results->set_changed($field, $val);
            $addr->$field($val);
        }
    }
}

# Replace Secondary Address Unit Designators, 213
# Uses Designators from 213.1 and Appendix C2
sub _replace_designators {
    my ($self, $addr, $results) = @_;

    my @fields = qw(street street2);
    foreach my $field (@fields) {
        my $val = $addr->$field;
        next unless defined($val);

        foreach my $rd (keys(%range_designators)) {

            if($val =~ /$rd/) {
                my $repl = $range_designators{$rd};
                $val =~ s/\b$rd\b/$repl/g;
                $results->set_changed($field, $val);
                $addr->$field($val);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Geo::Address::Mail::Standardizer::USPS - Offline implementation of USPS Postal Addressing Standards

=head1 SYNOPSIS

This module provides an offline implementation of the USPS Publication 28 - 
Postal Addressing Standards as defined by
L<http://pe.usps.com/text/pub28/welcome.htm>.

    my $std = Geo::Address::Mail::Standardizer::USPS->new;

    my $address = Geo::Address::Mail::US->new(
        name => 'Test Testerson',
        street => '123 Test Street',
        street2 => 'Apartment #2',
        city => 'Testville',
        state => 'TN',
        postal_code => '12345'
    );

    my $res = $std->standardize($address);
    my $corr = $res->standardized_address;

=head1 WARNING

This module is not a complete implementation of USPS Publication 28.  It
intends to be, but that will probably take a while.  In the meantime it
may be useful for testing or for pseudo-standardizaton.

=head1 USPS Postal Address Standards Implemented

This module currently handles the following sections from Publication 28:

=over 5

=item I<212 Format>

L<http://pe.usps.com/text/pub28/pub28c2_002.htm>

=item I<213.1 Common Designators>

L<http://pe.usps.com/text/pub28/pub28c2_003.htm>

Also, Appendix C2

L<http://pe.usps.com/text/pub28/pub28apc_003.htm#ep538629>

=item I<222 Punctuation>

Punctuation is removed from all fields except C<postal_code>.  Note that
this isn't really kosher when using address ranges...

L<http://pe.usps.com/text/pub28/pub28c2_007.htm>

=back

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

