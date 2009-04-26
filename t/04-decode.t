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
        classes => { C1 => [ qw/m1 m2 m3/ ] },
        decode => 'utf8'
    );
    
    my $obj = $o->map_to_objects(
        {
            'c1--m1' => 'あ',
            'c1--m2' => [ qw( あ い ) ],
            'c1--m3' => "あ\0い",
        }
    );
    
    my $c1 = $obj->{ 'C1' };
    
    
    {
        use utf8;
        
        ok( utf8::is_utf8( $c1->m1 ), 'decode' );
        is( $c1->m1, "あ", 'decode' );
        
        ok( utf8::is_utf8( $c1->m2->[0] ), 'decode ary1' );
        is( $c1->m2->[0], "あ", 'decode ary1' );
        ok( utf8::is_utf8( $c1->m2->[1] ), 'decode ary2' );
        is( $c1->m2->[1], "い", 'decode ary1' );
        
        
        ok( utf8::is_utf8( $c1->m3->[0] ), 'decode ary1' );
        is( $c1->m3->[0], "あ", 'decode ary1' );
        ok( utf8::is_utf8( $c1->m3->[1] ), 'decode ary2' );
        is( $c1->m3->[1], "い", 'decode ary1' );
    }
}

package Prefix::C1;
use Simo;

sub m1{ ac }
sub m2{ ac }
sub m3{ ac }

sub ATTRS{ qw/m1 m2/ }

