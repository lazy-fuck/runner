#!/usr/bin/env perl
#####################################
# runner by lazy-fuck © 2024.       #
# See './LICENSE' for license info. #
#####################################

# INFO: search for @entries to add menu entries.
# INFO: search for %key_to_action_map to map keys to actions (functions).

use v5.40;
use strict;
use warnings;

use Curses;
use Storable qw(dclone);

my $version = "1.00";

# set your greeting here
my $greeting = "runner v$version | w/k: move up | s/j: move down | enter: run | q: quit\n";
# .. or disable it completely by setting 0
my $show_greeting = 1;

# $> is set to the effective user id
# (weird ass perl variables..)
my $cmd_prompt = $> == 0 ? '# ' : '$ ';

# set surrounding characters (or strings) for selection
my @selected_surround = ('[ ', ' ]');
#my @selected_surround = ('>> ', ' <<');
#my @selected_surround = ('f**k> ', ' <you');

# !! add menu entries here
my @entries = (
	{	
		name => "grep stuff (interactive)",
		cmd  => 'xargs -I{} -- grep --color -irn \'{}\'',
	}, {
		name => "list directory",
		cmd  => "ls --color -lhA .",
	}, {
		name => "fuck you",
		cmd  => 'echo "Fuck you"',
	}, {
		name => "launch firefox",
		cmd  => "firefox &",
	}, {
		name => "flex",
		cmd  => "fastfetch || neofetch",
	}, {
		name => "show disk usage for /",
		cmd  => "du --si -d1 -t1 / 2>/dev/null"
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
	my $draw_buffer = "";

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

	# draw greeting
	if ($show_greeting) {
		$draw_buffer .= $greeting;
		$draw_buffer .= '-' x ((length $greeting) - 1) . "\n";
	}

	# draw prompt
	$draw_buffer .= "$cmd_prompt$entries[$selected]{cmd}\n\n";

	#foreach (@buffer) {
	#	$draw_buffer .= "$_->{name}\n";
	#}
	# idk if this is better but I like it more so fuck it and also
	# it's a one-liner, hipster gen-z solution
	$draw_buffer .= join "\n", map { $_->{name} } @buffer;

	addstr($draw_buffer);
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

	# a second call to endwin is fine as far as I'm aware..
	endwin;
	exit 0;
}

main;
