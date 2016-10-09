package PBS::Getopt; 

use Moose; 
use MooseX::Types::Moose qw( Bool Str ); 
use namespace::autoclean; 
use experimental qw( signatures ); 

with 'MooseX::Getopt::Usage'; 

has 'user', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,
    reader    => 'get_user', 
    default   => $ENV{ USER },   
    documentation => "Owner of jobs"
); 

has 'job', ( 
    is        => 'ro', 
    isa       => Str, 
    predicate => 'has_job', 
    reader    => 'get_job', 
    documentation => "Comma separated list of jobs"
); 

has 'format', ( 
    is        => 'rw', 
    isa       => Str, 
    lazy      => 1, 
    reader    => 'get_format', 
    default   => 'verbose',  
    documentation => 'Status format'
); 

has 'yes', ( 
    is        => 'rw', 
    isa       => Bool, 
    lazy      => 1, 
    default   => 0, 
    documentation => "Answer yes to all user prompts"
); 

has 'all', ( 
    is        => 'rw', 
    isa       => Bool, 
    lazy      => 1, 
    default   => 0,  
    documentation => "Apply operation to all users"
); 

sub getopt_usage_config ( $self ) {
    return 
        format   => "Usage: %c <status|delete|reset> [OPTIONS]", 
        headings => 1
}

__PACKAGE__->meta->make_immutable;

1
