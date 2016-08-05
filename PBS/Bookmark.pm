package PBS::Bookmark; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# core
use File::Find;

# cpan 
use Moose::Role;  
use namespace::autoclean; 
use Try::Tiny;

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
        
        # silent permission error 
        try { 
            find( sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, $self->init ); 
            $bookmark = ( sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time )[0] =~ s/\/OUTCAR//r; 
        }; 

        return $bookmark //= '';  
    }, 
); 

# <modifiers> 
after 'info' => sub ( $self ) { 
    if ( $self->bookmark ) { 
        printf "%-9s> %s\n", ucfirst('bookmark'), $self->bookmark =~ s/${\$self->init}\///r;  
    } 
}; 

# <methods>
# reset job by deleting latest OUTCAR  
sub reset ( $self ) { 
    if ( $self->bookmark and $self->prompt('reset') ) { unlink join '/', $self->bookmark, 'OUTCAR' }
} 

1; 
