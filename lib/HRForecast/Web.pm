package HRForecast::Web;

use strict;
use warnings;
use utf8;
use Kossy;
use HTTP::Date;
use Time::Piece;
use HRForecast::Data;
use Log::Minimal;
use JSON;

my $JSON = JSON->new()->ascii(1);
sub encode_json {
    $JSON->encode(shift);
}

sub data {
    my $self = shift;
    $self->{__data} ||= HRForecast::Data->new();
    $self->{__data};
}

sub calc_term {
    my $self = shift;
    my ($term, $from, $to) = @_;
    if ( $term eq 'w' ) {
        $from = time - 86400 * 10;
        $to = time;
    }
    elsif ( $term eq 'm' ) {
        $from = time - 86400 * 40;
        $to = time;
    }
    elsif ( $term eq 'y' ) {
        $from = time - 86400 * 400;
        $to = time;
    }
    else {
        $from = HTTP::Date::str2time($from);
        $to = HTTP::Date::str2time($to);
    }
    $from = localtime($from - ($from % 3600));
    $to = localtime($to - ($to % 3600));
    return ($from,$to);
}

filter 'sidebar' => sub {
    my $app = shift;
    sub {
        my ( $self, $c )  = @_;
        my $services = $self->data->get_services();
        my @services;
        for my $service ( @$services ) {
            my $sections = $self->data->get_sections($service);
            my @sections;
            for my $section ( @$sections ) {
                push @sections, {
                    active => 
                        $c->args->{service_name} && $c->args->{service_name} eq $service &&
                            $c->args->{section_name} && $c->args->{section_name} eq $section ? 1 : 0,
                    name => $section
                };
            }
            push @services , {
                name => $service,
                sections => \@sections,
            };
        }
        $c->stash->{services} = \@services;
        $app->($self,$c);
    }
};


filter 'get_metrics' => sub {
    my $app = shift;
    sub {
        my ($self, $c) = @_;
        my $row = $self->data->get(
            $c->args->{service_name}, $c->args->{section_name}, $c->args->{graph_name},
        );
        $c->halt(404) unless $row;
        $c->stash->{metrics} = $row;
        $app->($self,$c);
    }
};


get '/' => [qw/sidebar/] => sub {
    my ( $self, $c )  = @_;
    $c->render('index.tx', {});
};

get '/docs' => sub {
    my ( $self, $c )  = @_;
    $c->render('docs.tx',{});
};

my $metrics_validator = [
    't' => {
        default => 'm',
        rule => [
            [['CHOICE',qw/w m y c/],'invalid browse term'],
        ],
    },
    'from' => {
        default => localtime(time-86400*35)->strftime('%Y/%m/%d %T'),
        rule => [
            [sub{ HTTP::Date::str2time($_[1]) }, 'invalid From datetime'],
        ],
    },
    'to' => {
        default => localtime()->strftime('%Y/%m/%d %T'),
        rule => [
            [sub{ HTTP::Date::str2time($_[1]) }, 'invalid To datetime'],
        ],
    },
    'd' => {
        default => 0,
        rule => [
            [['CHOICE',qw/1 0/],'invalid download flag'],
        ],
    },
];

get '/list/:service_name/:section_name' => [qw/sidebar/] => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator($metrics_validator);
    my $rows = $self->data->get_metricses(
        $c->args->{service_name}, $c->args->{section_name}
    );
    my ($from ,$to) = $self->calc_term( map {$result->valid($_)} qw/t from to/);
    $c->render('list.tx',{ 
        metricses => $rows, valid => $result, 
        date_window => encode_json([$from->strftime('%Y/%m/%d %T'), 
                                    $to->strftime('%Y/%m/%d %T')]),
    });
};

get '/edit/:service_name/:section_name/:graph_name' => [qw/sidebar get_metrics/] => sub {
    my ( $self, $c )  = @_;
    $c->render('edit.tx');
};

post '/edit/:service_name/:section_name/:graph_name' => [qw/sidebar get_metrics/] => sub {
    my ( $self, $c )  = @_;
    my $check_uniq = sub {
        my ($req,$val) = @_;
        my $service = $req->param('service_name');
        my $section = $req->param('section_name');
        my $graph = $req->param('graph_name');
        $service = '' if !defined $service;
        $section = '' if !defined $section;
        $graph = '' if !defined $graph;
        my $row = $self->data->get($service,$section,$graph);
        return 1 if $row && $row->{id} == $c->stash->{metrics}->{id};
        return 1 if !$row;
        return;
    };
    my $result = $c->req->validator([
        'service_name' => {
            rule => [
                ['NOT_NULL', 'サービス名がありません'],
            ],
        },
        'section_name' => {
            rule => [
                ['NOT_NULL', 'セクション名がありません'],
            ],
        },
        'graph_name' => {
            rule => [
                ['NOT_NULL', 'グラフ名がありません'],
                [$check_uniq,'同じ名前のグラフがあります'],
            ],
        },
        'description' => {
            default => '',
            rule => [],
        },
        'sort' => {
            rule => [
                ['NOT_NULL', '値がありません'],
                [['CHOICE',0..19], '値が正しくありません'],
            ],
        },
        'color' => {
            rule => [
                ['NOT_NULL', '正しくありません'],
                [sub{ $_[1] =~ m!^#[0-9A-F]{6}$!i }, '#000000の形式で入力してください'],
            ],
        },
    ]);
    if ( $result->has_error ) {
        my $res = $c->render_json({
            error => 1,
            messages => $result->errors
        });
        return $res;
    }

    $self->data->update_metrics(
        $c->stash->{metrics}->{id},
        $result->valid->as_hashref
    );

    $c->render_json({
        error => 0,
        location => $c->req->uri_for(
            '/list/'.$result->valid('service_name').'/'.$result->valid('section_name'))->as_string,
    });
};

get '/csv/:service_name/:section_name/:graph_name' => [qw/get_metrics/] => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator($metrics_validator);
    my ($from ,$to) = $self->calc_term( map{ $result->valid($_) } qw/t from to/);
    my ($rows,$opt) = $self->data->get_data(
        $c->stash->{metrics}->{id},
        $from, $to
    );
    my $csv = sprintf("Date,%s\n",$c->args->{graph_name});
    foreach my $row ( @$rows ) {
        $csv .= sprintf "%s,%d\n", $row->{datetime}->strftime('%Y/%m/%d %T'), $row->{number}
    }
    if ( $result->valid('d') ) {
        $c->res->header('Content-Disposition',
                        sprintf('attachment; filename="metrics_%s.csv"',$c->stash->{metrics}->{id}));
        $c->res->content_type('application/octet-stream');
    }
    else {
        $c->res->content_type('text/plain');
    }
    $c->res->body($csv);
    $c->res;
};

post '/api/:service_name/:section_name/:graph_name' => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator([
        'number' => {
            rule => [
                ['NOT_NULL','number is null'],
                ['INT','number is not null']
            ],
        },
        'datetime' => {
            rule => [
                ['NOT_NULL','datetime is null'],
                [ sub { HTTP::Date::str2time($_[1]) } ,'datetime is not null']                
            ],
        },
    ]);

    if ( $result->has_error ) {
        my $res = $c->render_json({
            error => 1,
            messages => $result->messages
        });
        $res->status(400);
        return $res;
    }

    my $ret = $self->data->update(
        $c->args->{service_name}, $c->args->{section_name}, $c->args->{graph_name},
        $result->valid('number'), HTTP::Date::str2time($result->valid('datetime'))
    );
    $c->render_json({ error => 0 });
};

1;

