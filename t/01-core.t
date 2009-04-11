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
            'c1--' => undef,
            'm1' => 3,
            'm2' => 4,
            'c1-c1--m1-m1' => 5,
        },
        class_prefix => 'Prefix',
        default_class => 'C2',
        classes => [ qw( C1 C1::C1 C2 ) ]
    );
    
    my $data = $o->data;
    
    my $c1 = $data->c1;
    my $c2 = $data->c2;
    my $c1_c1 = $data->c1_c1;
    
    isa_ok( $c1, "Prefix::C1" );
    is_deeply( $c1, { m1 => 1, m2 => 2 }, 'class mapping1-1' );
    
    isa_ok( $c2, "Prefix::C2" );
    is_deeply( $c2, { m1 => 3, m2 => 4 }, 'class mapping1-2' );
    
    isa_ok( $c1_c1, "Prefix::C1::C1" );
    is_deeply( $c1_c1, { m1_m1 => 5 }, 'class mapping1-3' );
}

{
    eval{ CGI::DataObjectMapper->new };
    ok( $@, 'no input' );
}

{
    eval{ CGI::DataObjectMapper->new( input => [] ) };
    ok( $@, 'input is not hash ref' );
}

{
    my $o = CGI::DataObjectMapper->new( input => {}, classes => [] );
    
    eval{ $o->class_prefix( '' ) };
    ok( !$@, "class_prefix set '' ok" );
    
    eval{ $o->class_prefix( '~' ) };
    ok( $@, "class_prefix pass not class name" );
    
    eval{ $o->classes( 1 ) };
    ok( $@, "classes is not array ref" );
    
    eval{ $o->data( 1 ) };
    ok( $@, "data is read only" );
}

{
    eval{ CGI::DataObjectMapper->new( classes => [] ) };
    ok( $@, 'input is required' );
    
    eval{ CGI::DataObjectMapper->new( input => {} ) };
    ok( $@, 'calsses is required' );
}

{
    my $o = CGI::DataObjectMapper->new( input => { 'c3--m1' => 1 }, classes => [] );
    eval{ $o->data };
    like( $@, qr/'c3--m1' is invalid\. 'classes' must be contain a corresponging class/, 'invalid key is passed' );
}

{
    my $o = CGI::DataObjectMapper->new( input => { 'c4--m1' => 1 }, classes => [ 'C4' ] );
    eval{ $o->data };
    like( $@, qr/class 'C4' must have 'ATTRS' method/, 'attr_method is not defined' );
}

{
    my $o = CGI::DataObjectMapper->new(
        input => {
            'c1--m1' => 1,
            'c1--m2' => 2,
            'c1--m3' => 3
        },
        class_prefix => 'Prefix',
        classes => [ qw( C1 ) ],
    );
    eval{ $o->data };
    like( $@, qr/'Prefix::C1::m3' is not valid attr \( Original key 'c1--m3' \)/, 'not attr keys' );
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
use Simo;

sub m1{ ac }

