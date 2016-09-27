package PBS::CLU;

use File::Find; 

use Moose; 
use MooseX::Types::Moose qw( Bool Str ArrayRef HashRef ); 
use PBS::Types qw( ID ); 

use namespace::autoclean; 
use experimental qw( signatures );  

with qw( PBS::Job ); 
with qw( PBS::Status ); 

has 'user', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,
    default   => $ENV{USER}  
); 

has 'job', ( 
    is        => 'ro', 
    isa       => ArrayRef[ ID ],  
    traits    => [ 'Array' ], 
    lazy      => 1, 
    predicate => 'has_job', 
    writer    => '_set_job', 
    builder   => '_build_job', 
    handles  => { 
        get_user_jobs => 'elements' 
    }
); 

has 'yes', ( 
    is        => 'rw', 
    isa       => Bool, 
    traits    => [ 'Bool' ], 
    lazy      => 1, 
    default   => 0, 
    handles   => { 
        set_yes => 'set'
    }
); 

has 'all', ( 
    is        => 'rw', 
    isa       => Bool, 
    traits    => [ 'Bool' ], 
    lazy      => 1, 
    default   => 0,  
    handles   => { 
        set_all => 'set'
    }
); 

has 'format', ( 
    is        => 'rw', 
    isa       => Str, 
    lazy      => 1, 
    writer    => 'set_format', 
    default   => ''
); 

sub BUILD ( $self, @ ) { 
    # cache qstatf 
    $self->qstat; 

    # strip $HOSTNAME from full ID
    if  ( $self->has_job ) { 
        $self->_set_job( [ 
            grep { $self->isa_job( $_ ) } 
            map { s/(\d+).*$/$1/; $_ } 
            $self->get_user_jobs 
        ] ) 
    }
} 

sub status ( $self ) { 
    for my $job ( $self->get_user_jobs ) {  
        $self->print_status( $job, $self->format )
    }
} 

sub delete_job ( $self ) { 
    for my $job ( $self->get_user_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt('delete', $job) ) { 
            $self->delete( $job ); 
            $self->clean( $job )
        }
    } 
} 

sub reset_job ( $self ) { 
    for my $job ( $self->get_user_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt('reset', $job) ) { 
            $self->reset( $job )
        } 
    } 
} 

sub prompt ( $self, $method, $job ) { 
    printf "\n=> %s %s ? y/s [n] ", ucfirst($method), $job;  
    chomp ( my $reply = <STDIN> );  

    return 1 if $reply =~ /y|yes/i 
} 

# native
sub _build_job ( $self ) { 
    my @jobs = sort { $a <=> $b } $self->get_jobs; 

    return [ 
        $self->all
        ? @jobs          
        : grep $self->get_owner( $_) eq $self->user, @jobs 
    ]
} 

__PACKAGE__->meta->make_immutable;

1
