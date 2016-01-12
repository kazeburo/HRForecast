package HRForecast::Calculator;

use strict;
use warnings;
use utf8;
use HTTP::Date;
use Time::Piece;
use Time::Seconds;
use Data::Dumper;

use constant CALCULATIONS => [
  {function=>'',                      name=>'———',           minus_days_of_from =>  0},
  {function=>'runningtotal',          name=>'累計',             minus_days_of_from =>  0},
  {function=>'runningtotal_by_month', name=>'累計（月別）',     minus_days_of_from => 31},
  {function=>'difference',            name=>'差分',             minus_days_of_from =>  1},
  {function=>'difference_plus',       name=>'差分（増加のみ）', minus_days_of_from =>  1},
];

sub new {
    my $class = shift;
    bless {}, $class;
}

sub calculate {
    my ($self, $data, $id, $from, $to, $calculation) = @_;

    my $minus_days_of_from = $self->find_minus_days_of_from($calculation);
    my $from_extended = $from - ONE_DAY * $minus_days_of_from;

    my ($rows, $opt) = $data->get_data($id, $from_extended, $to);

    my $function_name = 'calculation_' . $calculation;
    my $rows_calculated = $self->$function_name($rows);
    my $rows_filtered = $self->filter_by_from($rows_calculated, $from);

    return $rows_filtered;
}

sub find_minus_days_of_from {
    my ($self, $calculation) = @_;

    foreach my $c ( @{CALCULATIONS()} ) {
        return $c->{minus_days_of_from} if $c->{function} eq $calculation;
    }

    return 0;
}

sub filter_by_from {
    my ($self, $rows, $from) = @_;

    my @rows_filtered = grep { $_->{datetime} >= $from } @$rows;
    return \@rows_filtered;
}

sub calculation_ {
    my ($self, $rows) = @_;

    return $rows;
}

sub calculation_runningtotal {
    my ($self, $rows) = @_;

    return $self->calculation_runningtotal_by($rows, sub {});
}

sub calculation_runningtotal_by_month {
    my ($self, $rows) = @_;

    return $self->calculation_runningtotal_by($rows, sub {
        my ($datetime, $last_datetime) = @_;
        my $month      = $datetime->strftime("%Y/%m");
        my $last_month = $last_datetime->strftime("%Y/%m");
        $month ne $last_month;
    });
}

sub calculation_runningtotal_by {
    my ($self, $rows, $by_function) = @_;

    my @calculated_rows;
    my %number;
    my %last_datetime;
    my $metrics_id;
    foreach my $row ( @$rows ) {
        $metrics_id = $row->{metrics_id};
        $number{$metrics_id} ||= 0;
        my $datetime = $row->{datetime};
        if ((exists $last_datetime{$metrics_id}) and $by_function->($datetime, $last_datetime{$metrics_id})) {
          $number{$metrics_id} = 0;
        }
        $number{$metrics_id} += $row->{number};
        push @calculated_rows, {
            metrics_id => $row->{metrics_id},
            datetime => $row->{datetime},
            number => $number{$metrics_id}
        };
        $last_datetime{$metrics_id} = $datetime;
    }

    return \@calculated_rows;
}

sub calculation_difference {
    my ($self, $rows) = @_;

    my @calculated_rows;
    my $number;
    my %last_number;
    my $metrics_id;
    foreach my $row ( @$rows ) {
        $number = $row->{number};
        $metrics_id = $row->{metrics_id};
        push @calculated_rows, {
            metrics_id => $row->{metrics_id},
            datetime => $row->{datetime},
            number => exists($last_number{$metrics_id}) ? $number - $last_number{$metrics_id} : 0
        };
        $last_number{$metrics_id} = $number;
    }

    return \@calculated_rows;
}

sub calculation_difference_plus {
    my ($self, $rows) = @_;

    $rows = $self->calculation_difference($rows);

    foreach my $row ( @$rows ) {
        if ($row->{number} < 0) {
            $row->{number} = 0;
        }
    }

    return $rows;
}

1;

