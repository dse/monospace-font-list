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
        printf("%d typefaces listed here.\n\n", scalar @$doc);
        foreach my $item (@$doc) {
            print(print_item($item));
        }
    }
}

sub print_item {
    my ($item, $indent) = @_;
    if (!defined $indent) {
        $indent = "";
    }
    my $name = delete $item->{name};
    if (!defined $name) {
        my $str = sprintf("\n\`\`\`\n%s\n\`\`\`\n\n", YAML::Dump($item));
        $str =~ s{^(?=[^\r\n])}{$indent}gm;
        return $str;
    }
    my $str = "";
    my $url = url($item);
    if (defined $url) {
        $str .= sprintf("-   [%s](%s)\n", $name, $url);
    } else {
        $str .= sprintf("-   %s\n", $name);
    }
    my $descr = delete $item->{descr};
    my $notes = delete $item->{notes};
    if (defined $descr) {
        $str .= indent(trimnorm($descr), "    ", "    ") . "\n";
    }
    if (defined $notes) {
        if (ref $notes eq 'ARRAY') {
            $str .= "    -   Notes:\n";
            foreach my $note (@$notes) {
                $str .= indent(trimnorm($note), "        -   ", "            ") . "\n";
            }
        } else {
            $str .= "    -   Notes:\n";
            $str .= indent(trimnorm($notes), "        ", "        ") . "\n";
        }
    }
    $str .= sprintf("    -   [source](%s)\n",       delete $item->{source_url})       if defined $item->{source_url};
    $str .= sprintf("    -   [fontlibrary](%s)\n",  delete $item->{fontlibrary_url})  if defined $item->{fontlibrary_url};
    $str .= sprintf("    -   [fontsquirrel](%s)\n", delete $item->{fontsquirrel_url}) if defined $item->{fontsquirrel_url};
    $str .= sprintf("    -   [fonts2u](%s)\n",      delete $item->{fonts2u_url})      if defined $item->{fonts2u_url};
    $str .= sprintf("    -   [dafont](%s)\n",       delete $item->{dafont_url})       if defined $item->{dafont_url};
    $str .= sprintf("    -   [googlefonts](%s)\n",  delete $item->{gfonts_url})  if defined $item->{gfonts_url};
    $str .= sprintf("    -   [myfonts](%s)\n",      delete $item->{myfonts_url})      if defined $item->{myfonts_url};
    foreach my $key (sort grep { /_url$/ } keys %$item) {
        my $new_key = $key;
        $new_key =~ s{_url$}{};
        $str .= sprintf("    -   [%s](%s)\n", md_escape($new_key), $item->{$key});
        delete $item->{$key};
    }
    my $variants = delete $item->{variants};
    if (defined $variants) {
        $str .= "    -   Variants:\n";
        if (ref $variants eq '') {
            $str .= indent(trimnorm($variants), "        ", "        ") . "\n";
        } elsif (ref $variants eq 'ARRAY') {
            foreach my $sub_item (@$variants) {
                $str .= print_item($sub_item, $indent . "        ");
            }
        }
    }
    $str =~ s{^(?=[^\r\n])}{$indent}gm;
    return $str;
}

sub url {
    my $item = shift;
    my $url = delete $item->{url};
    $url = delete $item->{source_url}        if !defined $url && defined $item->{source_url};
    $url = delete $item->{fontlibrary_url}   if !defined $url && defined $item->{fontlibrary_url};
    $url = delete $item->{fontsquirrel_url}  if !defined $url && defined $item->{fontsquirrel_url};
    $url = delete $item->{myfonts_url}       if !defined $url && defined $item->{myfonts_url};
    $url = delete $item->{gfonts_url}        if !defined $url && defined $item->{gfonts_url};
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

sub md_escape {
    my ($str) = @_;
    $str =~ s{\\}{\\\\}g;
    $str =~ s{_}{\\_}g;
    $str =~ s{\*}{\\*}g;
    return $str;
}
