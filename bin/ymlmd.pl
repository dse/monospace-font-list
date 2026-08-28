#!/usr/bin/env perl
use warnings;
use strict;
use YAML qw();
use Scalar::Util qw(looks_like_number);
# use Carp::Always;

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
            my $i = My::Item->new($item);
            print($i->as_md());
        }
    }
}

package My::Item {
    use Data::Dumper;
    use JSON::XS;
    use File::Basename qw(basename);
    use URI;

    our %KEYS;
    BEGIN {
        %KEYS = (
            also_url         => "SECONDARY",
            behance_url      => "behance.net",
            dafont_url       => "dafont.com",
            download_url     => "DOWNLOAD",
            fontlibrary_url  => "fontlibrary.org",
            fonts2u_url      => "fonts2u.com",
            fontshare_url    => "fontshare.com",
            fontsquirrel_url => "fontsquirrel.com",
            gfonts_url       => "fonts.google.com",
            github_url       => "github.com",
            microsoft_url    => "microsoft.com",
            myfonts_url      => "myfonts.com",
            osx_port_url     => "OSX port",
            secondary_url    => "SECONDARY",
            source_url       => "SOURCE",
            uncut_url        => "uncut.wtf",
            url_2_url        => "SECONDARY",
            usemodify_url    => "usemodify.com",
            via_url          => "via",
        );
    }

    sub new {
        my ($class, $data) = @_;
        my $self = bless({}, $class);
        $self->{data} = decode_json(encode_json($data));
        $self->{orig_data} = $data;
        $self->init();
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

        if (exists $data->{url}) {
            $self->add_urls($data->{url}, undef);
            delete $data->{url};
        }
        if (exists $data->{urls}) {
            $self->add_urls($data->{urls}, undef);
            delete $data->{urls};
        }
        foreach my $key (grep { /_url$/ } keys %$data) {
            $self->add_urls($data->{$key}, $key);
            delete $data->{$key};
        }

        my $variants = delete $data->{variants};
        if (defined $variants) {
            if (ref $variants eq '') {
                $self->{variants} = [$variants];
            } elsif (ref $variants eq 'ARRAY') {
                $self->{variants} = $variants;
            }
        }

        my $previews = delete $data->{previews};
        $self->{previews} = $previews if defined $previews;
    }

    sub add_urls {
        my ($self, $url, $key) = @_;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Indent = 0;
        if (defined $key) {
            if (exists $KEYS{$key}) {
                $key = $KEYS{$key};
                if (!defined $key) {
                    $key = "(other)";
                }
            } else {
                $key =~ s/_url$//;
            }
        }
        if (ref $url eq "") {
            if (defined $key && $key eq "PRIMARY") {
                $key = undef;
            }
            if (defined $key) {
                if (defined $self->{urls}->{PRIMARY}) {
                    push(@{$self->{urls}->{$key}}, $url);
                } else {
                    $self->{urls}->{PRIMARY} = $url;
                    if ($key eq "github.com") {
                        push(@{$self->{urls}->{$key}}, $url);
                    }
                }
            } else {
                if (defined $self->{urls}->{PRIMARY}) {
                    push(@{$self->{urls}->{SECONDARY}}, $url);
                } else {
                    $self->{urls}->{PRIMARY} = $url;
                }
            }
        } elsif (ref $url eq "ARRAY") {
            foreach my $url (@$url) {
                $self->add_urls($url, $key);
            }
        } elsif (ref $url eq "HASH") {
            foreach my $key (keys %$url) {
                $self->add_urls($url->{$key}, $key);
            }
        }
    }

    sub old_add_urls {
        my ($self, $url, $key, $primary) = @_;
        return if !defined $url;
        if (defined $key) {
            $key =~ s{_url$}{}i;
            $key .= "_url";
        }
        if (ref $url eq '') {
            if (defined $key) {
                if (defined $self->{$key}) {
                    push(@{$self->{other_urls}}, $url);
                } else {
                    $self->{$key} = $url;
                }
                if ($primary) {
                    if (defined $self->{url}) {
                        push(@{$self->{other_urls}}, $url);
                    } else {
                        $self->{url} = $url;
                    }
                }
            } else {
                if (defined $self->{url}) {
                    push(@{$self->{other_urls}}, $url);
                } else {
                    $self->{url} = $url;
                }
            }
        } elsif (ref $url eq 'ARRAY') {
            $self->add_urls($_, $key, $primary) foreach @$url;
        } elsif (ref $url eq 'HASH') {
            $self->add_urls($url->{$_}, $_, $primary) foreach keys %$url;
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

        if (defined $self->{urls} && defined $self->{urls}->{PRIMARY}) {
            my $primary_url = $self->{urls}->{PRIMARY};
            $str .= sprintf("-   [%s](%s)\n", $name, $primary_url);
            delete $self->{urls}->{PRIMARY};
        } else {
            $str .= sprintf("-   %s\n", $name);
        }

        my $descr = $self->{descr};
        my $notes = $self->{notes};
        if (defined $descr) {
            $str .= indent(trimnorm($descr), "    ", "    ") . "\n";
        }
        if (defined $notes) {
            $str .= "    -   Notes:\n";
            foreach my $note (@$notes) {
                $str .= indent(trimnorm($note), "        -   ", "            ") . "\n";
            }
        }

        if (defined $self->{urls} && defined $self->{urls}->{SECONDARY}) {
            my $secondary_urls = $self->{urls}->{SECONDARY};
            foreach my $url (@$secondary_urls) {
                my $domain = eval { URI->new($url)->host } // "(other)";
                $str .= sprintf("    -   [%s](%s)\n", $domain, $url);
            }
            delete $self->{urls}->{SECONDARY};
        }

        if (defined $self->{urls}) {
            foreach my $key (sort keys %{$self->{urls}}) {
                my @urls = @{$self->{urls}->{$key}};
                if (scalar @urls == 1) {
                    $str .= sprintf("    -   [%s](%s)\n", $key, $urls[0]);
                } elsif (scalar @urls > 1) {
                    $str .= sprintf("    -   %s:\n", $key);
                    foreach my $url (@urls) {
                        my $domain = eval { URI->new($url)->host } // "(other)";
                        $str .= sprintf("        -   [%s](%s)\n", $domain, $url);
                    }
                }
            }
        }
        delete $self->{urls};

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

        my $previews = $self->{previews};
        if (defined $previews) {
            $str .= "    -   Previews:\n";
            foreach my $preview (@$previews) {
                if (!defined $preview) {
                    printf STDERR ("UNDEFINED PREVIEW IN $name\n");
                }
                my $font_name;
                {
                    local $/ = "\n";
                    $font_name = basename($preview);
                }
                $font_name =~ s{\.preview\.png$}{};
                $str .= "        -   ${font_name}<br>\n";
                $str .= "            ![${preview}](${preview})\n";
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
