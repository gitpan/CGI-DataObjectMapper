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
            'c1--m1' => 'あ',
            'c1--m2' => [ qw( あ い ) ],
        },
        class_prefix => 'Prefix',
        classes => [ qw( C1 ) ],
        decode => 'utf8'
    );
    
    my $data = $o->data;
    
    my $c1 = $data->c1;
    ok( utf8::is_utf8( $c1->m1 ), 'decode' );
    
    ok( utf8::is_utf8( $c1->m2->[0] ), 'decode ary1' );
    ok( utf8::is_utf8( $c1->m2->[1] ), 'decode ary2' );
}

package Prefix::C1;
use Simo;

sub m1{ ac }
sub m2{ ac }

sub ATTRS{ qw/m1 m2/ }

