package WWW::VERNet::Service;

use strict;
use warnings;

use Scalar::Util qw( weaken );
use WWW::VERNet::Service::LiveData;

our @ATTR = qw( sid id description ps_link has_ps has_pop_data type );

{
	no strict 'refs';

	for my $attr ( @ATTR ) {
		*{ __PACKAGE__ ."::$attr" } = sub {
			my $self = shift;
			return $self->{ $attr }
		}
	}
}

sub new {
	my ( $class, $t, $s, $v ) = @_;

	my $self = bless {}, $class;
	$self->__init( $t, $s, $v );

	return $self
}

sub __init {
	my ( $self, $t, $s, $v ) = @_;

	weaken ( $self->{ __v }	= $v );
	$self->{ type }		= $t;
	$self->{ description }	= $s->as_trimmed_text;
	$self->{ description }	=~ s/^\s*\S+\s*//;

	( $self->{ sid }, $self->{ ps_link } ) 
				= $s->look_down( _tag => 'a' );

	$self->{ id }		= $self->{ sid }->as_trimmed_text;

	( $self->{ sid }	= $self->{ sid }->attr( 'href' ) ) 
				=~ s/^.*sid=//;
	
	if ( defined $self->{ ps_link } ) {
		$self->{ ps_link }	= $WWW::VERNet::__DOMAIN . $self->{ ps_link }->attr( 'href' );
		$self->{ has_ps }	= 1
	}

	if ( $s->look_down( _tag => 'img', alt => qr/Live data .* is available/ ) ) {
		$self->{ has_pop_data }	= 1
	}
}

sub live_data {
	my $self = shift;
	
	return $self->__live_data;
}

sub __live_data {
	my $self = shift;

	my $url = "https://$WWW::VERNet::__DOMAIN/viewservice.php?sid=$self->{ sid }";

	$self->{ __v }->{ __m }->get( $url );
	
        if ( $self->{ __v }->{ __m }->success
                and $self->{ __v }->{ __m }->title
                and $self->{ __v }->{ __m }->title =~ /Service Details/i
        ) {
                my $l = WWW::VERNet::Service::LiveData->new(
			$self->{ __t } = HTML::TreeBuilder->new_from_content( $self->{ __v }->{ __m }->res->content )
		);
		return $l
		
        }
        else {
                $self->{ __v }->__set_error(
                        error_message   => "unable to retrieve services: ". $self->{ __v }->{ __m }->response->message,
                        is_fatal        => 1
                )		
        }

}

1;
__END__

=head2 NAME 

WWW::VERNet::Service - Utility class for representing VERNet provisioned services.

=head2 METHODS

=head3 id ()

Returns the VERNet service ID.

=head3 description ()

Returns the VERNet service description.

=head3 type ()

Returns the service type - e.g. "Managed 10G".

=head3 has_ps ()

Returns a boolean value indicating if a provisioning statement is available for this service.

=head3 ps_link ()

Returns a the URL of the provisioning statement if a provisioning statement is available.

=head3 has_pop_data ()

Returns a boolean value indicating if live PoP data is available for this service.

=head live_data ()

Returns a L<WWW::VERNet::Service::LiveData> object exposing access to the live data available
from the VERNet PoP if PoP data is available.

=head2 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head2 SEE ALSO

L<WWW::VERNet>
L<WWW::VERNet::Service::LiveData>
L<WWW::VERNet::Service::LiveData::EndPoint>
