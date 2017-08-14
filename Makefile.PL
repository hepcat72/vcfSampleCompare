#Makefile.PL version 1.0

use 5.010001;
use ExtUtils::MakeMaker;
my @scripts = qw(rankVCF.pl);

WriteMakefile
  (
   NAME => 'rankVCF',
   ($[ >= 5.005 ?  #Add these new keywords supported since 5.005
    (AUTHOR        => 'Robert W. Leach (rleach@princeton.edu)',
     ABSTRACT_FROM => 'src/rankVCF.pl') : ()),
   VERSION_FROM    => 'src/rankVCF.pl', # finds $VERSION
   PREREQ_PM       => {'Getopt::Long' => 2.38,
		       'File::Glob'   => 1.17,
		       'strict'       => 1.07,
		       'warnings'     => 1.13},
   EXE_FILES       => [ map { "src/$_" } @scripts ]
  );
