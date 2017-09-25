package WWW::VERNet::Service::LiveData::EndPoint;

use strict;
use warnings;

our @ATTR = qw( eid receive_power pop_transmitting link_ok loopback );

{
	no strict 'refs';

	for my $attr ( @ATTR ) {
		*{ __PACKAGE__ . "::$attr" } = sub {
			my $self = shift;
			return $self->{ $attr }
		}
	}
}

sub new {
	my ( $class, %args ) = @_;
	
	my $self = bless {}, $class;
	$self->__init( %args );

	return $self
}

sub __init {
	my ( $self, %args ) = @_;

	for my $attr ( @ATTR ) {
		$self->{ $attr } = $args{ $attr }
	}
}

1;

__END__

=head2 NAME 

WWW::VERNet::Service::LiveData::EndPoint - Utility class for representing VERNet services 
PoP end points.

=head2 METHODS

=head3 eid ()

Returns the end point ID.

=head3 receive_power ()

Returns the end point reported receive power.

=head3 pop_transmitting ()

Returns the end point PoP transmitting value.

=head3 link_ok ()

Returns the end point Link OK status.

=head3 loopback ()

Returns the end point loopback status.

=head2 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head2 SEE ALSO

L<WWW::VERNet>
L<WWW::VERNet::Service>
L<WWW::VERNet::Service::LiveData>

