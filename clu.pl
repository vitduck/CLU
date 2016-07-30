#!/usr/bin/env perl 

use strict; 
use warnings; 

use autodie; 
use Getopt::Long; 
use IO::Pipe; 
use Pod::Usage; 

use PBS::Job; 

# POD 
my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 

clu.pl -- PBS job manager 

=head1 SYNOPSIS

clu.pl [-h] [-i] [-d] [-r] <JOB_ID>

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

Show information related to JOB_ID 

=item B<-d> 

Delete JOB_ID 

=item B<-r> 

Reset bootstraped JOB_ID

=item B<-a>

Apply operation all user's JOB_IDs 

=back 

=cut

# default optional arguments 
my $help = 0; 
my $mode = ''; 

# extract id from argument list
my @ids  = grep $_ !~ /^-+/, @ARGV; 

# parse optional arguments 
GetOptions( 
    'h'  => \$help, 
    'i'  => sub { $mode = 'info' }, 
    'd'  => sub { $mode = 'delete' }, 
    'r'  => sub { $mode = 'reset' }, 
    'a'  => sub { 
        @ids = (); 

        my $qstat = IO::Pipe->new();
        $qstat->reader("qstat -a"); 
        while ( <$qstat> ) { 
            if ( /$ENV{USER}/ ) { push @ids, (split)[0] }
        } 
    }, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help or @ids == 0 or $mode eq '' ) { pod2usage(-verbose => 99, -section => \@usages) }

# I am CLU 
for my $id ( @ids ) { 
    my $job = PBS::Job->new('id' => $id);  
    $job->$mode; 
}
