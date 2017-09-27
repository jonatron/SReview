package SReview::Videopipe;

use Mojo::JSON qw(decode_json);
use Moose;

has 'inputs' => (
	traits => ['Array'],
	is => 'ro',
	isa => 'ArrayRef[SReview::Video]',
	default => sub { [] },
	clearer => 'clear_inputs',
	handles => {
		add_input => 'push',
	},
);

has 'output' => (
	is => 'rw',
	isa => 'SReview::Video',
	required => 1,
);

has 'map' => (
	traits => ['Array'],
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {[]},
	clearer => 'clear_map',
	handles => {
		add_map => 'push',
	},
);

has 'vcopy' => (
	isa => 'Bool',
	is => 'rw',
	default => 1,
);

has 'acopy' => (
	isa => 'Bool',
	is => 'rw',
	default => 1,
);

has 'multipass' => (
	isa => 'Bool',
	is => 'rw',
	default => 0,
);

has 'progress' => (
	isa => 'CodeRef',
	is => 'ro',
	predicate => 'has_progress',
);

sub run_progress {
	my $self = shift;
	my $command = shift;
	my ($in, $out, $err);
	my $running;
	my @lines;
	my $old_perc = 0;
	my %vals;

	my $length = $self->inputs->[0]->duration * 1000000;
	shift @$command;
	unshift @$command, ('ffmpeg', '-progress', '/dev/stdout');
	open my $ffmpeg, "-|", @{$command};
	while(<$ffmpeg>) {
		/^(\w+)=(.*)$/;
		$vals{$1} = $2;
		if($1 eq 'progress') {
			my $perc = int($vals{out_time_ms} / $length * 100);
			if($vals{progress} eq 'end') {
				$perc = 100;
			}
			if($perc != $old_perc) {
				$old_perc = $perc;
				&{$self->progress}($perc);
			}
		}
	}
}

sub run {
	my $self = shift;
	my $pass;
	my @attrs = (
		'video_codec' => 'vcopy',
		'video_size' => 'vcopy',
		'video_width' => 'vcopy',
		'video_height' => 'vcopy',
		'video_bitrate' => 'vcopy',
		'video_framerate' => 'vcopy',
		'pix_fmt' => 'vcopy',
		'audio_codec' => 'acopy',
		'audio_bitrate' => 'acopy',
		'audio_samplerate' => 'acopy',
	);
	my @video_attrs = ('video_codec', 'video_size', 'video_width', 'video_height', 'video_bitrate', 'video_framerate', 'pix_fmt');
	my @audio_attrs = ('audio_codec', 'audio_bitrate', 'audio_samplerate');

	for($pass = 1; $pass <= ($self->multipass ? 2 : 1); $pass++) {
		my @command = ("ffmpeg", "-loglevel", "warning", "-y");
		foreach my $input(@{$self->inputs}) {
			if($self->multipass) {
				$input->pass($pass);
				$self->output->pass($pass);
			}
			while(scalar(@attrs) > 0) {
				my $attr = shift @attrs;
				my $target = shift @attrs;
				next unless $self->meta->get_attribute($target)->get_value($self);
				my $oval = $self->output->meta->get_attribute($attr)->get_value($self->output);
				my $ival = $input->meta->get_attribute($attr)->get_value($input);
				if(defined($oval) && $ival ne $oval) {
					$self->meta->get_attribute($target)->set_value($self, 0);
				}
			}
			push @command, $input->readopts($self->output);
		}
		foreach my $map(@{$self->map}) {
			push @command, "-map", $map;
		}
		if($self->vcopy) {
			push @command, ('-c:v', 'copy');
		}
		if($self->acopy) {
			push @command, ('-c:a', 'copy');
		}
		push @command, $self->output->writeopts($self);

		print "Running: '" . join ("' '", @command) . "'\n";
		if($self->has_progress) {
			$self->run_progress(\@command);
		} else {
			system(@command);
		}
	}
	foreach my $input(@{$self->inputs}) {
		$input->clear_pass;
	}
	$self->output->clear_pass;
}

no Moose;

1;
