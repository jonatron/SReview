package SReview::Schedule::WithParent::ParentedSpeaker;

use Moose;
use SReview::Schedule::Base;

extends 'SReview::Schedule::Base::Speaker';

has 'parent' => (
	is => 'ro',
	isa => 'SReview::Schedule::Base::Speaker',
	required => 1,
);

sub _load_name {
	return shift->parent->name;
}

sub _load_email {
	return shift->parent->email;
}

sub _load_upstreamid {
	return shift->parent->upstreamid;
}

no Moose;

package SReview::Schedule::WithParent::ParentedRoom;

use Moose;

extends 'SReview::Schedule::Base::Room';

has 'parent' => (
	is => 'ro',
	isa => 'SReview::Schedule::Base::Room',
	required => 1,
);

sub _load_name {
	return shift->parent->name;
}

sub _load_altname {
	return shift->parent->altname;
}

sub _load_outputname {
	return shift->parent->outputname;
}

no Moose;

package SReview::Schedule::WithParent::ParentedTrack;

use Moose;

extends 'SReview::Schedule::Base::Track';

has 'parent' => (
	is => 'ro',
	isa => 'SReview::Schedule::Base::Track',
	required => 1,
);

sub _load_name {
	return shift->parent->name;
}

sub _load_email {
	return shift->parent->email;
}

sub _load_upstreamid {
	return shift->parent->upstreamid;
}

no Moose;

package SReview::Schedule::WithParent::ParentedTalk;

use Moose;
use SReview::Schedule::Base;

extends 'SReview::Schedule::Base::Talk';

has 'parent' => (
	is => 'ro',
	isa => 'SReview::Schedule::Base::Talk',
	required => 1,
);

has 'speaker_type' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_load_speaker_type',
);

sub _load_speaker_type {
	return 'SReview::Schedule::WithParent::ParentedSpeaker';
}

has 'speaker_opts' => (
	is => 'ro',
	isa => 'HashRef[Any]',
	default => sub { {} },
);

has 'track_type' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_load_track_type',
);

sub _load_track_type {
	return 'SReview::Schedule::WithParent::ParentedTrack';
}

has 'track_opts' => (
	is => 'ro',
	isa => 'HashRef[Any]',
	default => sub { {} },
);

has 'room_type' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_load_room_type',
);

sub _load_room_type {
	return 'SReview::Schedule::WithParent::ParentedRoom';
}

has 'room_opts' => (
	is => 'ro',
	isa => 'HashRef[Any]',
	default => sub { {} },
);

sub _load_room {
	my $self = shift;
	my $type = $self->room_type;
	return $type->new(parent => $self->parent->room, %{$self->room_opts});
}

sub _load_slug {
	return shift->parent->slug;
}

sub _load_starttime {
	return shift->parent->starttime;
}

sub _load_endtime {
	return shift->parent->endtime;
}

sub _load_length {
	return shift->parent->length;
}

sub _load_title {
	return shift->parent->title;
}

sub _load_upstreamid {
	return shift->parent->upstreamid;
}

sub _load_subtitle {
	return shift->parent->subtitle;
}

sub _load_track {
	my $self = shift;
	my $type = $self->track_type;
	return $type->new(parent => $self->parent->track, %{$self->track_opts});
}

sub _load_description {
	return shift->parent->description
}

sub _load_flags {
	return shift->parent->flags;
}

sub _load_speakers {
	my $self = shift;
	my $rv = [];
	my $type = $self->speaker_type;
	foreach my $speaker(@{$self->parent->speakers}) {
		push @$rv, "$type"->new(parent => $speaker, %{$self->speaker_opts});
	}
	return $rv;
}

sub _load_filtered {
	return shift->parent->filtered;
}

no Moose;

package SReview::Schedule::WithParent::ParentedEvent;

use Moose;
use SReview::Schedule::Base;

extends 'SReview::Schedule::Base::Event';

has 'parent' => (
	is => 'ro',
	isa => 'SReview::Schedule::Base::Event',
	required => 1,
);

has 'talk_type' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_load_talk_type',
);

has 'talk_opts' => (
	is => 'ro',
	isa => 'HashRef[Any]',
	default => sub { {} },
);

sub _load_talk_type {
	return "SReview::Schedule::WithParent::ParentedTalk";
}

sub _load_talks {
	my $self = shift;
	my $rv = [];
	my $type = $self->talk_type;
	my $opts = $self->talk_opts;
	foreach my $talk(@{$self->parent->talks}) {
		push @$rv, $type->new(parent => $talk, %$opts);
	}
	return $rv;
}

sub _load_name {
	return shift->parent->name;
}

no Moose;

package SReview::Schedule::WithParent;

use Moose;

extends 'SReview::Schedule::Base';

has 'event_type' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_load_event_type',
);

has 'event_opts' => (
	is => 'ro',
	isa => 'HashRef[Any]',
	default => sub { {} },
);

has 'base_type' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_load_base_type',
);

has 'base_options' => (
	is => 'ro',
	isa => 'HashRef[Any]',
);

sub _load_events {
	my $self = shift;
	my $event_type = $self->event_type;
	my $base_type = "SReview::Schedule::" . ucfirst($self->base_type);
	eval "require $base_type" or die $!;
	my $event_opts = $self->event_opts;
	my $rv = [];
	foreach my $event(@{$base_type->new(url => $self->url)->events}) {
		push @$rv, $event_type->new(parent => $event, %$event_opts);
	}
	return $rv;
}

no Moose;

1;
