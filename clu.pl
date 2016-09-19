#!/usr/bin/env perl 

use strict; 
use warnings FATAL => 'all'; 

use Getopt::Long; 
use Pod::Usage; 

use PBS::CLU;  

use feature qw( switch ); 
use experimental qw( smartmatch ); 

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

=item B<-j, --job> 

List of jobs  

=item B<-u, --user> 

Owner of jobs 

=item B<-f, --format> 

Format of status output, such as oneline

=item B<-y, --yes>

Answer yes to all user prompts 

=back 

=cut

# parse optional arguments 
GetOptions(
    \ my %option, 
    'help', 'job=s@{1,}', 'user=s', 'format=s', 'yes' 
) or pod2usage(-verbose => 1); 

# help message 
if ( exists $option{help} ) { pod2usage(-verbose => 99, -section => \@usages) }  

# default behaviors 
my $pbs = 
    exists $option{user} ? PBS::CLU->new( user => $option{user} ) :  
    exists $option{job}  ? PBS::CLU->new( job  => $option{job}  ) :   
    PBS::CLU->new(); 

# set yes to all prompt 
$pbs->set_yes( exists $option{yes} ); 

# set format of status 
$pbs->set_format( $option{format} //= '' ); 

# switch 
my $mode = shift @ARGV // 'status'; 
given ( $mode ) { 
    $pbs->status when /status/; 
    $pbs->delete when /delete/; 
    $pbs->reset  when /reset/; 
    
    default { 
        pod2usage( -verbose => 1 )
    } 
} 
