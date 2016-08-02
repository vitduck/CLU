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

# <attributes>
has 'bookmark', ( 
    is        => 'ro', 
    isa       => 'Str', 
    lazy      => 1, 
    predicate => 'has_bookmark', 

    default   => sub ( $self ) { 
        my $bookmark; 
        my %mod_time = (); 
        my $init_dir = $self->init; 
        
        if ( $self->owner eq $ENV{USER} ) { 
            # recursively find modified time of all OUTCAR in directory 
            find( sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, $init_dir );  
            $bookmark = (sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time)[0];
            $bookmark =~ s/$init_dir\/(.*)\/OUTCAR/$1/;   
        }  
    }, 
); 

# <methods>
# reset job by deleting latest OUTCAR  
sub reset ( $self ) { 
    unlink join '/', $self->init, $self->has_bookmark, 'OUTCAR' 
} 

1; 
