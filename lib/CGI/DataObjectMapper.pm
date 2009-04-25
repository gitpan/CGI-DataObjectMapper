package CGI::DataObjectMapper;
use Simo;

use 5.008_001;

our $VERSION = '0.0104';

use Simo::Constrain qw( is_class_name is_hash_ref is_array_ref );
use Simo::Util qw( define_class decode_values );

use Carp;
use File::Basename 'basename';
require Encode;

sub input{ ac constrain => \&is_hash_ref }

sub class_prefix{ ac default => '', constrain => sub{ $_ eq '' || is_class_name }, }
sub classes{ ac constrain => \&is_hash_ref }

sub obj{ ac auto_build => 1, read_only => 1 }
sub build_obj{
    my $self = shift;
    $self->{ obj } = $self->_map_input_to_object;
}

sub decode{ ac }
sub ignore{ ac default => [], constrain => \&is_array_ref }

sub REQUIRED_ATTRS{ qw/input classes/ }


sub _map_input_to_object{
    my $self = shift;
    my $valid_classes = $self->_rearrange_classes;
    my $input = $self->_rearrange_input;
    
    $self->_check_input( $input, $valid_classes );
    
    my $obj = $self->_create_object( $input );
    
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
    my $self = shift;
    my $input = $self->input;
    
    my $rearranged_input = {};
    my %ignore = map{ $_ => 1 } @{ $self->ignore };

    foreach my $key ( keys %$input ){
        next if $ignore{ $key };

        my ( $class, $attr ) = split( /--/, $key );
        croak "Class must be specified in key '$key'" unless $class;
        croak "Attribute must be specified in key '$key'" unless $attr;
        
        my @class_parts = split( /-/, $class );
        @class_parts = map{ ucfirst lc $_ } @class_parts;
        $class = join( '::', @class_parts );
        
        my @attr_parts = split( /-/, $attr );
        @attr_parts = map{ lc $_ } @attr_parts;
        $attr = join( '_', @attr_parts );
        
        $rearranged_input->{ $class }{ $attr }{ original_key } = $key ;
        $rearranged_input->{ $class }{ $attr }{ val } = $input->{ $key };
    }
    return $rearranged_input;
}

sub _check_input{
    my ( $self, $input, $valid_classes ) = @_;
    
    foreach my $class ( keys %$input ){
        foreach my $attr ( keys %{ $input->{ $class } } ){
            unless( $valid_classes->{ $class }{ $attr } ){
                my $original_key = $input->{ $class }{ $attr }{ original_key };
                croak "'$original_key' is invalid. 'classes' must be contain a corresponging class and attribute."
            }
        }
    }
}

sub _create_object{
    my ( $self, $input ) = @_;
    my $container_class = __PACKAGE__ . "::Container::Process$$";
    
    my %accessors_of_container;
    foreach ( keys %$input ){
        my $accessor = $_;
        $accessor =~ s/::/_/g;
        $accessor = lc $accessor;
        $accessors_of_container{ $_ } = $accessor;
    }

    unless( $container_class->can( 'new' ) ){
        # define Container Class
        define_class( $container_class, values %accessors_of_container );
    }
    
    my $container_obj = $container_class->new;
    my $prefix = $self->class_prefix;
    
    foreach my $class ( keys %$input ){
        my $class_with_prefix = $prefix ? "${prefix}::" . $class : $class;
        
        eval "require $class_with_prefix"
            unless $class_with_prefix->can( 'new' );
        
        croak "Cannot call '${class_with_prefix}::new'."
            unless $class_with_prefix->can( 'new' );
        
        my @attrs = keys %{ $input->{ $class } };
        
        
        my $obj = $class_with_prefix->new;
        foreach my $attr ( keys %{ $input->{ $class } } ){
            croak "class '$class_with_prefix' must have '$attr' method."
                unless $class_with_prefix->can( $attr );
            
            $obj->$attr( $input->{ $class }{ $attr }{ val } );
        }
        
        my $decode = $self->decode;
        decode_values( $obj, $decode, @attrs ) if $decode;
        
        my $accessor_of_container = $accessors_of_container{ $class };
        $container_obj->$accessor_of_container( $obj );
    }
    return $container_obj;
}

=head1 NAME

CGI::DataObjectMapper - Data-Object Mapper for CGI form data

=head1 CAUTION

This Module is yet experimental stage. Please wait until it will be statble.

=head1 VERSION

Version 0.0104

=head1 SYNOPSIS
    
    my $q = CGI->new;
    
    # create mapper object
    my $mapper = CGI::DataObjectMapper->new( 
        input => $q->Vars, # this is hash ref
        class_prefix => 'YourApp',
        classes => { 
            Person => qw/name age contry_name/,
            Data::Book => qw/title author/
        },
        decode => 'utf8',
    );
    
    my $obj = $mapper->obj; # get mapped object
    
    my $person_name = $obj->person->name;
    my $person_age = $obj->person->age;
    my $person_country_name = $obj->person->country_name;
    
    my $book_name = $obj->data_book->title;
    my $book_author = $obj->data_book->author;
    
    
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

    my $title = $obj->data_book->title;

=head2 classes

is mapped class names. this must be array ref.
[ qw( Person Data::Book ) ] etc.

=head2 obj

is converted object.

You can get object.

    $data = $mapper->obj;
    
    my $person_name = $obj->person->name;
    my $person_age = $obj->person->age;
    my $person_country_name = $obj->person->country_name;
    
    my $book_name = $obj->data_book->title;
    my $book_author = $obj->data_book->author;

=head2 decode

is charset when data is decoded. 'utf8' etc.

if this is not specify, decode is not done.

=head2 ignore

is ignored attribute. This must be array ref.


=head1 Method

=head2 build_obj

is build obj from input information.

This is automatically called when obj method is called.

If you set new input data, Please call this method

    $mapper->input( { a => 1, b => 2 } );
    $mapper->build_obj;
    my $obj = $mapper->obj; # data is updated

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
