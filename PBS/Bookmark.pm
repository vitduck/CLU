package PBS::Bookmark; 

# pragma
use autodie; 

# core
use File::Find;

# cpan 
use Moose::Role;  
use namespace::autoclean; 

# features 
use experimental qw(signatures);  

# <roles> 
with qw(PBS::Qstat PBS::Prompt); 

# <attributes>
has 'bookmark', ( 
    is        => 'ro', 
    isa       => 'Str', 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $bookmark; 
        my %mod_time = (); 
        
        # required permission 
        if ( $self->owner eq $ENV{USER} ) { 
            # recursively find modified time of all OUTCAR in directory 
            find( sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, $self->init );  

            # the latest OUTCAR created 
            if ( %mod_time ) { 
                $bookmark = ( sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time )[0] =~ s/\/OUTCAR//r; 
            }
        }  

        return $bookmark //= '';  
    }, 
); 

# <modifiers> 
after 'info' => sub ( $self ) { 
    my $prefix = $self->init; 
    if ( $self->bookmark ) { 
        printf "%-9s> %s\n", ucfirst('bookmark'), $self->bookmark =~ s/$prefix\///r;  
    } 
}; 

# <methods>
# reset job by deleting latest OUTCAR  
sub reset ( $self ) { 
    if ( $self->bookmark and $self->prompt('reset') ) { 
        unlink join '/', $self->bookmark, 'OUTCAR'; 
    }
} 

1; 
