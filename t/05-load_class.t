use strict;
use warnings;

use Test::More 'no_plan';

use CGI::DataObjectMapper;
use lib 't/05-load_class';

{
    my $o = CGI::DataObjectMapper->new(
        input => {
            'c1--m1' => 1,
        },
        class_prefix => 'Prefix',
        classes => [ qw( C1 ) ]
    );
    
    my $data = $o->data;
    
    my $c1 = $data->c1;
    
    isa_ok( $c1, "Prefix::C1" );
    is_deeply( $c1, { m1 => 1 }, 'load module' );
}

{
    my $o = CGI::DataObjectMapper->new(
        input => {
            'ciilaksdjfie90892lasfj93k--m1' => 1,
        },,
        classes => [ qw( Ciilaksdjfie90892lasfj93k ) ]
    );
    
    eval{ $o->data };
    like( $@, qr/Cannot call 'Ciilaksdjfie90892lasfj93k::new'/, 'class is no exist' );
}
