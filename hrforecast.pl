#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/extlib/lib/perl5";
use lib "$FindBin::Bin/lib";
use File::Basename;
use Getopt::Long;
use File::Temp qw/tempdir/;
use Plack::Loader;
use Plack::Builder;
use Plack::Builder::Conditionals;
use Plack::Middleware::Header;
use Log::Minimal;
use HRForecast;
use HRForecast::Web;

$Log::Minimal::AUTODUMP = 1;

Getopt::Long::Configure ("no_ignore_case");
GetOptions(
    "c|config=s" => \my $config_file,
    "h|help" => \my $help,
);

if ( $help || !$config_file ) {
    print "usage: $0 --config config.pl\n";
    exit(1);
}

my $config;
{
    $config = do $config_file;
    croakf "%s: %s", $config_file, $@ if $@;
    croakf "%s: %s", $config_file, $! if $!;
    croakf "%s does not return hashref", $config_file if ref($config) ne 'HASH';
}

my $port = $config->{port} || 5125;
my $host = $config->{host} || 0;
my @front_proxy = exists $config->{front_proxy} ? @{$config->{front_proxy}} : ();
my @allow_from = exists $config->{allow_from} ? @{$config->{allow_from}} : ();
my @header = exists $config->{header} ? @{$config->{header}} : ();

local $HRForecast::CONFIG = $config;
debugf('dump config:%s',$config);

my $root_dir = File::Basename::dirname(__FILE__);
my $app = HRForecast::Web->psgi($root_dir);
$app = builder {
    enable 'Lint';
    enable 'StackTrace';
    if ( @front_proxy ) {
        enable match_if addr(\@front_proxy), 'ReverseProxy';
    }
    if ( @allow_from ) {
        enable match_if addr('!',\@allow_from), sub {
            sub { [403,['Content-Type','text/plain'], ['Forbidden']] }
        };
    }
    if ( @header ) {
        enable 'Header', @header;
    }
    enable 'Static',
        path => qr!^/(?:(?:css|js|img|fonts)/|favicon\.ico$)!,
            root => $root_dir . '/public';
    enable 'Scope::Container';
    $app;
};
my $loader = Plack::Loader->load(
    'Starlet',
    port => $port,
    host => $host || 0,
    max_workers => 5,
);
$loader->run($app);
