package Post;

use strict;
use warnings;
use LWP::UserAgent;

sub post_csv {
    my ($self, $service_name, $section_name, $csv_file) = @_;

    # read csv data
    open(my $fh, '<', $csv_file) or die "Can't read file '$csv_file' [$!]\n";
    my $title_line = <$fh>;
    chomp $title_line;
    my @titles = split(/,/, $title_line);

    # post data
    my $ua = LWP::UserAgent->new;
    while (my $data_line = <$fh>) {
        chomp $data_line;
        my @csv_data = split(/,/, $data_line);
        my $graphs_count = scalar @titles;

        # exit when last line
        last if scalar @csv_data != $graphs_count;

        my $dt = $csv_data[0];
        for (my $i = 1; $i < $graphs_count; $i++) {
            my $graph_name = lc($titles[$i]);
            my $graph_number = $csv_data[$i];

            # post
            $ua->post(sprintf(POST_URL, $service_name, $section_name, $graph_name), {
                datetime => $dt,
                number   => $graph_number,
            });
        }
    }
}

1; 
