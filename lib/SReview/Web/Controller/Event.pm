package SReview::Web::Controller::Event;

use Mojo::Base 'Mojolicious::Controller';
use SReview::API::Helpers;
use Data::Dumper;

sub add {
	my $c = shift->openapi->valid_input or return;

	return add_with_json($c, $c->req->json, "events", $c->openapi->spec('/components/schemas/Event/properties'));
}

sub update {
	my $c = shift->openapi->valid_input or return;

	my $eventId = $c->param("eventId");

	my $event = $c->req->json;

	$event->{id} = $eventId;

	return update_with_json($c, $event, "events",  $c->openapi->spec('/components/schemas/Event/properties'));
}

sub delete {
	my $c = shift->openapi->valid_input or return;

	my $eventId = $c->param('eventId');
	my $query = "DELETE FROM events WHERE id = ? RETURNING id";

	return delete_with_query($c, $query, $eventId);
}

sub getById {
	my $c = shift->openapi->valid_input or return;

	my $eventId = $c->param("eventId");
	my $event = db_query($c->dbh, "SELECT row_to_json(events.*) FROM events WHERE id = ?", $eventId);

	if(scalar(@$event) < 1) {
		return $c->render(openapi => {errors => [{message => "not found"}]}, status => 404);
	}

	$c->render(openapi => $event->[0]);
}

sub list {
	my $c = shift->openapi->valid_input or return;

	my $events = db_query($c->dbh, "SELECT row_to_json(events.*) FROM events");

	$c->render(openapi => $events);
}

sub overview {
	my $c = shift->openapi->valid_input or return;

	my $eventId = $c->param("eventId");
	my $query;
	if($c->srconfig->get("anonreviews")) {
		$query = "SELECT json_build_object('reviewurl', '/r/' || nonce, 'name', name, 'speakers', speakers, 'room', room, 'starttime', starttime::timestamp, 'endtime', endtime::timestamp, 'state', state, 'progress', progress) FROM talk_list WHERE eventid = ? AND state IS NOT NULL ORDER BY state, progress, room, starttime";
	} else {
		$query = "SELECT json_build_object('name', name, 'speakers', speakers, 'room', room, 'starttime', starttime::timestamp, 'endtime', endtime::timestamp, 'state', state, 'progress', progress) FROM talk_list WHERE eventid = ? AND state IS NOT NULL ORDER BY state, progress, room, starttime";
	}

	my $res = db_query($c->dbh, $query, $eventId);

	if(scalar(@$res) < 1) {
		return $c->render(openapi => {errors => [{message => "not found"}]}, status => 404);
	}

	$c->render(openapi => db_query($c->dbh, $query, $eventId));
}

1;
