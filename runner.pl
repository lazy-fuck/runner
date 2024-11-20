#!/usr/bin/env perl
#####################################
# runner by maciej © 2024.				  #
# See './LICENSE' for license info. #
#####################################

use v5.40;
use strict;
use warnings;

use Curses;
use Storable qw(dclone);

my $version = "0.1a";

# set your greeting here
my $greeting = "runner v$version | w/k: move up | s/j: move down | enter: run | q: quit\n";
# .. or disable it completely
my $show_greeting = 1;

# $> is set to the effective user id
my $cmd_prompt = $> == 0 ? '# ' : '$ ';

# set surrounding characters (or strings) for selection
my @selected_surround = ('[ ', ' ]');
#my @selected_surround = ('>> ', ' <<');
#my @selected_surround = ('fuck> ', ' <you');

# !! add menu entries here
my @entries = (
	{
		name => "list directory",
		cmd  => "ls --color -lhA .",
	}, {
		name => "fuck you",
		cmd  => 'echo "Fuck you"',
	}, {
		name => "initialize perl project",
		cmd  => 'perlinit new.pl',
	}, {
		name => "launch firefox",
		cmd  => "firefox &",
	}, {
		name => "flex",
		cmd  => "fastfetch || neofetch",
	}, {
		name => "mount music partition",
		cmd  => "su -c 'mount /dev/sdb1 /mnt/music'",
	}, {
		name => "mount data partition",
		cmd  => "su -c 'mount /dev/sdb2 /mnt/data'",
	}, {
		name => "show disk usage for /",
		cmd  => "du --si -d1 -t1 / 2>/dev/null"
	}, {
		name => "set brightness to 60",
		cmd  => "brightness 60"
	}
);

# everything below should be left in-tact unless you
# really wanna hack.

# add menu actions here. actions will receive a '%menu' reference
# as a paramater (see main subroutine).
my %key_to_action_map = (
	'w'   =>  \&move_selection_up,
	's'   =>  \&move_selection_down,
	'k'   =>  \&move_selection_up,
	'j'   =>  \&move_selection_down,
	"\n"  =>  \&run_selection,
	'q'   =>  \&quit,
);

sub quit {
	my $menu = shift;
	$menu->{running} = 0;
}

sub run_selection {
	my $menu = shift;
	my $nth = $menu->{selected};

	$menu->{running} = 0;	
	endwin; # we endwin here so command output is displayed correctly

	# execute cmd, we should be done here
	system $entries[$nth]{cmd};
}

sub move_selection_up {
	my $menu = shift;
	my $y = $menu->{selected} - 1;
	return if $y < 0;

	$menu->{selected} = $y;
}

sub move_selection_down {
	my $menu = shift;
	my $y = $menu->{selected} + 1;
	return if $y > $#entries;

	$menu->{selected} = $y;
}

# update: get key press;
# run action mapped to key pressed;
sub update {
	my $menu_ref = shift;

	my $key = getch;

	my $action = $key_to_action_map{$key};
	return unless defined($action);

	&{ $action }($menu_ref);	
}

# draw: clear screen;
# copy entries to 'buffer' array;
# draw 'selected' entry appropriately;
# show greeting;
# show entries;
sub draw {
	my $menu = shift;
	
	erase;

	# initialize stuff. '@buffer' should be
	# modified for visual changes.
	my $selected = $menu->{selected};

	# i don't know of a better way to do this, apart
	# from iterating over each 'name' and copying
	# to a new array. this is a neater solution imo,
	# but it does depend on 'use Clone'
	my @buffer = @{ dclone(\@entries) };

	# draw 'selected_surround' around entry name.
	$buffer[$selected]{name} =
		"$selected_surround[0]$buffer[$selected]{name}$selected_surround[1]";

	# draw stuff
	if ($show_greeting) {
		addstr($greeting);
		addstr('-' x ((length $greeting) - 1) . "\n");
	}
	addstr("$cmd_prompt$entries[$selected]{cmd}\n\n");

	foreach (@buffer) {
		addstr("$_->{name}\n");
	}
}

sub main {
	# initialize screen
	initscr; noecho; cbreak;
	
	# data structure to store the programs state
	# NOTE: on second thought, 'entries' doesn't even need to be here..
	my %menu = (
		running => 1,
		selected => 0,
		#entries => \@entries,
	);

	while ($menu{running}) {
		draw \%menu;
		update \%menu;
	}

	endwin;
	exit 0;
}

main;
