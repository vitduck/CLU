package PBS::Qstat; 

use Moose::Role;  
use IO::Pipe; 
use namespace::autoclean; 
use experimental qw( signatures ); 

requires '_build_qstat'; 

has '_qstat', ( 
    is       => 'ro', 
    isa      => 'HashRef',  
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
