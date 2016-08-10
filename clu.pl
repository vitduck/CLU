#!/usr/bin/env perl 

# pragma 
use autodie; 
use strict; 
use warnings; 

# core
use Getopt::Long; 
use IO::Pipe; 
use Pod::Usage; 

# cpan 
use Data::Printer; 

# OO
use PBS::Job; 

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

=back 

=cut

# parse optional arguments 
GetOptions(
    \ my %option, 
    'help', 'id=s@{1,}', 'mode=s', 'format=s' 
) or pod2usage(-verbose => 1); 

# help message 
if ( exists $option{help} ) { pod2usage(-verbose => 99, -section => \@usages) }  

# default behaviors 
my @ids  = exists $option{id}   ? $option{id}->@* : get_job_id(); 
my $mode = exists $option{mode} ? $option{mode}   : 'status';   

# status format (for instance, oneline) 
if ( $mode eq 'status' and exists $option{format} ) { 
    $mode = join '_', $mode, $option{format} 
} 

# object constructions 
my @jobs = map { PBS::Job->new(id => $_) } @ids; 

# I am CLU 
for my $job ( @jobs ) { $job->$mode } 

sub get_job_id { 
    my @ids; 

    my $qstat = IO::Pipe->new();
    $qstat->reader("qstat -a"); 
    while ( <$qstat> ) { 
        my ( $id, $user ) = (split)[0,1]; 
        if ( /$ENV{USER}/ ) { push @ids, $id }
    } 

    return @ids; 
} 
