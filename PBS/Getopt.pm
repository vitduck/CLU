package PBS::Getopt; 

use Moose; 
use MooseX::Types::Moose qw( Bool Str ); 
use namespace::autoclean; 

use experimental qw( signatures ); 

with qw( MooseX::Getopt::Usage ); 

has 'user', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,
    reader    => 'get_user', 
    default   => $ENV{ USER },   
    documentation => "Owner of jobs"
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
    reader    => 'all_job',
    default   => 0,  
    documentation => "Apply operation to all users"
); 

# from MooseX::Getopt
has '+extra_argv', ( 
    traits   => [ qw( Array ) ], 
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
