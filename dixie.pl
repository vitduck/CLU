#!/usr/bin/env perl 

use strict; 
use warnings; 
use Carp qw/croak/; 
use Getopt::Long; 
use Pod::Usage; 
use Switch; 

use Queue; 
use Primer; 

# POD 
my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 

dixie.pl (Flatline) -- PBS job manager 

=head1 SYNOPSIS

dixie.pl [-h] [-i] [-d] [-r] <JOB_ID>

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
my @jobs = (); 

# extract id from argument list
my @ids  = grep $_ !~ /^-+/, @ARGV; 

# parse optional arguments 
GetOptions( 
    'h'  => \$help, 
    'i'  => sub { $mode = 'info' }, 
    'd'  => sub { $mode = 'delete' }, 
    'r'  => sub { $mode = 'reset' }, 
    'a'  => sub { 
        my $queue = Queue->new();  
        @ids = $queue->get_job_list($ENV{USER}); 
    }, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help || @ids == 0 ) { pod2usage(-verbose => 99, -section => \@usages) }

# constructing object 
@jobs = map Primer->new($_), @ids; 

switch ( $mode ) { 
    case 'info'   { map $_->info  , @jobs }  
    case 'delete' { map $_->delete, @jobs }
    case 'reset'  { map $_->reset , @jobs }
    else          { pod2usage(-verbose => 99, -section => \@usages) }
} 
