#!/usr/bin/env perl
use warnings;
use strict;
use YAML qw();
use Scalar::Util qw(looks_like_number);

use FindBin;
use lib "${FindBin::Bin}/../lib";

use My::MonospaceFontList::Item;

STDOUT->autoflush(1);
STDERR->autoflush(1);

local $/ = undef;
while (<>) {
    my @docs = YAML::Load($_);
    foreach my $doc (@docs) {
        if (ref $doc ne 'ARRAY') {
            printf("\n\`\`\`\n%s\n\`\`\`\n\n", YAML::Dump($doc));
            next;
        }
        printf("%d typefaces listed here.\n\n", scalar @$doc);
        foreach my $item (@$doc) {
            my $i = My::MonospaceFontList::Item->new($item);
            print($i->as_md());
        }
    }
}
