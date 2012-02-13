package HRForecast::Web;

use strict;
use warnings;
use utf8;
use Kossy;
use HTTP::Date;
use Time::Piece;
use HRForecast::Data;
use Log::Minimal;
use JSON qw//;

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

filter 'get_complex' => sub {
    my $app = shift;
    sub {
        my ($self, $c) = @_;
        my $row = $self->data->get_complex(
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

get '/docs' => [qw/sidebar/] => sub {
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
    'stack' => {
        default => 0,
        rule => [
            [['CHOICE',qw/1 0/],'invalid stack flag'],
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

get '/view/:service_name/:section_name/:graph_name' => [qw/sidebar get_metrics/] => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator($metrics_validator);
    my ($from ,$to) = $self->calc_term( map {$result->valid($_)} qw/t from to/);
    $c->render('list.tx', {
        metricses => [$c->stash->{metrics}],
        valid => $result, 
        date_window => encode_json([$from->strftime('%Y/%m/%d %T'), 
                                    $to->strftime('%Y/%m/%d %T')]),        
    });
};

get '/view_complex/:service_name/:section_name/:graph_name' => [qw/sidebar get_complex/] => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator($metrics_validator);
    my ($from ,$to) = $self->calc_term( map {$result->valid($_)} qw/t from to/);
    $c->render('list.tx', {
        metricses => [$c->stash->{metrics}],
        valid => $result, 
        date_window => encode_json([$from->strftime('%Y/%m/%d %T'), 
                                    $to->strftime('%Y/%m/%d %T')]),        
    });
};

get '/ifr/:service_name/:section_name/:graph_name' => [qw/get_metrics/] => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator($metrics_validator);
    my ($from ,$to) = $self->calc_term( map {$result->valid($_)} qw/t from to/);
    $c->render('ifr.tx', {
        metrics => $c->stash->{metrics},
        valid => $result, 
        date_window => encode_json([$from->strftime('%Y/%m/%d %T'), 
                                    $to->strftime('%Y/%m/%d %T')]),        
    });
};

get '/ifr_complex/:service_name/:section_name/:graph_name' => [qw/get_complex/] => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator($metrics_validator);
    my ($from ,$to) = $self->calc_term( map {$result->valid($_)} qw/t from to/);
    $c->render('ifr_complex.tx', {
        metrics => $c->stash->{metrics},
        valid => $result, 
        date_window => encode_json([$from->strftime('%Y/%m/%d %T'), 
                                    $to->strftime('%Y/%m/%d %T')]),        
    });
};

get '/ifr/preview/' => sub {
    my ( $self, $c )  = @_;
    $c->render('pifr_dummy.tx');
};

get '/ifr/preview/:complex' => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator($metrics_validator);
    my ($from ,$to) = $self->calc_term( map{ $result->valid($_) } qw/t from to/);

    my @complex = split /:/, $c->args->{complex};
    my @colors;
    for my $id ( @complex ) {
        my $data = $self->data->get_by_id($id);
        push @colors, $data ? $data->{colors} : '#cccccc';
    }

    $c->render('pifr.tx', {
        complex => $c->args->{complex},
        valid => $result, 
        colors => encode_json(\@colors),
        date_window => encode_json([$from->strftime('%Y/%m/%d %T'), 
                                    $to->strftime('%Y/%m/%d %T')]),        
    });
};

get '/edit/:service_name/:section_name/:graph_name' => [qw/sidebar get_metrics/] => sub {
    my ( $self, $c )  = @_;
    $c->render('edit.tx');
};

post '/edit/:service_name/:section_name/:graph_name' => [qw/get_metrics/] => sub {
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

post '/delete/:service_name/:section_name/:graph_name' => [qw/get_metrics/] => sub {
    my ( $self, $c )  = @_;
    $self->data->delete_metrics(
        $c->stash->{metrics}->{id},
    );
    $c->render_json({
        error => 0,
        location => $c->req->uri_for(
            '/list/'.$c->args->{service_name}.'/'.$c->args->{section_name})->as_string,
    });
};

get '/add_complex' => [qw/sidebar/] => sub {
    my ( $self, $c )  = @_;
    my $all_metrics_names = $self->data->get_all_metrics_name();
    $c->render('add_complex.tx', { all_metrics_names => $all_metrics_names } );
};

sub check_uniq_complex {
    my ($self,$id) = @_;
    sub {
        my ($req,$val) = @_;
        my $service = $req->param('service_name');
        my $section = $req->param('section_name');
        my $graph = $req->param('graph_name');
        $service = '' if !defined $service;
        $section = '' if !defined $section;
        $graph = '' if !defined $graph;
        my $row = $self->data->get_complex($service,$section,$graph);
        if ($id) {
            return 1 if $row && $row->{id} == $id;
        }
        return 1 if !$row;
        return;
    };
}

post '/add_complex' => sub {
    my ( $self, $c )  = @_;
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
                [$self->check_uniq_complex,'同じ名前のグラフがあります'],
            ],
        },
        'description' => {
            default => '',
            rule => [],
        },
        'stack' => {
            rule => [
                ['NOT_NULL', 'スタックの値がありません'],
                [['CHOICE',0,1], 'スタックの値が正しくありません'],
            ],
        },
        'sort' => {
            rule => [
                ['NOT_NULL', 'ソートの値がありません'],
                [['CHOICE',0..19], 'ソートの値が正しくありません'],
            ],
        },
        '@path-data' => {
            rule => [
                [['@SELECTED_NUM',1,10], 'データが正しくありません'],
                ['NOT_NULL','データが正しくありません'],
                ['NATURAL', 'データが正しくありません'],
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

    $self->data->create_complex(
        $result->valid('service_name'),$result->valid('section_name'),$result->valid('graph_name'),
        $result->valid->mixed
    );
    $c->render_json({
        error => 0,
        location => $c->req->uri_for('/list/'.$result->valid('service_name').'/'.$result->valid('section_name'))->as_string,
    });
};

get '/edit_complex/:service_name/:section_name/:graph_name' => [qw/sidebar get_complex/] => sub {
    my ( $self, $c )  = @_;
    my $all_metrics_names = $self->data->get_all_metrics_name();
    $c->render('edit_complex.tx', { all_metrics_names => $all_metrics_names } );
};

post '/edit_complex/:service_name/:section_name/:graph_name' => [qw/sidebar get_complex/] => sub {
    my ( $self, $c )  = @_;
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
                [$self->check_uniq_complex($c->stash->{metrics}->{id}),'同じ名前のグラフがあります'],
            ],
        },
        'description' => {
            default => '',
            rule => [],
        },
        'stack' => {
            rule => [
                ['NOT_NULL', 'スタックの値がありません'],
                [['CHOICE',0,1], 'スタックの値が正しくありません'],
            ],
        },
        'sort' => {
            rule => [
                ['NOT_NULL', 'ソートの値がありません'],
                [['CHOICE',0..19], 'ソートの値が正しくありません'],
            ],
        },
        '@path-data' => {
            rule => [
                [['@SELECTED_NUM',1,10], 'データが正しくありません'],
                ['NOT_NULL','データが正しくありません'],
                ['NATURAL', 'データが正しくありません'],
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

    $self->data->update_complex(
        $c->stash->{metrics}->{id},
        $result->valid->mixed
    );
    $c->render_json({
        error => 0,
        location => $c->req->uri_for('/list/'.$result->valid('service_name').'/'.$result->valid('section_name'))->as_string,
    });
};


post '/delete_complex/:service_name/:section_name/:graph_name' => [qw/get_complex/] => sub {
    my ( $self, $c )  = @_;
    $self->data->delete_complex(
        $c->stash->{metrics}->{id},
    );
    $c->render_json({
        error => 0,
        location => $c->req->uri_for(
            '/list/'.$c->args->{service_name}.'/'.$c->args->{section_name})->as_string,
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
    my $csv = sprintf("Date,/%s/%s/%s\n",$c->stash->{metrics}->{service_name},$c->stash->{metrics}->{section_name},$c->stash->{metrics}->{graph_name});
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

my $complex_csv =  sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator($metrics_validator);
    my ($from ,$to) = $self->calc_term( map{ $result->valid($_) } qw/t from to/);

    my @data;
    my @id;
    if ( !$c->stash->{metrics} ) {
        my @complex = split /:/, $c->args->{complex};
        for my $id ( @complex ) {
            my $data = $self->data->get_by_id($id);
            next unless $data;
            push @data, $data;
            push @id, $data->{id};
        }
    }
    else {
        @data = @{$c->stash->{metrics}->{metricses}};
        @id = map { $_->{id} } @data;
    }

    my ($rows,$opt) = $self->data->get_data(
        [ map { $_->{id} } @data ],
        $from, $to
    );

    my %date_group;
    foreach my $row ( @$rows ) {
        my $datetime = $row->{datetime}->strftime('%Y%m%d%H%M%S');
        $date_group{$datetime} ||= {};
        $date_group{$datetime}->{$row->{metrics_id}} = $row->{number};
    }

    my $csv = sprintf("Date,%s\n", join ",", map { $_->{service_name}.'/'.$_->{section_name}.'/'.$_->{graph_name} } @data);
    foreach my $key ( sort keys %date_group ) {
        $key =~ m!^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$!;
        my $datetime = sprintf "%s/%s/%s %s:%s:%s", $1, $2, $3, $4, $5, $6;
        my $csv_data = join ",", map { exists $date_group{$key}->{$_} ? $date_group{$key}->{$_} : '' } @id;
        $csv .= "$datetime,$csv_data\n";
    }

    if ( $result->valid('d') ) {
        $c->res->header('Content-Disposition',
                        sprintf('attachment; filename="metrics_%02d.csv"', int(rand(100)) ));
        $c->res->content_type('application/octet-stream');
    }
    else {
        $c->res->content_type('text/plain');
    }
    $c->res->body($csv);
    $c->res;    
};

get '/csv/:complex' => $complex_csv;
get '/csv_complex/:service_name/:section_name/:graph_name' => [qw/get_complex/] => $complex_csv;

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

