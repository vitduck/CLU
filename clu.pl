#!/usr/bin/env perl 

use strict; 
use warnings;  
use feature qw( switch );  
use experimental qw( smartmatch );  

use PBS::CLU;  

my $pbs = PBS::CLU->new_with_options; 

$pbs->getopt_usage( exit => 1 ) if @ARGV == 0; 

given ( shift @ARGV ) { 
    when ( /status/ ) { $pbs->status             } 
    when ( /delete/ ) { $pbs->delete_job         } 
    when ( /reset/  ) { $pbs->reset_job          } 
    default           { print $pbs->getopt_usage }
} 
