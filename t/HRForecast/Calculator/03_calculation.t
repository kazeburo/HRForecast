use strict;
use warnings;
use Test::More;
use HRForecast;
use HRForecast::Calculator;

my $calculator = HRForecast::Calculator->new();

my $input_rows = [
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

subtest 'calculation=' => sub {
  my $expected = $input_rows;

  my $actual = $calculator->calculation_($input_rows);
  is_deeply($actual, $expected);
};

subtest 'calculation=runningtotal' => sub {
  my $expected = [
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   1},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>  11},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number => 111},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number => 121},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number => 122},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   2},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>  22},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number => 222},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number => 242},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number => 244},
  ];

  my $actual = $calculator->calculation_runningtotal($input_rows);
  is_deeply($actual, $expected);
};

subtest 'calculation=runningtotal_by_month' => sub {
  my $expected = [
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   1},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>  11},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number => 100}, #月が変わったのでリセット
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number => 110},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number => 111},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   2},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>  22},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number => 200}, #月が変わったのでリセット
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number => 220},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number => 222},
  ];

  my $actual = $calculator->calculation_runningtotal_by_month($input_rows);
  is_deeply($actual, $expected);
};

subtest 'calculation=difference' => sub {
  my $expected = [
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   0},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>   9},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number =>  90},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number => -90},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number =>  -9},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   0},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>  18},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number => 180},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number =>-180},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number => -18},
  ];

  my $actual = $calculator->calculation_difference($input_rows);
  is_deeply($actual, $expected);
};

subtest 'calculation=difference_plus' => sub {
  my $expected = [
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   0},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>   9},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number =>  90},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number =>   0},
    {metrics_id => 1 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number =>   0},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number =>   0},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number =>  18},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number => 180},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number =>   0},
    {metrics_id => 2 , datetime => Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number =>   0},
  ];

  my $actual = $calculator->calculation_difference_plus($input_rows);
  is_deeply($actual, $expected);
};

done_testing;


