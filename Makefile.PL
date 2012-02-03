use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'HRForecast',
    VERSION_FROM  => 'lib/HRForecast.pm',
    PREREQ_PM     => {
        'Kossy' =>  '0.06',
    },
    MIN_PERL_VERSION => '5.008001'
);

