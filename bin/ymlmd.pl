#!/usr/bin/env perl
use warnings;
use strict;
use YAML qw();
use Scalar::Util qw(looks_like_number);
use Carp::Always;

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
            my $i = My::Item->new($item);
            print($i->as_md());
            # print(print_item($item));
        }
    }
}

package My::Item {
    use Data::Dumper;
    use JSON::XS;

    sub new {
        my ($class, $data) = @_;
        my $self = bless({}, $class);
        $self->{data} = decode_json(encode_json($data));
        print STDERR (Dumper($data));
        print STDERR (Dumper($self->{data}));
        $self->{orig_data} = $data;
        $self->init();
        print STDERR (Dumper($self));
        return $self;
    }

    sub init {
        my ($self) = @_;
        my $data = $self->{data};

        my $name = delete $data->{name};
        $self->{name} = $name if defined $name;

        my $descr = delete $data->{descr};
        $self->{descr} = $descr if defined $descr;

        my $notes = delete $data->{notes};
        if (defined $notes) {
            if (ref $notes eq 'ARRAY') {
                $self->{notes} = $notes;
            } else {
                $self->{notes} = [$notes];
            }
        }

        my $primary_url = delete $data->{url};
        foreach my $key (qw(source_url
                            fontlibrary_url
                            fontsquirrel_url
                            myfonts_url
                            gfonts_url
                            dafont_url
                            fonts2u_url)) {
            my $url = delete $data->{$key};
            if (defined $url) {
                $primary_url //= $url;
                $self->{$key} = $url;
            }
        }
        foreach my $key (sort grep { /_url$/i } keys %$data) {
            my $url = delete $data->{$key};
            $self->{$key} = $url;
        }
        $self->{url} = $primary_url;

        my $variants = delete $data->{variants};
        if (defined $variants) {
            if (ref $variants eq '') {
                $self->{variants} = [$variants];
            } elsif (ref $variants eq 'ARRAY') {
                $self->{variants} = $variants;
            }
        }
    }

    sub as_md {
        my ($self, $indent) = @_;
        $indent //= "";
        my $name = $self->{name};
        if (!defined $name) {
            my $str = sprintf("\n\`\`\`\n%s\n\`\`\`\n\n", YAML::Dump($self->{orig_data}));
            $str =~ s{^(?=[^\r\n])}{$indent}gm;
            return $str;
        }
        my $str = "";
        my $url = $self->{url};
        if (defined $url) {
            $str .= sprintf("-   [%s](%s)\n", $name, $url);
        } else {
            $str .= sprintf("-   %s\n", $name);
        }
        my $descr = $self->{descr};
        my $notes =  $self->{notes};
        if (defined $descr) {
            $str .= indent(trimnorm($descr), "    ", "    ") . "\n";
        }
        if (defined $notes) {
            # if (scalar @$notes == 1) {
            #     $str .= "    -   Notes:\n";
            #     $str .= indent(trimnorm($notes->[0]), "        ", "        ") . "\n";
            # } else {
                $str .= "    -   Notes:\n";
                foreach my $note (@$notes) {
                    $str .= indent(trimnorm($note), "        -   ", "            ") . "\n";
                }
            # }
        }

        my %urls;
        foreach my $key (grep { /_url$/i } keys %$self) {
            my $key_name = $key;
            $key_name =~ s/_url$//i;
            $urls{$key_name} = $self->{$key};
        }

        foreach my $key (sort keys %urls) {
            delete $urls{$key} if defined $url && $urls{$key} eq $url;
        }

        $str .= sprintf("    -   [source](%s)\n",       delete $urls{source})       if defined $urls{source};
        $str .= sprintf("    -   [fontlibrary](%s)\n",  delete $urls{fontlibrary})  if defined $urls{fontlibrary};
        $str .= sprintf("    -   [fontsquirrel](%s)\n", delete $urls{fontsquirrel}) if defined $urls{fontsquirrel};
        $str .= sprintf("    -   [fonts2u](%s)\n",      delete $urls{fonts2u})      if defined $urls{fonts2u};
        $str .= sprintf("    -   [dafont](%s)\n",       delete $urls{dafont})       if defined $urls{dafont};
        $str .= sprintf("    -   [googlefonts](%s)\n",  delete $urls{gfonts})       if defined $urls{gfonts};
        $str .= sprintf("    -   [myfonts](%s)\n",      delete $urls{myfonts})      if defined $urls{myfonts};
        foreach my $key (sort keys %urls) {
            $str .= sprintf("    -   [%s](%s)\n", md_escape($key), $urls{$key});
        }

        my $variants = $self->{variants};
        if (defined $variants) {
            $str .= "    -   Variants:\n";
            if (scalar @$variants == 1) {
                $str .= indent(trimnorm($variants->[0]), "        ", "        ") . "\n";
            } else {
                foreach my $sub_item (@$variants) {
                    my $i = My::Item->new($sub_item);
                    $str .= $i->as_md($indent . "        ");
                }
            }
        }
        $str =~ s{^(?=[^\r\n])}{$indent}gm;

        return $str;
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

}
