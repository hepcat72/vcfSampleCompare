# rankVCF.pl [LEGACY VERSION OF vcfSampleCompare]

## WHAT IS THIS:

This script takes a sequence variant file in VCF format and sorts the records in the file in ranked order, with optional filtering.  If you have multiple samples for a variant on each row, you can define groups of samples, each with criteria to be met to keep each row, or filter it out.  E.g. You can specify that the genotype of a variant in samples 1 & 2 must be different from the genotype of the variant in samples 3 & 4.  Or you can specify that the genotype of the variant in at least N samples (1, 2, and 3) must differ from the genotype of the variant in at least M samples (4, 5, 6, and 7).

## INSTALL

cd into the rankVCF directory and run the following:

    perl Makefile.PL
    make
    sudo make install
    
## USAGE (SIMPLE)

    rankVCF.pl -i "input file(s)" [options]

     -i                   REQUIRED [stdin if present] VCF input file (generated
                                   by FreeBayes).
     -s                   OPTIONAL [none] List of sample names for filtering.
     -d                   OPTIONAL [all] Number of group samples required to
                                   differ.
     -m                   OPTIONAL [0.7] Minimum ratio of variant-supporting
                                   reads vs total.
     -r                   OPTIONAL [2] Minimum number of reads mapped over a
                                   variant.
     -o                   OPTIONAL [none] Outfile extension (appended to -i).
     --help               OPTIONAL Print general info and file formats.
     --extended           OPTIONAL Print extended usage.

## USAGE (ADVANCED)

    rankVCF.pl -i "input file(s)" [-s,-d,-m,-r,-o,--outfile,--outdir,--help,--dry-run]
    rankVCF.pl -i "input file(s)" [-s,-d,-m,-r,-o,--outfile,--outdir,--help,--dry-run] < input_file

     -i,--vcf-file,       REQUIRED [stdin if present] Input file(s).  Space
     --input-file,*                separated, globs OK (e.g. $flag "*.input
                                   [A-Z].{?,??}.inp").  See --help for file
                                   format.  May be supplied on standard in.
                                   When standard input detected and -i is given
                                   only 1 argument, it will be used as a file
                                   name stub for appending outfile suffixes.
                                   See --extended --help for advanced usage
                                   examples.
                                   *No flag required.
     -s,--sample-group,   OPTIONAL [none] This is a filtering option that
     --filter-group                allows you to arbitrarily define pairs of
                                   groups of samples in which to require a
                                   minimum number of members' genotype state of
                                   a variant to differ in order to pass
                                   filtering.  For example, if you have 3
                                   wildtype samples and 4 mutant samples, you
                                   can define these 2 groups using -s 's1 s2
                                   s3' -s 's4 s5 s6 s7' (where 's1' and other
                                   sample names match the sample names in the
                                   VCF column headers row).  If you want to
                                   require that at least 1 of the mutants
                                   differ from all the wildtype samples, after
                                   defining these groups, you would use: -d 3
                                   -d 1.  The ordering of the options is
                                   important
     -d,--group-diff-min  OPTIONAL [all] Sample groups defined by -s are
                                   procssed in pairs.  Each -s group is
                                   accompanied by a minimum number of samples
                                   in that group that are required to be
                                   different from the genotype of its partner
                                   group.  "Different" in this case means the
                                   genotype state of each sample for the
                                   variant defined by the VCF record (a data
                                   row/line in the VCF file).
     -m,                  OPTIONAL [0.7] Minimum ratio of reads supporting a
     --min-support-ratio           variant (over total reads that mapped over
                                   the variant) in order to keep the
                                   row/line/record.  If any sample meets this
                                   requirement, the entire record is kept
                                   (potentially including samples which failed
                                   this filter).  Applies to all samples.
     -r,--min-read-depth  OPTIONAL [2] Minimum number of reads required to have
                                   mapped over a variant position in order to
                                   make a variant call.  If any sample meets
                                   this requirement, the entire record is kept
                                   (potentially including samples which failed
                                   this filter).  Applies to all samples.
     -o,                  OPTIONAL [none] Outfile extension appended to -i.
     --outfile-extension,          Will not overwrite without --overwrite.
     --outfile-suffix              Supplying an empty string will effectively
                                   treat the input file name (-i) as a stub
                                   (may be used with --outdir as well).  When
                                   standard input is detected and no stub is
                                   provided via -i, appends to the string
                                   "STDIN".  Does not replace existing input
                                   file extensions.  Default behavior prints
                                   output to standard out.  This option is a
                                   mutually exclusive alternative to the named
                                   outfile option.  See --extended --help for
                                   output file format and advanced usage
                                   examples.
                                   Mutually exclusive with --outfile (both
                                   options specify an outfile name in different
                                   ways for the same output).
     --outfile,           OPTIONAL [stdout] Output file(s) - a named outfile
     --output-file                 that is a mutually exclusive alternative to
                                   supplying an outfile suffix.  Space
                                   separated.
                                   Mutually exclusive with -o (both options
                                   specify an outfile name in different ways
                                   for the same output).
     --outdir             OPTIONAL [none] Directory in which to put output
                                   files.  Relative paths will be relative to
                                   each individual input file.  Creates
                                   directories specified, but not recursively.
                                   Also see --extended --help for advanced
                                   usage examples.
     --help               OPTIONAL [1] Print general info and file format
                                   descriptions.  Includes advanced usage
                                   examples with --extended.
     --dry-run            OPTIONAL Run without generating output files.
     --verbose            OPTIONAL Verbose mode/level.  (e.g. --verbose 2)
     --quiet              OPTIONAL Quiet mode.
     --overwrite          OPTIONAL Overwrite existing output files.  By
                                   default, existing output files will not be
                                   over-written.  Supply twice to safely*
                                   remove pre-existing output directories (see
                                   --outdir).  Mutually exclusive with
                                   --skip-existing and --append.
                                   *Will not remove a directory containing
                                   manually touched files.
     --skip-existing      OPTIONAL Skip existing output files.  Mutually
                                   exclusive with --overwrite and --append.
     --append             OPTIONAL Append to existing output files.  Mutually
                                   exclusive with --overwrite and
                                   --skip-existing.
     --force              OPTIONAL Prevent script-exit upon critical error and
                                   continue processing.  Supply twice to
                                   additionally prevent skipping the processing
                                   of input files that cause errors.  Use this
                                   option with extreme caution.  This option
                                   will not over-ride over-write protection.
                                   See also --overwrite or --skip-existing.
     --header,--noheader  OPTIONAL [On] Print commented script version, date,
                                   and command line call to each output file.
     --debug              OPTIONAL Debug mode/level.  (e.g. --debug --debug)
                                   Values less than 0 debug the template code
                                   that was used to create this script.
     --error-type-limit   OPTIONAL [5] Limits each type of error/warning to
                                   this number of outputs.  Intended to
                                   declutter output.  Note, a summary of
                                   warning/error types is printed when the
                                   script finishes, if one occurred or if in
                                   verbose mode.  0 = no limit.  See also
                                   --quiet.
     --version            OPTIONAL Print version info.  Includes template
                                   version with --extended.
     --save-as-default    OPTIONAL Save the command line arguments.  Saved
                                   defaults are printed at the bottom of this
                                   usage output and used in every subsequent
                                   call of this script.  Supplying this flag
                                   replaces current defaults with all options
                                   that are provided with this flag.  Values
                                   are stored in [$defdir].
                                   See --help --extended for changing script
                                   behavior when no arguments are supplied on
                                   the command line.
     --pipeline-mode      OPTIONAL Supply this flag to include the script name
                                   in errors, warnings, and debug messages.  If
                                   not supplied, the script will try to
                                   determine if it is running within a series
                                   of piped commands or as a part of a parent
                                   script.
     --extended           OPTIONAL Print extended usage/help/version/header
                                   (and errors/warnings where noted).  Supply
                                   alone for extended usage.  Includes extended
                                   version in output file headers.
                                   Incompatible with --noheader.  See --help &
                                   --version.

## INPUT FORMAT (-i, --vcf-file, --input-file, STDIN)

A VCF file is a plain text, tab-delimited file.  The format is generally described here: http://bit.ly/2sulKcZ

However, the important parts that this script relies on are:

1. The column header line (in particular - looking for the FORMAT and sample name columns).
2. The colon-delimited codes in the FORMAT column values, specifically AO (the number of reads supporting the variant) and DP (Read depth)
3. The colon-delimited values in the sample columns that correspond to the positions defined in the FORMAT column.

The file may otherwise be a standard VCF file containing header lines preceded by '##'.  Empty lines are OK and will be printed regardless of parameters supplied to this script.  Note, the --header and --no-header flags of this script do not refer to the VCF file's header, but rather the script run info header.  Note that with the script run info header, the output is no longer a standard VCF format file.  Use --no-header and the format of the output will be consistent with a standard VCF file.

## OUTPUT FORMAT: (-o, --outfile-suffix, --outfile-extension, STDOUT)

The output file is essentially the same format as the input VCF files, except 3 columns are added at the beginning of the file:

1. Number of hits and a summary of the filters that were passed passed
2. A listing of variant support/mapped reads per sample
3. A listing of samples containing evidence for the variant
