#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;
use_ok('SReview::Video');
use_ok('SReview::Videopipe');

my $input = SReview::Video->new(url => 't/testvids/bbb.mp4');
isa_ok($input, 'SReview::Video');
my $output = SReview::Video->new(url => 't/testvids/1sec.webm', video_codec => 'libvpx-vp9', audio_codec => 'libopus', duration => 1, audio_bitrate => '128k');
isa_ok($output, 'SReview::Video');
my $pipe = SReview::Videopipe->new(inputs => [$input], output => $output, vcopy => 0, acopy => 0);
isa_ok($pipe, 'SReview::Videopipe');
$pipe->run;
ok(-f $output->url, 'The output file exists');
my $check = SReview::Video->new(url => $output->url);
isa_ok($check, 'SReview::Video');
ok($check->video_size eq $input->video_size, 'The video was generated with the correct output size');
ok($check->video_codec eq 'vp9', 'The video is encoded using VP9');
ok($check->audio_codec eq 'opus', 'The audio is encoded using Opus');
unlink($output->url);
