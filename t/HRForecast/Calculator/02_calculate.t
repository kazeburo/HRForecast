use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Time::Piece;
use Time::Seconds;
use HRForecast;
use HRForecast::Calculator;
use Data::Dumper;

my $calculator = HRForecast::Calculator->new();

subtest 'calculate(identity)' => sub {
  my $from = Time::Piece->strptime('2015-10-30', '%Y-%m-%d');
  my $to   = Time::Piece->strptime('2015-11-03', '%Y-%m-%d');

  my @rows_of_get_data = ();
  for (my $i = 0; $i < 5; $i++) {
    push @rows_of_get_data, {metrics_id=>1, datetime=>$from + ONE_DAY * $i, number=>10};
    push @rows_of_get_data, {metrics_id=>2, datetime=>$from + ONE_DAY * $i, number=>20};
  }

  my $data = Test::MockObject->new;
  $data->mock('get_data' => sub {
    my ($self, $id, $from, $to) = @_;
    is(123, $id);
    is('2015-10-30', $from->ymd);
    is('2015-11-03', $to->ymd);
    return \@rows_of_get_data;
  });

  my $expected = \@rows_of_get_data;
  my $actual = $calculator->calculate($data, 123, $from, $to, '');
  is_deeply($actual, $expected);
};

subtest 'calculate(runningtotal_by_month)' => sub {
  my $from = Time::Piece->strptime('2015-10-30', '%Y-%m-%d');
  my $to   = Time::Piece->strptime('2015-11-03', '%Y-%m-%d');

  my @rows_of_get_data = ();
  for (my $i = -31; $i < 5; $i++) {
    push @rows_of_get_data, {metrics_id=>1, datetime=>$from + ONE_DAY * $i, number=>10};
    push @rows_of_get_data, {metrics_id=>2, datetime=>$from + ONE_DAY * $i, number=>20};
  }

  my $data = Test::MockObject->new;
  $data->mock('get_data' => sub {
    my ($self, $id, $from, $to) = @_;
    is(123, $id);
    is('2015-09-29', $from->ymd);
    is('2015-11-03', $to->ymd);
    return \@rows_of_get_data;
  });

  my $expected = [
    {metrics_id=>1, datetime=>Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number=> 300},
    {metrics_id=>2, datetime=>Time::Piece->strptime('2015-10-30', '%Y-%m-%d'), number=> 600},
    {metrics_id=>1, datetime=>Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number=> 310},
    {metrics_id=>2, datetime=>Time::Piece->strptime('2015-10-31', '%Y-%m-%d'), number=> 620},
    {metrics_id=>1, datetime=>Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number=>  10},
    {metrics_id=>2, datetime=>Time::Piece->strptime('2015-11-01', '%Y-%m-%d'), number=>  20},
    {metrics_id=>1, datetime=>Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number=>  20},
    {metrics_id=>2, datetime=>Time::Piece->strptime('2015-11-02', '%Y-%m-%d'), number=>  40},
    {metrics_id=>1, datetime=>Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number=>  30},
    {metrics_id=>2, datetime=>Time::Piece->strptime('2015-11-03', '%Y-%m-%d'), number=>  60},
  ];

  my $actual = $calculator->calculate($data, 123, $from, $to, 'runningtotal_by_month');
  is_deeply($actual, $expected);
};

done_testing;


