#!/usr/bin/env perl
use warnings;
use strict;
use YAML qw();
use List::Util qw(uniq);
use HTTP::Date qw(str2time);
use POSIX qw(strftime);

use FindBin;
use lib "${FindBin::Bin}/../lib";

use My::MonospaceFontList::Item;

STDOUT->autoflush(1);
STDERR->autoflush(1);

my @new;

local $/ = undef;
while (<>) {
    my @docs = YAML::Load($_);
    foreach my $doc (@docs) {
        foreach my $item (@$doc) {
            if (defined $item->{date_listed}) {
                push(@new, My::MonospaceFontList::Item->new($item));
            }
        }
    }
}

@new = sort { $b->{data}->{date_listed} cmp $a->{data}->{date_listed} } @new;

my @dates_listed = uniq map { $_->{data}->{date_listed} } @new;

foreach my $date_listed (@dates_listed) {
    my $date = str2time($date_listed);
    printf("## %s\n", uc(strftime("%a %d-%b-%Y", localtime($date))));
    foreach my $item (grep { $_->{data}->{date_listed} eq $date_listed } @new) {
        print($item->as_md(oneline => 1, previews => 0));
    }
}
