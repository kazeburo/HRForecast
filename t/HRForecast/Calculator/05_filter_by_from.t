use strict;
use warnings;
use Test::More;
use HRForecast;
use HRForecast::Calculator;

my $calculator = HRForecast::Calculator->new();

my $rows = [
  {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   1},
  {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>  10},
  {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number => 100},
  {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number =>  10},
  {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number =>   1},
  {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   2},
  {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>  20},
  {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number => 200},
  {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number =>  20},
  {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number =>   2},
];

subtest 'filter_by_from' => sub {
  my $actual;

  $actual = $calculator->filter_by_from($rows, Time::Piece->strptime('2015-10-30', '%Y-%m-%d'));
  is(scalar(@$actual), 10);

  $actual = $calculator->filter_by_from($rows, Time::Piece->strptime('2015-11-01', '%Y-%m-%d'));
  is(scalar(@$actual), 6);
};

done_testing;


