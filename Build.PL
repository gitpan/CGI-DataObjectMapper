use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::DataObjectMapper',
    license             => 'perl',
    dist_author         => 'Yuki Kimoto <kimoto.yuki@gmail.com>',
    dist_version_from   => 'lib/CGI/DataObjectMapper.pm',
    build_requires => {
        'Test::More' => 0,
        'Simo' => 0.1007,
    },
    requires => {
        'Object::Simple' => 0.0203,
        'Object::Simple::Constraint' => 0,
        'Simo::Util' => 0.0301
    },
    add_to_cleanup      => [ 'CGI-DataObjectMapper-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
