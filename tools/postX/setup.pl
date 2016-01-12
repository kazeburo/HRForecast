#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

my $rprofilename = ".Rprofile";
my $rprofile = "$ENV{HOME}/$rprofilename";

my $config = (! -e $rprofile)
        ? create_rprofile($rprofile)
        : parse_rprofile($rprofile)
        ;

my $rprofile_pit = "$rprofilename.pit";
write_file($rprofile_pit, <<EOL);
---
"puredata":
  "user_id": '$config->[0]'
  "password": '$config->[1]'
EOL

sub create_rprofile {
    my @config;
    for my $q ("your id?", "your password?") {
        my $line;
        do {
            print $q, "\n", "=> ";
            chomp($line = <STDIN>);
        } until $line;

        push @config, $line;
    }

    write_file($rprofile, <<EOL);
ECN_PUREDATA_ID <- '$config[0]'
ECN_PUREDATA_PASSWORD <- '$config[1]'
EOL

    return \@config;
}

sub parse_rprofile {
    my @config;
    open my $rfh, "<", $rprofile;
    my $lines = do { local $/; <$rfh> };
    close $rfh;

    die "cannot parse your $rprofile" if $lines !~ m/ECN_PUREDATA_ID\s+<-\s+'(.+?)'\s+ECN_PUREDATA_PASSWORD\s+<-\s+'(.+?)'/;
    @config = ($1, $2);

    \@config;
}

sub write_file {
    my $fname = shift;
    my $body = shift;

    open my $wfh, '>', $fname or die "cannot open $fname $!";
    print {$wfh} $body;
    close $wfh;
}
