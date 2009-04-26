use strict;
use warnings;

use Test::More 'no_plan';

use CGI::DataObjectMapper;

BEGIN{
    use_ok( 'CGI::DataObjectMapper' );
}


{
    my $o = CGI::DataObjectMapper->new(
        class_prefix => 'Prefix',
        classes => { 
            C1 => [ qw/m1 m2/ ],
            'C1::C1' => [ 'm1_m1' ]
         },
    );
    
    my $obj = $o->map_to_objects(
        {
            'c1--m1' => 1,
            'c1--m2' => 2,
            'c1-c1--m1-m1' => 5,
            'rm' => 1,
            'c3--' => 1,
            '--c4' => 1,
        }
    );
    
    my $c1 = $obj->{ 'C1' };
    my $c1_c1 = $obj->{ 'C1::C1' };
    
    isa_ok( $c1, "Prefix::C1" );
    is_deeply( $c1, { m1 => 1, m2 => 2 }, 'class mapping1-1' );
    
    isa_ok( $c1_c1, "Prefix::C1::C1" );
    is_deeply( $c1_c1, { m1_m1 => 5 }, 'class mapping1-3' );
    
    is_deeply( [ sort @{ $o->unmapped } ], [ sort ( qw/rm c3-- --c4/ ) ], 'unmapped' );
}

{
    my $o = CGI::DataObjectMapper->new(
        classes => { 
            C1 => [ qw/m1 m2/ ],
            'C1::C1' => [ 'm1_m1' ]
         },
    );
    
    my $obj = $o->map_to_objects(
        'c1--m1' => 1,
        'c1--m2' => "a\0b\0c",
        'c1-c1--m1-m1' => [ 'a', 'b' ],
        'rm' => 1,
        'c3--' => 1,
        '--c4' => 1,
        'c4--m1' => 1,
        'c1--m3' => 1,
    );
    
    my $c1 = $obj->{ 'C1' };
    my $c1_c1 = $obj->{ 'C1::C1' };
    
    isa_ok( $c1, "C1" );
    is_deeply( $c1, { m1 => 1, m2 => [ 'a', 'b', 'c' ] }, 'class mapping1-1' );
    
    isa_ok( $c1_c1, "C1::C1" );
    is_deeply( $c1_c1, { m1_m1 => [ 'a', 'b' ] }, 'class mapping1-3' );
    
    is_deeply( [ sort @{ $o->unmapped } ], [ sort ( qw/rm c3-- --c4 c1--m3 c4--m1/ ) ], 'unmapped' );
}


{
    my $o = CGI::DataObjectMapper->new( classes => {} );
    eval{ $o->map_to_objects( 1 ) };
    like( $@, qr/args must be hash or hash ref/, 'input is hash ref' );
}

{
    my $o = CGI::DataObjectMapper->new( classes => {} );
    
    eval{ $o->class_prefix( '' ) };
    ok( !$@, "class_prefix set '' ok" );
    
    eval{ $o->class_prefix( '~' ) };
    ok( $@, "class_prefix pass not class name" );
    
    eval{ $o->classes( 1 ) };
    ok( $@, "classes is not hash ref" );
}

{
    eval{ CGI::DataObjectMapper->new };
    ok( $@, 'calsses is required' );
    
    my $o = CGI::DataObjectMapper->new( classes => { C1 => 1 } );
    eval{ $o->map_to_objects( { 'c1--m1' => 1 } ) };
    like( $@, qr/each class of 'classes' has attribute list/, 'each class must be array ref' );
}
{
    my $o = CGI::DataObjectMapper->new( classes => { 'C4' => [ 'm2' ] } );
    eval{ $o->map_to_objects( { 'c4--m2' => 1 } ) };
    like( $@, qr/class 'C4' must have 'm2' method/, 'not accessor' );
}

package Prefix::C1;
use Simo;

sub m1{ ac }
sub m2{ ac }
sub m3{ ac }

package C1;
use Simo;

sub m1{ ac }
sub m2{ ac }
sub m3{ ac }

package Prefix::C1::C1;
use Simo;

sub m1_m1{ ac }

package C1::C1;
use Simo;

sub m1_m1{ ac }


package Prefix::C2;
use Simo;

sub m1{ ac }
sub m2{ ac }

sub m1_m1{ ac }

package C4;

sub new{ bless {}, __PACKAGE__ }
sub m1{ }
