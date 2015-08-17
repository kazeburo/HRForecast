package Hrforecast::Puredata;

use strict;
use warnings;
use FindBin;

use constant DATA_BASE => 'puredata_name';
use constant HOST_NAME => 'my.puredata.com';

our $COMMAND_PATH;

sub output_to_csv {
    my $self = shift;
    my $user_id = shift;
    my $password = shift;
    my $sql_file = shift;
    my $csv_file = shift;

    $ENV{MY_ENCODING} ||= 'UTF-8'; # SQL に日本語が入っている場合用の対応
    system($COMMAND_PATH, "-d", DATA_BASE, "-u", $user_id, "-pw", $password, "-host", HOST_NAME, "-f", $sql_file, "-A", "-F,", "-o", $csv_file);
}

1;
