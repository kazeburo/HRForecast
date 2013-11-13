package HRForecast;

use strict;
use warnings;
use utf8;

our $VERSION = 0.01;

our $CONFIG;
sub config { $CONFIG };


1;

__END__

=head1 NAME

HRForecast - A Graphing/Visualization Tool

=head1 DESCRIPTION

HRForecast is Graphing/Data Visualization tool.  Whereas L<GrowthForecast> (HRForecast's older brother) is a tool for monitoring real-time data, HRForecast is aimed to keep track of data for a relatively long time frame.

So while L<GrowthForecast> shows you data in terms of average rates (i.e. RRD style) and the smallest graphing unit for a given data set is "1 minute average", HRForecast uses raw numbers and the smallest unit is "value at a given date".

=head1 AUTHOR

Masahiro Nagano C<< <kazeburo {at} gmail.com> >>


=cut
