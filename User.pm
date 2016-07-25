package User; 

use 5.010; 

use autodie; 
use File::Find; 
use Moose::Role;  
use namespace::autoclean; 

sub _build_bootstrap { 
    my ( $self ) = @_; 

    my $bootstrap = 'none'; 

    my $init_dir = $self->init; 
    if ( $self->owner eq $ENV{USER} ) { 
        ( $bootstrap ) = grep { -d and /bootstrap/ } glob "$init_dir/*"; 
    }  

    return $bootstrap; 
} 

sub _build_current { 
    my ( $self ) = @_; 

    my $current = 'none'; 

    # hash of file => last modified time 
    my %mod_time = (); 

    if ( $self->owner eq $ENV{USER} and $self->state eq 'R' ) { 
        my $init    = $self->init; 

        find( sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, $init);
        $current = (sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time)[0]; 

        # trim the init from current 
        $current =~ s/$init\/(.*)\/OUTCAR/$1/; 
    }
    
    return $current; 
} 

1;
