use strict;
use warnings;
use Test::More;
use HRForecast;
use HRForecast::Calculator;

my $calculator = HRForecast::Calculator->new();

subtest 'find_minus_days_of_from' => sub {
  is($calculator->find_minus_days_of_from(''),                       0);
  is($calculator->find_minus_days_of_from('runningtotal'),           0);
  is($calculator->find_minus_days_of_from('runningtotal_by_month'), 31);
  is($calculator->find_minus_days_of_from('difference_plus'),        1);
  is($calculator->find_minus_days_of_from('difference_plus'),        1);
};

done_testing;


