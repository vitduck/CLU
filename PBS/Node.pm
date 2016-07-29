package PBS::Node; 

use 5.010; 

use autodie; 
use File::Find;
use Moose::Role;  
use namespace::autoclean; 

# roles 
with qw(PBS::Qstat); 

has 'node' => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub { 
        my ( $self ) = @_; 

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

sub reset { 
    my ( $self ) = @_; 

    # delete latest OUTCAR file 
    unlink join '/', $self->init, $self->node, 'OUTCAR'; 

    return; 
} 

1; 
