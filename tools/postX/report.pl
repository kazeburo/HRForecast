#!/usr/perl
use strict;
use warnings;
use FindBin;
use Config::Pit;
use File::Temp 'tempfile';

use lib "$FindBin::Bin/lib";
use Hrforecast::Load;
use Hrforecast::Post;
use Hrforecast::Puredata;

use App::Options(
    option => {
        date      => { type => 'date' },
        not_post  => { type => 'boolean', default => 0 },
        post_only => { type => 'boolean', default => 0 },
        sql_dir   => { type => 'string' },
        sql       => { type => 'string' },
    },
);

use constant SQL_DIR => "$FindBin::Bin/sql/";
use constant CSV_DIR => "$FindBin::Bin/data/";
use constant COMMAND_PATH => "$FindBin::Bin/lib/nzsql/bin/nzsql";

&main();

sub main () {

    my $config = pit_get("puredata", require => {
        user_id => "your user_id on PureData",
        password => "your password on PureData",
    });

    # Load sql files
    $Hrforecast::Load::SQL_DIR = SQL_DIR;
    my $dir_files = Hrforecast::Load->load_sql_files;

    foreach my $service_name (keys %$dir_files) {
        next if $App::options{sql_dir} && $App::options{sql_dir} !~ m/$service_name/xms;

        my $files = $dir_files->{$service_name};
        foreach my $file_name (@$files) {
            my($section_name) = split('\.', $file_name);
            my $csv_file = CSV_DIR . $service_name . "_" . $section_name. ".csv";

            if (!$App::options{post_only}) {
                my $sql_file = SQL_DIR . $service_name . "/" . $file_name;

                next if $App::options{sql} && $sql_file !~ m/$App::options{sql}$/xms;

                $sql_file = create_replaced_sql_file($sql_file, $App::options{date}) if $App::options{date};

                # output data by sql
                $Hrforecast::Puredata::COMMAND_PATH = COMMAND_PATH;
                Hrforecast::Puredata->output_to_csv($config->{user_id}, $config->{password}, $sql_file, $csv_file);
            }

            next if $App::options{not_post};

            # post csv data
            Hrforecast::Post->post_csv($service_name, $section_name, $csv_file);
        }
    }
}

sub create_replaced_sql_file {
    my($sql_file, $date) = @_;

    open my $rfh, '<', $sql_file or die "cannot open $sql_file: $!";
    my $lines = do { local $/; <$rfh> };
    close $rfh;

    $lines =~ s/NOW\(\)/DATE('$date')/g;

    my($tempfh, $replaced_sql_file) = tempfile;
    print {$tempfh} $lines;
    close $tempfh;

    return $replaced_sql_file;
}

1; 
