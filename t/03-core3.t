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
            'c1--m3' => 3,
         },
         ignore => [ 'c1--m1', 'c1--m2' ],
         classes => [ 'C1' ],
         attr_method => 'columns'
    );
    
    is_deeply( $o->data->c1, { m3 => 3 }, 'ignore' );
}


package C1;
use Simo;

sub m1{ ac }
sub m2{ ac }
sub m3{ ac }

sub columns{ qw/m1 m2 m3/ }

