#!/usr/bin/perl

use strict;
use warnings;
use Bio::DB::EUtilities;
use Bio::SeqIO;
use IO::Handle;


my @months = ("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12");

# Change the year boundaries for the harvesting here:
my @years = (1982 .. 2014);


open(my $amphibianResultsFH, ">", "AmphibianResults.txt") or die "Couldn't open AmphibianResults.txt for writing: $!\n";
$amphibianResultsFH->autoflush(1); # This allows you to monitor progress as the months are being completed

foreach my $year (@years) {
    foreach my $month (@months) {
        my $minDate = $year . "/" . $month . "/01";
        my $maxDate = $year . "/" . $month . "/31"; # This works because NCBI is fine with you saying February 31, for instance
	
        my $factory = Bio::DB::EUtilities->new(-eutil   => 'esearch',
                                               -email   => 'youremail@address.com', # Change this to your email address
                                               -db      => 'nucleotide',
                                               -term    => 'Amphibia[Organism]',
                                               -mindate => $minDate,
                                               -maxdate => $maxDate,
                                               -datetype => 'pdat',
                                               -usehistory => 'y');
        my $count = $factory->get_count;
        my $hist = $factory->next_History || die "No history data returned";
        
        $factory->set_parameters(-eutil     => 'efetch',
                                 -rettype   => 'fasta',
                                 -retmode   => 'text',
                                 -history   => $hist);
        my $retry = 0;
        my ($retmax, $retstart) = (10000,0); # 10,000 is the maximum allowed by NCBI
        
	# This is a temporary file that will hold the sequences for each month (and will be deleted at the
	# end of processing each month)
        open (my $out, ">", "seqsAmphib.txt") || die "Couldn't open seqsAmphib.txt for writing: $!\n";
        
	# Here's where we actually pull the EST sequences from the NCBI server and write them to file

        RETRIEVE_SEQS:
        while ($retstart < $count) {
            $factory->set_parameters(-retstart => $retstart,
                                     -retmax   => $retmax);
            
            eval { $factory->get_Response(-cb => sub {my ($data) = @_; print $out $data} ); };
            
            if ($@) {
                die "Server error: $@. Try again later" if $retry == 5;
                print STDERR "Server error, redo #$retry\n";
                $retry++ && redo RETRIEVE_SEQS;
            }
            print "Retrieved $retstart";
            $retstart += $retmax;
        }
        
        
        
        
        my $factoryEST = Bio::DB::EUtilities->new(-eutil   => 'esearch',
                                               -email   => 'youremail@address.com', # Change this to your email address
                                               -db      => 'nucest',
                                               -term    => 'Amphibia[Organism]',
                                               -mindate => $minDate,
                                               -maxdate => $maxDate,
                                               -datetype => 'pdat',
                                               -usehistory => 'y');
        my $countEST = $factoryEST->get_count;
        my $histEST = $factoryEST->next_History || die "No history data returned";
        
        $factoryEST->set_parameters(-eutil     => 'efetch',
                                 -rettype   => 'fasta',
                                 -retmode   => 'text',
                                 -history   => $histEST);
        my $retryEST = 0;
        my ($retmaxEST, $retstartEST) = (10000,0); # 10,000 is the maximum allowed by NCBI

	
	# Here's where we actually pull the EST sequences from the NCBI server and write them to file
        RETRIEVE_SEQS_EST:
        while ($retstartEST < $countEST) {
            $factoryEST->set_parameters(-retstart => $retstartEST,
                                     -retmax   => $retmaxEST);
            
            eval { $factoryEST->get_Response(-cb => sub {my ($data) = @_; print $out $data} ); };
            
            if ($@) {
                die "Server error: $@. Try again later" if $retryEST == 5;
                print STDERR "Server error, redo #$retry\n";
                $retryEST++ && redo RETRIEVE_SEQS_EST;
            }
            print "Retrieved $retstartEST";
            $retstartEST += $retmaxEST;
        }

        close $out;
        

	# Now that we've printed all of the results for our query into the seqs.txt file, we just have to count how
	# many bases are in that file for the total bases in that month
        my $monthBaseCounter = 0;
        my $seqIn = Bio::SeqIO->new(-file => "seqsAmphib.txt",
                                    -format => "fasta");
	# Go through each sequence in the file, one by one, and add the length of that sequence to the counter
        while (my $seq = $seqIn->next_seq()) {
            $monthBaseCounter += $seq->length(); 
        }
        
        print $amphibianResultsFH "$year-$month\t$monthBaseCounter\n"; # This is the raw data we use to make our plots
        unlink("seqs.txt"); # We'll recreate this file for the next month
    }
}