#Makefile.PL version 1.0

use 5.010001;
use ExtUtils::MakeMaker;
my @scripts = qw(vcfSampleCompare.pl);

WriteMakefile
  (
   NAME => 'vcfSampleCompare',
   ($[ >= 5.005 ?  #Add these new keywords supported since 5.005
    (AUTHOR        => 'Robert W. Leach (rleach@princeton.edu)',
     ABSTRACT_FROM => 'src/vcfSampleCompare.pl') : ()),
   VERSION_FROM    => 'src/vcfSampleCompare.pl', # finds $VERSION
   PREREQ_PM       => {'Getopt::Long'         => 2.38,
		       'File::Glob'           => 1.17,
		       'strict'               => 1.07,
		       'warnings'             => 1.13,
		       'CommandLineInterface' => 4.133},
   EXE_FILES       => [ map { "src/$_" } @scripts ],
   TEST_REQUIRES   => {
		       'Test::More'           => 0.98,
		       'strict'               => 1.07,
		       'warnings'             => 1.13,
		       'CommandLineInterface' => 4.135,
		       'lib'                  => 0.63,
		       'File::Basename'       => 2.84,
		      },
  );
