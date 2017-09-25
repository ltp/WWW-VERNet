package WWW::VERNet;

use strict;
use warnings;

use HTML::TreeBuilder;
use WWW::Mechanize;
use WWW::VERNet::Service;

our $__DOMAIN = 'support.vernet.net.au';
our $VERSION  = '0.01';

sub new {
	my ( $class, %args ) = @_;

	my $self = bless {}, $class;
	$self->__init( %args );

	return $self
}

sub __init {
	my ( $self, %args ) = @_;

	$args{ username } or die "Mandatory parameter 'username' not provided in constructor.";
	$args{ password } or die "Mandatory parameter 'password' not provided in constructor.";
	$args{ timeout  } ||= 180;

	$self->{ username } = $args{ username };
	$self->{ password } = $args{ password };
	$self->{ __m      } = WWW::Mechanize->new( timeout => $args{ timeout } );
	$self->{ __t      } = HTML::TreeBuilder->new();
	$self->__login;
}

sub service {
	my ( $self, $id ) = @_;

	$self->__set_error( 'No service ID provided to service()' )
		and return 0 unless $id;

	my ( $s ) = grep { $_->id eq $id } $self->services;

	return $s
}

sub services {
	my $self = shift;

	$self->{ __have_services } or $self->__process_services;

	return @{ $self->{ __services } }
}

sub __login {
	my $self = shift;

	my $url = "https://$__DOMAIN/index.php";

	$self->{ __m }->get( $url );

	if ( $self->{ __m }->success
		and $self->{ __m }->title
		and $self->{ __m }->title =~ /VERNet Support Portal/i
	) {
		my %f = ( username => $self->{ username },
			  password => $self->{ password }
		);

		$self->{ __m }->submit_form( with_fields => \%f );

		if ( $self->{ __m }->success
			and $self->{ __m }->res->content =~ /check your profile here/ ) {
			$self->{ __have_session } = 1;
			return 1
		}
	}
	else {
		$self->__set_error(
			error_message	=> "request was unsuccessful: ". $self->{ __m }->response->message,
			is_fatal	=> 1
		)
	}
}

sub __set_error {
        my ( $self, %a ) = @_; 

        $self->{ __have_error } = 1;
        $self->{ __last_error } = $self->{ __error };
        $self->{ __error } = $a{ error_message };
        die $self->{ __error } if ( $a{ is_fatal } )
}

sub __process_services {
	my $self = shift;

	$self->__get_services();

	# Get a list of services by grouping - e.g. <strong>Managed 1Gbe Services</strong>
	my @s = $self->{ __raw }->look_down( _tag => 'strong' );
	# Each service grouping has a <ul> of services for that group
	my @u = $self->{ __raw }->look_down( _tag => 'ul' );
	# There's a ul in the header and an empty "recently updated" service group that we can throw away
	splice( @u, 0, 2 );

	for( my $c = 0; $c < @s ; $c++ ) {
		$self->__process_service_set( $s[ $c ]->as_trimmed_text, $u[ $c ] );
	}
	
	$self->{ __have_services } = 1
}

sub __process_service_set {
	my ( $self, $service, $list ) = @_;

	for my $s ( $list->look_down( _tag => 'li' ) ) {
		push @{ $self->{ __services } }, WWW::VERNet::Service->new( $service, $s, $self )
	}
}

sub __get_services {
	my $self = shift;

	$self->{ __have_session } || $self->__login;

	my $url = "https://$__DOMAIN/myservices.php";
	$self->{ __m }->get( $url );

	if ( $self->{ __m }->success
		and $self->{ __m }->title
		and $self->{ __m }->title =~ /My Services/i
	) {
		$self->{ __raw } = $self->{ __t }->parse_content( $self->{ __m }->res->content );
	}
	else {
		$self->__set_error(
			error_message	=> "unable to retrieve services: ". $self->{ __m }->response->message,
			is_fatal	=> 1
		)
	}
}

1;

__END__

=head2 NAME

WWW::VERNet - Screen-scraping API for VERNet service information.

=head2 SYNOPSIS

This module provides a rudimentary screen-scraping "API" for VERNet service information.

You may use this module to access information about your VERNet services including
live data from end points.

	use WWW::VERNet;

        # Create a new WWW::VERNet object using our customer credentials.

        my $v = WWW::VERNet->new(
                        username => 'email@myorganisation.org',
                        password => 'My%3cretP@ssw0rd!'
                ) or die "Unable to create new WWW::VERNet object: $!\n";

        # For each VERNet service, print out the service ID and description,
        # and for service endpoint, print out the endpoint ID, link and transmit 
        # status, and receive power _if_ available.

        for my $service ( $v->services ) { 
                if ( $service->has_pop_data ) { 
                        print "Service ". $service->id ." (". $service->description .")\n";
                            
                        for my $endpoint ( $service->live_data->endpoints ) { 

                                print " - Endpoint ". $endpoint->eid 
                                        ."\n\tLink OK: ".       $endpoint->link_ok
                                        ."\n\tReceive power: ". $endpoint->receive_power
                                        ."\n\tTransmitting: ".  $endpoint->pop_transmitting
                                        ."\n\n"
                        }   
                            
                        print "\n\n"
                }   
        }

	# e.g. print something like:
	#
	# Service MYORG01234567M (CBD Campus to Remote Campus)
	# - Endpoint A001
	#	Link OK: Yes
	#	Receive power: -5.67 dBm
	#	Transmitting: -5.67 dBm
	#
	# - Endpoint A002
	#	Link OK: Yes
	#	Receive power: -8.096 dBm
	#	Transmitting: -8.096 dBm
	#
	# ...


        # If we know our service and endpoint IDs, we can get direct access
        # to the live data we are interested in.

        print "MYORG01234567M endpoint A001 Rx power is "
                . $v->service( 'MYORG01234567M' )->live_data->endpoint( 'A001' )->receive_power;

	create_service_alert( 'VERNet service MYORG01234567M link state degraded' )
		unless ( $v->service( 'MYORG01234567M' )->live_data->endpoint( 'A001' )->link_ok );

=head2 METHODS

=head3 new ( %args )

Constructor - accepts the following parameters:

=over 4

=item username

Mandatory - the username of the VERNet customer account.

=item password

Mandatory - the password of the VERNet customer account.

=item timeout

Optional - the timeout period (in seconds) to wait for HTTP requests to be service.
If not provided this will default to a value of 180s.

=back

=head3 services ()

Returns an array of L<WWW::VERNet::Service> objects representing the provisioned 
VERNet services for your account.

=head3 service ( $service_id )

Returns a L<WWW::VERNet::Service> object representing the service identified by the
B<$service_id> parameter.

=head2 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head2 BUGS

Please report any bugs or feature requests to C<bug-www-vernet at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-VERNet>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head2 SEE ALSO

L<WWW::VERNet::Service>
L<WWW::VERNet::Service::LiveData>
L<WWW::VERNet::Service::LiveData::EndPoint>

=head2 SUPPORT

B<Please note> that this is B<not> an authorised or official API and that it is B<not>
endorsed or supported by VERNet.  This module is a convenience provided by community
support only.

You can find documentation for this module with the perldoc command.

    perldoc WWW::VERNet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-VERNet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-VERNet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-VERNet>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-VERNet/>

=back

=head2 ACKNOWLEDGEMENTS

=head2 LICENSE AND COPYRIGHT

Copyright 2017 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
