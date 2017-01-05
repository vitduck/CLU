package PBS::Format; 

use Moose::Role;  
use MooseX::Types::Moose qw/HashRef Str/; 
use List::Util 'max'; 

use namespace::autoclean; 
use experimental 'signatures'; 

has 'print_format', ( 
    is        => 'ro', 
    isa       => HashRef,  
    traits    => [ 'Hash' ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_print_format', 
    handles   => { 
        get_print_format => 'get'
    }
); 

sub _build_print_format ( $self ) { 
    my %format = ( 
        owner   => join( '', $self->_max_attr_length( 'owner'   ), 's' ), 
        name    => join( '', $self->_max_attr_length( 'name'    ), 's' ), 
        nodes   => join( '', $self->_max_attr_length( 'nodes'   ), 's' ), 
        elapsed => join( '', $self->_max_attr_length( 'elapsed' ), 's' ) 
    ); 

    return \%format; 
} 

sub _max_attr_length ( $self, $attr ) { 
    return ( 
        $self->all_job 
            ? max( 
            map length( $_->{$attr} ), 
            values $self->qstat->%* 
            ) 
            : max ( 
                map length( $_->{$attr} ), 
                grep $_->{ owner } eq $self->get_user, 
                values $self->qstat->%* 
            ) 
    )
} 

1
