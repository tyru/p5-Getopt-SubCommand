use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name         => 'Getopt::SubCommand',
    license             => 'perl',
    dist_author         => 'tyru <tyru.exe@gmail.com>',
    dist_version_from   => 'lib/Getopt/SubCommand.pm',
    requires => {
        'Test::More' => 0,
        'Test::Pod' => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Perl::Critic' => 0,
        'Test::Exception' => 0,
        'Test::Output' => 0,
        'Data::Util' => 0,
        'Class::Accessor::Fast' => 0,
    },
    add_to_cleanup      => [ 'Getopt-SubCommand-*' ],
)->create_build_script;

