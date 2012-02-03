package HRForecast::Data;


use strict;
use warnings;
use utf8;
use Time::Piece;
use Time::Piece::MySQL;
use JSON;
use Log::Minimal;
use DBIx::Sunny;
use Scope::Container::DBI;
use List::MoreUtils qw/uniq/;
use List::Util qw/first/;

my $JSON = JSON->new()->ascii(1);
sub encode_json {
    $JSON->encode(shift);
}

sub new {
    my $class = shift;
    bless {}, $class;
}

sub dbh {
    my $self = shift;
    local $Scope::Container::DBI::DBI_CLASS = 'DBIx::Sunny';    
    Scope::Container::DBI->connect(
        HRForecast->config->{dsn},
        HRForecast->config->{username},
        HRForecast->config->{password}
    );
}

sub inflate_row {
    my ($self, $row) = @_;
    $row->{created_at} = Time::Piece->from_mysql_datetime($row->{created_at});
    $row->{updated_at} = Time::Piece->from_mysql_timestamp($row->{updated_at});
    my $ref =  decode_json($row->{meta}||'{}');
    my %result = (
        %$ref,
        %$row
    );
    $result{colors} = encode_json([$result{color}]);
    \%result
}

sub inflate_data_row {
    my ($self, $row) = @_;
    $row->{datetime} = Time::Piece->from_mysql_datetime($row->{datetime});
    $row->{updated_at} = Time::Piece->from_mysql_timestamp($row->{updated_at});
    my %result = (
        %$row
    );
    \%result
}

sub inflate_complex_row {
    my ($self, $row) = @_;
    $row->{created_at} = Time::Piece->from_mysql_datetime($row->{created_at});
    $row->{updated_at} = Time::Piece->from_mysql_timestamp($row->{updated_at});
    my $ref =  decode_json($row->{meta}||'{}');
    my %result = (
        %$ref,
        %$row
    );
    \%result
}

sub get {
    my ($self, $service, $section, $graph) = @_;
    my $row = $self->dbh->select_row(
        'SELECT * FROM metrics WHERE service_name = ? AND section_name = ? AND graph_name = ?',
        $service, $section, $graph
    );
    return unless $row;
    $self->inflate_row($row);
}

sub get_by_id {
    my ($self, $id) = @_;
    my $row = $self->dbh->select_row(
        'SELECT * FROM metrics WHERE id = ?',
        $id
    );
    return unless $row;
    $self->inflate_row($row);
}

sub update {
    my ($self, $service, $section, $graph, $number, $timestamp ) = @_;
    my $dbh = $self->dbh;
    $dbh->begin_work;
    my $metrics = $self->get($service, $section, $graph);
    if ( ! defined $metrics ) {
        my @colors = List::Util::shuffle(qw/33 66 99 cc/);
        my $color = '#' . join('', splice(@colors,0,3));
        my $meta = encode_json({ color => $color });
        $dbh->query(
            'INSERT INTO metrics (service_name, section_name, graph_name, meta, created_at) 
                         VALUES (?,?,?,?,NOW())',
            $service, $section, $graph, $meta
        );
        $metrics = $self->get($service, $section, $graph);
    }
    $dbh->commit;

    my $fixed_timestamp = $timestamp - ($timestamp % 3600);
    $dbh->query(
        'REPLACE data SET metrics_id = ?, datetime = ?, number = ?',
        $metrics->{id}, localtime($fixed_timestamp)->mysql_datetime, $number
    );

    1;
}

sub get_data {
    my ($self, $id, $from, $to) = @_;

    my $rows = $self->dbh->select_all(
        'SELECT * FROM data WHERE metrics_id = ? AND (datetime BETWEEN ? AND ?) ORDER BY datetime ASC',
        $id, localtime($from)->mysql_datetime, localtime($to)->mysql_datetime
    );
    my @ret;
    for my $row ( @$rows ) {
        push @ret, $self->inflate_data_row($row); 
    }
    return \@ret, {
        from => Time::Piece->new($from),
        to => Time::Piece->new($to),
    };
}


sub get_services {
    my $self = shift;
    my $rows = $self->dbh->select_all(
        'SELECT DISTINCT service_name FROM metrics ORDER BY service_name',
    );
    my $complex_rows = $self->dbh->select_all(
        'SELECT DISTINCT service_name FROM complex ORDER BY service_name',
    );
    my @names = uniq map { $_->{service_name} } (@$rows,@$complex_rows);
    \@names
}

sub get_sections {
    my $self = shift;
    my $service_name = shift;
    my $rows = $self->dbh->select_all(
        'SELECT DISTINCT section_name FROM metrics WHERE service_name = ? ORDER BY section_name',
        $service_name,
    );
    my $complex_rows = $self->dbh->select_all(
        'SELECT DISTINCT section_name FROM complex WHERE service_name = ? ORDER BY section_name',
        $service_name,
    );
    my @names = uniq map { $_->{section_name} } (@$rows,@$complex_rows);
    \@names;
} 


sub get_metricses {
   my $self = shift;
   my ($service_name, $section_name) = @_;
   my $rows = $self->dbh->select_all(
       'SELECT * FROM metrics WHERE service_name = ? AND section_name = ? ORDER BY sort DESC',
       $service_name, $section_name
   );
   my $complex_rows = $self->dbh->select_all(
       'SELECT * FROM complex WHERE service_name = ? AND section_name = ? ORDER BY sort DESC',
       $service_name, $section_name
   );
   my @ret;
   for my $row ( @$rows ) {
       push @ret, $self->inflate_row($row); 
   }
   for my $row ( @$complex_rows ) {
       push @ret, $self->inflate_complex_row($row); 
   }
   @ret = sort { $b->{sort} <=> $a->{sort} } @ret;
   \@ret;
}


1;

