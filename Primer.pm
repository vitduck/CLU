package Primer; 

use strict; 
use warnings; 
use File::Find; 
use File::Path qw/rmtree/; 
use IO::Dir; 
use IO::File; 

# inheritence
use parent qw/Job/; 

# overiding _init
sub _init { 
    my ( $self, $id ) = @_; 

    # primer info 
    my @primer = qw/bootstrap tree.dat/; 

    # search inheritence chain for _init() 
    $self->SUPER::_init($id); 

    # addition info 
    $self->set_bootstrap;  
    $self->set_cur_dir;  

    return; 
}

# bootstrap 
sub set_bootstrap { 
    my ( $self ) = @_; 
    
    $self->{bootstrap} = '';  

    if ( $self->{owner} eq $ENV{USER} ) { 
        ( $self->{bootstrap} ) = grep { -d and /bootstrap/ } glob "$self->{init_dir}/*"; 
    }

    return; 
}

# current directory 
sub set_cur_dir { 
    my ( $self ) = @_;  
    my %current = (); 
    
    # hash of file => last modified time 
    $self->{cur_dir} = ''; 

    if ( $self->{owner} eq $ENV{USER} ) { 
        # sort key based on modified time
        find(sub { $current{$File::Find::name} = -M if /OUTCAR/ }, $self->{init_dir}); 
        $self->{cur_dir} = (sort { $current{$a} <=> $current{$b} } keys %current)[0];

        # trim the init_dir from cur_dir
        $self->{cur_dir} =~ s/$self->{init_dir}\/(.*)\/OUTCAR/$1/; 
    }

    return; 
}

# job info 
sub info { 
    my ( $self ) = @_; 

    # search inheritence chain for info() 
    $self->SUPER::info; 

    if ( $self->get_cur_dir) {  printf "Cur_dir  > %s\n", $self->get_cur_dir } 

    return; 
}

# overiding delete
sub delete { 
    my ( $self ) = @_; 

    # search inheritence chain for delete() 
    $self->SUPER::delete; 

    # clean up the rest 
    if ( $self->get_bootstrap ) { rmtree $self->get_bootstrap }  

    return; 
}

# bootstrap calculation
sub reset { 
    my ( $self ) = @_; 

    # display job information 
    $self->info(); 

    # short-circuit 
    if ( $self->get_state eq 'Q' ) { return } 

    # OUTCAR 
    my $outcar = join '/', $self->get_init_dir, $self->get_cur_dir, 'OUTCAR';  

    # confirmation 
    printf "\n=> Reset %s? ", $self->get_id; 
    chomp ( my $answer = <STDIN> ); 

    # delete OUTCAR
    if ( $answer =~ /^y/i and -f $outcar ) { unlink $outcar } 

    return; 
}

1; 
