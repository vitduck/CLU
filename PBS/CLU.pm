package PBS::CLU;

use Moose; 
use MooseX::Types::Moose qw( Bool Str ArrayRef HashRef );  
use PBS::Types qw( ID ); 
use File::Find; 
use namespace::autoclean; 
use experimental qw( signatures );   

with qw( MooseX::Getopt::Usage );  
with qw( PBS::Job PBS::Status );  

has 'user', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,
    default   => $ENV{ USER },   

    documentation => "Owner of jobs"
); 

has 'job', ( 
    is        => 'ro', 
    isa       => Str, 
    predicate => 'has_job', 

    documentation => "Comma separated list of jobs"
); 

has 'format', ( 
    is        => 'rw', 
    isa       => Str, 
    lazy      => 1, 
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

has 'job_list', ( 
    is        => 'ro', 
    isa       => ArrayRef,  
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    init_arg  => undef,  
    builder   => '_build_job_list', 
    handles   => { 
        get_job_list => 'elements' 
    }, 
); 

sub BUILD ( $self, @ ) { 
    $self->qstat; 
} 

sub getopt_usage_config ( $self ) {
    return 
        format   => "Usage: %c <status|delete|reset> [OPTIONS]", 
        headings => 1
}

sub status ( $self ) { 
    for my $job ( $self->get_job_list ) {  
        $self->print_status( $job, $self->format )
    }
} 

sub delete_job ( $self ) { 
    for my $job ( $self->get_job_list ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt( 'delete', $job ) ) { 
            $self->delete( $job ); 
            $self->clean( $job )
        }
    } 
} 

sub reset_job ( $self ) { 
    for my $job ( $self->get_job_list ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt( 'reset', $job ) ) { 
            $self->reset( $job )
        } 
    } 
} 

sub prompt ( $self, $method, $job ) { 
    printf "\n=> %s %s ? y/s [n] ", ucfirst( $method ), $job;  
    chomp ( my $reply = <STDIN> );  

    return 1 if $reply =~ /y|yes/i 
} 

# native
sub _build_job_list ( $self ) { 
    return [
        $self->has_job 
        ? do {  
            grep { $self->isa_job( $_ ) }   # check from cached 
            map { s/(\d+).*$/$1/; $_ }      # strip the hostname 
            split /,/, $self->job           # turn string to list 
        }
        : do { 
            my @jobs = sort { $a <=> $b } $self->get_jobs; 
            
            # return all job if --all is set
            $self->all
            ? @jobs          
            : grep $self->get_owner( $_) eq $self->user, @jobs 
        }
    ]
} 

__PACKAGE__->meta->make_immutable;

1
