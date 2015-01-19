reptileAmphibianSeqGrowth
=========================

Code for data aggregation and figure generation for our review in Annual Reviews of Animal Biosciences. It searches month-by-month through the nucleotide and EST databases from [NCBI](http://www.ncbi.nlm.nih.gov/) and counts how many bases were published to those databases in those months. To calculate the sequence accumulation through time for a different organism, just change the two instances of the "-term" in the setup of the Bio::DB::EUtilities objects to some other query.

**The Perl scripts require BioPerl, including Bio::DB::EUtilities,** which, depending on how you've downloaded and installed BioPerl may need to be downloaded separately and added to Perl's @INC (from, for example, [here](https://github.com/bioperl/Bio-EUtilities)).

Please be patient while running the "gatherData" scripts--it takes quite some time to download all of this data from NCBI's servers. Approximate runtimes for each of these queries ("Amphibia\[Organism\]" and "Reptilia\[Organism\]") were about 24 hours on our machine.

After running the data gathering script, run the accompanying R script to visualize the sequence accumulation through time.
