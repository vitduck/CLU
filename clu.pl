#!/usr/bin/env perl 

# core
use Getopt::Long; 
use IO::Pipe; 
use Pod::Usage; 

# cpan 
use Data::Printer output => 'stdout';  
use Try::Tiny; 

# pragma 
use autodie; 
use strict; 
use warnings; 

# Moose class
use PBS::Job; 
use PBS::Queue; 

# POD 
my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 

clu.pl -- PBS job manager 

=head1 SYNOPSIS

clu.pl -i JOB_ID -m status -f oneline

=head1 OPTIONS

=over 16

=item B<-h, --help>

Print the help message and exit.

=item B<-i, --id> 

List of Job ID 

=item B<-m, --mode> 

Available mode: status, delete, reset 

=item B<-f, --format> 

Format of status output, such as oneline

=item B<-y, --yes>

Answer yes to all user prompts 

=back 

=cut

# parse optional arguments 
GetOptions(
    \ my %option, 
    'help', 'id=s@{1,}', 'mode=s', 'format=s', 'yes' 
) or pod2usage(-verbose => 1); 

# help message 
if ( exists $option{help} ) { pod2usage(-verbose => 99, -section => \@usages) }  

# construct a list of user's jobs 
my @all  = try { PBS::Queue->new
                           ->list_user_job
                           ->@* 
}; 

# default behaviors 
my @ids  = exists $option{id}   ? $option{id}->@* : @all; 
my $mode = exists $option{mode} ? $option{mode}   : 'status';   

# status format (for instance, oneline) 
if ( $mode eq 'status' and exists $option{format} ) { 
    $mode = join '_', $mode, $option{format} 
} 

# I am CLU
for my $id ( @ids ) { 
    my $job = PBS::Job->new( id  => $id,  
                             yes => exists($option{yes})
    ); 
    
    $job->$mode; 
}
