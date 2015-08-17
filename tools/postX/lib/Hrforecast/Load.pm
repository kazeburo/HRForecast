package Load;

use strict;
use warnings;
use FindBin;

our $SQL_DIR;

sub load_sql_files {
    my $self = shift;
    my %dir_sqls;

    # load dir
    opendir DIR, $SQL_DIR or die "can't open the directory" . $SQL_DIR;
    my @dirs = readdir DIR;

    # load dir files
    foreach my $dir_name (@dirs) {
        next if ($dir_name eq "." || $dir_name eq "..");

        # load files
        my $folder = $SQL_DIR . "/$dir_name";
        opendir my $fh, $folder or die "can't open the directory" . $folder;
        my @file_list = readdir $fh;
        closedir $fh;

        my @files;
        foreach my $file (@file_list) {
            next if ($file eq "." || $file eq "..");
            if ($file =~/^\w+\.sql$/) {
                push @files, $file;
            }
        }

        if (scalar @files) {
            $dir_sqls{$dir_name} = \@files;
        }
    }
    closedir DIR;
 
    return \%dir_sqls;
}

1; 
