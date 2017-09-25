## NAME

WWW::VERNet - Screen-scraping API for VERNet service information.

## SYNOPSIS

This module provides a rudimentary screen-scraping "API" for VERNet service information.

You may use this module to access information about your VERNet services including
live data from end points.

```perl
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

        # If we know our service and endpoint IDs, we can get direct access
        # to the live data we are interested in.
        print "MYORG01234567M endpoint A001 Rx power is "
                . $v->service( 'MYORG01234567M' )->live_data->endpoint( 'A001' )->receive_power;
```	

## METHODS

### new ( %args )

Constructor - accepts the following parameters:

- username

    Mandatory - the username of the VERNet customer account.

- password

    Mandatory - the password of the VERNet customer account.

- timeout

    Optional - the timeout period (in seconds) to wait for HTTP requests to be service.
    If not provided this will default to a value of 180s.

### services ()

Returns an array of [WWW::VERNet::Service](https://metacpan.org/pod/WWW::VERNet::Service) objects representing the provisioned 
VERNet services for your account.

### service ( $service\_id )

Returns a [WWW::VERNet::Service](https://metacpan.org/pod/WWW::VERNet::Service) object representing the service identified by the
__$service\_id__ parameter.

## AUTHOR

Luke Poskitt, `<ltp at cpan.org>`

## BUGS

Please report any bugs or feature requests to `bug-www-vernet at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-VERNet](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-VERNet).  I will be 
notified, and then you'll automatically be notified of progress on your bug as I make changes.

## SEE ALSO

[WWW::VERNet::Service](https://metacpan.org/pod/WWW::VERNet::Service)
[WWW::VERNet::Service::LiveData](https://metacpan.org/pod/WWW::VERNet::Service::LiveData)
[WWW::VERNet::Service::LiveData::EndPoint](https://metacpan.org/pod/WWW::VERNet::Service::LiveData::EndPoint)

## SUPPORT

__Please note__ that this is __not__ an authorised or official API and that it is __not__
endorsed or supported by VERNet.  This module is a convenience provided by community
support only.

You can find documentation for this module with the perldoc command.

    perldoc WWW::VERNet

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-VERNet](http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-VERNet)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/WWW-VERNet](http://annocpan.org/dist/WWW-VERNet)

- CPAN Ratings

    [http://cpanratings.perl.org/d/WWW-VERNet](http://cpanratings.perl.org/d/WWW-VERNet)

- Search CPAN

    [http://search.cpan.org/dist/WWW-VERNet/](http://search.cpan.org/dist/WWW-VERNet/)

## ACKNOWLEDGEMENTS

## LICENSE AND COPYRIGHT

Copyright 2017 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0)

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
