package PBS::Getopt; 

use Moose; 
use MooseX::Types::Moose qw/Bool Str/; 

use namespace::autoclean; 
use experimental 'signatures'; 

with 'MooseX::Getopt::Usage';  

has 'user', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,
    reader    => 'get_user', 
    default   => $ENV{ USER },   
    documentation => "Owner of jobs"
); 

has 'format', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    reader    => 'get_format', 
    default   => 'verbose',  
    documentation => 'Status format'
); 

has 'yes', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    default   => 0, 
    documentation => "Answer yes to all user prompts"
); 

has 'all', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    predicate => 'has_all',
    default   => 0,  
    documentation => "Apply operation to all users"
); 

has 'debug', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    predicate => 'has_debug',  
    default   => 0, 
    documentation => "Debug mode"
); 

# from MooseX::Getopt
has '+extra_argv', ( 
    traits   => [ 'Array' ], 
    handles  => { 
        argv => 'elements'   
    }
); 

sub help ( $self, $exit ) { 
    $self->getopt_usage( exit => $exit ); 
} 

sub getopt_usage_config ( $self ) {
    return 
        format   => "Usage: %c <status|delete|reset> [OPTIONS]", 
        headings => 1
}

__PACKAGE__->meta->make_immutable;

1
