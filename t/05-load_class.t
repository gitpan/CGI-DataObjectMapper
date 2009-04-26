use strict;
use warnings;

use Test::More 'no_plan';

use CGI::DataObjectMapper;
use lib 't/05-load_class';

{
    my $o = CGI::DataObjectMapper->new(
        class_prefix => 'Prefix',
        classes => { C1 => [ 'm1' ] }
    );
    
    my $obj = $o->map_to_objects(
        {
            'c1--m1' => 1,
        }
    );
    
    my $c1 = $obj->{ 'C1' };
    
    isa_ok( $c1, "Prefix::C1" );
    is_deeply( $c1, { m1 => 1 }, 'load module' );
}

{
    my $o = CGI::DataObjectMapper->new(
        classes => { Ciilaksdjfie90892lasfj93k => [ 'm1' ] }
    );
    
    eval{ $o->map_to_objects(
            {
                'ciilaksdjfie90892lasfj93k--m1' => 1,
            }
        )
    };
    like( $@, qr/Cannot call 'Ciilaksdjfie90892lasfj93k::new'/, 'class is no exist' );
}
