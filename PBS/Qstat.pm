package PBS::Qstat; 

use IO::Pipe; 

use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 

use namespace::autoclean; 
use experimental qw( signatures ); 

requires qw( _build_qstat );  

has '_qstat', ( 
    is       => 'ro', 
    isa      => HashRef,  
    traits   => [ 'Hash' ],
    lazy     => 1, 
    init_arg => undef,  
    builder  => '_build_qstat', 
    handles  => { 
        isa_job      => 'exists',  
        get_all_jobs => 'keys', 
        get_qstatf   => 'kv', 
    }
); 

1
