#!/usr/bin/env perl 

use strict; 
use warnings; 

use MooseX::Types::Moose qw( Str );  
use MooseX::Types -declare => [ qw( ID ) ]; 

subtype ID, as Str, where { /\d+(\.$ENV{ HOSTNAME })?/ }; 

1
