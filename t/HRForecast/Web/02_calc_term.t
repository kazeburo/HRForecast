use strict;
use warnings;
use Test::More;
use HRForecast;
use HRForecast::Web;

my $obj = bless({}, 'HRForecast::Web');

local $HRForecast::CONFIG = {};

subtest 't => w' => sub {
  my ($from, $to) = $obj->calc_term(t => 'w');
  is($to->epoch, int(time / 3600) * 3600);
  is(($to - $from), (10 * 24 * 60 * 60));
};

subtest 't => m' => sub {
  my ($from, $to) = $obj->calc_term(t => 'm');
  is($to->epoch, int(time / 3600) * 3600);
  is(($to - $from), (40 * 24 * 60 * 60));
};

subtest 't => y' => sub {
  my ($from, $to) = $obj->calc_term(t => 'y');
  is($to->epoch, int(time / 3600) * 3600);
  is(($to - $from), (400 * 24 * 60 * 60));
};

subtest 't => range' => sub {
  my ($from, $to) = $obj->calc_term(t => 'range', offset => 5000, period => 36000);
  is($to->epoch, int((time - 5000) / 3600) * 3600);
  is(($to - $from), 36000);
};

subtest 't => c, and from&to' => sub {
  my ($from, $to) = $obj->calc_term(t => 'c', from => '2014-06-08 12:34:56', to => '2014-07-09 01:23:45');
  is($from->epoch, HTTP::Date::str2time('2014-06-08 12:00:00'));
  is($to->epoch,   HTTP::Date::str2time('2014-07-09 01:00:00'));
};

done_testing;


