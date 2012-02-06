use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'HRForecast',
    VERSION_FROM  => 'lib/HRForecast.pm',
    PREREQ_PM     => {
        'Kossy' =>  '0.06',
        'DBIx::Sunny' =>  '0.14',
        'DBD::mysql' => '4.018',
        'Time::Piece' => '1.15',
        'Time::Piece::MySQL' => '0.06',
        'HTTP::Date' => 0,
        'Log::Minimal' => '0.09',
        'List::MoreUtils' => '0',
        'Starlet' => '0.14',
        'Parallel::Scoreboard' => '0.03',
        'Plack::Builder::Conditionals' => '0.03',
        'Scope::Container::DBI' => '0.03',
        'Plack::Middleware::Scope::Container' => '0.01',
    },
    MIN_PERL_VERSION => '5.008001'
);

