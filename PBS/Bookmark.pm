package PBS::Bookmark; 

use Moose::Role;  
use File::Find; 
use Term::ANSIColor; 
use namespace::autoclean; 
use experimental qw( signatures ); 

has 'bookmark', ( 
    is        => 'ro', 
    isa       => 'HashRef',  
    lazy      => 1, 
    traits    => [ 'Hash' ], 
    init_arg  => undef, 
    builder   => '_build_bookmark', 
    handles   => { 
        has_bookmark => 'defined', 
        get_bookmark => 'get'
    } 
); 

sub print_bookmark ( $self, $job ) { 
    if ( $self->has_bookmark( $job ) ) {  
        # trim the leading path 
        my $init     = $self->get_init( $job ); 
        my $bookmark = $self->get_bookmark( $job ) =~ s/$init\///r; 
        printf "%-9s=> %s\n", ucfirst('bookmark'), $bookmark          
    }
} 

sub remove_bookmark ( $self, $job ) { 
    unlink join '/', $self->get_bookmark( $job), 'OUTCAR' if  $self->has_bookmark( $job )
} 

sub _build_bookmark ( $self ) { 
    my %bookmark = ();  

    for my $job ( $self->get_user_jobs ) { 
        $bookmark{$job} = ( 
            $self->get_owner( $job ) eq $ENV{USER} ?  
            do { 
                my %mod_time = ();   
                find { 
                    wanted => sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, 
                    follow => $self->follow_symbolic 
                }, $self->get_init( $job );  
                # trim OUTCAR from full path
                ( sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time )[0] =~ s/\/OUTCAR//r; 
            } : 
            undef
        )
    }

    return \%bookmark; 
} 

1 
