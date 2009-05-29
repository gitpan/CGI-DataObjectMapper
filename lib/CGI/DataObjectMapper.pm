package CGI::DataObjectMapper;
use Object::Simple;

use 5.008_001;

our $VERSION = '0.0106';

use Object::Simple::Constraint qw( is_class_name );
use Simo::Util qw( decode_values );

use Carp;
use File::Basename 'basename';
require Encode;

sub class_prefix : Attr {default => ''}
sub classes      : Attr {}
sub decode       : Attr {}
sub unmapped     : Attr {}

sub map_to_objects{
    my ( $self, @input ) = @_;
    
    @input = %{ $input[0] } if ref $input[0] eq 'HASH';
    croak "args must be hash or hash ref." if @input % 2;
    
    my $rearranged_input = $self->_rearrange_input( @input );
    
    my $obj = $self->_create_objects( $rearranged_input );
    
    return $obj;
}

# rearrange classes
sub _rearrange_classes{
    my $self = shift;
    my $classes = $self->classes;
    
    my $rearranged_classes = {};
    foreach my $class ( keys %{ $self->classes } ){
        my $attrs = $classes->{ $class };
        croak "each class of 'classes' has attribute list" unless ref $attrs eq 'ARRAY';
        foreach my $attr ( @{ $classes->{ $class } } ){
            $rearranged_classes->{ $class }{ $attr } = 1;
        }
    }
    return $rearranged_classes;
}

sub _rearrange_input{
    my ( $self, %input ) = @_;
    
    my $rearranged_input = {};
    my $valid_classes = $self->_rearrange_classes;
    
    my $unmapped = [];

    foreach my $key ( keys %input ){

        my ( $class, $attr ) = split( /--/, $key );
        
        if( !$class || !$attr ){
            push @{ $unmapped }, $key;
            next;
        }
        
        my @class_parts = split( /-/, $class );
        @class_parts = map{ ucfirst lc $_ } @class_parts;
        $class = join( '::', @class_parts );
        
        my @attr_parts = split( /-/, $attr );
        @attr_parts = map{ lc $_ } @attr_parts;
        $attr = join( '_', @attr_parts );
        
        unless( $valid_classes->{ $class }{ $attr } ){
            push @{ $unmapped }, $key;
            next;
        }
        
        $rearranged_input->{ $class }{ $attr }{ original_key } = $key ;
        
        my $val = $input{ $key };
        if( !ref $val && $val =~ /\0/ ){
            $val = [ split( /\0/, $val, -1 ) ];
        }
        $rearranged_input->{ $class }{ $attr }{ val } = $val;
    }
    
    $self->unmapped( $unmapped );
    return $rearranged_input;
}

sub _create_objects{
    my ( $self, $input ) = @_;
    my $objects = {};
    
    my $prefix = $self->class_prefix;
    my @classes = keys %{ $self->classes };
    
    foreach my $class ( @classes ){
        my $class_with_prefix = $prefix ? "${prefix}::" . $class : $class;
        
        eval "require $class_with_prefix"
            unless $class_with_prefix->can( 'new' );
        
        croak "Cannot call '${class_with_prefix}::new'."
            unless $class_with_prefix->can( 'new' );
        
        my @attrs = keys %{ $input->{ $class } };
        
        my $object = $class_with_prefix->new;
        foreach my $attr ( @attrs ){
            croak "class '$class_with_prefix' must have '$attr' method."
                unless $class_with_prefix->can( $attr );
            
            $object->$attr( $input->{ $class }{ $attr }{ val } );
        }
        
        my $decode = $self->decode;
        decode_values( $object, $decode, @attrs ) if $decode;
        
        $objects->{ $class } = $object;
    }
    return $objects;
}

Object::Simple->end; # End of Object::Simple!

=head1 NAME

CGI::DataObjectMapper - Data-Object Mapper for CGI form data

=head1 CAUTION

This Module is yet experimental stage. Please wait until it will be statble.

=head1 VERSION

Version 0.0106

=head1 SYNOPSIS
    
    my $q = CGI->new;
    
    # create mapper object
    my $mapper = CGI::DataObjectMapper->new( 
        class_prefix => 'YourApp',
        classes => { 
            Person => qw/name age contry_name/,
            'Data::Book' => qw/title author/
        },
        decode => 'utf8',
    );
    
    my $objects = $mapper->map_to_objects( $q->Vars );
    
    my $person = $objects->{ 'Person' };
    my $person_name = $person->name;
    my $person_age = $person->age;
    my $person_country_name = $person->country_name;
    
    my $book = $objects->{ 'Data::Book' };
    my $book_title = $data_book->title;
    my $book_author = $data_book->author;
    
    
    package YourApp::Person;
    use Object::Simple;
    
    sub name : Attr {}
    sub age : Attr {}
    sub country_name : Attr {}
    
    Object::Simple->end;
   
    package YourApp::Data::Book;
    use Object::Simple;
    
    sub title : Attr {}
    sub author : Attr {}
    
    Object::Simple->end;
    
    # Folloing is post data
    # This data is mapping YourApp::Person and YourApp::Data::Book
    
    <form method="post" action="xxxx.cgi" >
      <input type="hidden" name="rm" value="start-mode" />
      
      <input type="text" "name="person--name" value="some" />
      <input type="text" name="person--age" value="some" />
      <input type="text" name="person--country-name" value="some" />
      
      <input type="text" name="data-book--title" value="some" />
      <input type="text" name="data-book--author" value="some" />
    </form>

=head1 DESCRIPTION

This module is data-object mapper for CGI form data.

and decode data if you want.

    
=head1 ACCESSORS


Usually get hash data to use CGI::Vars method

   my $q = CGI->new;
   $q->Vars;

=head2 class_prefix

is class prefix. 

I want you to specify this value, because Some class names may be conficted.

=head2 classes

is mapped class names. this must be array ref.
    
    {
        Person => qw/name age contry_name/,
        'Data::Book' => qw/title author/
    }

etc.

=head2 decode

is charset when data is decoded. 'utf8' etc.

if this is not specify, decode is not done.


=head1 Method

=head2 map_to_objects

convert input to objects.

You can get object.

    my $objects = $mapper->map_to_objects( $q->Vars );
    
    my $person = $objects->{ 'Person' };
    my $person_name = $person->name;
    my $person_age = $person->age;
    my $person_country_name = $person->country_name;
    
    my $book = $objects->{ 'Data::Book' };
    my $book_title = $data_book->title;
    my $book_author = $data_book->author;

=head2 unmapped

You can get unmapped key after calling map_to_objects

    my $unmapped = $mapper->unmapped;

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
