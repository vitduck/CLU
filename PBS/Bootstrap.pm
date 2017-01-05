package PBS::Bootstrap;

use Moose::Role;  
use MooseX::Types::Moose qw/Undef Str HashRef/; 
use File::Path 'rmtree';  

use namespace::autoclean; 
use experimental 'signatures'; 

has 'bootstrap', ( 
    is        => 'ro', 
    isa       => HashRef[ Str | Undef ], 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_bootstrap', 
    handles   => { 
        has_bootstrap => 'defined', 
        get_bootstrap => 'get'
    }
); 

sub delete_bootstrap ( $self, $job ) { 
    rmtree $self->get_bootstrap( $job ) if $self->has_bootstrap( $job ) 
} 

sub _build_bootstrap ( $self ) { 
    my %bootstrap = (); 
    
    for my $job ( $self->get_jobs ) { 
        $bootstrap{ $job } = (
            $self->get_owner( $job ) eq $ENV{USER}
            ? ( grep { -d and /bootstrap-\d+/ } glob "${ \$self->get_init( $job ) }/*" )[0]
            : undef
        )
    }

    return \%bootstrap
} 

1 
