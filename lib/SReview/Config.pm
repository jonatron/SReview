use strict;
use warnings;

package SReview::Config;

use Data::Dumper;
use Carp;
use Mojo::JSON qw/decode_json encode_json/;

=head1 NAME

SReview::Config - Self-reproducing and self-documenting configuration file system

=head1 SYNOPSIS

  use SReview::Config;

  my $config = SReview::Config->new('/etc/sreview/config.pm');
  $config->define('name', 'The name of this element', 'default');
  ...
  print "You configured " . $config->get('name') . " as the name\n";
  print "Full configuration: \n" . $config->dump;

=head1 DESCRIPTION

SReview::Config is a class to easily manage self-reproducing and
self-documenting configuration. You create an SReview::Config object,
populate it with possible configuration values, and then retrieve them.

=head1 METHODS

=head2 SReview::Config->new('path/to/filename');

Create a new SReview::Config object.

=cut

sub new {
	my $self = {defs => {}};
	my $class = shift;

	bless $self, $class;

	my $cfile = shift;

	if (! -f $cfile) {
		unless (grep /^SREVIEW_/, keys(%ENV)) {
			carp "Warning: could not find configuration file $cfile, falling back to defaults";
		}
	} else {
		package SReview::Config::_private;
		use Carp;
		my $rc = do($cfile);
		if($@) {
			croak "could not compile config file $cfile: $@";
		} elsif(!defined($rc)) {
			carp "could not read config file $cfile. Falling back to defaults.";
		} elsif(!$rc) {
			croak "could not process config file $cfile";
		}
	}
	return $self;
};

=head2 $config->define(name, doc, default)

Define a new configuration value. Not legal after C<get> has already
been called.

Name should be the name of the configuration value. Apart from the fact
that it should not have a sigil, it should be a valid name for a perl
scalar variable.

=cut

sub define {
	my $self = shift;
	my $name = shift;
	my $doc = shift;
	my $default = shift;
	if(exists($self->{fixed})) {
		croak "Tried to define a new value after a value has already been requested. This is not allowed!";
	}
	$self->{defs}{$name}{doc} = $doc;
	$self->{defs}{$name}{default} = $default;
	my $NAME = uc $name;
	if(exists($ENV{"SREVIEW_${NAME}"})) {
		$self->set($name => decode_json($ENV{"SREVIEW_${NAME}"}));
	}
};

sub define_computed {
	my $self = shift;
	my $name = shift;
	my $sub = shift;

	$self->{defs}{$name}{sub} = $sub;
}

=head2 $config->get('name')

Return the value of the given configuration item. Also finalizes the
definitions of this configuration file; that is, once this method has
been called, the C<define> method above will croak.

The returned value will either be the default value configured at
C<define> time, the value configured in the configuration file, or the
value set in the environment variable C<SREVIEW_I<name> >, where I<name>
is the upper-case version of the name of the configuration item.

=cut

sub get {
	my $self = shift;
	my $name = shift;
	my $talk = shift;

	if(!exists($self->{defs}{$name})) {
		die "e: definition for config file item $name does not exist!";
	}

	if(exists($self->{defs}{$name}{sub})) {
		return &{$self->{defs}{$name}{sub}}($self, $talk);
	}
	$self->{fixed} = 1;
	if(exists($SReview::Config::_private::{$name})) {
		return ${$SReview::Config::_private::{$name}};
	}
	if(defined($ENV{'SREVIEW_VERBOSE'}) && $ENV{'SREVIEW_VERBOSE'} gt 0) {
		print "No configuration value found for $name, using defaults\n";
	}
	return $self->{defs}{$name}{default};
};

=head2 $config->set('name', value);

Change the current value of the given configuration item.

Note, this does not change the defaults, only the configured value.

=cut

sub set {
	my $self = shift;
	my %vals = @_;

	foreach my $name(keys %vals) {
		if(! exists($self->{defs}{$name})) {
			croak "Configuration value $name is not defined yet";
		}
		{
			my $val = $vals{$name};
			$SReview::Config::_private::{$name} = \$val;
		}
	}
}

=head2 $config->describe('name');

Return the documentation string for the given name

=cut

sub describe {
	my $self = shift;
	my $conf = shift;

	return $self->{defs}{$conf}{doc};
}

=head2 $config->dump

Return a string describing the whole configuration.

Each configuration item will produced in one of the following two
formats:

=over

=item *

For an item that only has a default set:

  # Documentation value given to define
  #$name = "default value";

=item *

For an item that has a different value configured (either through the
configuration file, or through C<set>):

  # Documentation value given to define
  $name = "current value";

=cut

sub dump {
	my $self = shift;
	my $rv = "";
	$Data::Dumper::Indent = 1;
	$Data::Dumper::Sortkeys = 1;
	foreach my $conf(sort(keys %{$self->{defs}})) {
		$rv .= "# " . $self->{defs}{$conf}{doc} . "\n";
		if(exists($SReview::Config::_private::{$conf}) && (!defined($self->{defs}{$conf}{default}) || ${$SReview::Config::_private::{$conf}} ne $self->{defs}{$conf}{default})) {
			$Data::Dumper::Pad = "";
			$rv .= Data::Dumper->Dump([${$SReview::Config::_private::{$conf}}], [$conf]) . "\n";
		} else {
			$Data::Dumper::Pad = "#";
			$rv .= Data::Dumper->Dump([$self->{defs}{$conf}{default}], [$conf]) . "\n";
		}
	}
	$rv .= "# Do not remove this, perl needs it\n1;\n";

	return $rv;
};

=back

=head2 $config->dump_item("item")

Print a JSON value for the given configuration item. Prints the default
item if this item hasn't been set a value.

=cut

sub dump_item {
	my ($self, $item) = @_;

	print encode_json($self->get($item));
}

=head2 $config->is_default("item")

Return a truthy value if the given configuration item is still at its
default value.

=cut

sub is_default {
	my ($self, $item) = @_;

	return (exists($SReview::Config::_private::{$item})) ? 0 : 1;
}

=head1 BUGS

It is currently not possible to load more than one configuration file in
the same process space. This will be fixed at some point in the future.

=cut

1;
