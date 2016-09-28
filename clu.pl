#!/usr/bin/env perl 

use strict; 
use warnings;  

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

clu.pl [status|delete|reset] -j <JOB_ID> -f <oneline> -y 

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

=item B<-a, --all> 

Apply operation to all users 

=back 

=cut

# parse optional arguments 
GetOptions(
    \ my %option, 
    'help', 'job=s@{1,}', 'user=s', 'format=s', 'yes', 'all' 
) or pod2usage( -verbose => 1 ); 

# help message 
if ( exists $option{ help } ) { pod2usage( -verbose => 99, -section => \@usages ) }  

# default behaviors 
my $pbs = ( 
    exists $option{ user} ? PBS::CLU->new( user => $option{ user } ) :  
    exists $option{ job}  ? PBS::CLU->new( job  => $option{ job } )  :   
    PBS::CLU->new() 
); 

# logistic
$pbs->set_yes if exists $option{ yes } ;
$pbs->set_all if exists $option{ all }; 

# format 
$pbs->set_format( $option{ format } ) if exists $option{ format }; 

# switch 
my $mode = shift @ARGV // 'status'; 

given ( $mode ) { 
    when ( /status/ ) { $pbs->status } 
    when ( /delete/ ) { $pbs->delete_job } 
    when ( /reset/  ) { $pbs->reset_job } 
    default           { pod2usage( -verbose => 1 ) } 
} 
