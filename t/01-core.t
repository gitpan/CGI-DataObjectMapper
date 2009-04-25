use strict;
use warnings;

use Test::More 'no_plan';

use CGI::DataObjectMapper;

BEGIN{
    use_ok( 'CGI::DataObjectMapper' );
}


{
    my $o = CGI::DataObjectMapper->new(
        input => {
            'c1--m1' => 1,
            'c1--m2' => 2,
            'c1-c1--m1-m1' => 5,
            'rm' => 1
        },
        class_prefix => 'Prefix',
        classes => { 
            C1 => [ qw/m1 m2/ ],
            'C1::C1' => [ 'm1_m1' ]
         },
         ignore => [ 'rm' ]
    );
    
    my $obj = $o->obj;
    
    my $c1 = $obj->c1;
    my $c1_c1 = $obj->c1_c1;
    
    isa_ok( $c1, "Prefix::C1" );
    is_deeply( $c1, { m1 => 1, m2 => 2 }, 'class mapping1-1' );
    
    isa_ok( $c1_c1, "Prefix::C1::C1" );
    is_deeply( $c1_c1, { m1_m1 => 5 }, 'class mapping1-3' );
}

{
    eval{ CGI::DataObjectMapper->new };
    ok( $@, 'no input' );
}

{
    eval{ CGI::DataObjectMapper->new( input => 1 ) };
    ok( $@, 'input is not hash ref' );
}

{
    my $o = CGI::DataObjectMapper->new( input => {}, classes => {} );
    
    eval{ $o->class_prefix( '' ) };
    ok( !$@, "class_prefix set '' ok" );
    
    eval{ $o->class_prefix( '~' ) };
    ok( $@, "class_prefix pass not class name" );
    
    eval{ $o->classes( 1 ) };
    ok( $@, "classes is not hash ref" );
    
    eval{ $o->obj( 1 ) };
    ok( $@, "obj is read only" );
}

{
    eval{ CGI::DataObjectMapper->new( classes => {} ) };
    ok( $@, 'input is required' );
    
    eval{ CGI::DataObjectMapper->new( input => {} ) };
    ok( $@, 'calsses is required' );
    
    my $o = CGI::DataObjectMapper->new( input => { 'c1--m1' => 1 }, classes => { C1 => 1 } );
    eval{ $o->obj };
    like( $@, qr/each class of 'classes' has attribute list/, 'each class must be array ref' );
}

{
    eval{ CGI::DataObjectMapper->new( input => {}, classes => {}, ignore => 1 ) };
    ok( $@, 'ignore not array ref' );
}

{
    my $o = CGI::DataObjectMapper->new( input => { 'c3--m1' => 1 }, classes => {} );
    eval{ $o->obj };
    like( $@, qr/'c3--m1' is invalid\. 'classes' must be contain a corresponging class/, 'invalid key is passed' );
}

{
    my $o = CGI::DataObjectMapper->new(
        input => {
            'c1--m1' => 1,
            'c1--m2' => 2,
            'c1--m3' => 3
        },
        class_prefix => 'Prefix',
        classes => { C1 => [ qw/m1 m2/ ] },
    );
    eval{ $o->obj };
    like( $@, qr/'c1--m3' is invalid\. 'classes' must be contain a corresponging class and attribute/, 'not contained in classes' );
}

{
    my $o = CGI::DataObjectMapper->new(
        input => { '--c1' => 1 },
        classes => {}
    );
    
    eval{ $o->obj };
    
    like( $@, qr/Class must be specified in key '--c1'/, 'not specifed class' )
}

{
    my $o = CGI::DataObjectMapper->new(
        input => { 'c1--' => 1 },
        classes => {}
    );
    
    eval{ $o->obj };
    
    like( $@, qr/Attribute must be specified in key 'c1--'/, 'not specifed attr' )
}

package Prefix::C1;
use Simo;

sub m1{ ac }
sub m2{ ac }
sub m3{ ac }

sub ATTRS{ qw/m1 m2/ }

package Prefix::C1::C1;
use Simo;

sub m1_m1{ ac }

sub ATTRS{ qw/m1_m1/ }


package Prefix::C2;
use Simo;

sub m1{ ac }
sub m2{ ac }

sub m1_m1{ ac }

sub ATTRS{ qw/m1 m2 m1_m1/ }

package C4;

sub new{ bless {}, __PACKAGE__ }
sub m1{ }
