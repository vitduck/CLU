package PBS::Bootstrap; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 

# core 
use File::Path qw(rmtree); 

# cpan 
use Moose::Role;  
use namespace::autoclean; 
use Try::Tiny; 

# features 
use experimental qw(signatures); 

# <attributes>
has 'bootstrap', ( 
    is        => 'ro', 
    isa       => 'Str', 
    lazy      => 1,   
    init_arg  => undef, 

    default   => sub ( $self ) { 
        # silent the permission error
        my $bootstrap = try { (grep { -d and /bootstrap-\d+/ } glob "${\$self->init}/*" )[0] }; 

        return $bootstrap //= ''; 
    },    
); 

# <methods> 
# remove bootstrap directory after job deletion
sub clean ( $self ) { 
    if ( $self->bootstrap ) { rmtree $self->bootstrap };  
} 

1; 
