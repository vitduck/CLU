package Primer; 

use strict; 
use warnings; 
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

    # read content of init_dir
    my $dirfh = IO::Dir->new($self->{init_dir});  
    if ( $dirfh ) { 
        for my $file ( $dirfh->read ) { 
            # primer match 
            if ( grep $file eq $_, @primer ) { 
                # remove the extension
                ( my $key = $file ) =~ s/\..*$//; 
                $self->{$key} = join '/', $self->{init_dir}, $file;  
            }
        }
        $dirfh->close; 
    }

    # current dir 
    $self->{cur_dir} = 'none'; 
    if ( exists $self->{tree} ) { 
        $self->{cur_dir} = join '/', $self->{init_dir}, read_tree($self->{tree}) 
    }   
    
    return; 
}

# job info 
sub info { 
    my ( $self ) = @_; 

    # search inheritence chain for info() 
    $self->SUPER::info; 

    printf "Cur_dir  > %s\n", $self->get_cur_dir;

    return; 
}

# overiding delete
sub delete { 
    my ( $self ) = @_; 

    # search inheritence chain for delete() 
    $self->SUPER::delete; 

    # clean up the rest 
    if ( $self->get_bootstrap ) { rmtree $self->get_bootstrap }  
    if ( $self->get_tree )      { unlink $self->get_tree }  

    return; 
}

# bootstrap calculation
sub reset { 
    my ( $self ) = @_; 

    # short-circuit 
    if ( $self->get_state eq 'Q' ) { return } 

    # shorten curdir 
    (my $current = $self->get_cur_dir) =~ s/$ENV{HOME}/~/; 

    # OUTCAR 
    my $outcar = join '/', $self->get_cur_dir, 'OUTCAR';  

    # confirmation 
    printf "=> Current directory: %s\n", $current; 
    printf "=> Reset %s? ", $self->get_id; 
    chomp ( my $answer = <STDIN> ); 

    # delete OUTCAR
    if ( $answer =~ /^y/i and -f $outcar ) { unlink $outcar } 

    return; 
}

# current directory 
sub read_tree { 
    my ( $tree ) = @_;  
    
    my $level = 0; 
    my @dirs  = (); 
    
    my $fh    = IO::File->new($tree, 'r'); 
    while ( <$fh> ) { 
        # skip the top node +
        if ( /\+/ ) { next }     

        # depth 
        $level = grep /\|/, split; 

        # directory 
        if ( /_(.+?)( \[\*\])?$/ ) { $dirs[$level] = $1 } 

        # current 
        if ( /\*/ ) { last }
    }
    $fh->close; 
    
    return join('/',  @dirs[0..$level]);  
}

1; 
