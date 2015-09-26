use strict;
use warnings;
use Test::More;
use HRForecast;
use HRForecast::Web;

my $obj = bless({}, 'HRForecast::Web');

local $HRForecast::CONFIG = {};

subtest 'merge_params' => sub {
  my $merge_params = HRForecast::Web::create_merge_params(['a', 1, 'b', 2]);
  is_deeply($merge_params->({c => 3}), ['c', 3, 'a', 1, 'b', 2]);
};

subtest 'merge_params overwrite' => sub {
  my $merge_params = HRForecast::Web::create_merge_params(['a', 1, 'b', 2]);
  is_deeply($merge_params->({a => 3}), ['a', 3, 'b', 2]);
};

subtest 'merge_params value=empty' => sub {
  my $merge_params = HRForecast::Web::create_merge_params(['a', '', 'b', 2]);
  is_deeply($merge_params->({c => ''}), ['b', 2]);
};

done_testing;


