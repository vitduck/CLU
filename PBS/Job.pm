package PBS::Job; 

use File::Find; 
use Term::ANSIColor; 

use Moose::Role;  
use MooseX::Types::Moose qw( Str HashRef ); 

use namespace::autoclean; 
use feature qw( state switch );   
use experimental qw( signatures smartmatch );  

with qw( PBS::Qstat PBS::Qdel PBS::Bookmark PBS::Bootstrap ); 

my @attributes = qw( name owner state queue nodes walltime elapsed init );  

for my $attr ( @attributes ) { 
    has $attr, ( 
        is        => 'ro', 
        isa       => HashRef[Str],  
        traits    => [ 'Hash' ], 
        lazy      => 1, 
        init_arg  => undef, 
        default   => sub { ( { map { $_->[0] => $_->[1]{$attr} } $_[0]->get_qstatf } ) }, 
        handles   => { 
            'get_'.$attr => 'get' 
        } 
    ); 
}

has 'header', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { ( { map { $_ => $_[0]->color_header( $_ ) } $_[0]->get_jobs } ) }, 
    handles   => { 
        get_header => 'get' 
    } 
); 

sub color_header ( $self, $job ) { 
    given ( $self->get_state( $job ) ) {  
        when ( /R/ ) { return colored( "< $job >", 'bold blue' ) } 
        when ( /Q/ ) { return colored( "< $job >", 'bold red'  ) } 
        default      { return colored( "< $job >", 'green' )     } 
    } 
} 

sub print_header( $self, $job ) {
    printf "\n%s\n", $self->get_header( $job );
} 

sub print_bookmark ( $self, $job ) { 
    if ( $self->has_bookmark( $job ) ) {  
        # trim the leading path 
        my $init     = $self->get_init( $job ); 
        my $bookmark = $self->get_bookmark( $job ) =~ s/$init\///r; 

        printf "%-9s=> %s\n", ucfirst('bookmark'), $bookmark          
    }
} 

sub print_qstat ( $self, $job ) { 
    for my $attr ( @attributes) { 
        my $get_attr = 'get_'.$attr;  
        printf "%-9s=> %s\n", ucfirst($attr), $self->$get_attr( $job );  
    }
}  

sub print_status ( $self, $job, $format = '' ) { 
    given ( $format ) {  
        when ( /oneline/ ) { $self->print_status_oneline( $job ) } 
        default            { 
            $self->print_header  ( $job ); 
            $self->print_qstat   ( $job );     
            $self->print_bookmark( $job )
        }
    }
}

sub print_status_oneline ( $self, $job ) { 
    state $count = 0;  

    my $dir = 
        $self->has_bookmark( $job ) ?  
        $self->get_bookmark( $job ) =~ s/$ENV{HOME}/~/r: 
        $self->get_init( $job )     =~ s/$ENV{HOME}/~/r; 

    printf
        "%02d. %s ( %s ) %s\n", 
        ++$count, $self->get_header( $job ), $self->get_elapsed( $job ), $dir  
} 

sub _build_bootstrap ( $self ) { 
    my %bootstrap = (); 

    for my $job ( $self->get_jobs ) { 
        $bootstrap{$job} = (
            $self->get_owner( $job ) eq $ENV{USER} ?  
            ( grep { -d and /bootstrap-\d+/ } glob "${\$self->get_init( $job )}/*" )[0] :
            undef
        )
    }

    return \%bootstrap
} 

sub _build_bookmark ( $self ) { 
    my %bookmark = ();  

    for my $job ( $self->get_jobs ) { 
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
