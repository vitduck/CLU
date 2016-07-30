package PBS::Node; 

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
with qw(PBS::Qstat); 

# <attributes>
has 'node' => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub ( $self ) { 
        my %mod_time = (); 
        my $init_dir = $self->init; 
        
        if ( $self->owner eq $ENV{USER} ) { 
            # recursively find modified time of all OUTCAR in directory 
            eval { find( sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, $init_dir ) };   
            my $node = (sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time)[0];
            $node =~ s/$init_dir\/(.*)\/OUTCAR/$1/;   
            
            return $node; 
        } else {   
            return ''; 
        } 
    }, 
); 

# <methods>
# reset job by deleting latest OUTCAR  
sub reset ( $self ) { unlink join '/', $self->init, $self->node, 'OUTCAR' } 

1; 
