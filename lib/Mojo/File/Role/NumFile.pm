package Mojo::File::Role::NumFile;
use strict;
use warnings;

use Mojo::Base -role;

sub next {
    my $self = shift;

    my $opts = ref $_[-1] eq "HASH" ? pop : {};
    my ($template, $max, $children);

    $max = 0;

    if ($opts->{template}) {
	my $zero = sprintf $opts->{template}, 0;
	my $re = $zero =~ s/(0+)(.+)$/"(" . ("\\d" x length $1) . ")" . $2 . '$'/er;
	$children = $self->list
	    ->grep(sub { /$re/ })
	    ->map(sub {
		      /$re/;
		      [ $_, $1 ]
		  });
	$max = $children->size ? $children->map(sub { $_->[1] })->sort(sub { $a <=> $b })->last : 0;
	$template = Mojo::File->new($self, $opts->{template});
    } else {
	my $minl = $opts->{min_length} || 1;
	my $maxl = $opts->{max_length} || 5;
	$children = $self->list
	    ->map(sub { /(.+?\D+)(\d{$minl,$maxl})\.([a-z0-9\.]+)$/; [ $_, $2, $1, $3 ] })
	    ->grep(sub { $_->[1] && $_->[1] =~ /\d/ });

	my $roots   = $children->map(sub { $_->[2] })->uniq;
	my $exts    = $children->map(sub { $_->[3] })->uniq;
	my $lengths = $children->map(sub { length $_->[1] })->uniq;
	$max = $children->map(sub { $_->[1] })->sort(sub { $a <=> $b })->last;
	if ($roots->size == 1 && $exts->size == 1 && $lengths->size == 1) { 
	    $template = sprintf "%s%%0%dd.%s", $roots->first, $lengths->first, $exts->first;
	} else {
	    die "Error: no template was provided, and none could be calculated from files"
	}
    }

    $opts->{start} //= 1;
    $max = $max > $opts->{start} ? $max : $opts->{start} - 1;

    print STDERR $template, $max if $opts->{debug};
    return Mojo::File->new(sprintf $template, $max + 1);
}

1;
