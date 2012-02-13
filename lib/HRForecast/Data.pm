package HRForecast::Data;


use strict;
use warnings;
use utf8;
use Time::Piece;
use Time::Piece::MySQL;
use JSON qw//;
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
    my $ref =  JSON::decode_json($row->{meta}||'{}');
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
    my $ref =  JSON::decode_json($row->{meta}||'{}');
    $ref->{uri} = join ":", @{ $ref->{'path-data'} };
    $ref->{complex} = 1;
    $ref->{metricses} = [];
    for my $metrics_id ( @{ $ref->{'path-data'} } ) {
        my $data = $self->get_by_id($metrics_id);
        push @{$ref->{metricses}}, $data if $data;
    }
    $ref->{colors} = encode_json([ map { $_->{color} } @{$ref->{metricses}} ]);
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

sub update_metrics {
    my ($self, $id, $args) = @_;
    my @update = map { delete $args->{$_} } qw/service_name section_name graph_name sort/;
    my $meta = encode_json($args);
    my $dbh = $self->dbh;
    $dbh->query(
        'UPDATE metrics SET service_name=?, section_name=?, graph_name=?, sort=?, meta=? WHERE id = ?',
        @update, $meta,  $id
    );
    return 1;
}

sub delete_metrics {
    my ($self, $id) = @_;
    my $dbh = $self->dbh;
    $dbh->begin_work;
    my $rows = 1;
    while ( $rows > 1 ) {
        $rows = $dbh->query('DELETE FROM data WHERE metrics_id = ? LIMIT 1000',$id);
    }
    $dbh->query('DELETE FROM metrics WHERE id =?',$id);
    $dbh->commit;
    1;
}


sub get_data {
    my ($self, $id, $from, $to) = @_;
    my @id = ref $id ? @$id : ($id);
    my $rows = $self->dbh->select_all(
        'SELECT * FROM data WHERE metrics_id IN (?) AND (datetime BETWEEN ? AND ?) ORDER BY datetime ASC',
        \@id, localtime($from)->mysql_datetime, localtime($to)->mysql_datetime
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

sub get_all_metrics_name {
   my $self = shift;
   $self->dbh->select_all(
       'SELECT id,service_name,section_name,graph_name FROM metrics ORDER BY service_name, section_name, sort DESC',
   );
}

sub get_complex {
    my ($self, $service, $section, $graph) = @_;
    my $row = $self->dbh->select_row(
        'SELECT * FROM complex WHERE service_name = ? AND section_name = ? AND graph_name = ?',
        $service, $section, $graph
    );
    return unless $row;
    $self->inflate_complex_row($row);
}

sub get_complex_by_id {
    my ($self, $id) = @_;
    my $row = $self->dbh->select_row(
        'SELECT * FROM complex WHERE id = ?',
        $id
    );
    return unless $row;
    $self->inflate_complex_row($row);
}

sub create_complex {
    my ($self, $service, $section, $graph, $args) = @_;
    my @update = map { delete $args->{$_} } qw/sort/;
    my $meta = encode_json($args);
    $self->dbh->query(
        'INSERT INTO complex (service_name, section_name, graph_name, sort, meta,  created_at) 
                         VALUES (?,?,?,?,?,NOW())',
        $service, $section, $graph, @update, $meta
    ); 
    $self->get_complex($service, $section, $graph);
}

sub update_complex {
    my ($self, $id, $args) = @_;
    my @update = map { delete $args->{$_} } qw/service_name section_name graph_name sort/;
    my $meta = encode_json($args);
    $self->dbh->query(
        'UPDATE complex SET service_name=?, section_name=?, graph_name=?, sort=?, meta=? WHERE id=?',
        @update, $meta, $id
    );
}

sub delete_complex {
    my ($self, $id) = @_;
    $self->dbh->query(
        'DELETE FROM complex WHERE id=?',
        $id
    );
}

1;


