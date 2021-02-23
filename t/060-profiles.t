#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 20;
use_ok('SReview::Video');
use_ok('SReview::Videopipe');
use_ok('SReview::Video::ProfileFactory');

$ENV{SREVIEW_WDIR} = './t';

open CONFIG, '>t/config.pm';
print CONFIG "\$extra_profiles={test => { parent => 'mp4' }};\n1;\n";
close CONFIG;

my $input = SReview::Video->new(url => 't/testvids/bbb.mp4');
ok(defined($input), "Could create the input video");
ok($input->video_codec eq "h264", "video codec of input file is what we expected");

my $profile = SReview::Video::ProfileFactory->create("vp9", $input);
ok(defined($profile), "Could create a VP9 video profile based on the input video");
ok($profile->video_codec ne $input->video_codec, "video codec of profiled file is not the same as the input video codec");

my $output = SReview::Video->new(url => "t/testvids/foo.webm", reference => $profile);
ok(defined($output), "Could create an output video from the profile");
ok($output->video_height == $input->video_height, "The VP9 video has the same height as the input video");

$profile = SReview::Video::ProfileFactory->create('vp8_lq', $input);
ok(defined($profile), "Could create a VP8 LQ profile based on the input video");
unlink($output->url);
$output = SReview::Video->new(url => "t/testvids/foo.webm", reference => $profile);
ok(defined($output), "Could create an output video from the LQ profile");
ok($output->video_height < $input->video_height, "The LQ profile creates smaller videos");
ok($output->video_codec eq "vp8", "A VP8 video has the correct video codec");

my $pipe = SReview::Videopipe->new(inputs => [$input], output => $output);
ok(defined($pipe), "We can create a video pipe from a profiled output file");
$pipe->run();

my $check = SReview::Video->new(url => $output->url);
ok(-f $output->url, "Creating a profiled video creates output");
ok($check->video_height eq $output->video_height, "Creating a scaled video produces smaller output") or diag($check->video_height, " is not the same as ", $output->video_height);

my $copypr = SReview::Video::ProfileFactory->create("copy", $input);
isa_ok($copypr, 'SReview::Video::Profile::Base');

unlink($output->url);

$output = SReview::Video->new(url => 't/testvids/foo.mp4', reference => $copypr);

SReview::Videopipe->new(inputs => [$input], output => $output)->run();

ok(-f $output->url, "copying data by profile creates output");

eval { my $val = SReview::Video::ProfileFactory->create("unknown", $input); };
ok($@, "Creating a nonexisting profile dies");

my $testprof = SReview::Video::ProfileFactory->create("test", $input);
ok(defined($testprof), "Can create a profile from config");

unlink($output->url);
unlink('t/config.pm');
