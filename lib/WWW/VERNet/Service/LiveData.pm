package WWW::VERNet::Service::LiveData;

use strict;
use warnings;

use DateTime;
use WWW::VERNet::Service::LiveData::EndPoint;

our @ATTR = qw( datestamp ends );
our %d = ( sun => 0, mon => 1, tue => 2, wed => 3, thu => 4, fri => 5, sat => 6 );
our %m = ( jan => 0, feb => 1, mar => 2, apr => 3, may => 4, jun => 5, jul => 6,
		aug => 7, sep => 8, oct => 9, nov => 10, dec => 12 );

sub new {
	my ( $class, $s ) = @_;

	my $self = bless {}, $class;
	$self->__init( $s );

	return $self
}

sub endpoint_ids {
	my $self = shift;

	return map { $_->eid } @{ $self->{ __endpoints } }
}

sub endpoints {
	my $self = shift;

	return @{ $self->{ __endpoints } }
}

sub endpoint {
	my ( $self, $id ) = @_;

	my ( $e ) = grep { $_->eid eq $id } @{ $self->{ __endpoints } };
	
	return $e
}

sub __init {
	my ( $self, $s ) = @_;

	# Extract the timestamp
	( $self->{ timestamp_raw } = $s->look_down( _tag => 'h3' )->as_trimmed_text ) =~ s/^.*: //;

	$self->__extract_timestamp;

	$self->__extract_live_data( $s->look_down( _tag => 'fieldset' ) );
}

sub __extract_live_data {
	my ( $self, $d ) = @_;

	$self->__extract_endpoints( $d );

	$self->{ d } = $d;
}

sub __extract_endpoints {
	my ( $self, $d ) = @_;

	my @ep = split /<u>/, $d->as_HTML;
	# Throw away the "Live PoP Data" header
	shift @ep;

	map {
		push @{ $self->{ __endpoints } }, 
			WWW::VERNet::Service::LiveData::EndPoint->new( __extract_endpoint_data( $_ ) )
	} @ep;
}

sub __extract_endpoint_data {
	my $ep = shift;

	my %ep;
	# Split into "fields" and remove HTML tags
	my @f = map { s|<.+?>||g; $_ } ( split /<strong>/, $ep );

	# Endpoint end ID
	$ep{ eid } = shift @f;
	$ep{ eid } =~ s/^From //;
	$ep{ eid } =~ s/ End://;

	# Extract endpoint field names and values
	for my $f ( @f ) {
		my( $var, $val ) = split /[:?] /, $f;
		$var =~ s/ /_/g;
		$var = lc( $var );
		$ep{ $var } = $val
	}

	return %ep
}

sub __extract_timestamp {
	my $self = shift;

	# Extract the live data timestamp and use it to create a
	# DateTime object to allow for calculation, manipulation, etc.
	my ( $wd, $d, $o, $m, $y, $t, $me ) = split / /, $self->{ timestamp_raw };

	$wd = $d{ substr lc( $wd ), 0, 3 };
	( $d ) = $d =~ /(\d+)/;
	$m = $m{ substr lc( $m ), 0, 3 };
	my ( $h, $mm, $s ) = split /:/, $t;
	$h += 12 if ( $me eq 'PM' and $h > 12 );

	$self->{ timestamp } = DateTime->new(
		year	=> $y,
		month	=> $m,
		day	=> $d,
		hour	=> $h,
		minute	=> $mm,
		second	=> $s
	);
}

1;

__END__

=head2 NAME 

WWW::VERNet::Service::LiveData - Utility class for representing VERNet services PoP data.

=head2 METHODS

=head3 endpoints ()

Returns an array of L<WWW::VERNet::Service::LiveData::EndPoint> objects representing the
PoP end points.

=head3 endpoint ( $endpoint_id )

Returns a <WWW::VERNet::Service::LiveData::Endpoint> object representing the PoP end point
identified by the provided end point ID (e.g. A001).

=head2 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head2 SEE ALSO

L<WWW::VERNet>
L<WWW::VERNet::Service>
L<WWW::VERNet::Service::LiveData::EndPoint>
