#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::DataObjectMapper' );
}

diag( "Testing CGI::DataObjectMapper $CGI::DataObjectMapper::VERSION, Perl $], $^X" );
