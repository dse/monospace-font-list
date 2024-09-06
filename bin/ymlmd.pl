#!/usr/bin/env perl
use warnings;
use strict;
use YAML qw();
use Scalar::Util qw(looks_like_number);

local $/ = undef;
while (<>) {
    my @docs = YAML::Load($_);
    foreach my $doc (@docs) {
        if (ref $doc ne 'ARRAY') {
            printf("\n\`\`\`\n%s\n\`\`\`\n\n", YAML::Dump($doc));
            next;
        }
        foreach my $item (@$doc) {
            my $name = delete $item->{name};
            if (!defined $name) {
                printf("\n\`\`\`\n%s\n\`\`\`\n\n", YAML::Dump($item));
                next;
            }
            my $url = url($item);
            if (defined $url) {
                printf("-   [%s](%s)\n", $name, $url);
            } else {
                printf("-   %s\n", $name);
            }
            my $descr = delete $item->{descr};
            my $notes = delete $item->{notes};
            if (defined $descr) {
                print(indent(trimnorm($descr), "    -   ", "        "), "\n");
            }
            if (defined $notes) {
                print(indent(trimnorm($notes), "    -   ", "        "), "\n");
            }
            printf("    -   [source](%s)\n",       delete $item->{source_url})       if defined $item->{source_url};
            printf("    -   [fontlibrary](%s)\n",  delete $item->{fontlibrary_url})  if defined $item->{fontlibrary_url};
            printf("    -   [fontsquirrel](%s)\n", delete $item->{fontsquirrel_url}) if defined $item->{fontsquirrel_url};
            printf("    -   [fonts2u](%s)\n",      delete $item->{fonts2u_url})      if defined $item->{fonts2u_url};
            printf("    -   [dafont](%s)\n",       delete $item->{dafont_url})       if defined $item->{dafont_url};
            printf("    -   [googlefonts](%s)\n",  delete $item->{gfonts_url})  if defined $item->{gfonts_url};
            printf("    -   [myfonts](%s)\n",      delete $item->{myfonts_url})      if defined $item->{myfonts_url};
            foreach my $key (sort grep { /(?:^|_)url(?:$|_)/ } keys %$item) {
                printf("    -   [%s](%s)\n", $key, $item->{$key});
                delete $item->{$key};
            }
            my $variants = delete $item->{variants};
            if (defined $variants) {
                print("    -   Variants:\n");
                print(indent(trimnorm($variants), "        ", "        "), "\n");
            }
        }
    }
}

sub url {
    my $item = shift;
    my $url = delete $item->{url};
    $url = delete $item->{github_url}        if !defined $url && defined $item->{github_url};
    $url = delete $item->{fontlibrary_url}   if !defined $url && defined $item->{fontlibrary_url};
    $url = delete $item->{fontsquirrel_url}  if !defined $url && defined $item->{fontsquirrel_url};
    $url = delete $item->{myfonts_url}       if !defined $url && defined $item->{myfonts_url};
    $url = delete $item->{gfonts_url}   if !defined $url && defined $item->{gfonts_url};
    $url = delete $item->{dafont_url}        if !defined $url && defined $item->{dafont_url};
    $url = delete $item->{fonts2u_url}       if !defined $url && defined $item->{fonts2u_url};
    return $url;
}

sub trimnorm {
    my ($str) = @_;
    $str =~ s{\A\s*\R}{};
    $str =~ s{\s*\z}{};
    return $str;
}

sub indent {
    my ($str, $indent, $indent_2) = @_;
    $indent //= "    ";
    $indent_2 //= $indent;
    my $count = 0;
    $str =~ s{^}{$count++ ? $indent_2 : $indent}gme;
    return $str;
}
