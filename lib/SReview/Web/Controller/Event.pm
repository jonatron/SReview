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
	my $event = db_query($c->dbh, "SELECT events.* FROM events WHERE id = ?", $eventId);

	if(scalar(@$event) < 1) {
		return $c->render(openapi => {errors => [{message => "not found"}]}, status => 404);
	}

	$c->render(openapi => $event->[0]);
}

sub list {
	my $c = shift->openapi->valid_input or return;

	my $events = db_query($c->dbh, "SELECT events.* FROM events");

	$c->render(openapi => $events);
}

sub overview {
	my $c = shift->openapi->valid_input or return;

	my $eventId = $c->param("eventId");
	my $query;
	my $st = $c->dbh->prepare("SELECT id FROM events WHERE id = ?");
	$st->execute($eventId);
	if($st->rows < 1) {
		return $c->render(openapi => {errors => [{message => "not found"}]}, status => 404);
	}

	if($c->srconfig->get("anonreviews")) {
		$query = "SELECT '/r/' || nonce AS reviewurl, name, speakers, room, starttime::timestamp, endtime::timestamp, state, progress FROM talk_list WHERE eventid = ? AND state IS NOT NULL ORDER BY state, progress, room, starttime";
	} else {
		$query = "SELECT name, speakers, room, starttime::timestamp, endtime::timestamp, state, progress FROM talk_list WHERE eventid = ? AND state IS NOT NULL ORDER BY state, progress, room, starttime";
	}

	my $res = db_query($c->dbh, $query, $eventId);

	$c->render(openapi => $res);
}

sub talksByState {
	my $c = shift->openapi->valid_input or return;

	my $eventId = $c->param("eventId");
	my $state = SReview::Talk::State->new($c->param("state"));

	my $st = $c->dbh->prepare("SELECT MIN(starttime::date) AS start, MAX(endtime::date) AS end, title FROM events WHERE id = ?");
	$st->execute($eventId);
	if($st->rows < 1) {
		return $c->render(openapi => {errors => [{message => "not found"}]},status => 404);
	}
	my $row = $st->fetchrow_hashref;
	my $rv = {};
	my $have_default = 0;
	my %formats;
	$rv->{conference}{title} = $row->{title};
	$rv->{conference}{date} = [ $row->{start}, $row->{end} ];
	$st = $c->dbh->prepare("SELECT filename FROM raw_files JOIN talks ON raw_files.room = talks.room WHERE talks.event = ? LIMIT 1");
	$st->execute($eventId);
	if($st->rows < 1) {
		$c->render(openapi => {errors => [{message => "can't detect video files yet"}]},status => 400);
		return;
	}
	$row = $st->fetchrow_hashref;
	my $vid = SReview::Video->new(url => $row->{filename});
	foreach my $format(@{$c->srconfig->get("output_profiles")}) {
		my $nf;
		$c->app->log->debug("profile $format");
		my $prof = SReview::Video::rofileFactory->create($format, $vid);
		if(!$have_default) {
			$nf = 'default';
			$have_default = 1;
		} else {
			$nf = $format;
		}
		$rv->{conference}{video_formats}{$nf} = { vcodec => $prof->video_codec, acodec => $prof->audio_codec, resolution => $prof->video_size, bitrate => $prof->video_bitrate . "k" };
		$formats{$nf} = $prof;
	}
	$rv->videos = [];
	$st = $c->dbh->prepare("SELECT id, title, subtitle, description, starttime, starttime::date AS date, to_char(starttime, 'yyyy') AS year, endtime, rooms.name as room, rooms.outputname as rooms_output, upstreamid, events.name as event, slug FROM talks JOIN rooms on talks.room = rooms.id JOIN events on talks.event = events.id WHERE state=? AND event=?");
	$st->execute($state, $eventId);
	my $speakers = $c->dbh->prepare("SELECT name FROM speakers JOIN speakerslist ON speakers.id = speakerlist.speaker WHERE speakerlist.talk = ?");
	if($st->rows < 1) {
		$c->render(openapi => $rv);
	}
	my $mt = Mojo::Template->new;
	$mt->vars(1);
	while(my $row = $st->fetchrow_hashref()) {
		my $video = {};
		$speakers->execute($row->{id});
		my $subtitle = defined($row->{subtitle}) ? ": " . $row->{subtitle} : "";
		$video->{title} = $row->{title} . $subtitle;
		$video->{speakers} = [];
		while(my $srow = $speakers->fetchrow_hashref()) {
			push @{$video->{speakers}}, $srow->{name};
		}
		$video->{description} = $row->{description};
		$video->{start} = $row->{starttime};
		$video->{end} = $row->{endtime};
		$video->{room} = $row->{room};
		$video->{eventid} = $row->{upstreamid};
		my @outputdirs;
		foreach my $subdir(@{$c->srconfig->get("output_subdirs")}) {
			push @outputdirs, $row->{$subdir};
		}
		my $outputdir = join('/', @outputdirs);
		if($state > 'transcoding' && $state <= 'done') {
			if(defined($c->srconfig->get('eventurl_format'))) {
				$video->{details_url} = $mt->render($c->srconfig->get('eventurl_format'), {
					slug => $row->{slug},
					room => $row->{room},
					date => $row->{date},
					event => $row->{event},
					upstreamid => $row->{upstreamid},
					year => $row->{year} });
				chomp $video->{details_url};
			}
			$video->{video} = join('/',$outputdir, $row->{slug}) . "." . $formats{default}->exten;
		} elsif($state > 'cutting' && $state < 'preview') {
			$video->{video} = join('/',$eventId, $row->{date}, substr($row->{room}, 0, 1), $row->{slug} . ".mkv");
		}
		push @{$rv->{videos}}, $video;
	}
	$c->render(openapi => $rv);
}

1;
