#!/usr/bin/env perl 

use strict; 
use warnings;  
use feature qw( switch );  
use experimental qw( smartmatch );  

use PBS::CLU;  

my $pbs = PBS::CLU->new_with_options; 

$pbs->help( 1 ) if @ARGV == 0; 

given ( shift @ARGV ) { 
    when ( /status/ ) { $pbs->status    } 
    when ( /delete/ ) { $pbs->delete    } 
    when ( /reset/  ) { $pbs->reset     } 
    default           { $pbs->help( 0 ) }
} 
