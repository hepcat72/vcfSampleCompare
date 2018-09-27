# Run with `perl perl_script_template.t` or:
#          `perl perl_script_template.t ../perl_script_template`
#          `perl perl_script_template.t ../perl_script_template`
# in the t/ directory

use strict;
use warnings;
use lib '../lib';           #BEGIN block chdirs to t/
use CommandLineInterface;
use File::Basename;

##
## Global variables
##

my($num_tests,$available_starts,$available_ranges,$changed_dir,$script,
   $test_script);
my $perl_call_def   = 'perl -I../lib';
my $test_script_def = '../src/vcfSampleCompare.pl';
my $outd            = 'got';  #Main test directory to store test output
my $test_num        = 0;
my $subtest_hash    = {};
my $test_cmd        = '';
my $sub_test_num    = 0;
my $reqnum          = 0;
my $in_script       = '';  #Used in case edits to the script are necessary
my $generate        = 0;

##
## Option variables
##

my($test_only);
my $starting_test     = 1;
my $ending_test       = $num_tests;
my $script_debug      = 0;  #Debug level to provide in the command line call
                            #Set by --script-debug-mode.  Manipulates the value
                            #of $debug_opts using '--debug'
my $script_debug_flag = '--debug'; #Assumed to be a 'count' flag
my $debug_opts        = ''; #Added to command line call
my $self_debug        = 0;  #Debug mode for this script (set by --debug from CLI
                            #via isDebug())
my $installation_mode = 0;
my $clean             = 0;
my $perl_call         = $perl_call_def;


setScriptInfo(VERSION => '2.000',
              CREATED => '9/21/2018',
              AUTHOR  => 'Robert Leach',
              CONTACT => 'rleach@princeton.edu',
              COMPANY => 'Princeton University',
              LICENSE => 'Copyright 2018',
              HELP    => 'Test suite for vcfSampleDiff.pl.');

#Infiles & outfiles are not used, so keep the defaults out of the usage by
#hiding them
addInfileOption(FLAG   => 'infile',
	        HIDDEN => 1);
addOutfileSuffixOption(FLAG   => 'suffix',
		       HIDDEN => 1);

addOption(GETOPTKEY   => 't|run-testnum',
          GETOPTVAL   => \$test_only,
	  TYPE        => 'integer',
	  REQUIRED    => 0,
	  DEFAULT     => 'all',
	  ACCEPTS     => $available_ranges,
	  SMRY_DESC   => join('',('Single test number to run.  See `--usage ',
				'--extended` for acceptable test numbers.')),
	  DETAIL_DESC => join('',('Test number to run 1 test.  Not every test ',
				  'can be tested by itself.  Any test number ',
				  'can be submitted, but testing will start ',
				  'from a number in the list provided here ',
				  'and stop at the number you provide.  The ',
				  'reason is that some tests\' setup may only ',
				  'be performed once for a number of tests ',
				  'together.')));

addOption(GETOPTKEY   => 'b|starting-test',
          GETOPTVAL   => \$starting_test,
	  TYPE        => 'integer',
	  REQUIRED    => 0,
	  DEFAULT     => $starting_test,
	  ACCEPTS     => $available_ranges,
	  SMRY_DESC   => join('',
			      ('Number of first test to run.  See `--usage ',
			       '--extended` for acceptable test numbers.')),
	  DETAIL_DESC => join('',('Start tests at this test number.  Note, ',
				  'not every test can be a starting test.  ',
				  'Any test number can be submitted, but ',
				  'testing will start from a number in the ',
				  'list provided here, just before the number ',
				  'you provide.  The reason is that some ',
				  'tests\' setup may only be performed once ',
				  'for a number of tests together.')));

addOption(GETOPTKEY   => 'e|ending-test',
          GETOPTVAL   => \$ending_test,
	  TYPE        => 'integer',
	  REQUIRED    => 0,
	  DEFAULT     => $ending_test,
	  ACCEPTS     => ["1-$num_tests"],
	  SMRY_DESC   => 'Number of last test to run.');

addOption(GETOPTKEY   => 'd|script-debug-mode',
          GETOPTVAL   => \$script_debug,
	  TYPE        => 'count',
	  DEFAULT     => $script_debug,
	  SMRY_DESC   => 'Supply --debug to test script calls.',
	  DETAIL_DESC => join('',('Supply the --debug flag to the script ',
				  'calls.  An optional integer value can be ',
				  'supplied as well to set the debug level.  ',
				  'This is different to this test script\'s ',
				  '--debug flag (which debugs this script.')));

addOption(GETOPTKEY   => 'installation',
          GETOPTVAL   => \$installation_mode,
	  TYPE        => 'bool',
	  DEFAULT     => $installation_mode,
	  SMRY_DESC   => 'Test the installation.',
	  DETAIL_DESC => join('',('Test the globally installed version of ',
				  'the script (versus the version compiled in ',
				  'this directory).  The global version is ',
				  'the one which should appear in your PATH ',
				  'which you installed by running `sudo make ',
				  'install`.  The default is to only test the ',
				  'version you compiled but did not install ',
				  '(the version created by running `make`).  ',
				  'This option also affects the perl call ',
				  'option (--perl-call).  If --perl-call is ',
				  "its default value [$perl_call_def], it ",
				  'will be modified to [perl] so as not to ',
				  'use the modules in this locally compiled ',
				  "version's directory, but rather the system-",
				  'wide version.')));

addOption(GETOPTKEY   => 'clean',
          GETOPTVAL   => \$clean,
	  TYPE        => 'negbool',
	  ADVANCED    => 1,
	  DEFAULT     => $clean,
	  SMRY_DESC   => 'Do not clean up test files.');

addOption(GETOPTKEY   => 'perl-call=s',
          GETOPTVAL   => \$perl_call,
	  DEFAULT     => $perl_call,
	  DETAIL_DESC => ('The perl call to put before each script.  See ' .
			  '--installation, which affects this option.'));

addOption(GETOPTKEY   => 'generate',
          GETOPTVAL   => \$generate,
	  TYPE        => 'bool',
	  ADVANCED    => 1,
	  HIDDEN      => 1,
	  DEFAULT     => $generate,
	  SMRY_DESC   => 'Generate/regenerate expected output.',
	  DETAIL_DESC => join('',('If the script being tested has changed and ',
				  'a test is failing due to different output, ',
				  'supply this option to generate new ',
				  'expected output.  This will only correct ',
				  'tests of exact file output.  Any tests ',
				  'which look for patterns or test exit codes ',
				  'will have to be manually recoded if they ',
				  'continue to fail after regeneration of ',
				  'expected output files.  NOTE: CHANGES HERE ',
				  'WILL GET OVERWRITTEN THE NEXT TIME YOU ',
				  'UPDATE YOUR SCRIPT FROM THE MAIN ',
				  'REPOSITORY.')));

setDefaults(HEADER     => 0,
	    DEFRUNMODE => 'run');

processCommandLine();

##
## Setup test run and validate options
##

if(defined($test_only) && ($starting_test > 1 || $ending_test < $num_tests))
   {
     error("Cannot supply -t and either -b or -e at the same time.");
     quit(2);
   }
elsif(defined($test_only))
   {
     $starting_test = $test_only;
     $ending_test = $test_only;
   }

if(scalar(grep {$_ == $starting_test} @$available_starts) == 0)
  {
    warning("TEST [$starting_test] cannot be used as a starting test.  ",
	    "Changing to the previous available starting test number.");
    $starting_test = (grep {$_ < $starting_test} @$available_starts)[-1];
  }

if($starting_test)
  {$num_tests = $ending_test - $starting_test + 1}

#Set the number of tests at runtime instead of pre-compile because num_tests
#can change based on user options.
eval('use Test::More tests => $num_tests');

$test_script = $test_script_def;
if($installation_mode)
  {
    $test_script = basename($test_script);
    if($perl_call eq $perl_call_def)
      {$perl_call = 'perl'}
  }
$in_script = $test_script;

if($script_debug)
  {
    #This sets the --debug flag of the script we're testing in the command line
    #call
    if($script_debug > 1 || $script_debug < 0)
      {$debug_opts = "$script_debug_flag $script_debug"}
    else
      {$debug_opts = $script_debug_flag}
  }

#Set the debug flag for putting this test script in debug mode
$self_debug = isDebug();

#Make sure we can run the test script (in whichever mode was selected)
my $tmp_test_script = `which $test_script`;
chomp($tmp_test_script);
if($? || !-e $tmp_test_script || !-x $tmp_test_script)
  {
    error("Test Script: [$test_script] does not exist or is not executable.  ",
	  "$!");
    quit(3);
  }

#Skip to the starting test
if($starting_test > 1)
  {
    print STDERR "Skipping to test number $starting_test\n";
    $test_num = $starting_test - 1; #Will get incremented in the test code
    goto("TEST" . $starting_test);
  }


##
## Script we're testing
##

$in_script = $test_script;


##
## Tests
##


TEST1:

#Describe the test
$test_num++;
$sub_test_num = 1;
$reqnum = '4';

my $inf1  = 'inputs/fbse1.vcf';
my $expf1 = "expected/test$test_num.in1.s1.s3.d1.d1.af.a6.nh.fy.gy.rvcf";


testaf4(#Test description
	$test_num,
	$sub_test_num,
	$reqnum,
	"Allelic frequency with gap 0.6, filtering, and growth to stdout",

	$in_script,
        $outd,

	#Input files (to make sure they pre-exist)
	[$inf1],
	#Supply the first input file on standard in
	0,

	#Output files (they will be deleted if they pre-exist)
	[],
	#Don't delete these pre-existing outfiles before test (e.g. if you want
	#to test overwrite protection & created them on purpose)
	[],

	#Options to supply to the test script on command line in 1 string.
	#Be sure to specify in & out files, but no redirection.
	"-a 0.6 --noheader -s gDNA-PA14 -d 1 -s '205w3 205w2 205w1' -d 1 " .
	"--nogenotype --filter --grow $inf1",

	#Names of files expected to NOT be created. Supply undef if not testing.
	[],

	#Exact expected stdout & stderr files.  Supply undef if no test.
	$expf1,undef,
	#Exact expected output files.  Must be the same size as the output files
	#array above.  Supply undef if not testing.
	[],

	#Patterns expected in string output for stdout & stderr.  Supply undef
	#if not testing.
	undef,undef,
	#Patterns expected in string output for o1, o2, ...  Supply undef if not
	#testing.
	[],

	#Patterns not expected in string output for stdout & stderr.  Supply
	#undef if not testing.
        undef,'(ERROR|WARNING)\d+:',
	#Patterns not expected in string output for o1, o1, ...  Supply undef if
	#not testing.
        [],

	#Exit code (0 = success, 1 = error: means any non-0 value is expected)
	0);


TEST2:

#Describe the test
$test_num++;
$sub_test_num++;
$reqnum = '4';

$inf1  = 'inputs/fbse1.vcf';
$expf1 = "expected/test$test_num.in1.s1.s3.d1.d1.gt.nh.fy.gy.rvcf";


testaf4(#Test description
	$test_num,
	$sub_test_num,
	$reqnum,
	"Genotype mode with filtering and growth to stdout",

	$in_script,
        $outd,

	#Input files (to make sure they pre-exist)
	[$inf1],
	#Supply the first input file on standard in
	0,

	#Output files (they will be deleted if they pre-exist)
	[],
	#Don't delete these pre-existing outfiles before test (e.g. if you want
	#to test overwrite protection & created them on purpose)
	[],

	#Options to supply to the test script on command line in 1 string
	"--noheader -s gDNA-PA14 -d 1 -s '205w3 205w2 205w1' -d 1 --genotype " .
	"--filter --grow $inf1",

	#Names of files expected to NOT be created. Supply undef if not testing.
	[],

	#Exact expected stdout & stderr files.  Supply undef if no test.
	$expf1,undef,
	#Exact expected output files.  Must be the same size as the output files
	#array above.  Supply undef if not testing.
	[],

	#Patterns expected in string output for stdout & stderr.  Supply undef
	#if not testing.
	undef,undef,
	#Patterns expected in string output for o1, o2, ...  Supply undef if not
	#testing.
	[],

	#Patterns not expected in string output for stdout & stderr.  Supply
	#undef if not testing.
        undef,'(ERROR|WARNING)\d+:',
	#Patterns not expected in string output for o1, o1, ...  Supply undef if
	#not testing.
        [],

	#Exit code (0 = success, 1 = error: means any non-0 value is expected)
	0);



TEST3:

#Describe the test
$test_num++;
$sub_test_num++;
$reqnum = '4';

$inf1  = 'inputs/fbse1.vcf';
$expf1 = "expected/test$test_num.in1.s1.s3.d1.d1.gt.nh.fn.gy.rvcf";


testaf4(#Test description
	$test_num,
	$sub_test_num,
	$reqnum,
	"Genotype mode with no filtering and growth to stdout",

	$in_script,
        $outd,

	#Input files (to make sure they pre-exist)
	[$inf1],
	#Supply the first input file on standard in
	0,

	#Output files anticipated (they will be deleted if they pre-exist)
	[],
	#Don't delete these pre-existing outfiles before test (e.g. if you want
	#to test overwrite protection & created them on purpose)
	[],

	#Options to supply to the test script on command line in 1 string
	"--noheader -s gDNA-PA14 -d 1 -s '205w3 205w2 205w1' -d 1 --genotype " .
	"--nofilter --grow $inf1",

	#Names of files expected to NOT be created. Supply to Outfiles to test
	#Up to 6 (NOT inc. STD's).  Supply undef if not testing.
	[],

	#Exact expected stdout & stderr files.  Supply undef if no test.
	$expf1,undef,
	#Exact expected output files.  Must be the same size as the output files
	#array above.  Supply undef if not testing.
	[],

	#Patterns expected in string output for stdout & stderr.  Supply undef
	#if not testing.
	undef,undef,
	#Patterns expected in string output for o1, o2, ...  Supply undef if not
	#testing.
	[],

	#Patterns not expected in string output for stdout & stderr.  Supply
	#undef if not testing.
        undef,'(ERROR|WARNING)\d+:',
	#Patterns not expected in string output for o1, o1, ...  Supply undef if
	#not testing.
        [],

	#Exit code (0 = success, 1 = error: means any non-0 value is expected)
	0);



TEST4:

#Describe the test
$test_num++;
$sub_test_num++;
$reqnum = '4';

$inf1  = 'inputs/fbse1.vcf';
$expf1 = "expected/test$test_num.in1.s1.s3.d1.d1.af.a6.nh.fn.gy.rvcf";


testaf4(#Test description
	$test_num,
	$sub_test_num,
	$reqnum,
	"Allelic frequency with gap 0.6, no filtering, and growth to stdout",

	$in_script,
        $outd,

	#Input files (to make sure they pre-exist)
	[$inf1],
	#Supply the first input file on standard in
	0,

	#Output files anticipated (they will be deleted if they pre-exist)
	[],
	#Don't delete these pre-existing outfiles before test (e.g. if you want
	#to test overwrite protection & created them on purpose)
	[],

	#Options to supply to the test script on command line in 1 string
	"--noheader -a 0.6 -s gDNA-PA14 -d 1 -s '205w3 205w2 205w1' -d 1 " .
	"--nogenotype --nofilter --grow $inf1",

	#Names of files expected to NOT be created. Supply to Outfiles to test
	#Up to 6 (NOT inc. STD's).  Supply undef if not testing.
	[],

	#Exact expected stdout & stderr files.  Supply undef if no test.
	$expf1,undef,
	#Exact expected output files.  Must be the same size as the output files
	#array above.  Supply undef if not testing.
	[],

	#Patterns expected in string output for stdout & stderr.  Supply undef
	#if not testing.
	undef,undef,
	#Patterns expected in string output for o1, o2, ...  Supply undef if not
	#testing.
	[],

	#Patterns not expected in string output for stdout & stderr.  Supply
	#undef if not testing.
        undef,'(ERROR|WARNING)\d+:',
	#Patterns not expected in string output for o1, o1, ...  Supply undef if
	#not testing.
        [],

	#Exit code (0 = success, 1 = error: means any non-0 value is expected)
	0);



TEST5:

#Describe the test
$test_num++;
$sub_test_num++;
$reqnum = '4';

$inf1  = 'inputs/fbse1.vcf';
$expf1 = "expected/test$test_num.in1.s1.s3.d1.d1.af.a6.nh.fn.gn.rvcf";


testaf4(#Test description
	$test_num,
	$sub_test_num,
	$reqnum,
	"Allelic frequency with gap 0.6, no filtering, and no growth to stdout",

	$in_script,
        $outd,

	#Input files (to make sure they pre-exist)
	[$inf1],
	#Supply the first input file on standard in
	0,

	#Output files anticipated (they will be deleted if they pre-exist)
	[],
	#Don't delete these pre-existing outfiles before test (e.g. if you want
	#to test overwrite protection & created them on purpose)
	[],

	#Options to supply to the test script on command line in 1 string
	"--noheader -a 0.6 -s gDNA-PA14 -d 1 -s '205w3 205w2 205w1' -d 1 " .
	"--nogenotype --nofilter --nogrow $inf1",

	#Names of files expected to NOT be created. Supply to Outfiles to test
	#Up to 6 (NOT inc. STD's).  Supply undef if not testing.
	[],

	#Exact expected stdout & stderr files.  Supply undef if no test.
	$expf1,undef,
	#Exact expected output files.  Must be the same size as the output files
	#array above.  Supply undef if not testing.
	[],

	#Patterns expected in string output for stdout & stderr.  Supply undef
	#if not testing.
	undef,undef,
	#Patterns expected in string output for o1, o2, ...  Supply undef if not
	#testing.
	[],

	#Patterns not expected in string output for stdout & stderr.  Supply
	#undef if not testing.
        undef,'(ERROR|WARNING)\d+:',
	#Patterns not expected in string output for o1, o1, ...  Supply undef if
	#not testing.
        [],

	#Exit code (0 = success, 1 = error: means any non-0 value is expected)
	0);



TEST6:

#Describe the test
$test_num++;
$sub_test_num++;
$reqnum = '4';

$inf1  = 'inputs/fbse1.vcf';
$expf1 = "expected/test$test_num.in1.s1.s3.d1.d1.gt.nh.fn.gn.rvcf";


testaf4(#Test description
	$test_num,
	$sub_test_num,
	$reqnum,
	"Genotype mode with no filtering and no growth to stdout",

	$in_script,
        $outd,

	#Input files (to make sure they pre-exist)
	[$inf1],
	#Supply the first input file on standard in
	0,

	#Output files anticipated (they will be deleted if they pre-exist)
	[],
	#Don't delete these pre-existing outfiles before test (e.g. if you want
	#to test overwrite protection & created them on purpose)
	[],

	#Options to supply to the test script on command line in 1 string
	"--noheader -s gDNA-PA14 -d 1 -s '205w3 205w2 205w1' -d 1 --genotype " .
	"--nofilter --nogrow $inf1",

	#Names of files expected to NOT be created. Supply to Outfiles to test
	#Up to 6 (NOT inc. STD's).  Supply undef if not testing.
	[],

	#Exact expected stdout & stderr files.  Supply undef if no test.
	$expf1,undef,
	#Exact expected output files.  Must be the same size as the output files
	#array above.  Supply undef if not testing.
	[],

	#Patterns expected in string output for stdout & stderr.  Supply undef
	#if not testing.
	undef,undef,
	#Patterns expected in string output for o1, o2, ...  Supply undef if not
	#testing.
	[],

	#Patterns not expected in string output for stdout & stderr.  Supply
	#undef if not testing.
        undef,'(ERROR|WARNING)\d+:',
	#Patterns not expected in string output for o1, o1, ...  Supply undef if
	#not testing.
        [],

	#Exit code (0 = success, 1 = error: means any non-0 value is expected)
	0);


TEST7:

#Describe the test
$test_num++;
$sub_test_num++;
$reqnum = '4';

$inf1     = 'inputs/fbse1.vcf';

my $tdir  = "$outd/TEST$test_num";
my $outf1 = "$tdir/" . basename($inf1) . ".in1.s1.s3.d1.d1.af.a6.nh.fy.gy.rvcf";
my $outf2 = "$tdir/" . basename($inf1) . ".in1.s1.s3.d1.d1.af.a6.nh.fy.gy.vcf";

$expf1    = "expected/test$test_num.in1.s1.s3.d1.d1.af.a6.nh.fy.gy.rvcf";
my $expf2 = "expected/test$test_num.in1.s1.s3.d1.d1.af.a6.nh.fy.gy.vcf";


testaf4(#Test description
	$test_num,
	$sub_test_num,
	$reqnum,
	"Allelic frequency with gap 0.6, filtering, and growth, and with " .
	"rvcf & vcf output",

	$in_script,
        $outd,

	#Input files (to make sure they pre-exist)
	[$inf1],
	#Supply the first input file on standard in
	0,

	#Output files (they will be deleted if they pre-exist)
	[$outf1,$outf2],
	#Don't delete these pre-existing outfiles before test (e.g. if you want
	#to test overwrite protection & created them on purpose)
	[],

	#Options to supply to the test script on command line in 1 string.
	#Be sure to specify in & out files, but no redirection.
	"-a 0.6 --noheader -s gDNA-PA14 -d 1 -s '205w3 205w2 205w1' -d 1 " .
	"--nogenotype --filter --grow $inf1 --outdir '$tdir' -u " .
	".in1.s1.s3.d1.d1.af.a6.nh.fy.gy.rvcf -o " .
	".in1.s1.s3.d1.d1.af.a6.nh.fy.gy.vcf",

	#Names of files expected to NOT be created. Supply undef if not testing.
	[],

	#Exact expected stdout & stderr files.  Supply undef if no test.
	undef,undef,
	#Exact expected output files.  Must be the same size as the output files
	#array above.  Supply undef if not testing.
	[$expf1,$expf2],

	#Patterns expected in string output for stdout & stderr.  Supply undef
	#if not testing.
	undef,undef,
	#Patterns expected in string output for o1, o2, ...  Supply undef if not
	#testing.
	[undef,undef],

	#Patterns not expected in string output for stdout & stderr.  Supply
	#undef if not testing.
        undef,'(ERROR|WARNING)\d+:',
	#Patterns not expected in string output for o1, o1, ...  Supply undef if
	#not testing.
        [undef,undef],

	#Exit code (0 = success, 1 = error: means any non-0 value is expected)
	0);


TEST8:

#Describe the test
$test_num++;
$sub_test_num++;
$reqnum = '4';

$inf1  = 'inputs/fbse1.vcf';

$tdir  = "$outd/TEST$test_num";
$outf1 = "$tdir/" . basename($inf1) . ".in1.s1.s3.d1.d1.gt.nh.fy.gy.rvcf";
$outf2 = "$tdir/" . basename($inf1) . ".in1.s1.s3.d1.d1.gt.nh.fy.gy.vcf";

$expf1 = "expected/test$test_num.in1.s1.s3.d1.d1.gt.nh.fy.gy.rvcf";
$expf2 = "expected/test$test_num.in1.s1.s3.d1.d1.gt.nh.fy.gy.vcf";


testaf4(#Test description
	$test_num,
	$sub_test_num,
	$reqnum,
	"Genotype mode with filtering and growth, and with rvcf & vcf output",

	$in_script,
        $outd,

	#Input files (to make sure they pre-exist)
	[$inf1],
	#Supply the first input file on standard in
	0,

	#Output files (they will be deleted if they pre-exist)
	[$outf1,$outf2],
	#Don't delete these pre-existing outfiles before test (e.g. if you want
	#to test overwrite protection & created them on purpose)
	[],

	#Options to supply to the test script on command line in 1 string
	"--noheader -s gDNA-PA14 -d 1 -s '205w3 205w2 205w1' -d 1 --genotype " .
	"--filter --grow $inf1 --outdir '$tdir' -u " .
	".in1.s1.s3.d1.d1.gt.nh.fy.gy.rvcf -o " .
	".in1.s1.s3.d1.d1.gt.nh.fy.gy.vcf",

	#Names of files expected to NOT be created. Supply undef if not testing.
	[],

	#Exact expected stdout & stderr files.  Supply undef if no test.
	undef,undef,
	#Exact expected output files.  Must be the same size as the output files
	#array above.  Supply undef if not testing.
	[$expf1,$expf2],

	#Patterns expected in string output for stdout & stderr.  Supply undef
	#if not testing.
	undef,undef,
	#Patterns expected in string output for o1, o2, ...  Supply undef if not
	#testing.
	[undef,undef],

	#Patterns not expected in string output for stdout & stderr.  Supply
	#undef if not testing.
        undef,'(ERROR|WARNING)\d+:',
	#Patterns not expected in string output for o1, o1, ...  Supply undef if
	#not testing.
        [undef,undef],

	#Exit code (0 = success, 1 = error: means any non-0 value is expected)
	0);









































##
## Supporting methods
##

BEGIN
  {
    $script = $0;

    $num_tests = `grep -E -c "^TEST[0-9]+:" $script`;
    chomp($num_tests);

    #Determine available tests to start from
    my $grepcmd1 = "grep -E '^TEST[0-9]+:' $script | grep -v '#'";
    my $grepout = `$grepcmd1`;
    my $astarts =
      [map {s/TEST(\d+):.*/$1/;$_} grep {/./} split(/\n/,$grepout,-1)];
    @$available_starts = @$astarts;

    my(@ranges);
    my $range = [];
    for(@$available_starts) {
      if(scalar(@$range) == 0 ||
	 (scalar(@$range) && $_ - $range->[$#{$range}] == 1))
	{
	  push(@$range,$_);
	  next;
	}
      push(@ranges,$range);
      $range = [$_];
    }
    if(scalar(@$range))
      {push(@ranges,$range)}

    my @rangelist = (map {scalar(@$_) > 2 ? "$_->[0]-$_->[-1]" : @$_} @ranges);

    $available_ranges = [@rangelist];

    $changed_dir = 0;
    if($ENV{PWD} !~ m%/t/?$% && -e 't' && -d 't')
      {
	chdir('t');
	$changed_dir = 1;
	$ENV{PWD} .= '/t';
	$script =~ s%^t/%%;
	$script =~ s%^[/\.].*?/t/%%;
      }

    #Check labels in the test script for an error
    my $cmd = "grep -E \"^TEST[0-9]+:\" $script | sort | uniq -c | " .
      "grep -E \" [2-9]| [1-9][0-9]\"";
    my $label_dupes = `$cmd`;
    if(!-e $script)
      {error("Command for test label validation failed: [$cmd]",
	     ($! ne '' ? ": [$!]." : '.'))}
    elsif($label_dupes =~ /./)
      {
	error("ERROR: Duplicate test labels exist in $script:\n$label_dupes");
	quit(1);
      }

    debug("PWD: $ENV{PWD}\nScript: $script\n");
  }

END
  {
    if($generate)
      {print("\n\n*** New expected outfiles generated.  CHECK THAT THEY ARE ",
	     "VALID EVEN IF ALL TESTS NOW PASS!  Note, you will have to ",
	     "manually remove any expected output files that have been ",
	     "abandonned.\n\n")}
    #If the user supplied --usage or --help, Test::More won't have loaded
    if(eval('Test::More->builder->is_passing'))
      {print("All tests passed.\n")}
    if($changed_dir)
      {
	chdir('..');
	$script = "t/$script";
	$changed_dir = 1;
      }
  }

#Basic test that handles up to 6 input files.  Adds the ability to ensure some
#outfiles WERE NOT created
sub test6f3
  {
    #Describe the test
    my $test_num     = $_[0];
    my $sub_test_num = $_[1];
    my $reqnum       = $_[2];
    my $description  = $_[3];

    #Path to or name of the script being tested
    my $script = $_[4];

    #Main output directory.  A test directory will be created here for each test
    my $dir = $_[5];

    #Added a param to not delete a pre-existing file to test the output modes
    my $nodel1 = defined($_[6]) ? $_[6] : 0;

    #Allow the first infile to be optionally provided on standard input
    my $first_on_stdin = defined($_[7]) ? $_[7] : 0;

    #The input files (supplied on cmd line)
    my $testf  = $_[8];
    my $testf2 = $_[9];
    my $testf3 = $_[10];
    my $testf4 = $_[11];
    my $testf5 = $_[12];
    my $testf6 = $_[13];

    #The output files the test will generate
    my $outf1 = $_[14];
    my $outf2 = $_[15];
    my $outf3 = $_[16];
    my $outf4 = $_[17];
    my $outf5 = $_[18];
    my $outf6 = $_[19];

    #Command options
    my $test_cmd_opts = $_[20];

    #Files that should NOT be created
    my $no_outf1 = $_[21];
    my $no_outf2 = $_[22];
    my $no_outf3 = $_[23];
    my $no_outf4 = $_[24];
    my $no_outf5 = $_[25];
    my $no_outf6 = $_[26];

    #Get the files that have the expected output
    my $expected_stdoutf = $_[27];
    my $expected_stderrf = $_[28];
    my $expected_outf1   = $_[29];
    my $expected_outf2   = $_[30];
    my $expected_outf3   = $_[31];
    my $expected_outf4   = $_[32];
    my $expected_outf5   = $_[33];
    my $expected_outf6   = $_[34];

    my $should_stdout_pat = $_[35];
    my $should_stderr_pat = $_[36];
    my $should_outf1_pat  = $_[37];
    my $should_outf2_pat  = $_[38];
    my $should_outf3_pat  = $_[39];
    my $should_outf4_pat  = $_[40];
    my $should_outf5_pat  = $_[41];
    my $should_outf6_pat  = $_[42];

    my $shouldnt_stdout_pat = $_[43];
    my $shouldnt_stderr_pat = $_[44];
    my $shouldnt_outf1_pat  = $_[45];
    my $shouldnt_outf2_pat  = $_[46];
    my $shouldnt_outf3_pat  = $_[47];
    my $shouldnt_outf4_pat  = $_[48];
    my $shouldnt_outf5_pat  = $_[49];
    my $shouldnt_outf6_pat  = $_[50];

    my $exit_error = $_[51]; #Non-zero if expected to return an exit code not
                             #equal to 0

    ##
    ## Prepare for test run
    ##

    #Warn if a subtest number is repeated
    if(exists($subtest_hash->{$reqnum}) &&
       exists($subtest_hash->{$reqnum}->{$sub_test_num}))
      {warning("Requirement: [$reqnum] has duplicate subtest numbers: ",
	       "[$sub_test_num] for test [$test_num].")}
    $subtest_hash->{$reqnum}->{$sub_test_num} = 1;

    #Directory in which to create a test directory for stdout & stderr files
    my $testdir          = "$dir/TEST$test_num";
    my $scrname          = basename($script);
    my $test_errorf      = "$dir/TEST$test_num/$scrname.stderr.txt";
    my $test_stdoutf     = "$dir/TEST$test_num/$scrname.stdout.txt";
    if(!-e $dir)
      {mkdir($dir)}
    if(!-e $testdir)
      {mkdir($testdir)}

    #Clean up outfile paths
    $outf1 =~ s%/\./%/%g if(defined($outf1));
    $outf2 =~ s%/\./%/%g if(defined($outf2));
    $outf3 =~ s%/\./%/%g if(defined($outf3));
    $outf4 =~ s%/\./%/%g if(defined($outf4));
    $outf5 =~ s%/\./%/%g if(defined($outf5));
    $outf6 =~ s%/\./%/%g if(defined($outf6));

    #Clean up any previous tests
    unlink($outf1)  if(defined($outf1) && $outf1 ne '' && -e $outf1 &&
		       (!defined($nodel1) || !$nodel1));
    unlink($outf2)  if(defined($outf2) && $outf2 ne '' && -e $outf2);
    unlink($outf3)  if(defined($outf3) && $outf3 ne '' && -e $outf3);
    unlink($outf4)  if(defined($outf4) && $outf4 ne '' && -e $outf4);
    unlink($outf5)  if(defined($outf5) && $outf5 ne '' && -e $outf5);
    unlink($outf6)  if(defined($outf6) && $outf6 ne '' && -e $outf6);

    #Create the command
    if($debug_opts ne '' && ($test_cmd_opts !~ /$script_debug_flag/ ||
			     isForce()))
      {
	if($test_cmd_opts =~ /$script_debug_flag/)
	  {$test_cmd_opts =~ s/$script_debug_flag(\s+\-?\d+)?/$debug_opts/}
	else
	  {$test_cmd_opts .= " $debug_opts"}
      }
    my $test_cmd = $first_on_stdin ? "cat $testf | " : '';
    $test_cmd   .= ("$perl_call $script $test_cmd_opts 1> $test_stdoutf 2> " .
		    "$test_errorf");

    ##
    ## Run the test
    ##

    #Run the command
    verbose({LEVEL => 2},"TEST$test_num: $test_cmd");
    `$test_cmd`;

    ##
    ## Refresh expected files if in generate mode
    ##

    if($generate)
      {
	generate([$test_stdoutf,$test_errorf,$outf1,$outf2,$outf3,$outf4,$outf5,
		  $outf6],
		 [$expected_stdoutf,$expected_stderrf,$expected_outf1,
		  $expected_outf2,$expected_outf3,$expected_outf4,
		  $expected_outf5,$expected_outf6],
		 $test_num);
      }

    ##
    ## Evaluate test result
    ##

    my $exit_code = $?;

    #Create a string or pattern for the expected result
    my $should_stdout_str = getContents($expected_stdoutf);
    my $should_stderr_str = getContents($expected_stderrf);
    my $should_outf1_str  = getContents($expected_outf1);
    my $should_outf2_str  = getContents($expected_outf2);
    my $should_outf3_str  = getContents($expected_outf3);
    my $should_outf4_str  = getContents($expected_outf4);
    my $should_outf5_str  = getContents($expected_outf5);
    my $should_outf6_str  = getContents($expected_outf6);

    #Retrieve what the script generated in the test
    my $test_output = getContents($test_stdoutf);
    my $test_error  = getContents($test_errorf);
    my $test_outf1  = getContents($outf1);
    my $test_outf2  = getContents($outf2);
    my $test_outf3  = getContents($outf3);
    my $test_outf4  = getContents($outf4);
    my $test_outf5  = getContents($outf5);
    my $test_outf6  = getContents($outf6);

    my $test_description = "TEST$test_num: REQ$reqnum SubTest$sub_test_num " .
      "- $description";

    #Evaluate the result
    my $test_status = ((!defined($outf1) ||
			(-e $outf1 && $should_outf1_str eq $test_outf1)) &&
		       (!defined($outf2) ||
			(-e $outf2 && $should_outf2_str eq $test_outf2)) &&
		       (!defined($outf3) ||
			(-e $outf3 && $should_outf3_str eq $test_outf3)) &&
		       (!defined($outf4) ||
			(-e $outf4 && $should_outf4_str eq $test_outf4)) &&
		       (!defined($outf5) ||
			(-e $outf5 && $should_outf5_str eq $test_outf5)) &&
		       (!defined($outf6) ||
			(-e $outf6 && $should_outf6_str eq $test_outf6)) &&

		       #Test that these files that are not supposed to be
		       #created did not get created
		       (!defined($no_outf1) || !-e $outf1) &&
		       (!defined($no_outf2) || !-e $outf2) &&
		       (!defined($no_outf3) || !-e $outf3) &&
		       (!defined($no_outf4) || !-e $outf4) &&
		       (!defined($no_outf5) || !-e $outf5) &&
		       (!defined($no_outf5) || !-e $outf6) &&

		       (!defined($should_stdout_str) ||
			$should_stdout_str eq $test_output) &&
		       (!defined($should_stderr_str) ||
			$should_stderr_str eq $test_error) &&

		       matchPats($test_outf1,$should_outf1_pat,1,$outf1) &&
		       matchPats($test_outf2,$should_outf2_pat,1,$outf2) &&
		       matchPats($test_outf3,$should_outf3_pat,1,$outf3) &&
		       matchPats($test_outf4,$should_outf4_pat,1,$outf4) &&
		       matchPats($test_outf5,$should_outf5_pat,1,$outf5) &&
		       matchPats($test_outf6,$should_outf6_pat,1,$outf6) &&

		       matchPats($test_outf1,$shouldnt_outf1_pat,0,$outf1) &&
		       matchPats($test_outf2,$shouldnt_outf2_pat,0,$outf2) &&
		       matchPats($test_outf3,$shouldnt_outf3_pat,0,$outf3) &&
		       matchPats($test_outf4,$shouldnt_outf4_pat,0,$outf4) &&
		       matchPats($test_outf5,$shouldnt_outf5_pat,0,$outf5) &&
		       matchPats($test_outf6,$shouldnt_outf6_pat,0,$outf6) &&

		       matchPats($test_output,$should_stdout_pat,1,'STDOUT') &&

		       matchPats($test_output,$shouldnt_stdout_pat,0,
				 'STDOUT') &&

		       matchPats($test_error,$should_stderr_pat,1,'STDERR') &&

		       matchPats($test_error,$shouldnt_stderr_pat,0,
				 'STDERR') &&

		       (($exit_error == 0 && $exit_code == 0) ||
			($exit_error != 0 && $exit_code != 0)));
    ok($test_status,$test_description);

    ##
    ## Report test result
    ##

    #If the test failed while in debug mode, print a description of what went
    #wrong
    if(!$test_status && $self_debug)
      {
	my $success = (($exit_error != 0  && $exit_code != 0) ||
		       ($exit_error == 0  && $exit_code == 0));
	my $expected = ($success ? [] : [['EXITCO',$exit_error]]);
	my $gotarray = ($success ? [] : [['EXITCO',$exit_code]]);

	#Each array in this foreach is: output name, output filename, content
	#of file, expected exact output string, expected output pattern,
	#unexpected output pattern (i.e. should not match), and if the file
	#should not have been created
	foreach my $ary (['STDOUT',$test_stdoutf,$test_output,
			  $should_stdout_str,$should_stdout_pat,
			  $shouldnt_stdout_pat,undef,$expected_stdoutf],
			 ['STDERR',$test_errorf,$test_error,$should_stderr_str,
			  $should_stderr_pat,$shouldnt_stderr_pat,undef,
			  $expected_stderrf],
			 ['OUTF1 ',$outf1,$test_outf1,$should_outf1_str,
			  $should_outf1_pat,$shouldnt_outf1_pat,$no_outf1,
			  $expected_outf1],
			 ['OUTF2 ',$outf2,$test_outf2,$should_outf2_str,
			  $should_outf2_pat,$shouldnt_outf2_pat,$no_outf2,
			  $expected_outf2],
			 ['OUTF3 ',$outf3,$test_outf3,$should_outf3_str,
			  $should_outf3_pat,$shouldnt_outf3_pat,$no_outf3,
			  $expected_outf3],
			 ['OUTF4 ',$outf4,$test_outf4,$should_outf4_str,
			  $should_outf4_pat,$shouldnt_outf4_pat,$no_outf4,
			  $expected_outf4],
			 ['OUTF5 ',$outf5,$test_outf5,$should_outf5_str,
			  $should_outf5_pat,$shouldnt_outf5_pat,$no_outf5,
			  $expected_outf5],
			 ['OUTF6 ',$outf6,$test_outf6,$should_outf6_str,
			  $should_outf6_pat,$shouldnt_outf6_pat,$no_outf6,
			  $expected_outf6])
	  {
	    if(defined($ary->[3]))
	      {
		if((($ary->[1] eq 'STDOUT' || $ary->[1] eq 'STDERR' ||
		     -e $ary->[1]) && $ary->[2] ne $ary->[3]) ||
		   ($ary->[1] ne 'STDOUT' && $ary->[1] ne 'STDERR' &&
		    !-e $ary->[1]))
		  {
		    push(@$expected,[$ary->[0],
				     "`diff '$ary->[1]' '$ary->[7]'` = empty"]);
		    push(@$gotarray,[$ary->[0],
				     (defined($ary->[1]) && defined($ary->[7]) ?
				      `diff '$ary->[1]' '$ary->[7]'` :
				      'undef')]);
		  }
	      }
	    if(defined($ary->[4]))
	      {
		my @pats = ();
		if(ref($ary->[4]) eq 'ARRAY')
		  {push(@pats,@{$ary->[4]})}
		else
		  {push(@pats,$ary->[4])}
		foreach my $pat (@pats)
		  {
		    if((($ary->[1] eq 'STDOUT' || $ary->[1] eq 'STDERR' ||
			 -e $ary->[1]) && $ary->[2] !~ /$pat/s) ||
		       ($ary->[1] ne 'STDOUT' && $ary->[1] ne 'STDERR' &&
			!-e $ary->[1]))
		      {
			push(@$expected,[$ary->[0],"/$pat/s"]);
			push(@$gotarray,[$ary->[0],$ary->[2]]);
		      }
		  }
	      }
	    if(defined($ary->[5]))
	      {
		my @pats = ();
		if(ref($ary->[5]) eq 'ARRAY')
		  {push(@pats,@{$ary->[5]})}
		else
		  {push(@pats,$ary->[5])}
		foreach my $pat (@pats)
		  {
		    if((($ary->[1] eq 'STDOUT' || $ary->[1] eq 'STDERR' ||
			 -e $ary->[1]) && $ary->[2] =~ /$pat/s) ||
		       ($ary->[1] ne 'STDOUT' && $ary->[1] ne 'STDERR' &&
			!-e $ary->[1]))
		      {
			push(@$expected,[$ary->[0],"!~ /$pat/s"]);
			push(@$gotarray,[$ary->[0],$ary->[2]]);
		      }
		  }
	      }
	    if(defined($ary->[6]) && -e $ary->[1])
	      {
		push(@$expected,[$ary->[0],"$ary->[1] not created"]);
		push(@$gotarray,[$ary->[0],"$ary->[1] created"]);
	      }
	  }

	debug3($expected,$gotarray,$test_status,$test_cmd);
      }

    ##
    ## Clean up test output
    ##

    if($clean)
      {
	#Clean up files:
	foreach my $tfile (grep {defined($_)} ($outf1,$outf2,$outf3,$outf4,
					       $outf5,$outf6,$test_errorf,
					       $test_stdoutf))
	  {unlink($tfile)}
	`rm -rf $testdir`;
	#foreach my $tdir ($outd1,$outd2)
	#  {`rm -rf $tdir` if(defined($tdir) && $tdir ne '' && -e $tdir)}
      }
  }

#Improved to take any number of files
#Globals used: $generate, $clean, $ending_test
sub testaf4
  {
    #Describe the test
    my $test_num     = $_[0];
    my $sub_test_num = $_[1];
    my $reqnum       = $_[2];
    my $description  = $_[3];

    #Path to or name of the script being tested
    my $script = $_[4];

    #Main output directory.  A test directory will be created here for each test
    my $dir = $_[5];

    #The input files (supplied on cmd line)
    my $infiles = $_[6];

    #Allow the first infile to be optionally provided on standard input
    my $first_on_stdin = defined($_[7]) ? $_[7] : 0;

    #The output files the test will generate
    my $outf1 = $_[8];

    #Added a param to not delete a pre-existing file to test the output modes
    my $nodel1 = defined($_[9]) ? $_[9] : [];

    #Command options
    my $test_cmd_opts = $_[10];

    #Files that should NOT be created
    my $no_outf1 = $_[11];

    #Get the files that have the expected output
    my $expected_stdoutf = $_[12];
    my $expected_stderrf = $_[13];
    my $expected_outf1   = $_[14];

    my $should_stdout_pat = $_[15];
    my $should_stderr_pat = $_[16];
    my $should_outf1_pat  = $_[17];

    my $shouldnt_stdout_pat = $_[18];
    my $shouldnt_stderr_pat = $_[19];
    my $shouldnt_outf1_pat  = $_[20];

    my $exit_error = $_[21]; #Non-zero if expected to return an exit code not
                             #equal to 0

    ##
    ## Prepare for test run
    ##

    #Warn if a subtest number is repeated
    if(exists($subtest_hash->{$reqnum}) &&
       exists($subtest_hash->{$reqnum}->{$sub_test_num}))
      {warning("Requirement: [$reqnum] has duplicate subtest numbers: ",
	       "[$sub_test_num] for test [$test_num].")}
    $subtest_hash->{$reqnum}->{$sub_test_num} = 1;

    #Directory in which to create a test directory for stdout & stderr files
    my $testdir          = "$dir/TEST$test_num";
    my $scrname          = basename($script);
    my $test_errorf      = "$testdir/$scrname.stderr.txt";
    my $test_stdoutf     = "$testdir/$scrname.stdout.txt";
    if(!-e $dir)
      {mkdir($dir)}
    if(!-e $testdir)
      {mkdir($testdir)}

    #Clean up outfile paths
    foreach my $outf (@$outf1)
      {$outf =~ s%/\./%/%g if(defined($outf))}

    #Clean up any previous tests without deleting files marked to not be deleted
    my $nodel_hash = {};
    foreach my $file (@$nodel1)
      {$nodel_hash->{$file}++}
    foreach my $outf (@$outf1)
      {unlink($outf)  if(defined($outf) && $outf ne '' && -e $outf &&
			 (!defined($nodel1) || !exists($nodel_hash->{$outf})))}

    #Create the command
    if($debug_opts ne '' && ($test_cmd_opts !~ /$script_debug_flag/ ||
			     isForce()))
      {
	if($test_cmd_opts =~ /$script_debug_flag/)
	  {$test_cmd_opts =~ s/$script_debug_flag(\s+\-?\d+)?/$debug_opts/}
	else
	  {$test_cmd_opts .= " $debug_opts"}
      }
    my $test_cmd = $first_on_stdin ? "cat $infiles->[0] | " : '';
    $test_cmd   .= ("$perl_call $script $test_cmd_opts 1> $test_stdoutf 2> " .
		    "$test_errorf");

    ##
    ## Run the test
    ##

    #Run the command
    verbose({LEVEL => 2},"TEST$test_num: $test_cmd");
    `$test_cmd`;

    ##
    ## Refresh expected files if in generate mode
    ##

    if($generate)
      {generate([$test_stdoutf,$test_errorf,@$outf1],
		[$expected_stdoutf,$expected_stderrf,@$expected_outf1],
		$test_num)}

    ##
    ## Evaluate test result
    ##

    my $exit_code = $?;

    #Create a string or pattern for the expected result
    my $should_stdout_str = getContents($expected_stdoutf);
    my $should_stderr_str = getContents($expected_stderrf);
    my $should_outf1_str  = [];
    foreach my $expected_outf (@$expected_outf1)
      {push(@$should_outf1_str,getContents($expected_outf))}

    #Retrieve what the script generated in the test
    my $test_output = getContents($test_stdoutf);
    my $test_error  = getContents($test_errorf);
    my $test_outf1  = [];
    foreach my $outf (@$outf1)
      {push(@$test_outf1,getContents($outf))}

    my $test_description = "TEST$test_num: REQ$reqnum SubTest$sub_test_num " .
      "- $description";

    #Evaluate the result
    my $test_status =
      (#Files exist and have expected exact content (or no exact match test)
       filesMatchExactly($outf1,$should_outf1_str,$test_outf1) &&

       #Standard out matches exactly the expected output (or has no expect val)
       (!defined($should_stdout_str) || $should_stdout_str eq $test_output) &&
       #Standard err matches exactly the expected output (or has no expect val)
       (!defined($should_stderr_str) || $should_stderr_str eq $test_error) &&

       #Test that these files that are not supposed to be created did not get
       #created
       filesNotCreated($no_outf1) &&

       #All output files match supplied (positive) patterns
       filesMatchPattern($test_outf1,$should_outf1_pat,1,$outf1) &&
       matchPats($test_output,$should_stdout_pat,1,'STDOUT') &&
       matchPats($test_error,$should_stderr_pat,1,'STDERR') &&

       #All output files don't match supplied (negative) patterns
       filesMatchPattern($test_outf1,$shouldnt_outf1_pat,0,$outf1) &&
       matchPats($test_output,$shouldnt_stdout_pat,0,'STDOUT') &&
       matchPats($test_error,$shouldnt_stderr_pat,0,'STDERR') &&

       #Exit status is as expected
       (($exit_error == 0 && $exit_code == 0) ||
	($exit_error != 0 && $exit_code != 0)));

    ok($test_status,$test_description);

    ##
    ## Report test result
    ##

    #If the test failed while in debug mode, print a description of what went
    #wrong
    if(!$test_status && $self_debug)
      {
	my $success = (($exit_error != 0  && $exit_code != 0) ||
		       ($exit_error == 0  && $exit_code == 0));
	my $expected = ($success ? [] : [['EXITCO',$exit_error]]);
	my $gotarray = ($success ? [] : [['EXITCO',$exit_code]]);

	#Each array in this foreach is: output name, output filename, content
	#of file, expected exact output string, expected output pattern,
	#unexpected output pattern (i.e. should not match), and if the file
	#should not have been created
	foreach my $ary (['STDOUT',$test_stdoutf,$test_output,
			  $should_stdout_str,$should_stdout_pat,
			  $shouldnt_stdout_pat,undef,$expected_stdoutf],
			 ['STDERR',$test_errorf,$test_error,$should_stderr_str,
			  $should_stderr_pat,$shouldnt_stderr_pat,undef,
			  $expected_stderrf],
			 (map {["OUTF" . ($_ + 1) . (length($_) > 1 ? '' : ' '),
				$outf1->[$_],
				$test_outf1->[$_],
				$should_outf1_str->[$_],
				$should_outf1_pat->[$_],
				$shouldnt_outf1_pat->[$_],
				undef,
				$expected_outf1->[$_]]} (0..$#{$outf1})),
			 (map {["NOOUT" . ($_ + 1),
				undef,
				undef,
				undef,
				undef,
				undef,
				$no_outf1->[$_],
				undef]} (0..$#{$no_outf1})))
	  {
	    #If no outfiles were supplied, the 3rd $ary will be undefined
	    next if(!defined($ary));

	    if(defined($ary->[3]))
	      {
		if(defined($ary->[1]) && defined($ary->[7]) &&
		   (!-e $ary->[1] || $ary->[2] ne $ary->[3]))
		  {
		    if(!-e $ary->[7])
		      {error("Expected outfile does not exist: [$ary->[7]].")}
		    else
		      {
			my $diff = `diff '$ary->[1]' '$ary->[7]'`;
			if($?)
			  {error("Diff failed.  $!")}
			elsif(!defined($diff) || $diff eq '')
			  {
			    push(@$expected,[$ary->[0],$ary->[3]]);
			    push(@$gotarray,[$ary->[0],$ary->[2]]);
			  }
			else
			  {
			    push(@$expected,
				 [$ary->[0],
				  "`diff '$ary->[1]' '$ary->[7]'` = empty"]);
			    push(@$gotarray,[$ary->[0],
					     (-e $ary->[1] ? $diff : 'undef')]);
			  }
		      }
		  }
	      }
	    if(defined($ary->[4]))
	      {
		my @pats = ();
		if(ref($ary->[4]) eq 'ARRAY')
		  {push(@pats,@{$ary->[4]})}
		else
		  {push(@pats,$ary->[4])}
		foreach my $pat (@pats)
		  {
		    if((($ary->[1] eq 'STDOUT' || $ary->[1] eq 'STDERR' ||
			 -e $ary->[1]) && $ary->[2] !~ /$pat/s) ||
		       ($ary->[1] ne 'STDOUT' && $ary->[1] ne 'STDERR' &&
			!-e $ary->[1]))
		      {
			push(@$expected,[$ary->[0],"/$pat/s"]);
			push(@$gotarray,[$ary->[0],$ary->[2]]);
		      }
		  }
	      }
	    if(defined($ary->[5]))
	      {
		my @pats = ();
		if(ref($ary->[5]) eq 'ARRAY')
		  {push(@pats,@{$ary->[5]})}
		else
		  {push(@pats,$ary->[5])}
		foreach my $pat (@pats)
		  {
		    if((($ary->[1] eq 'STDOUT' || $ary->[1] eq 'STDERR' ||
			 -e $ary->[1]) && $ary->[2] =~ /$pat/s) ||
		       ($ary->[1] ne 'STDOUT' && $ary->[1] ne 'STDERR' &&
			!-e $ary->[1]))
		      {
			push(@$expected,[$ary->[0],"!~ /$pat/s"]);
			push(@$gotarray,[$ary->[0],$ary->[2]]);
		      }
		  }
	      }
	    if(defined($ary->[6]) && -e $ary->[6])
	      {
		push(@$expected,[$ary->[0],"$ary->[6] not created"]);
		push(@$gotarray,[$ary->[0],"$ary->[6] created"]);
	      }
	  }

	debug3($expected,$gotarray,$test_status,$test_cmd);
      }

    ##
    ## Clean up test output
    ##

    if($clean)
      {
	#Clean up files:
	foreach my $tfile (grep {defined($_)} (@$outf1,$test_errorf,
					       $test_stdoutf,@$nodel1))
	  {unlink($tfile)}
	`rm -rf $testdir`;
	#foreach my $tdir ($outd1,$outd2)
	#  {`rm -rf $tdir` if(defined($tdir) && $tdir ne '' && -e $tdir)}
      }

    quit(0) if($test_num == $ending_test);
  }

#Checks to make sure that files which have expected contents were created and
#exactly match the expected contents.  The arrays must be the same size.  If an
#outfile has no expected content (i.e. it may be anything), the $shoulds array
#should have an undef value for that file.
sub filesMatchExactly
  {
    my $outfiles = $_[0]; #Array of strings of file names
    my $shoulds  = $_[1]; #Array of strings of expected file contents
    my $actuals  = $_[2]; #Array of strings of actual file contents

    return(scalar(grep {!defined($outfiles->[$_]) ||
			  (-e $outfiles->[$_] &&
			   $shoulds->[$_] eq $actuals->[$_])}
		  0..$#{$outfiles}) ==
	   scalar(@$outfiles));
  }

#Checks to make sure that all files that should not be created were not created
sub filesNotCreated
  {
    my $files = $_[0];
    return(scalar(grep {!defined($_) || !-e $_} @$files) == scalar(@$files));
  }

#Determines whether all *defined* patterns match/don't match as expected or not
sub filesMatchPattern
  {
    my $contents = $_[0]; #Array of strings of file contents
    my $patterns = $_[1]; #Array of patterns and/or arrays of patterns
    my $pos_neg  = $_[2]; #Boolean - expected to match or not match
    my $outfiles = $_[3]; #Array of outfile names
    return(scalar(grep {matchPats($contents->[$_],
				  $patterns->[$_],
				  $pos_neg,
				  $outfiles->[$_])} 0..$#{$outfiles}) ==
	   scalar(@$outfiles));
  }

sub getContents
  {
    my $file     = $_[0];
    my $contents = '';
    if(defined($file) && -e $file && open(CONT,$file))
      {
	$contents = join('',<CONT>);
	close(CONT);
      }
    return($contents);
  }

#Globals used: $test_num, $test_cmd
sub debug3
  {
    my $expected_array = $_[0]; #[[output_name,string_describing_expectation],]
    my $got_array      = $_[1]; #[[output_name,actual_output],...]
    #Tests 127+ expect this input:
    my $test_status    = $_[2];
    my $test_cmd       = (defined($_[3]) ? $_[3] : $test_cmd);
    if(scalar(@$expected_array) != scalar(@$got_array))
      {
	error("Expected file array and got file array are not the same size [",
	      scalar(@$expected_array)," != ",scalar(@$got_array),"].");
	return();
      }
    elsif(scalar(grep {ref($_) ne 'ARRAY' || scalar(@$_) != 2}
		 @$expected_array))
      {
	error("Expected file array is invalid.");
	return();
      }
    elsif(scalar(grep {ref($_) ne 'ARRAY' || scalar(@$_) != 2} @$got_array))
      {
	error("Got file array is invalid.\n");
	return();
      }
    #return() if($local_test_status || !$self_debug);
    print("TEST$test_num: $test_cmd\n");
    for(my $i = 0;$i < scalar(@$got_array);$i++)
      {
	$expected_array->[$i]->[1] =~ s/\n(?=.)/\n\t                  /g;
	$expected_array->[$i]->[1] =~ s/\n$/\n\t                 /g;
	$got_array->[$i]->[1]      =~ s/\n(?=.)/\n\t                  /g;
	$got_array->[$i]->[1]      =~ s/\n$/\n\t                 /g;
	print("\tExpected $expected_array->[$i]->[0]: ",
	      "[$expected_array->[$i]->[1]]\n",
	      "\tGot:             [$got_array->[$i]->[1]]\n");
      }
  }

sub matchPats
  {
    my $str    = $_[0];
    my $pats   = $_[1];
    my $should = $_[2];
    my $outf   = $_[3];
    if(!defined($pats) || !defined($outf))
      {return(1)}
    #If it's an output file that's not a standard output and it doesn't exist,
    #it can't match, so return false
    elsif($outf ne 'STDOUT' && $outf ne 'STDERR' && !-e $outf)
      {return(0)}
    elsif(ref($pats) eq 'ARRAY')
      {return($should ?
	      scalar(@$pats) == scalar(grep {$str =~ /$_/s} @$pats) :
	      scalar(@$pats) == scalar(grep {$str !~ /$_/s} @$pats))}
    else
      {return($should ? scalar($str =~ /$pats/s) : scalar($str !~ /$pats/s))}
  }

sub generate
  {
    my $got_files = $_[0];
    my $exp_files = $_[1];
    my $test_num  = $_[2];

    if(scalar(@$got_files) != scalar(@$exp_files))
      {
	error("Different number of output files [",scalar(@$got_files),
	      "] versus expected output files [",scalar(@$exp_files),"].");
	return();
      }

    foreach my $i (0..$#{$got_files})
      {
	if(defined($got_files->[$i]) && defined($exp_files->[$i]))
	  {
	    if($exp_files->[$i] eq '')
	      {error("Expected outfile name of file [",($i + 1),
		     "] submitted is an empty string in test [$test_num].  ",
		     "Unable to generate file.")}
	    elsif(-e $got_files->[$i])
	      {
		my $cmd = "cp $got_files->[$i] $exp_files->[$i]";
		`$cmd`;
		if($?)
		  {error("Command [$cmd] failed.  $!")}
	      }
	    else
	      {error("Expected outfile: [$exp_files->[$i]] could not be ",
		     "generated for test [$test_num] because the file ",
		     "[$got_files->[$i]] wasn't generated by the script.")}
	  }
	elsif(defined($exp_files->[$i]) && -e $exp_files->[$i])
	  {`rm -f $exp_files->[$i]`}
      }
  }

