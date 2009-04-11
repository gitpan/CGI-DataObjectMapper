package CGI::DataObjectMapper;
use 5.008_001;

our $VERSION = '0.0101';

use Simo;
use Simo::Constrain qw( is_class_name is_hash_ref is_array_ref );
use Simo::Wrapper;

use Carp;
use File::Basename 'basename';

sub input{ ac constrain => \&is_hash_ref }
sub ignore{ ac default => [], constrain => \&is_array_ref }

sub class_prefix{ ac default => '', constrain => sub{ $_ eq '' || is_class_name }, }
sub default_class{ ac default => '' }
sub classes{ ac constrain => \&is_array_ref }

sub data{ ac auto_build => 1, read_only => 1 }
sub build_data{
    my $self = shift;
    $self->{ data } = $self->_parse_input;
}

sub decode{ ac }

sub REQUIRED_ATTRS{ qw/input classes/ }

sub _parse_input{
    my $self = shift;
    my $input = $self->input;
    my $data = {};
    
    my %valid_class = map{ $_ => 1 } @{ $self->classes };
    my $default_class = $self->default_class;
    
    if( $default_class ){
        croak "'classes' must be contain 'default_class'"
            unless $valid_class{ $default_class };
    }
    
    my %ignore = map{ $_ => 1 } @{ $self->ignore };
    
    foreach my $key ( keys %$input ){
        next if $ignore{ $key };
        
        my $key_arrange = $key =~ /--/ ? $key : "--$key";
        
        my ( $class, $accessor ) = split( /--/, $key_arrange );
        $class ||= $default_class;
        next unless $accessor;
        
        my @class_parts = split( /-/, $class );
        @class_parts = map{ ucfirst lc $_ } @class_parts;
        $class = join( '::', @class_parts );
        
        my @accessor_parts = split( /-/, $accessor );
        @accessor_parts = map{ lc $_ } @accessor_parts;
        $accessor = join( '_', @accessor_parts );
        
        croak "'$key' is invalid. 'classes' must be contain a corresponging class."
            unless $valid_class{ $class };
        
        my $val = $input->{ $key };
        if( my $decode = $self->decode ){
            require Encode;
            if( ref $val eq 'ARRAY' ){
               @{ $val } = map{ Encode::decode( $decode, $_ ) } @{ $val }
            }
            else{
                $val = Encode::decode( $decode, $val );
            }
        }
        
        $data->{ $class }{ $accessor } = $val;
    }
    
    
    my $prefix = $self->class_prefix;
    my $container_class = __PACKAGE__ . "::Container::Process$$";
    
    my %accessors_for_class;
    foreach ( keys %$data ){
        my $accessor = $_;
        $accessor =~ s/::/_/g;
        $accessor = lc $accessor;
        $accessors_for_class{ $_ } = $accessor;
    }

    unless( $container_class->can( 'new' ) ){
         my $w = Simo::Wrapper->create( obj => $container_class )->define( values %accessors_for_class );
    }
    
    my $container = $container_class->new;
    
    foreach my $class ( keys %$data ){
        my @accessors = keys %{ $data->{ $class } };
        my $class_with_prefix = $prefix ? "${prefix}::" . $class : $class;
        
        my $data_object = $class_with_prefix->new( %{ $data->{ $class } } );
        
        my $accessor_for_class = $accessors_for_class{ $class };
        $container->$accessor_for_class( $data_object );
    }
    return $container;
}


=head1 NAME

CGI::DataObjectMapper - Data-Object Mapper for CGI form data

=head1 CAUTION

This Module is yet experimental stage. Please wait until it will be statble.

=head1 VERSION

Version 0.0101

=head1 SYNOPSIS
    
    my $q = CGI->new;
    
    # create mapper object
    my $mapper = CGI::DataObjectMapper->new( 
        input => $q->Vars, # this is hash ref
        class_prefix => 'YourApp',
        classes => [ qw( Person Data::Book ) ],
        ignore => [ 'rm' ]
        decode => 'utf8',
    );
    
    my $data = $mapper->data; # get mapped object
    
    my $person_name = $data->person->name;
    my $person_age = $data->person->age;
    my $person_country_name = $data->person->country_name;
    
    my $book_name = $data->data_book->title;
    my $book_author = $data->data_book->author;
    
    
    package YourApp::Person;
    use Simo;
    
    sub name{ ac }
    sub age{ ac }
    sub country_name{ ac }
    
    
    package YourApp::Data::Book;
    use Simo;
    
    sub title{ ac }
    sub author{ ac }
    
    # Folloing is post data
    # This data is mapping YourApp::Person and YourApp::Data::Book
    
    <form method="post" action="xxxx.cgi" >
      <input type="hidden" name="rm" value="start-mode" />
      
      <input type="text" "name="person--name" value="some" />
      <input type="text" name="person--age" value="some" />
      
      <input type="text" name="data-book--title" value="some" />
      <input type="text" name="data-book--author" value="some" />
    </form>

=head1 DESCRIPTION

This module is data-object mapper for CGI form data.

and decode data if you want.

    
=head1 ACCESSORS

=head2 input

is input data. This must be hash ref.

Usually get hash data to use CGI::Vars method

   my $q = CGI->new;
   $q->Vars;

=head2 ignore

is ignored attribute. This must be array ref.

=head2 class_prefix

is class prefix. 

I want you to specify this value, because Some class names may be conficted.

=head2 default_class

is default class when class name cannot get form input attribute name.

    <input type="text" name="title" > # class is omited

    my $mapper = CGI::DataObjectMapper->new( 
        input => $q->Vars,
        default_class => 'Data::Book',
        classes => [ qw( Person Data::Book ) ],
    );

title is attribute of Data::Book

You can get title value this way.

    my $title = $data->data_book->title;

=head2 classes

is mapped class names. this must be array ref.
[ qw( Person Data::Book ) ] etc.


=head2 data

is converted data.

You can get object.

    $data = $mapper->data;
    
    my $person_name = $data->person->name;
    my $person_age = $data->person->age;
    my $person_country_name = $data->person->country_name;
    
    my $book_name = $data->data_book->title;
    my $book_author = $data->data_book->author;

=head2 decode

is charset when data is decoded. 'utf8' etc.

if this is not specify, decode is not done.

=head1 Method

=head2 build_data

is build data from input information.

This is automatically called when data method is called.

If you set new input data, Please call this method

    $mapper->input( { a => 1, b => 2 } );
    $mapper->build_data;
    my $data = $mapper->data; # data is updated

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-dataobjectmapper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-DataObjectMapper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::DataObjectMapper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-DataObjectMapper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-DataObjectMapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-DataObjectMapper>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-DataObjectMapper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of CGI::DataObjectMapper
