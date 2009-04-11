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
            'c2--m1' => 3,
            'c2--m2' => 4,
            'c1-c1--m1-m1' => 5,
        },
        classes => [ qw( C1 C1::C1 C2 ) ],
        attr_method => { C1 => 'columns', other => 'attr_list' }
    );
    
    my $data = $o->data;
    
    my $c1 = $data->c1;
    my $c2 = $data->c2;
    my $c1_c1 = $data->c1_c1;
    
    isa_ok( $c1, "C1" );
    is_deeply( $c1, { m1 => 1, m2 => 2 }, 'class mapping1-1' );
    
    isa_ok( $c2, "C2" );
    is_deeply( $c2, { m1 => 3, m2 => 4 }, 'class mapping1-2' );
    
    isa_ok( $c1_c1, "C1::C1" );
    is_deeply( $c1_c1, { m1_m1 => 5 }, 'class mapping1-3' );
}

package C1;
use Simo;

sub m1{ ac }
sub m2{ ac }

sub columns{ qw/m1 m2/ }

package C1::C1;
use Simo;

sub m1_m1{ ac }

sub attr_list{ qw/m1_m1/ }

package C2;
use Simo;

sub m1{ ac }
sub m2{ ac }

sub m1_m1{ ac }

sub attr_list{ qw/m1 m2 m1_m1/ }