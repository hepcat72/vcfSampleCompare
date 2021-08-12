package CommandLineInterface;

##
## NOTICE
## ------
## This is a pre-release version of this module, which has been incorporated
## into multiple released tools under http://github.com/hepcat72/.  This module
## has not yet been released as its own stand-alone module.  It is in alpha
## phase development, and while it can be used, as it is found in other tools,
## it is provided with no guarantee.  Core functionality may be subject to
## change before beta release.
##


#Robert William Leach
#Princeton University
#Carl Icahn Laboratory
#Lewis Sigler Institute for Integrative Genomics
#Bioinformatics Group
#Princeton, NJ 08544
#rleach@princeton.edu
#Copyright 2018

use warnings;
use strict;
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev);
use File::Glob ':glob';

our
  $VERSION = '4.135.1';
our($compile_err);

#Basic script info
my($script_version_number,
   $created_on_date,
   $help_summary,
   $advanced_help,
   $script_author,
   $script_contact,
   $script_company,
   $script_license);
#Variables that are not directly controlled by the command line
my($default_stub,
   $preserve_args,
   $defaults_dir,
   $error_limit_default);

#Standard variables controlled by the command line
my($header,
   $user_collide_mode,  #Overrides everything
   $error_limit,
   $help,
   $extended,
   $extended_def,
   $version,
   $overwrite,
   $overwrite_def,
   $skip_existing,
   $append,
   $dry_run,
   $verbose,
   $verbose_def,
   $quiet,
   $DEBUG,
   $DEBUG_def,
   $force,
   $force_def,
   $pipeline_mode_def,
   $pipeline_mode,
   $use_as_default);

#Variables controlled by the command line, but are user-configurable
my($outfile_suffix_array,
   $input_files_array,
   $default_infiles_array,
   $outdirs_array,
   $default_outdirs_array,
   $array_defaults_hash);

#Variables for tracking the command line params, input files, and output_files
my($GetOptHash,
   $input_file_sets,
   $output_file_sets);

#Former global variables converted to package variables
my($stderr_buffer,
   $verbose_freq_hash,
   $last_verbose_size,
   $last_verbose_state,
   $verbose_warning,
   $error_number,
   $error_hash,
   $warning_number,
   $warning_hash,
   $infile_line_buffer,
   $debug_number,
   $time_marks,
   $open_out_handles,
   $rejected_out_handles,
   $closed_out_handles,
   $open_in_handles,
   $header_str);

#New variables for tracking internal workings of the code
#All 1D arrays of indexes except required_suffix_types which holds arrays of 3
#indexes (a $required_infile_types index, the index of the suffix, and the
#suffix ID)
my($required_infile_types,
   $required_suffix_types,
   $required_outfile_types,
   $required_outdirs,
   $required_opt_refs,
   $required_relationships,
   $outdirs_added,
   $accepts_hash,
   $primary_infile_type,       #Index into input_files_array
   $exp_nonprimary_inf_types,  #Explicitly-set non-primary infile types hash
   $flagless_multival_type,    #Index into usage_array
   $usage_array,
   $usage_lookup,
   $infile_flag_array,
   $suffix_flag_array,
   $outdir_flag_array,
   $general_flag_hash,
   $suffix_id_lookup,
   $suffix_primary_vals,
   $file_set_num,
   $max_set_num,
   $unproc_file_warn,
   $file_returned_before,
   $auto_file_iterate,
   $command_line_processed,    #Whether GetOptions has run
   $processCommandLine_called, #Whether processCommandLine has been called
   $usage_file_indexes,
   $outfile_types_hash,
   $outfile_tagteams,
   $tagteam_to_supplied_oid,
   $collid_modes_array,
   $def_collide_mode,          #Used if not specified per outfile type
   $def_collide_mode_suff,
   $def_collide_mode_outf,
   $outfile_mode_lookup,
   $default_infile_added,
   $default_outfile_suffix_added,
   $default_outfile_added,
   $default_outdir_added,
   $default_tagteam_added,
   $default_infile_opt,
   $default_outfile_suffix_opt,
   $default_outfile_opt,
   $default_outdir_opt,
   $default_outfile_id,
   $default_outfile_suffix_id,
   $file_group_num,
   $explicit_quit,
   $cleanup_mode,
   $run,
   $usage,
   $explicit_run,
   $explicit_dry_run,
   $explicit_help,
   $explicit_usage,
   $flag_check_hash,
   $default_run_mode,
   $inf_to_usage_hash,
   $outf_to_usage_hash,
   $genopt_types,
   $fileopt_types,
   $window_width,
   $window_width_def,
   $pipe_cache,
   $lsof_cache);

sub _init
  {
    #If preserve_args is defined and the values look different
    if(defined($preserve_args) &&
       (scalar(@ARGV) != scalar(@$preserve_args) ||
	(scalar(@ARGV) && scalar(@$preserve_args) &&
	 $ARGV[0] ne $preserve_args->[0])))
      #Restore ARGV which is assumed to have been manipulated by GetOptions
      {@ARGV               = @$preserve_args}
    else
      #Save the command line arguments before they are processed
      {$preserve_args      = [@ARGV]}

    #Basic script info
    $script_version_number = undef;
    $created_on_date       = undef;
    $help_summary          = undef;
    $advanced_help         = undef;
    $script_author         = undef;
    $script_contact        = undef;
    $script_company        = undef;
    $script_license        = undef;

    #Set some early defaults
    $defaults_dir          = (sglob('~/.rpst'))[0];
    $default_stub          = 'STDIN';
    $error_limit_default   = 5;
    $header                = 1;

    #These need to be initialized for later
    $outfile_suffix_array  = [];
    $input_files_array     = [];
    $default_infiles_array = [];
    $outdirs_array         = [];
    $default_outdirs_array = [];
    $array_defaults_hash   = {};
    $GetOptHash            = {};
    $input_file_sets       = [];
    $output_file_sets      = [];

    #These command line params should be cleared
    $user_collide_mode     = undef; #This has to be undef to know if user-set
    $def_collide_mode      = undef; #This has to be undef to know if prog-set
    $error_limit           = undef;
    $help                  = undef;
    $extended              = undef;
    $extended_def          = undef;
    $version               = undef;
    $overwrite             = undef;
    $overwrite_def         = undef;
    $skip_existing         = undef;
    $append                = undef;
    $run                   = undef;
    $dry_run               = undef;
    $verbose               = undef;
    $verbose_def           = undef;
    $quiet                 = undef;
    $DEBUG                 = undef;
    $DEBUG_def             = undef;
    $force                 = undef;
    $force_def             = undef;
    $pipeline_mode_def     = undef;
    $pipeline_mode         = undef;
    $use_as_default        = undef;

    #Initialize the default command line params
    $GetOptHash =
      {
       'overwrite:+'          => \$overwrite,                #OPTIONAL [Off]
       'skip'                 => \$skip_existing,            #OPTIONAL [Off]
       'append'               => \$append,                   #OPTIONAL [Off]
       'force:+'              => \$force,                    #OPTIONAL [Off]
       'verbose:+'            => \$verbose,                  #OPTIONAL [Off]
       'quiet'                => \$quiet,                    #OPTIONAL [Off]
       'debug:+'              => \$DEBUG,                    #OPTIONAL [Off]
       'extended:+'           => \$extended,                 #OPTIONAL [Off]
       'version'              => \$version,                  #OPTIONAL [Off]
       'header!'              => \$header,                   #OPTIONAL [On]
       'error-limit=i'        => \$error_limit,              #OPTIONAL [5]
       'save-args'            => \$use_as_default,           #OPTIONAL [Off]
       'collision-mode=s'     => \$user_collide_mode,        #OPTIONAL [error]
       'pipeline!'            => \$pipeline_mode,            #OPTIONAL [auto]

       #The presentation of these options varies, but they're always recognized
       #so that the user can set an alternative default run mode.  Thus they
       #are set here, but also get added by addRunModeOptions along with case-
       #specific settings.  Detection of duplicate options is suppressed for
       #these options.  * Default values are determined at run-time.

       'help'                 => \$explicit_help,            #OPTIONAL [*]
       'usage'                => \$explicit_usage,           #OPTIONAL [*]
       'run'                  => \$explicit_run,             #OPTIONAL [*]
       'dry-run'              => \$explicit_dry_run,         #OPTIONAL [*]
      };

    $required_infile_types        = [];
    $required_suffix_types        = [];
    $required_outfile_types       = [];
    $required_outdirs             = 0;
    $required_opt_refs            = [];
    $required_relationships       = []; #Array of arrays: [[id1,id2,'1:M'],...]
    $accepts_hash                 = {}; #A hash of array of scalars
    $primary_infile_type          = undef;
    $exp_nonprimary_inf_types     = {};
    $flagless_multival_type       = undef;
    $usage_array                  = [];
    $usage_lookup                 = {};
    $infile_flag_array            = []; #[file type index] = primary flag
    $suffix_flag_array            = []; #[suffix id] = primary flag
    $outdir_flag_array            = []; #[dir type index] = primary flag
    $general_flag_hash            = {}; #{variable reference} = primary flag
    $suffix_id_lookup             = []; #[suffix_id] = [file_type_index,
                                        #               suffix_index]
    $suffix_primary_vals          = []; #Like the outfile_suffix_array, only
                                        #primary values for suffixes. Internal
                                        #use only
    $file_set_num                 = undef;
    $max_set_num                  = undef;
    $unproc_file_warn             = 1;
    $file_returned_before         = {};
    $auto_file_iterate            = 1;  #0=false,non-0=true. See nextFileCombo
    $command_line_processed       = 0;
    $processCommandLine_called    = 0;
    $usage_file_indexes           = [];
    $outfile_types_hash           = {};
    $outfile_tagteams             = {}; #id=>{SUFFID/OUTFID/PRIMARY/REQUIRED...
    $tagteam_to_supplied_oid      = {};
    $collid_modes_array           = [];
    $outfile_mode_lookup          = {};
    $default_infile_added         = 0;
    $default_outfile_added        = 0;
    $default_outfile_suffix_added = 0;
    $default_outdir_added         = 0;
    $default_tagteam_added        = 0;
    $default_infile_opt           = 'i|infile=s';
    $default_outfile_suffix_opt   = 'o|suffix=s';
    $default_outfile_opt          = 'outfile=s';
    $default_outdir_opt           = 'outdir=s';
    $default_outfile_id           = undef;
    $default_outfile_suffix_id    = undef;
    $file_group_num               = [];
    $explicit_quit                = 0;
    $cleanup_mode                 = 0;
    $flag_check_hash              = {};
    $default_run_mode             = 'usage'; #usage,run,help,dry-run
    $outdirs_added                = 0;
    $inf_to_usage_hash            = {};
    $outf_to_usage_hash           = {};
    $genopt_types                 = {'bool'    => '',   #val is appended to key
				     'negbool' => '!',
				     'count'   => ':+',
				     'string'  => '=s',
				     'integer' => '=i',
				     'float'   => '=f',
				     'enum'    => '=s',
				     'string_array'    => '=s',
				     'integer_array'   => '=s',
				     'float_array'     => '=s',
				     'enum_array'      => '=s',
				     'string_array2d'  => '=s',
				     'integer_array2d' => '=s',
				     'float_array2d'   => '=s',
				     'enum_array2d'    => '=s'};
    $fileopt_types                = {'infile'  => '=s',
				     'outfile' => '=s',
				     'stub'    => '=s',
				     'outdir'  => '=s',
				     'suffix'  => '=s'};

    $def_collide_mode_suff = 'error';  #Use these 2 defaults for mode for
    $def_collide_mode_outf = 'merge';  #outfile option types' collide mode

    $stderr_buffer         = undef;
    $verbose_freq_hash     = undef;
    $last_verbose_size     = undef;
    $last_verbose_state    = undef;
    $verbose_warning       = undef;
    $error_number          = undef;
    $error_hash            = undef;
    $warning_number        = undef;
    $warning_hash          = undef;
    $infile_line_buffer    = undef;
    $debug_number          = undef;
    $time_marks            = undef;
    $open_out_handles      = undef;
    $rejected_out_handles  = undef;
    $closed_out_handles    = undef;
    $open_in_handles       = undef;
    $header_str            = undef;
    $explicit_dry_run      = undef;
    $explicit_run          = undef;
    $explicit_help         = undef;
    $explicit_usage        = undef;
    $window_width          = undef;
    $window_width_def      = 80;
    $pipe_cache            = undef;
    $lsof_cache            = undef;
  }

sub setScriptInfo
  {
    my @params   = qw(VERSION HELP CREATED AUTHOR CONTACT COMPANY LICENSE
		      DETAIL|DETAILED_HELP);
    my $check    = {map {$_ => 1} @params};
    my @in       = getSubParams([@params],[],[@_],1);
    my %infohash = map {$params[$_] => $in[$_]} 0..$#in;

    if($command_line_processed && ($help || $version))
      {
	error("You cannot set the script information (i.e. call ",
	      "setScriptInfo()) after the command line has already been ",
	      "processed (i.e. processCommandLine()) without at least ",
	      "re-initializing (i.e. calling _init()) because --help or ",
	      "--version flags which return the information set by this ",
	      "method have already been acted on during the processing ",
	      "of the default options.  Call setScriptInfo before doing any ",
	      "file processing.");
	return(undef);
      }

    debug({LEVEL => -1},"Keys passed in: [",join(',',keys(%infohash)),"].");

    my @invalid = grep {!exists($check->{$_})} keys(%infohash);

    if(scalar(@invalid) > 0)
      {
	%infohash = map {$_ => $infohash{$_}} grep {exists($check->{$_})}
	  keys(%infohash);

	warning("Invalid keys passed in: [",join(',',@invalid),"].");
      }

    $script_version_number = $infohash{VERSION};
    $help_summary          = $infohash{HELP};
    $created_on_date       = $infohash{CREATED};
    $script_author         = $infohash{AUTHOR};
    $script_contact        = $infohash{CONTACT};
    $script_company        = $infohash{COMPANY};
    $script_license        = $infohash{LICENSE};
    $advanced_help         = $infohash{'DETAIL|DETAILED_HELP'};

    $script_version_number =~ s/^\n+// if(defined($script_version_number));
    $help_summary          =~ s/^\n+// if(defined($help_summary));
    $created_on_date       =~ s/^\n+// if(defined($created_on_date));
    $script_author         =~ s/^\n+// if(defined($script_author));
    $script_contact        =~ s/^\n+// if(defined($script_contact));
    $script_company        =~ s/^\n+// if(defined($script_company));
    $script_license        =~ s/^\n+// if(defined($script_license));
    $advanced_help         =~ s/^\n+// if(defined($advanced_help));
  }

sub getRelationStr
  {
    #NOTE: Requirement 140 needs to be implemented to properyly support M:M
    my $instr = $_[0]; #'1','1:1','1:M','1:1orM'
    my $default  = undef;
    if(scalar(@_) != 1)
      {
	if(scalar(@_))
	  {warning('Expected 1 parameter.  Got [',scalar(@_),'].')}
	else
	  {
	    error('Expected 1 parameter.  Got [',scalar(@_),'].  ',
		  "Returning default: [",
		  (defined($default) ? $default : 'undef'),"].");
	    return($default);
	  }
      }
    if(!defined($instr))
      {return($default)}
    elsif(ref($instr) ne '')
      {
	error('Expected a scalar.  Got [',ref($instr),'].  ',
	      "Returning default: [",
		  (defined($default) ? $default : 'undef'),"].");
	return($default);
      }

    if($instr eq '')
      {return($default)}
    elsif($instr =~ /^(1|one)[\s\-_]?(:|to)[\s\-_]?(1|one)$/i)
      {return('1:1')}
    elsif($instr =~ /^(1|one)[\s\-_]?(:|to)[\s\-_]?(m|n|many)$/i)
      {return('1:M')}
#TODO: Requirement 140 needs to be implemented to properyly support M:M
#    elsif($instr =~ /^(m|n|many)[\s\-_]?(:|to)[\s\-_]?(m|n|many)$/i)
#      {return('M:M')}
    elsif($instr =~ /^(1|one)[\s\-_]?(:|to)[\s\-_]?(1|one)
		     [\s\-_]?(or|\|)[\s\-_]?(m|n|many)$/ix)
      {return('1:1orM')}
    elsif($instr =~ /^(\d+|one)$/i)
      {
	my $val = $1;
	$val = 1 if($val =~ /\D/);
	return($val);
      }

    error('Invalid relation string: [',$instr,"].  Valid values are: ['1',",
	  "'1:1','1:M','1:1orM'].  Returning default: [",
	  (defined($default) ? $default : 'undef'),"].");
    return($default);
  }

#Might add the ability to indicate what file types must have the same number of
#input files
#Returns a file type ID to be used in addOutfileSuffixOption
#Globals used: $inf_to_usage_hash (and others)
sub addInfileOption
  {
    my @in = getSubParams([qw(FLAG|GETOPTKEY REQUIRED DEFAULT PRIMARY HIDDEN
			      SMRY|SMRY_DESC|SHORT_DESC
			      DETAIL|DETAIL_DESC|LONG_DESC FORMAT|FORMAT_DESC
			      PAIR_WITH PAIR_RELAT FLAGLESS ADVANCED)],
			  [scalar(@_) ? qw(FLAG|GETOPTKEY) : ()],
			  [@_]);
    my $get_opt_str = $in[0]; #e.g. 'i|infile=s'
    my $required    = $in[1]; #Is file required?: 0 (false) or non-zero (true)
    my $default     = $in[2]; #String, ref to a 1D or 2D array of strings/globs
    my $primary     = $in[3]; #0 or non-0: true = flag optional & accepts pipe
    my $hidden      = $in[4]; #0 or non-0. Non-0 requires a default or to be a
                              #primary option (i.e. takes input on STDIN).
                              #Excludes from usage output.
    my $smry_desc   = $in[5]; #e.g. 'Input file(s).  See --help for format.'
                              #Empty/undefined = exclude from short usage
    my $detail_desc = $in[6]; #e.g. 'Input file(s).  Space separated, globs...'
    my $format_desc = $in[7]; #e.g. 'Tab delimited text w/ columns: 1. Name...'
    my $req_with    = $in[8]; #File type ID (as returned by this sub)
    my $req_rel_str = getRelationStr($in[9]); #e.g. 1,1:1,1:M,1:1orM
    my $flagless    = $in[10];#Whether the option can be supplied sans flag
    my $advanced    = $in[11];#Advanced options print when extended >= 2

    #Trim leading & trailing hard returns and white space characters (from
    #using '<<')
    $smry_desc   =~ s/^\s+//s if(defined($smry_desc));
    $smry_desc   =~ s/\s+$//s if(defined($smry_desc));
    $detail_desc =~ s/^\s+//s if(defined($detail_desc));
    $detail_desc =~ s/\s+$//s if(defined($detail_desc));
    $format_desc =~ s/^\s+//s if(defined($format_desc));
    $format_desc =~ s/\s+$//s if(defined($format_desc));

    if($command_line_processed)
      {
	error("You cannot add command line options (i.e. call ",
	      "addInfileOption()) after the command line has already been ",
	      "processed (i.e. processCommandLine()) without at least ",
	      "re-initializing (i.e. calling _init()).");
	return(undef);
      }

    #Defaults mode - Only call with no params once.
    my $adding_default = (scalar(@in) == 0);
    if($adding_default)
      {
	if($default_infile_added)
	  {
	    error('The default input file type has already been added.');
	    return(undef);
	  }

	debug({LEVEL => -1},'Setting default values for addInfileOption.');

	$get_opt_str = removeDupeFlags($default_infile_opt);
	if(!defined($get_opt_str) || $get_opt_str eq '')
	  {
	    error('Unable to add default input file type ',
		  "[$default_infile_opt] due to redundant flags: [",
		  join(',',getDupeFlags($default_infile_opt)),'].');
	    $default_infile_opt = $get_opt_str;
	    return(undef);
	  }
	$default_infile_opt = $get_opt_str;

	$default_infile_added = 1;
	$required    = 0;
	$primary     = 1;
	#The descriptions are added below
      }

    #Allow the flag to be an array of scalars and turn it into a get opt str
    my $save_getoptstr = $get_opt_str;
    $get_opt_str = makeGetOptKey($get_opt_str,'infile',1,'addInfileOption');

    if(defined($get_opt_str))
      {$get_opt_str = fixStringOpt($get_opt_str)}

    if(!isGetOptStrValid($get_opt_str,'infile'))
      {
	if($adding_default)
	  {warning("Unable to add default input file option.")}
	else
	  {
	    error("Invalid GetOpt parameter flag definition: ",
		  "[$save_getoptstr] for infile type.");
	    quit(-5);
	  }
	return(undef);
      }

    if(defined($required) && $required !~ /^\d+$/)
      {error("Invalid required parameter: [$required].")}

    if(defined($req_with))
      {
	my $uhash = getInfileUsageHash($req_with);
	if(!defined($uhash) || !exists($uhash->{OPTTYPE}))
	  {error("Invalid PAIR_WITH input file ID: [$req_with].  Must be an ",
		 "ID returned by addInfileOption.")}
	#TODO: Requirement 280 will allow linking to either input or output
	#      file types
	elsif($uhash->{OPTTYPE} ne 'infile')
	  {error("File type ID passed in using the PAIR_WITH parameter must ",
		 "be an input file type ID.  Instead, received an ID of ",
		 "type: [$uhash->{OPTTYPE}].")}
      }

    my $flags = [getOptStrFlags($get_opt_str)];
    my $flag  = getDefaultFlag($flags);

    #If hidden is not defined and there is a linked file, default to the hidden
    #state of the file type this is linked to, otherwise 0.
    if(!defined($hidden) && defined($req_with))
      {
	if(defined($req_with) && isFileTypeHidden($req_with))
	  {$hidden = 1}
	else
	  {$hidden = 0}
      }
    elsif(!defined($hidden))
      {$hidden = 0}
    elsif(!$hidden && defined($req_with))
      {
	#Error if this option is set to be visible and it is linked to a hidden
	#file that has no default and is not primary
	if(isFileTypeHidden($req_with) && !isFileTypeDefaulted($req_with) &&
	   !isFileTypePrimary($req_with))
	  {
	    error("Input file option [$flag] cannot be visible when its ",
		  "PAIR_WITH linked file [",getInfileFlag($req_with,2),"] is ",
		  "hidden, has no default value, and is not primary.",
		  {DETAIL =>
		   join('',("A linked file (e.g. [",getInfileFlag($req_with,2),
			    "]) is required to be supplied if [$flag] is ",
			    "supplied, but since the linked file type is ",
			    "hidden, there's no way to tell the user of the ",
			    "required file type that may be missing, thus if ",
			    "a file type is hidden, any file type linked to ",
			    "it must also be hidden and thereby revealed ",
			    "together when viewing hidden options."))});
	    $hidden = 1;
	  }
      }

    my $file_type_index = scalar(@$input_files_array);
    push(@$input_files_array,[]);

    if(!defined($primary))
      {$primary = 0}
    elsif(!$primary)
      {$exp_nonprimary_inf_types->{$file_type_index} = 0}

    if($hidden && !defined($default) && !$primary &&
       defined($required) && $required)
      {
	warning("Cannot hide option [$flag] if",

		(!defined($default) ? ' no default provided' : ''),

		(!defined($default) && !$primary ? ' or' : ''),

		(!$primary ?
		 " it does't take standard input (i.e. it's not a primary " .
		 'infile option)' : ''),

		((!defined($default) && defined($required) && $required) ?
		 (!defined($default) && !$primary ? ', and if' : ' and if') :
		 ''),

		(defined($required) && $required ? ' it is required' : ''),
		".  Setting as not hidden.");

	$hidden = 0;
      }

    my $default_str = '';

    #Add the default(s) to the default infiles array, to be globbed when the
    #command line is processed
    if(defined($default))
      {
	my($twodarray);
	($twodarray,$default_str) = makeCheck2DScalarArray($default);
	if(defined($twodarray))
	  {$default_infiles_array->[$file_type_index] = $twodarray}
	else
	  {quit(-2)}
      }

    $infile_flag_array->[$file_type_index] = $flag;

    #Only set default if not defined and (detail desc not defined or required)
    if((!defined($smry_desc) || $smry_desc eq '') &&
       (!defined($detail_desc) || $required))
      {$smry_desc = 'Input file(s).'}

    if(!defined($detail_desc) || $detail_desc eq '')
      {$detail_desc =
	 join('',('Input file(s)',
		  ($file_type_index ? " type " . ($file_type_index + 1) : ''),
		  ".",(defined($format_desc) && $format_desc ne '' ?
		       '  See --help for file format.' : '')))}
    #If the description doesn't reference the help flag for the file format and
    #a file format was provided, add a reference to it
    elsif($detail_desc !~ /--help/ && defined($format_desc) &&
	  $format_desc ne '')
      {$detail_desc .= "\n\nSee --help for file format."}

    my $getoptsub = 'sub {push(@{$input_files_array->[' . $file_type_index .
      ']},[sglob($_[1])])}';
    $GetOptHash->{$get_opt_str} = eval($getoptsub);

    if($default_str ne '')
      {
	#If the default value is simple, clean up its display
	if($default_str !~ /\)\(/)
	  {
	    $default_str =~ s/^\(\(//;
	    $default_str =~ s/\)\)$//;
	  }
      }

    if($primary)
      {
	if(defined($primary_infile_type))
	  {
	    error("Multiple primary input file options supplied ",
		  "[$get_opt_str].  Only 1 is allowed.");
	    return(undef);
	  }

	$primary_infile_type = $file_type_index;
      }

    if(defined($flagless) && $flagless)
      {
	if(defined($flagless_multival_type) && $flagless_multival_type > -1)
	  {
	    error("An additional multi-value option has been designated as ",
		  "'flagless': [$get_opt_str]: [$flagless].  Only 1 is ",
		  "allowed.",
		  {DETAIL => "First flagless option was: [" .
		   getDefaultFlag($usage_array->[$flagless_multival_type]
				  ->{OPTFLAG}) . "]."});
	    return(undef);
	  }

	$getoptsub = 'sub {checkFileOpt($_[0],1);push(@{$input_files_array->['.
	  $file_type_index . ']},[sglob($_[0])])}';
	$GetOptHash->{'<>'} = eval($getoptsub);

	#This assumes that the call to addToUsage a few lines below is the
	#immediate next call to addToUsage
	$flagless_multival_type = getNextUsageIndex();
      }

    if($required)
      {push(@$required_infile_types,$file_type_index)}

    addRequiredRelationship($file_type_index,$req_with,$req_rel_str);

    push(@$usage_file_indexes,
	 addToUsage($get_opt_str,$flags,$smry_desc,$detail_desc,$required,
		    $default_str,undef,$hidden,'infile',$flagless,$advanced,
		    undef,undef,$primary,$format_desc,$file_type_index));

    debug({LEVEL => -1},"Adding input file type [$file_type_index] as a key ",
	  "to inf_to_usage_hash, value: [$#{$usage_array}].");
    #TODO: This will change with requirement 280
    $inf_to_usage_hash->{$file_type_index} = $#{$usage_array};

    return($file_type_index);
  }

#Given an input file type ID, returns the usage hash for the file type
#Globals used: $inf_to_usage_hash
sub getInfileUsageHash
  {
    my $file_type_id = $_[0];
    if(defined($file_type_id) && exists($inf_to_usage_hash->{$file_type_id}) &&
       scalar(@$usage_array) > $inf_to_usage_hash->{$file_type_id} &&
       $inf_to_usage_hash->{$file_type_id} > -1)
      {return($usage_array->[$inf_to_usage_hash->{$file_type_id}])}
    debug({LEVEL => -1},"File type: [",
	  (defined($file_type_id) ? $file_type_id : 'undef'),
	  "] inf_to_usage_hash key [",
	  (defined($file_type_id) &&
	   exists($inf_to_usage_hash->{$file_type_id}) ?
	   'exists' : 'does not exist'),
	  "] usage index less than usage_array size: [",
	  (defined($file_type_id) &&
	   defined($inf_to_usage_hash->{$file_type_id}) &&
	   scalar(@$usage_array) > $inf_to_usage_hash->{$file_type_id} ?
	   'yes' : 'no'),"] usage index greater than -1: [",
	  (defined($file_type_id) &&
	   defined($inf_to_usage_hash->{$file_type_id}) &&
	   $inf_to_usage_hash->{$file_type_id} > -1 ? 'yes' : 'no'),"].");
    error('Invalid input file type ID: [',
	  (defined($file_type_id) ? $file_type_id : 'undef'),
	  '].  Must be an ID as returned by addInfileOption.');
    return(undef);
  }

#Given an output file suffix ID, returns the usage hash for the file type
#defined *by the programmer*.  That is to say, a usage entry exists for both
#the outfile index and the suffix index.  The usage for the one that
#corresponds to the original function called is the one that is returned (i.e.
#if the programmer called addOutfileOption, the 'outfile' usage is returned and
#if the programmer called addOutfileSuffixOption, the 'suffix' usage is
#returned).  This is significant because addOutfileOption calls
#addOutfileSuffixOption.
#Globals used: $outf_to_usage_hash
sub getOutfileUsageHash
  {
    my $suffix_id = $_[0];
    if(defined($suffix_id) && exists($outf_to_usage_hash->{$suffix_id}) &&
       scalar(@$usage_array) > $outf_to_usage_hash->{$suffix_id} &&
       $outf_to_usage_hash->{$suffix_id} > -1)
      {return($usage_array->[$outf_to_usage_hash->{$suffix_id}])}
    error('Invalid suffix ID: [',
	  (defined($suffix_id) ? $suffix_id : 'undef'),'].');
    return(undef);
  }

sub getOutdirUsageHash
  {
    ##TODO: The outdir options need to be fixed. See requirement 178
    my $oduh = undef;
    foreach my $uh (@$usage_array)
      {
	if($uh->{OPTTYPE} eq 'outdir')
	  {
	    if(defined($oduh))
	      {outdirLimitation(0)}
	    $oduh = $uh;
	  }
      }
    return($oduh);
  }

sub fixStringOpt
  {
    my $get_opt_str = $_[0];
    my $force_fix   = defined($_[1]) ? $_[1] : 0;

    if(!defined($get_opt_str) || $get_opt_str eq '')
      {debug({LEVEL => -1},"Unable to fix option string: [",
	     (defined($get_opt_str) ? $get_opt_str : 'undef'),"].")}
    else
      {
	#Remove any leading dashes
	$get_opt_str =~ s/^-+//;

	#If the option specification is just missing the string type, add it
	if(defined($get_opt_str) && $get_opt_str ne '' &&
	   $get_opt_str !~ /[=+:\@\%!]/)
	  {$get_opt_str .= '=s'}
	elsif(defined($get_opt_str) && $get_opt_str ne '' && $force_fix &&
	      $get_opt_str !~ /=s$/)
	  {
	    $get_opt_str =~ s/[=+:\@\%!].*//;
	    $get_opt_str .= '=s';
	  }
      }

    return($get_opt_str);
  }

#Globals used: $genopt_types, $fileopt_types
sub makeGetOptKey
  {
    my $get_opt_str = $_[0];
    my $type        = $_[1]; #Does not remove trailing flag type str if undef
    my $local_quiet = defined($_[2]) ? $_[2] : 0;
    my $calling_sub = $_[3];

    my %types = %$genopt_types;
    if(defined($type) && scalar(grep {$type eq $_} %$fileopt_types))
      {%types = %$fileopt_types}

    if(defined($get_opt_str))
      {
	if(ref($get_opt_str) eq 'ARRAY')
	  {
	    if(scalar(grep {ref($_) ne ''} @$get_opt_str))
	      {
		error("FLAG supplied to $calling_sub must be either a scalar ",
		      "or a reference to an array of scalars, but an array ",
		      "containing [",join("','",map {ref($_)}
					  grep {ref($_) ne ''} @$get_opt_str),
		      "] was supplied.")
		  unless($local_quiet > 1);
		quit(-100);
	      }
	    if(scalar(grep {defined($_) && /[=+:\@\%!].*/} @$get_opt_str))
	      {
		error("FLAG array supplied to $calling_sub [",
		      join(',',grep {defined($_)} @$get_opt_str),
		      "] must not contain type information.",
		      {DETAIL => ('Must not contain the following ' .
				  'characters: [=+:\@\%!].')})
		  unless($local_quiet > 1);
		return(undef);
	      }
	    elsif(scalar(grep {!defined($_)} @$get_opt_str))
	      {
		error("FLAG array supplied to $calling_sub [",
		      join(',',map {defined($_) ? $_ : 'undef'} @$get_opt_str),
		      "] must not contain undefined values.",
		      {DETAIL => ('Must not contain the following ' .
				  'characters: [=+:\@\%!].')})
		  unless($local_quiet > 1);
		quit(-101);
	      }
	    $get_opt_str = join('|',@$get_opt_str);
	  }
	elsif(ref($get_opt_str) eq '')
	  {
	    #Assume flags are to be separated by "invalid characters, like
	    #commas, spaces, etc. if the flags contain unacceptable characters
	    if($get_opt_str !~ /\|/ &&
	       $get_opt_str =~ /[^a-zA-Z0-9\-_\?=+:\@\%!]/)
	      {$get_opt_str = join('|',split(/[^a-zA-Z0-9\-_\?=+:\@\%!]+/,
					     $get_opt_str))}
	  }
	else
	  {
	    error("FLAG supplied to $calling_sub must be either a scalar ",
		  "or a reference to an array of scalars, but [",
		  ref($get_opt_str),"] was supplied.")
	      unless($local_quiet > 1);
	    return(undef);
	  }
      }

    if(defined($type) && scalar(grep {$type eq $_} keys(%types)) == 0)
      {
	error("Invalid type: [$type] for [$calling_sub].",
	      {DETAIL => 'Must be one of [' . join(',',keys(%types)) . '].'})
	  unless($local_quiet > 1);
	return(undef);
      }

    if(!defined($get_opt_str) || $get_opt_str eq '')
      {
	debug({LEVEL => -1},"Unable to fix option string: [",
	      (defined($get_opt_str) ? $get_opt_str : 'undef'),"].");
	return(undef);
      }

    if(defined($type))
      {
	if(!$local_quiet && $get_opt_str =~ /([=+:\@\%!].*)/)
	  {warning("FLAG string [$get_opt_str] contains type information ",
		   "[$1], but a TYPE [$type] was also supplied.  Setting ",
		   "type information to [$types{$type}].")}

	if($get_opt_str =~ /[=+:\@\%!]/)
	  {
	    if(($type eq 'suffix'          && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'infile'          && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'outfile'         && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'outdir'          && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'stub'            && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'bool'                                     ) ||
	       ($type eq 'negbool'         && $get_opt_str !~ /!$/  ) ||
	       ($type eq 'string'          && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'float'           && $get_opt_str !~ /=f$/ ) ||
	       ($type eq 'enum'            && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'count'           && $get_opt_str !~ /:\+$/) ||
	       ($type eq 'integer'         && $get_opt_str !~ /=i$/ ) ||
	       ($type eq 'float'           && $get_opt_str !~ /=f$/ ) ||
	       ($type eq 'string_array'    && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'float_array'     && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'enum_array'      && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'integer_array'   && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'string_array2d'  && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'float_array2d'   && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'enum_array2d'    && $get_opt_str !~ /=s$/ ) ||
	       ($type eq 'integer_array2d' && $get_opt_str !~ /=s$/ )    )
	      {warning("Invalid flag definition: [$get_opt_str] for type ",
		       "[$type] in [$calling_sub].")}
	  }

	#Remove anything following the flags
	$get_opt_str =~ s/[=+:\@\%!].*//;

	$get_opt_str .= $types{$type};
      }

    #Remove any leading dashes
    $get_opt_str =~ s/^-+//;

    return($get_opt_str);
  }

#Globals used: $genopt_types, $fileopt_types
#If undef is returned, the type is assumed to be set in the FLAG string
sub getOptType
  {
    my $type_str    = $_[0];
    my $get_opt_str = $_[1];
    my $accepts     = $_[2]; #Only used for assuming enum type
    my $get_opt_ref = $_[3]; #Only used to change bool to negbool if true
    my %types       = (%$genopt_types,%$fileopt_types);

    if(defined($type_str) && scalar(grep {$type_str eq $_} keys(%types)) == 0)
      {error("Invalid type: [$type_str].")}
    elsif(defined($type_str) && scalar(grep {$type_str eq $_} keys(%types)))
      {
	if($type_str eq 'enum' &&
	   (!defined($accepts) || ref($accepts) ne 'ARRAY' ||
	    scalar(@$accepts) == 0 || scalar(grep {ref($_) ne ''} @$accepts)))
	  {
	    error("TYPE enum requires a valid ACCEPTS value.",
		  {DETAIL => ('ACCEPTS must be a reference to an array of ' .
			      "scalars.  [" .
			      (!defined($accepts) ? 'nothing' :
			       (ref($accepts) ne 'ARRAY' ?
				(ref($accepts) eq '' ?
				 'a SCALAR' : 'a reference to (' .
				 ref($accepts) . ')') :
				(scalar(@$accepts) ?
				 'a reference to an array of (' .
				 join(',',map {ref($_) eq '' ?
						 'SCALAR' : ref($_)}
				      @$accepts) . ')' :
				 'a reference to an empty array'))) .
			      "] was passed in.")});
	    quit(-95);
	  }

	#If the user defined this as a bool, but set the default value to true,
	#assume they actually want a negbool
	if($type_str eq 'bool' && ref($get_opt_ref) eq 'SCALAR' &&
	   defined($$get_opt_ref) && $$get_opt_ref)
	  {
	    warning("Initial value of a [bool] should evaluate to false.  ",
		    "Changing type of [",
		    getDefaultFlag(scalar(getOptStrFlags($get_opt_str))),
		    "] to [negbool].");
	    $type_str = 'negbool';
	  }

	return($type_str);
      }

    #If the type is not defined in the get opt key, default to 'string'
    if($get_opt_str !~ /[=+:\@\%!].*/)
      {return('string')}

    return(undef);
  }

#This sub is a helper to addInfileOption specifically.  The error wordings are
#specific to that sub.
#Takes a string, reference to an array of strings, or a reference to an array
#of references to arrays of strings.  Ensures dimensionality is consistent.  If
#a string is provided, it puts it as the first element of the first array of an
#array.  If a 1D array is provided, it puts it as the first array of an array.
#Ensures that there are no undefined values and that there are no empty arrays
#or empty strings.
#Copies the array sent in.
#Returns a copy of the conformed array and a string version of the array
sub makeCheck2DScalarArray
  {
    my $inarray = copyArray($_[0]);

    #If the array is not defined
    if(!defined($inarray))
      {
	error("Undefined default input file encountered.");
	return(undef,'');
      }
    #If it's a scalar, but an empty string
    elsif(ref(\$inarray) eq 'SCALAR' && $inarray eq '')
      {
	error("Default input file defined as empty string.");
	return(undef,'');
      }
    #If it's just a valid scalar value
    elsif(ref(\$inarray) eq 'SCALAR' && $inarray ne '')
      {return([[$inarray]],"(($inarray))")}

    #If it's a valid 1D array
    elsif(ref($inarray) eq 'ARRAY' && scalar(@$inarray) &&
	  scalar(@$inarray) ==
	  scalar(grep {defined($_) && ref(\$_) eq 'SCALAR' && $_ ne ''}
		 @$inarray))
      {return([$inarray],'((' . join(',',@$inarray) . '))')}
    #If it's an empty 1D array, silently return undef
    elsif(ref($inarray) eq 'ARRAY' && scalar(@$inarray) == 0)
      {return(undef,'')}
    #If it's an invalid 1D array containing undefined values
    elsif(ref($inarray) eq 'ARRAY' && scalar(grep {!defined($_)} @$inarray))
      {
	error("Undefined default input file in a 1D array encountered.");
	return(undef,'');
      }
    #If it's an invalid 1D array containing empty strings
    elsif(ref($inarray) eq 'ARRAY' && scalar(grep {$_ eq ''} @$inarray))
      {
	error("Default input file defined as empty string in a 1D array.");
	return(undef,'');
      }
    #If it's an invalid 1D array containing a mix of strings and something else
    elsif(ref($inarray) eq 'ARRAY' &&
	  scalar(grep {ref(\$_) eq 'SCALAR'} @$inarray) &&
	  scalar(grep {ref(\$_) ne 'SCALAR'} @$inarray))
      {
	error("File strings in a 1D array mixed with non-scalar values.");
	return(undef,'');
      }

    #If it's a valid 2D array
    elsif(ref($inarray) eq 'ARRAY' && scalar(@$inarray) &&
	  scalar(@$inarray) ==
	  scalar(grep {defined($_) && ref($_) eq 'ARRAY' && scalar(@$_)}
		 @$inarray) &&
	  scalar(@$inarray) ==
	  scalar(grep {my $a=$_;scalar(@$a) && scalar(@$a) ==
			 scalar(grep {defined($_) && ref(\$_) eq 'SCALAR' &&
					$_ ne ''}
				@$a)} @$inarray))
      {return($inarray,'((' . join(')(',map {join(',',@$_)} @$inarray) . '))')}

    error("Invalid 2D array of non-empty file strings encountered.  All ",
	  "inner arrays must be defined and contain 1 or more non-empty ",
	  "strings of globs/file names.");

    return(undef,'');
  }

#This method will add a relationship between file types to the
#required_relationships array.
#Globals used: $primary_infile_type,$input_files_array,$required_relationships
sub addRequiredRelationship
  {
    my $file_type1   = $_[0]; #The file type being added
    my $file_type2   = $_[1]; #A file type that should have already been added
    my $relationship = $_[2]; #String matching: '1','1:1','1:M','1:1orM'

    ##
    ## Input validation
    ##

    #Enforce required params and fill in defaults
    if(!defined($file_type1))
      {
	error("First parameter (file type being added) is required.");
	return();
      }
    #Silently return if the last 2 params are not defined/empty
    elsif((!defined($file_type2)   || $file_type2 eq '') &&
	  (!defined($relationship) || $relationship eq ''))
      {return()}
    elsif(!defined($file_type2) || $file_type2 eq '')
      {
	my $def_prim_inf_type = getDefaultPrimaryInfileID();
	#If the paired file type doesn't matter, set it to the first file type,
	#even if it is with itself
	if($relationship =~ /^\d+$/ && defined($def_prim_inf_type))
	  {$file_type2 = $def_prim_inf_type}
	elsif(!defined($primary_infile_type))
	  {
	    error("No PAIR_WITH file type was provided and no primary input ",
		  "file type has yet been added.  Please supply ",
		  "addInfileOption with a previously added file type ID ",
		  "using the PAIR_WITH option or remove the ",
		  "PAIR_RELAT option.");
	    quit(-3);
	  }
	elsif($primary_infile_type == $file_type1)
	  {
	    error("No PAIR_WITH file type was provided and the default ",
		  "primary input file type is what is being added.  Please ",
		  "supply addInfileOption with a previously added file type ",
		  "ID using the PAIR_WITH option.  ");
	    quit(-4);
	  }
	else
	  {
	    warning("Setting primary input file type to establish ",
		    "relationship: [$relationship] with another file type ",
		    "that is dependent on it because the file type ID was ",
		    "not supplied.",
		    {DETAIL =>
		     join('',('Usually, this happens when an outfile suffix ',
			      'is defined either by addOutfileSuffixOption ',
			      'or addOutfileTagteamOption without FILETYPEID ',
			      'or PAIR_WITH being defined, though other ',
			      'dependant options can also cause this ',
			      'warning.  If there is only 1 input file type ',
			      'or one input file type has been set as ',
			      'primary, it is set here automatically with ',
			      'this warning.'))});
	    $file_type2 = $primary_infile_type;
	  }
      }
    elsif(!defined($relationship) || $relationship eq '')
      {$relationship = '1:1orM'}

    #Make sure the first file type ID is an unsigned integer
    if($file_type1 !~ /^\d+$/)
      {
	error('Invalid file type 1 ID (first parameter): [',$file_type1,']');
	return();
      }

    #If the relationship is '1' (only 1 file allowed regardless of any input
    #file type), set the file type 2 to undefined
    if($relationship eq '1')
      {undef($file_type2)}
    #Make sure the second file type ID is an unsigned integer
    elsif($file_type2 !~ /^\d+$/)
      {
	error('Invalid file type 2 ID (second parameter): [',$file_type2,']');
	return();
      }
    #Make sure the second file type ID pre-exists
    elsif($file_type2 >= scalar(@$input_files_array) ||
	  $file_type1 == $file_type2)
      {
	error('Second file type ID supplied (second parameter): ',
	      "[$file_type2] does not exist or is a duplicate.  The ",
	      'PAIR_WITH option can only take file type IDs which have been ',
	      'previously added using addInfileOption or addOutfileOption.');
	return();
      }

    ##
    ## Add the relationship
    ##

    push(@$required_relationships,[$file_type1,$file_type2,$relationship]);
  }

#Checks strings for 7 types of params: infile, outfile, suffix, outdir,
#general, 1darray, and 2darray
sub isGetOptStrValid
  {
    my $get_opt_str = $_[0];
    my $type        = $_[1];
    my $allow_dupes = defined($_[2]) ? $_[2] : 0;
    my $answer      = 1;

    if(!defined($get_opt_str))
      {
	error("Invalid option flag definition: [undef].");
	return(0);
      }

    my @existing = getDupeFlags($get_opt_str);
    if(scalar(@existing))
      {
	if(!$allow_dupes)
	  {
	    error("Duplicate flags detected: [",join(',',@existing),"].");
	    debug({LEVEL => -1},"Existing flags: [",
		  join(',',keys(%$GetOptHash)),
		  "]. Adding Flag: [$get_opt_str]");
	    $answer = 0;
	    return($answer);
	  }
	else
	  {debug({LEVEL => -2},
		 "Duplicate flags detected: [",join(',',@existing),
		 "], but allowed.")}
      }

    #General validity checks
    if($get_opt_str !~ /[a-zA-Z0-9!+\@\}\@\%]$/)
      {
	error("Invalid option flag definition: [$get_opt_str].  The flag ",
	      "specification [$get_opt_str] must not be an empty string and ",
	      "end in a letter, number, or one of: [!+\@\}\%].  See the ",
	      "Summary of Option Specifications section of `perldoc Getopt::",
	      "Long` for how to specify the command line option.");
	$answer = 0;
      }

    #Make sure the user has specified a string type
    my $ok = 1;
    if($get_opt_str !~ /=s$/)
      {$ok = 0}

    if($type eq 'infile' || $type eq 'outfile' ||
       $type eq 'suffix' || $type eq 'outdir')
      {
	if(!$ok)
	  {
	    error("In order to split the values the user passes in, the ",
		  "option flag specification must end with '=s'.  ",
		  "[$get_opt_str] was passed in.");
	    $answer = 0;
	  }
      }
    elsif($type eq '1darray' || $type eq '2darray')
      {
	if(!$ok)
	  {
	    error("The option specification: [$get_opt_str] must end with ",
		  "'=s'.",
		  {DETAIL =>
		   join('',
			("In order to split the values, ",
			 "CommandLineInterface requires array options to ",
			 "have the string type passed to GetOpt::Long ",
			 "because it replaces option string with a reference ",
			 "to a subroutine and does not have its own type-",
			 "enforcement (e.g. for integers).  ",
			 "CommandLineInterface's subroutine for array ",
			 "options adds mitigations of some shell-imposed ",
			 "command-line length limitations and can handle 2D ",
			 "arrays (or multiple 1D arrays of the same type).  ",
			 "Thus, you must enforce types in your own code."))});
	    $answer = 0;
	  }
      }
    elsif($type ne 'general')
      {warning("Unknown option type: [$type].  Unable to validate option.")}

    return($answer);
  }

#This method populates and checks flags against the flag_check_hash and
#Returns the specific -f or --flag values that have duplicates
#globals used: $flag_check_hash, $GetOptHash
sub getDupeFlags
  {
    my $get_opt_str = $_[0];

    my @opt_strs = ();
    my $existing = [];
    if(scalar(keys(%$flag_check_hash)) == 0 && scalar(keys(%$GetOptHash)))
      {push(@opt_strs,keys(%$GetOptHash))}

    push(@opt_strs,$get_opt_str);

    debug({LEVEL => -2},"Looking for dupes in: [",
	  join(',',map {defined($_) ? $_ : 'undef'} @opt_strs),"].");

    foreach my $opt_str (@opt_strs)
      {
	my $negatable = ($opt_str =~ /\!$/);

	#Get rid of the flag modifiers, etc.
	$opt_str =~ s/[=:!+].*//;

	#Cycle through the flags (without the dashes)
	foreach my $flag (split(/\|+/,$opt_str))
	  {
	    my $tflag = $flag;

	    if(exists($flag_check_hash->{$flag}))
	      {push(@$existing,(length($flag) == 1 ? "-$flag" : "--$flag"))}

	    $flag_check_hash->{$tflag} = 0;

	    if($negatable)
	      {
		$flag_check_hash->{"no$tflag"}  = 0;
		$flag_check_hash->{"no-$tflag"} = 0;
	      }
	  }
      }

    if(wantarray)
      {return(@$existing)}

    return($existing);
  }

#Globals used: $GetOptHash
sub removeDupeFlags
  {
    my $get_opt_str = $_[0];

    my @opt_strs = ();
    my $hash = {};
    if(scalar(keys(%$GetOptHash)))
      {push(@opt_strs,keys(%$GetOptHash))}
    else
      {return($get_opt_str)}

    foreach my $opt_str (@opt_strs)
      {
	my $negatable = ($opt_str =~ /\!$/);

	#Get rid of the flag modifiers, etc.
	$opt_str =~ s/[=:!+].*//;

	#Cycle through the flags (without the dashes)
	foreach my $flag (split(/\|+/,$opt_str))
	  {
	    my $tflag = $flag;

	    $hash->{$tflag} = 0;

	    if($negatable)
	      {
		$hash->{"no$tflag"}  = 0;
		$hash->{"no-$tflag"} = 0;
	      }
	  }
      }

    #Separate the end of the get opt str from the body
    my $get_opt_str_end = $get_opt_str;
    if($get_opt_str_end =~ /.*([=:!+].*)/)
      {$get_opt_str_end =~ s/.*([=:!+].*)/$1/}
    else
      {$get_opt_str_end = ''}
    my $new_get_opt_str = $get_opt_str;
    $new_get_opt_str =~ s/[=:!+].*//;

    #Determine whether the flag could have "no" or "no-" prepended to it
    my $negatable = ($get_opt_str =~ /\!$/);

    $new_get_opt_str =
      join('|',
	   grep {!exists($hash->{$_}) &&
		   (!$negatable || (!exists($hash->{"no$_"}) &&
				    !exists($hash->{"no-$_"})))}
	   split(/\|/,$new_get_opt_str));

    if($new_get_opt_str eq '')
      {return($new_get_opt_str)}

    $new_get_opt_str .= $get_opt_str_end;

    return($new_get_opt_str);
  }

#This sub does not add new functionality.  It simply adds an infile option, but
#marks it as an outfile in the outfile_types_array.  It also adds a hidden
#outfile_suffix option with a static default value of an empty string.  That
#way, no functionality needs to change with regard to outfile checking.
#Though, there needs to be checks added to the outfile_types_hash to not
#complain about missing input files.
#Globals used: $outf_to_usage_hash
sub addOutfileOption
  {
    my @in = getSubParams([qw(FLAG|GETOPTKEY COLLISIONMODE REQUIRED PRIMARY
			      DEFAULT SMRY|SMRY_DESC|SHORT_DESC
			      DETAIL|DETAIL_DESC|LONG_DESC FORMAT|FORMAT_DESC
			      HIDDEN PAIR_WITH PAIR_RELAT FLAGLESS ADVANCED)],
			  [scalar(@_) ? qw(FLAG|GETOPTKEY) : ()],
			  [@_]);
    my $get_opt_str = $in[0]; #e.g. 'o|outfile=s'
    my $collid_mode = getCollisionMode(undef,'outfile',$in[1]);
    my $required    = $in[2]; #Is file required?: 0 (false) or non-zero (true)
    my $primary     = defined($in[3]) ? $in[3] : 1; #non-0:stdout 0:no output
    my $default     = $in[4]; #e.g. 'my_output_file.txt'
    my $smry_desc   = $in[5]; #e.g. 'Input file(s).  See --help for format.'
                              #Empty/undefined = exclude from short usage
    my $detail_desc = $in[6]; #e.g. 'Input file(s).  Space separated, globs...'
    my $format_desc = $in[7]; #e.g. 'Tab delimited text w/ columns: 1. Name...'
    my $hidden      = $in[8]; #0 or non-0. Requires a default. Excludes from
                              #usage output.
    my $req_with    = $in[9]; #File type ID (as returned by this sub)
    my $req_rel_str = getRelationStr($in[10]); #e.g. 1,1:1,1:M,1:1orM
    my $flagless    = $in[11];#Whether the option can be supplied sans flag
    my $advanced    = $in[12];#Advanced options print when extended >= 2

    #Trim leading & trailing hard returns and white space characters (from
    #using '<<')
    $smry_desc   =~ s/^\s+//s if(defined($smry_desc));
    $smry_desc   =~ s/\s+$//s if(defined($smry_desc));
    $detail_desc =~ s/^\s+//s if(defined($detail_desc));
    $detail_desc =~ s/\s+$//s if(defined($detail_desc));
    $format_desc =~ s/^\s+//s if(defined($format_desc));
    $format_desc =~ s/\s+$//s if(defined($format_desc));

    if($command_line_processed)
      {
	error("You cannot add command line options (i.e. call ",
	      "addOutfileOption()) after the command line has already been ",
	      "processed (i.e. processCommandLine()) without at least ",
	      "re-initializing (i.e. calling _init()).");
	return(undef);
      }

    ##
    ## Create the option associated with a faux entry in the input_files_array
    ##

    #Defaults mode - Only call with no params once.
    my $adding_default = (scalar(@in) == 0);
    if($adding_default)
      {
	if($default_outfile_added)
	  {
	    error('The default output file type has already been added.');
	    return(undef);
	  }

	debug({LEVEL => -1},'Setting default values for addOutfileOption.');

	$get_opt_str = removeDupeFlags($default_outfile_opt);
	if(!defined($get_opt_str) || $get_opt_str eq '')
	  {
	    error('Unable to add default output file type ',
		  "[$default_outfile_opt] due to redundant flags: [",
		  join(',',getDupeFlags($get_opt_str)),'].');
	    $default_outfile_opt = $get_opt_str;
	    return(undef);
	  }
	$default_outfile_opt = $get_opt_str;

	$default_outfile_added = 1;
	$default_outfile_id    = scalar(@$input_files_array);
	#The descriptions are added below

	#If a compatible outfile type exists that we will be tagteamed up with,
	#match it.  (Returns undef if none.)
	$req_with = getDefaultPrimaryLinkedInfileID();

	if(defined($req_with))
	  {$req_rel_str = getRelationStr('1:1orM')}
      }

    #Allow the flag to be an array of scalars and turn it into a get opt str
    my $save_getoptstr = $get_opt_str;
    $get_opt_str = makeGetOptKey($get_opt_str,'outfile',1,'addOutfileOption');

    if(defined($get_opt_str))
      {$get_opt_str = fixStringOpt($get_opt_str)}

    if(!isGetOptStrValid($get_opt_str,'outfile'))
      {
	if($adding_default)
	  {warning("Unable to add default output file option.")}
	else
	  {
	    error("Invalid GetOpt parameter flag definition: ",
		  "[$save_getoptstr] for outfile type.");
	    quit(-73);
	  }
	return(undef);
      }

    if(defined($collid_mode) && $collid_mode ne '' &&
       $collid_mode ne 'error' && $collid_mode ne 'rename' &&
       $collid_mode ne 'merge')
      {error("Invalid COLLISIONMODE parameter: [$collid_mode].  Must be one ",
	     "of ['error','merge','rename'].")}

    if(defined($required) && $required !~ /^\d+$/)
      {error("Invalid REQUIRED parameter: [$required].")}

    if(defined($req_with))
      {
	my $uhash = getInfileUsageHash($req_with);
	if(!defined($uhash))
	  {
	    #getInfileUsageHash should have already issued an error
	    quit(-68);
	  }
	elsif(!exists($uhash->{OPTTYPE}))
	  {error("Invalid PAIR_WITH input file ID: [$req_with].  Must be an ",
		 "ID returned by addInfileOption.")}
	#TODO: Requirement 280 will allow linking to either input or output
	#      file types
	elsif($uhash->{OPTTYPE} ne 'infile')
	  {error("File type ID passed in using the PAIR_WITH parameter must ",
		 "be an input file type ID.  Instead, received an ID of ",
		 "type: [$uhash->{OPTTYPE}].")}
      }

    #If hidden is not defined, default to the hidden state of whatever file
    #type this might be linked to, otherwise 0.
    if(!defined($hidden) && defined($req_with))
      {
	if(isFileTypeHidden($req_with))
	  {$hidden = 1}
	else
	  {$hidden = 0}
      }
    elsif(!defined($hidden))
      {$hidden = 0}

    my $flags = [getOptStrFlags($get_opt_str)];
    my $flag  = getDefaultFlag($flags);

    if(defined($required) && defined($hidden) && $required && $hidden)
      {
	warning('Required options cannot be hidden.  Setting option: [',
		"$flag] as not hidden.");
	$hidden = 0;
      }

    my $file_type_index = scalar(@$input_files_array);
    push(@$input_files_array,[]);
    $outfile_types_hash->{$file_type_index} = 1; #Uses existence 4 type determ.

    my $default_str = '';

    #Add the default(s) to the default infiles array, to be globbed when the
    #command line is processed
    if(defined($default))
      {
	my($twodarray);
	($twodarray,$default_str) = makeCheck2DScalarArray($default);
	if(defined($twodarray))
	  {$default_infiles_array->[$file_type_index] = $twodarray}
	else
	  {quit(-6)}
      }

    $infile_flag_array->[$file_type_index] = $flag;

    #Note, addToUsage won't include if set to empty string
    if(!defined($smry_desc) || $smry_desc eq '')
      {
	if($required)
	  {$smry_desc = 'Output file(s).'}
	elsif(!defined($smry_desc))
	  {$smry_desc = ''}
      }

    if(!defined($detail_desc) || $detail_desc eq '')
      {$detail_desc =
	 join('',('Output file(s)',
		  ($file_type_index ?
		   " " . (defined($req_with) &&
			  !exists($outfile_types_hash->{$req_with}) ?
			  "associated with [" . getInfileFlag($req_with) .
			  "] input file(s)" .
			  (defined($req_rel_str) ?
			   " in a " . getDispRelStr($req_rel_str) .
			   " relationship" : '') :
			  "type " . ($file_type_index + 1)) : ''),
		  '.',(defined($format_desc) && $format_desc ne '' ?
		       '  See --help for file format.' : '')))}
    #If the description doesn't reference the help flag for the file format and
    #a file format was provided, add a reference to it
    elsif($detail_desc !~ /--help/ && defined($format_desc) &&
	  $format_desc ne '')
      {$detail_desc .= "\n\nSee --help for file format."}

    my $getoptsub = 'sub {push(@{$input_files_array->[' . $file_type_index .
      ']},[sglob($_[1])])}';
    $GetOptHash->{$get_opt_str} = eval($getoptsub);

    if($required)
      {push(@$required_outfile_types,$file_type_index)}

    if(defined($flagless) && $flagless)
      {
	if(defined($flagless_multival_type) && $flagless_multival_type > -1)
	  {
	    error("An additional multi-value option has been designated as ",
		  "'flagless': [$get_opt_str]: [$flagless].  Only 1 is ",
		  "allowed.",
		  {DETAIL => "First flagless option was: [" .
		   getDefaultFlag($usage_array->[$flagless_multival_type]
				  ->{OPTFLAG}) . "]."});
	    return(undef);
	  }

	$getoptsub = 'sub {checkFileOpt($_[0],1);push(@{$input_files_array->['.
	  $file_type_index . ']},[sglob($_[0])])}';
	$GetOptHash->{'<>'} = eval($getoptsub);

	#This assumes that the call to addToUsage a few lines below is the
	#immediate next call to addToUsage
	$flagless_multival_type = getNextUsageIndex();
      }

    #If req_with is not defined, this call just returns without doing anything
    addRequiredRelationship($file_type_index,$req_with,$req_rel_str);

    if($default_str eq '' && $primary && !$required)
      {$default_str = 'STDOUT'}
    elsif($default_str ne '')
      {
	#If the default value is simple, clean up its display
	if($default_str !~ /\)\(/)
	  {
	    $default_str =~ s/^\(\(//;
	    $default_str =~ s/\)\)$//;
	  }
      }

    push(@$usage_file_indexes,
	 addToUsage($get_opt_str,$flags,$smry_desc,$detail_desc,$required,
		    $default_str,undef,$hidden,'outfile',$flagless,$advanced,
		    undef,undef,$primary,$format_desc,$file_type_index));

    my $usage_index = $#{$usage_array};

    ##
    ## Create a hidden outfile_suffix_array element for the faux input file
    ##

    my $hidden_opt_str = join('|',
			      (map {if(/[\:\=\+\!]/){
				s/([:=\+\!])/-hidden-suffix$1/;$_}
				    else{$_ .= '-hidden-suffix'}}
			       split(/\|/,$get_opt_str)));
    my $error_message = join('',('This is a hidden outfile suffix option.  ',
				 'The user should not see it.  This option ',
				 'adds an empty string to an "input file ',
				 'type" which is treated as an output file ',
				 'type.  This is an internal way of handling ',
				 'output files so that they are grouped with ',
				 'the appropriate input files in sets.'));

    #We need to return the suffix_id returned by addOutfileSuffixOption so that
    #getOutfile returns the correct output file name.

    my $suffix_id =
      addOutfileSuffixOption($hidden_opt_str,$file_type_index,undef,1,$primary,
			     '',1,'',$error_message,$error_message,
			     $collid_mode);

    #TODO: This will change with requirement 280
    #This will overwrite the value set by addOutfileSuffixOption so that we get
    #the actual usage hash of the desired option
    $outf_to_usage_hash->{$suffix_id} = $usage_index;

    return($suffix_id);
  }

#Makes relationship strings such as '1','1:1','1:M','1:1orM' human-readable
sub getDispRelStr
  {
    my $str = $_[0];
    if(defined($str))
      {
	if($str eq '1')
	  {return('one to all')}
	elsif($str eq '1:1')
	  {return('one to one')}
	elsif($str eq '1:M')
	  {return('one to many')}
	elsif($str eq '1:1orM')
	  {return('one to (one or many)')}
      }

    return('ERROR');
  }

#This method checks whether a file type (infile or outfile) is required.
#If there is an error, returns false
sub isFileTypeRequired
  {
    my $file_type_id = $_[0];

    if(!defined($file_type_id) || $file_type_id >= scalar(@$input_files_array))
      {
	error("Invalid file type ID: [",
	      (defined($file_type_id) ? $file_type_id : 'undef'),"].");
	return(0);
      }

    my @required_types = @$required_infile_types;
    push(@required_types,@$required_outfile_types)
      if(scalar(@$required_outfile_types));

    if(scalar(@required_types) == 0)
      {return(0)}

    #If the supplied type is among the required file types
    if(scalar(grep {$_ == $file_type_id} @required_types))
      {return(1)}

    return(0)
  }

sub isFileTypeHidden
  {
    my $file_type_id = $_[0];

    if(!defined($file_type_id) || $file_type_id >= scalar(@$input_files_array))
      {
	error("Invalid file type ID: [",
	      (defined($file_type_id) ? $file_type_id : 'undef'),"].");
	return(0);
      }

    my $uhash = {};
    if(exists($outfile_types_hash->{$file_type_id}))
      {
	#This assumes there's only 1 (hidden) suffix when the type is outfile
	$uhash = getOutfileUsageHash((getSuffixIDs($file_type_id))[0]);
      }
    else
      {$uhash = getInfileUsageHash($file_type_id)}

    if(!defined($uhash) || !exists($uhash->{HIDDEN}) ||
       !defined($uhash->{HIDDEN}))
      {
	warning("Usage hash for file type ID [$file_type_id] invalid/not ",
		"found.");
	return(0);
      }

    return($uhash->{HIDDEN})
  }

sub isFileTypePrimary
  {
    my $file_type_id = $_[0];

    if(!defined($file_type_id) || $file_type_id >= scalar(@$input_files_array))
      {
	error("Invalid file type ID: [",
	      (defined($file_type_id) ? $file_type_id : 'undef'),"].");
	return(0);
      }

    my $uhash = {};
    if(exists($outfile_types_hash->{$file_type_id}))
      {
	#This assumes there's only 1 (hidden) suffix when the type is outfile
	$uhash = getOutfileUsageHash((getSuffixIDs($file_type_id))[0]);
      }
    else
      {$uhash = getInfileUsageHash($file_type_id)}

    if(!defined($uhash) || !exists($uhash->{PRIMARY}) ||
       !defined($uhash->{PRIMARY}))
      {
	warning("Usage hash for file type ID [$file_type_id] invalid/not ",
		"found.");
	return(0);
      }

    return($uhash->{PRIMARY})
  }

#Determines whether a file type (infile or outfile) has an actual default
#value.  This does not count the display default in the usage hash - only the
#actual default set.
#Globals used: $default_infiles_array
sub isFileTypeDefaulted
  {
    my $file_type_id = $_[0];

    if(!defined($file_type_id) || $file_type_id >= scalar(@$input_files_array))
      {
	error("Invalid file type ID: [",
	      (defined($file_type_id) ? $file_type_id : 'undef'),"].");
	return(0);
      }

    #If the default infile array is defined, is large enough for this file
    #type, there's a sub-array defined for this file type, it has a sub array
    #in it, and at least 1 of the sub-sub-arrays has something in it
    #(regardless of whether it's valid or not), we will return true
    if(defined($default_infiles_array) &&
       scalar(@$default_infiles_array) > $file_type_id &&
       defined($default_infiles_array->[$file_type_id]) &&
       scalar(@{$default_infiles_array->[$file_type_id]}) &&
       scalar(grep {scalar(@$_)} @{$default_infiles_array->[$file_type_id]}))
      {return(1)}

    return(0);
  }

#This returns a file flag and/or 'stdin' or the default file name(s) depending
#on whether the file option is hidden, primary, or has a default.  Supplying
#--extended 2+ will always show the flag, hidden or not.
#Globals used: $extended
sub getFileFlag
  {
    my $file_type_index = $_[0];
    #Always use --extended if supplied and non-0, else use the supplied param
    #Special case: force flag only when extended == -1
    my $local_extended  = (defined($_[1]) ?
			   (defined($extended) && $extended ?
			    $extended : $_[1]) :
			   (defined($extended) ? $extended : 0));

    if(!defined($file_type_index) || $file_type_index < 0 ||
       $file_type_index >= scalar(@$infile_flag_array))
      {
	error("Invalid file type ID: [",
	      (defined($file_type_index) ? $file_type_index : 'undef'),
	      "].  Index is ",(defined($file_type_index) ?
			       "out of range." : 'undefined.'));
	return('');
      }

    if($local_extended != -1)
      {
	#If primary and (visible or extended > 1)
	if(isFileTypePrimary($file_type_index) &&
	   (!isFileTypeHidden($file_type_index) || $local_extended > 1))
	  {return($infile_flag_array->[$file_type_index] .
		  ($local_extended > 1 ? ' (or "STD' .
		   (exists($outfile_types_hash->{$file_type_index}) ?
		    'OUT' : 'IN') . '")' : ''))}
	#If primary and hidden
	elsif(isFileTypePrimary($file_type_index) &&
	      isFileTypeHidden($file_type_index))
	  {return('"STD' . (exists($outfile_types_hash->{$file_type_index}) ?
			   'OUT"' : 'IN"'))}
	#Guaranteed not primary, so if defaulted and hidden and extended < 2
	elsif(isFileTypeDefaulted($file_type_index) &&
	      isFileTypeHidden($file_type_index) && $local_extended < 2)
	  {
	    if(scalar(@{$default_infiles_array->[$file_type_index]}) == 1)
	      {return(join(',',map {defined($_) ? $_ : 'undef'}
			   @{$default_infiles_array->[$file_type_index]
			       ->[0]}))}
	    else
	      {return('(' .
		      join('),(',
			   map {my $a = $_;
				join(',',map {defined($_) ? $_ : 'undef'} @$a)}
			   @{$default_infiles_array->[$file_type_index]}) .
		      ')')}
	  }
	elsif(isFileTypeHidden($file_type_index) && $local_extended < 2)
	  {return('[HIDDEN - use `--extended --extended` to reveal]')}
      }

    return($infile_flag_array->[$file_type_index]);
  }

sub getInfileFlag
  {
    my $file_type_index = $_[0];
    #Always use --extended if supplied and non-0, else use the supplied param
    #Special case: force flag only when extended == -1
    my $local_extended  = (defined($_[1]) ?
			   (defined($extended) && $extended ?
			    $extended : $_[1]) :
			   (defined($extended) ? $extended : 0));

    if(!defined($file_type_index) || $file_type_index < 0 ||
       $file_type_index >= scalar(@$infile_flag_array) ||
       exists($outfile_types_hash->{$file_type_index}))
      {
	error("Invalid input file type ID: [",
	      (defined($file_type_index) ? $file_type_index : 'undef'),"].",
	      (defined($file_type_index) ?
	       ("  Index is ",
		($file_type_index < 0 ||
		 $file_type_index >= scalar(@$infile_flag_array) ?
		 'out of range.' : 'for an outfile type.')) : ''));
	return('');
      }

    return(getFileFlag($file_type_index,$local_extended));
  }

sub getOutfileFlag
  {
    my $file_type_index = $_[0];
    #Always use --extended if supplied and non-0, else use the supplied param
    #Special case: force flag only when extended == -1
    my $local_extended  = (defined($_[1]) ?
			   (defined($extended) && $extended ?
			    $extended : $_[1]) :
			   (defined($extended) ? $extended : 0));

    if(!defined($file_type_index) || $file_type_index < 0 ||
       $file_type_index >= scalar(@$infile_flag_array) ||
       !exists($outfile_types_hash->{$file_type_index}))
      {
	error("Invalid output file type ID: [",
	      (defined($file_type_index) ? $file_type_index : 'undef'),"].");
	return('');
      }

    return(getFileFlag($file_type_index,$local_extended));
  }

sub getOutfileSuffixFlag
  {
    my $suffix_id = $_[0];
    #Always use --extended if supplied and non-0, else use the supplied param
    #Special case: force flag only when extended == -1
    my $local_extended  = (defined($_[1]) ?
			   (defined($extended) && $extended ?
			    $extended : $_[1]) :
			   (defined($extended) ? $extended : 0));

    if(!defined($suffix_id) || $suffix_id < 0 ||
       $suffix_id >= scalar(@$suffix_flag_array))
      {
	error("Invalid output file suffix ID: [",
	      (defined($suffix_id) ? $suffix_id : 'undef'),"].");
	return('');
      }

    my $flag = $suffix_flag_array->[$suffix_id];
    my $uhash = getFileUsageHash($suffix_id,'suffix');

    if($local_extended != -1)
      {
	#If primary and (visible or extended > 1)
	if($uhash->{PRIMARY} && (!$uhash->{HIDDEN} || $local_extended > 1))
	  {return($flag . ($local_extended > 1 ? ' (or "STDOUT")' : ''))}
	#If primary and hidden
	elsif($uhash->{PRIMARY} && $uhash->{HIDDEN})
	  {return('"STDOUT"')}
	#Guaranteed not primary, so if defaulted and hidden and extended < 2
	elsif(defined($uhash->{DEFAULT}) && $uhash->{HIDDEN} &&
	      $local_extended < 2)
	  {return($uhash->{DEFAULT})}
	elsif($uhash->{HIDDEN} && $local_extended < 2)
	  {return('[HIDDEN - use `--extended --extended` to reveal]')}
      }

    return($flag);
  }

#Globals used: usage_array
sub getOutdirFlag
  {
    my $local_extended  = (defined($_[0]) ?
			   (defined($extended) && $extended ?
			    $extended : $_[0]) :
			   (defined($extended) ? $extended : 0));

    ##TODO: The outdir options need to be fixed. See requirement 178
    my $flag = (defined($outdir_flag_array->[0]) ? $outdir_flag_array->[0] :
		getDefaultFlag(getOptStrFlags($default_outdir_opt)));

    if(defined($outdir_flag_array->[0]))
      {
	##TODO: The outdir options need to be fixed. See requirement 178
	my $oduhashes = [grep {$_->{OPTTYPE} eq 'outdir'} @$usage_array];
	my $uhash = {};
	if(scalar(@$oduhashes))
	  {$uhash = $oduhashes->[0]}

	if($local_extended != -1)
	  {
	    #If visible or extended > 1
	    if(!$uhash->{HIDDEN} || $local_extended > 1)
	      {return($flag)}
	    #If defaulted and hidden and extended < 2
	    elsif(defined($uhash->{DEFAULT}) && $uhash->{HIDDEN} &&
		  $local_extended < 2)
	      {return($uhash->{DEFAULT})}
	    elsif($uhash->{HIDDEN} && $local_extended < 2)
	      {return('[HIDDEN - use `--extended --extended` to reveal]')}
	  }
      }

    return($flag);
  }

#Returns the suffix sub-index in the array indexed the same as the file type
#index gotten from addInfileOption
#Globals used: $outfile_suffix_array, $input_files_array, $outf_to_usage_hash
sub addOutfileSuffixOption
  {
    debug({LEVEL => -1},"Params sent in BEFORE: [",
	  join(',',map {defined($_) ? $_ : 'undef'} @_),"].");
    my @in = getSubParams([qw(FLAG|GETOPTKEY FILETYPEID VARREF|GETOPTVAL
			      REQUIRED PRIMARY DEFAULT HIDDEN
			      SMRY|SMRY_DESC|SHORT_DESC
			      DETAIL|DETAIL_DESC|LONG_DESC FORMAT|FORMAT_DESC
			      COLLISIONMODE ADVANCED)],
			  #If there are any params sent in, require the first
			  [scalar(@_) ?
			   #If there are at least 2 input file types, also
			   #require the FILETYPEID
			   (scalar(@$input_files_array) < 2 ?
			    qw(FLAG|GETOPTKEY) :
			    qw(FLAG|GETOPTKEY FILETYPEID)) : ()],
			  [@_]);
    debug({LEVEL => -1},"Params sent in AFTER: [",
	  join(',',map {defined($_) ? $_ : 'undef'} @in),"].");
    my $get_opt_str     = $in[0]; #e.g. 'o|suffix=s'
    my $file_type_index = $in[1]; #Val returned from addInfileOption
    my $get_opt_val     = $in[2]; #A reference to a scalar
    my $required        = $in[3]; #Is suff required?: 0 (false) or non-0 (true)
    my $primary         = defined($in[4]) ? $in[4] : 1; #non-0=STDOUT if no suf
    my $default         = $in[5]; #e.g. '.out'
    my $hidden          = $in[6]; #0 or non-0. Non-0 requires a default.
                                  #Excludes from usage output.
    my $smry_desc       = $in[7]; #e.g. Input file(s).  See --help for format.
                                  #Empty/undefined = exclude from short usage
    my $detail_desc     = $in[8]; #e.g. 'Input file(s).  Space separated,...'
    my $format_desc     = $in[9]; #e.g. 'Tab delimited text w/ cols: 1.Name...'
    my $loc_collid_mode = getCollisionMode(undef,'suffix',$in[10]);
    my $advanced        = $in[11];#Advanced options print when extended >= 2
    ##TODO: Don't use the generic/global collide_mode here - implement an
    #output mode that the user can control per outfile type.  See requirement
    #114

    #Trim leading & trailing hard returns and white space characters (from
    #using '<<')
    $smry_desc   =~ s/^\s+//s if(defined($smry_desc));
    $smry_desc   =~ s/\s+$//s if(defined($smry_desc));
    $detail_desc =~ s/^\s+//s if(defined($detail_desc));
    $detail_desc =~ s/\s+$//s if(defined($detail_desc));
    $format_desc =~ s/^\s+//s if(defined($format_desc));
    $format_desc =~ s/\s+$//s if(defined($format_desc));

    if(defined($get_opt_val) && ref($get_opt_val) ne 'SCALAR')
      {
	error("GETOPTVAL must be a reference to a SCALAR to hold the value ",
	      "for the outfile suffix string, but instead, a [",
	      (ref($get_opt_val) eq '' ?
	       'SCALAR' : 'reference to a ' . ref($get_opt_val)),
	      "] was received.  Unable to add outfile suffix option.");
	return(undef);
      }

    if($command_line_processed)
      {
	error("You cannot add command line options (i.e. call ",
	      "addOutfileSuffixOption()) after the command line has already",
	      " been processed (i.e. processCommandLine()) without at ",
	      "least re-initializing (i.e. calling _init()).");
	return(undef);
      }

    #Keep track of whether this method was called internally or not
    my $called_implicitly = 0;
    #Defaults mode - Only call with no params once.
    my $adding_default = (scalar(@in) == 0);
    if($adding_default)
      {
	if($default_outfile_suffix_added)
	  {
	    error('The default output file suffix type has already been ',
		  'added.');
	    return(undef);
	  }

	debug({LEVEL => -1},'Setting default values for ',
	      'addOutfileSuffixOption.');

	$get_opt_str = removeDupeFlags($default_outfile_suffix_opt);
	if(!defined($get_opt_str) || $get_opt_str eq '')
	  {
	    error('Unable to add default output file suffix type ',
		  "[$default_outfile_suffix_opt] due to redundant flags: [",
		  join(',',getDupeFlags($get_opt_str)),'].');
	    $default_outfile_suffix_opt = $get_opt_str;
	    return(undef);
	  }
	$default_outfile_suffix_opt = $get_opt_str;

	$default_outfile_suffix_added = 1;
	$default_outfile_suffix_id    = scalar(@$suffix_id_lookup);
	$required                     = 0;
	$loc_collid_mode              = getCollisionMode(undef,'suffix');
	##TODO: Use a command line flag specific to the outfile type instead of the current def_collide_mode which applies to all outfile types.  Create the flag when the outfile suffix option is created (but only if the programmer specified that the user is to choose).  See requirement 114

	#If a compatible outfile type exists that we will be tagteamed up with,
	#match it.  (Returns undef if none.)
	$file_type_index = getDefaultPrimaryLinkedInfileID();

	#The descriptions are added below
      }
    else
      {
	if(isCaller('addDefaultFileOptions','addOutfileOption'))
	  {$called_implicitly = 1}
	if(!$called_implicitly)
	  {debug({LEVEL => -1},'Received custom values for ',
		 'addOutfileSuffixOption.')}
      }

    if(!defined($get_opt_str) || $get_opt_str eq '')
      {
	error("The first parameter (Getopt::Long key string) is required.");
	quit(-91);
      }

    #If the file type ID is not an integer
    if(defined($file_type_index) && $file_type_index !~ /^\d+$/)
      {
	error("Invalid FILETYPEID parameter: [$file_type_index].  Must be an ",
	      "unsigned integer.");
	quit(-92);
      }
    #If the integer is defined, was supplied by the programmer, and references
    #an output file type
    elsif(defined($file_type_index) && !isCaller('addOutfileOption') &&
	  exists($outfile_types_hash->{$file_type_index}))
      {
	error("Invalid FILETYPEID parameter: [$file_type_index].  Must refer ",
	      "to an input file type, not an output file type.");
	quit(-93);
      }
    #If the file type is not defined
    elsif(!defined($file_type_index))
      {
	$file_type_index = getDefaultPrimaryInfileID();

	if(!defined($file_type_index))
	  {
	    error("No input file types have been added.  Unable to determine ",
		  "default FILETYPEID.");
	    quit(-94);
	  }
      }
    #If the valid file type ID was added as a part of creating a default
    elsif($adding_default)
      {debug({LEVEL => -1},"Input file type is: [",
	     getInfileFlag($file_type_index,-1),"].")}

    #If the file type looked right, but was supplied by the programmer, double-
    #check they actually got the file type ID from addInfileOption
    if(defined($file_type_index) && !$called_implicitly)
      {
	my $uhash = getInfileUsageHash($file_type_index);
	if(!defined($uhash))
	  {
	    #getInfileUsageHash should have already issued an error
	    quit(-69);
	  }
	elsif(!exists($uhash->{OPTTYPE}))
	  {error("Invalid FILETYPEID: [$file_type_index].  Must be an ID ",
		 "returned by addInfileOption.")}
	#TODO: Requirement 280 will allow linking to either input or output
	#      file types
	elsif($uhash->{OPTTYPE} ne 'infile')
	  {error("FILETYPEID passed in must be an input file type ID as ",
		 "returned by addInfileOption.  Instead, received an ID of ",
		 "type: [$uhash->{OPTTYPE}].")}
      }

    #If hidden is not defined, default to the hidden state of whatever file
    #type this might be linked to, except when called via addOutfileOption,
    #otherwise 0.
    if(!defined($hidden) && defined($file_type_index) &&
       !isCaller('addOutfileOption'))
      {
	if(isFileTypeHidden($file_type_index))
	  {$hidden = 1}
	else
	  {$hidden = 0}
      }
    elsif(!defined($hidden))
      {$hidden = 0}

    #Allow the flag to be an array of scalars and turn it into a get opt str
    my $save_getoptstr = $get_opt_str;
    $get_opt_str = makeGetOptKey($get_opt_str,'suffix',1,
				 'addOutfileSuffixOption');

    if(!defined($get_opt_str) || !isGetOptStrValid($get_opt_str,'suffix'))
      {
	if($adding_default)
	  {warning("Unable to add default output file suffix option.")}
	else
	  {
	    error("Invalid flag definition: [$save_getoptstr] for outfile-",
		  "suffix type.");
	    quit(-74);
	  }
      }

    $get_opt_str = fixStringOpt($get_opt_str);

    my $flags = [getOptStrFlags($get_opt_str)];
    my $flag  = getDefaultFlag($flags);

    if($hidden && !defined($default) && (defined($required) && $required))
      {
	warning("Cannot hide option [$flag] if",
		(!defined($default) ? ' no default provided' : ''),
		((!defined($default) && defined($required) && $required) ?
		 ' and if' : ''),
		(defined($required) && $required ? ' it is required' : ''),
		".  Setting as not hidden.");
	$hidden = 0;
      }

    if($file_type_index < 0 || $file_type_index =~ /\D/)
      {
	error("Invalid file type id: [$file_type_index].  Must be a value ",
	      "returned from addInfileOption.");
	return(undef);
      }

    if($file_type_index >= scalar(@$input_files_array))
      {
	error("Outfile suffix option [$get_opt_str] has been added to take ",
	      "a suffix that is appended to input file type ",
	      "[$file_type_index], but that input file type has not been ",
	      "created yet.  File types should be created by addInfileOption ",
	      "before specifying an outfile suffix is added to be appended ",
	      "to those files.");
	return(undef);
      }

    #We can add the default suffix directly to the 2D suffix array because
    #we're going to pass a reference to the value in the array to Getopt::Long
    #for it to change directly in the 2D array if the user supplies a value
    my($suffix_index);
    my $suffix_id = scalar(@$suffix_id_lookup);
    if((scalar(@$outfile_suffix_array) - 1) < $file_type_index ||
       !defined($outfile_suffix_array->[$file_type_index]))
      {
	$outfile_suffix_array->[$file_type_index] = [$default];
	$suffix_index = 0;
      }
    else
      {
	$suffix_index = scalar(@{$outfile_suffix_array->[$file_type_index]});
	push(@{$outfile_suffix_array->[$file_type_index]},$default);
      }
    debug({LEVEL => -1},"Default suffix for input file type [",
	  getInfileFlag($file_type_index,-1),"] added is [",
	  (defined($default) ? $default : 'undef'),"].")
      if(!exists($outfile_types_hash->{$file_type_index}));
    push(@$suffix_id_lookup,[$file_type_index,$suffix_index]);

    #Save the primary value for this type and suffix index
    $suffix_primary_vals->[$file_type_index]->[$suffix_index] = $primary;

    $collid_modes_array->[$file_type_index]->[$suffix_index] =
      $loc_collid_mode;

    #Fix any subarrays in the middle that are undefined
    foreach my $omi (0..$#{$collid_modes_array})
      {if(!defined($collid_modes_array->[$omi]))
	 {$collid_modes_array->[$omi] = []}}

    debug({LEVEL=>-1},"Creating an outfile suffix option at infile type ",
	  "index [$file_type_index] and suffix index [$suffix_index].");

    my $suffix_ref =
      \$outfile_suffix_array->[$file_type_index]->[$suffix_index];

    #Fix any subarrays in the middle that are undefined
    foreach my $osi (0..$#{$outfile_suffix_array})
      {if(!defined($outfile_suffix_array->[$osi]))
	 {$outfile_suffix_array->[$osi] = []}}

    #Set both the variable sent in from main and the internal suffix tracking
    my $getoptsub = (defined($get_opt_val) ?
		     sub {$$get_opt_val = $$suffix_ref = $_[1]} : $suffix_ref);

    $GetOptHash->{$get_opt_str} = $getoptsub;

    if($required)
      {push(@$required_suffix_types,
	    [$file_type_index,$suffix_index,$suffix_id])}

    $suffix_flag_array->[$suffix_id] = $flag;

    #If smry_desc is not defined or is an empty string
    if(!defined($smry_desc) || $smry_desc eq '')
      {
	#If the option is not hidden (we have to check this because we cannot
	#call getFileFlag on some hidden options because they are output files
	#made in addOutfileOption) and the option is required or this type
	#hasn't been setup as an outfile type yet (i.e. it's not the already
	#default-added -o being replaced), and detail_desc is undefined, then
	#set a default summary description
	if((!defined($hidden) || !$hidden) &&
	   ($required || (!exists($outfile_types_hash->{$file_type_index}) &&
			  !defined($detail_desc))))
	  {$smry_desc = 'Outfile suffix appended to file names supplied to [' .
	     getInfileFlag($file_type_index) . '].'}
	else
	  {$smry_desc = ''}
      }

    if((!defined($detail_desc) || $detail_desc eq '') &&
       !exists($outfile_types_hash->{$file_type_index}))
      {$detail_desc =
	 join('',
	      ('Outfile suffix appended to file names supplied to [',
	       getInfileFlag($file_type_index),
	       '].  See --help for file format.'))}
    #If the description doesn't reference the help flag for the file format and
    #a file format was provided, add a reference to it
    elsif($detail_desc !~ /--help/ && defined($format_desc) &&
	  $format_desc ne '')
      {$detail_desc .= "\n\nSee --help for file format."}

    if((!defined($default) || $default eq '') && $primary && !$required)
      {$default = 'STDOUT'}
    elsif(!defined($default))
      {$default = ''}

    addToUsage($get_opt_str,
	       $flags,
	       $smry_desc,
	       $detail_desc,
	       $required,
	       $default,
	       undef,
	       $hidden,
	       'suffix',
	       0,
	       $advanced,
	       undef,
	       undef,
	       $primary,
	       $format_desc,
	       $suffix_id);

    #TODO: This will change with requirement 280
    $outf_to_usage_hash->{$suffix_id} = $#{$usage_array};

    return($suffix_id);
  }

sub addOutfileTagteamOption
  {
    my @in =
      getSubParams([qw(FLAG_SUFF|GETOPTKEY_SUFF FLAG_FILE|GETOPTKEY_FILE
		       FILETYPEID|PAIR_WITH PAIR_RELAT VARREF_SUFF|GETOPTVAL
		       REQUIRED PRIMARY FORMAT|FORMAT_DESC DEFAULT
		       DEFAULT_IS_FILE HIDDEN_SUFF HIDDEN_FILE
		       SMRY_SUFF|SMRY_DESC_SUFF|SHORT_DESC_SUFF
		       SMRY_FILE|SMRY_DESC_FILE|SHORT_DESC_FILE
		       DETAIL_SUFF|DETAIL_DESC_SUFF|LONG_DESC_SUFF
		       DETAIL_FILE|DETAIL_DESC_FILE|LONG_DESC_FILE
		       COLLISIONMODE_SUFF COLLISIONMODE_FILE ADVANCED_SUFF
		       ADVANCED_FILE)],
		   #If there are any params sent in, require the first
		   [scalar(@_) == 0 ? () :
		    #If there are at least 2 input file types, also require the
		    # FILETYPEID
		    (scalar(@$input_files_array) < 2 ?
		     qw(FLAG_SUFF|GETOPTKEY_SUFF FLAG_FILE|GETOPTKEY_FILE) :
		     qw(FLAG_SUFF|GETOPTKEY_SUFF FLAG_FILE|GETOPTKEY_FILE
			FILETYPEID|PAIR_WITH))],
		   [@_]);
    my $get_opt_str_suff = $in[0];  #e.g. 'o|suffix=s'
    my $get_opt_str_file = $in[1];  #e.g. 'outfile=s'
    my $file_type_index  = $in[2];  #Val returned from addInfileOption
    my $relationship     = $in[3];  #e.g. 1,1:1,1:M,1:1orM
    my $get_opt_val      = $in[4];  #A reference to a scalar
    my $required         = $in[5];  #Is outfile required?: 0=false non-0=true
    my $primary          = $in[6];  #non-0=STDOUT if unsup
    my $format_desc      = $in[7];  #e.g. 'Tab delim text w/ cols: 1.Name...'
    my $default          = $in[8];  #e.g. '.out' or 'file.out'
    my $default_is_file  = $in[9];  #0 or non-0.
    my $hidden_suff      = $in[10]; #0 or non-0. Non-0 requires a default.
                                    #Excludes from usage
    my $hidden_file      = $in[11]; #0 or non-0. Non-0 requires a default.
                                    #Excludes from usage
    my $smry_desc_suff   = $in[12]; #e.g. Outfile suffix.
                                    #Empty/undefined = exclude from short usage
    my $smry_desc_file   = $in[13]; #e.g. Output file.
                                    #Empty/undefined = exclude from short usage
    my $detail_desc_suff = $in[14]; #e.g. Outfile suffix.  See --help for...
    my $detail_desc_file = $in[15]; #e.g. Output file.  See --help for...
    my $loc_collide_suff = $in[16]; #Adds to collid_modes_array
			            #1 of: merge,rename,error
    my $loc_collide_file = $in[17]; #Adds to collid_modes_array
			            #1 of: merge,rename,error
    my $advanced_suff    = $in[18];#Advanced options print when extended >= 2
    my $advanced_file    = $in[19];#Advanced options print when extended >= 2
    my($suffix_id,$outfile_id);

    #If no parameters were submitted, add the default options
    if(scalar(@_) == 0)
      {
	if($default_tagteam_added)
	  {
	    error("A default outfile tagteam has already been added.");
	    return(undef);
	  }
	$default_tagteam_added = 1;

	$suffix_id  = addOutfileSuffixOption();
	$outfile_id = addOutfileOption();
      }
    else
      {
	#There can only be 1 with a default
	my($default_suff,$default_file) =
	  (defined($default_is_file) && $default_is_file ?
	   (undef,$default) : ($default,undef));

	$suffix_id  = addOutfileSuffixOption($get_opt_str_suff,
					     $file_type_index,
					     $get_opt_val,
					     $required,
					     $primary,
					     $default_suff,
					     $hidden_suff,
					     $smry_desc_suff,
					     $detail_desc_suff,
					     $format_desc,
					     $loc_collide_suff);
	$outfile_id = addOutfileOption($get_opt_str_file,
				       $loc_collide_file,
				       $required,
				       $primary,
				       $default_file,
				       $smry_desc_file,
				       $detail_desc_file,
				       $format_desc,
				       $hidden_file,
				       $file_type_index,
				       $relationship);
      }

    return(createSuffixOutfileTagteam($suffix_id,$outfile_id,0));
  }

#This sub links options created by addOutfileSuffixOption and addOutfileOption
#in such a way that either one or the other can be supplied to generate output
#file names.  It edits the options if there is a conflict in the options versus
#what was supplied to this method.  Difference in PRIMARY and REQUIRED can
#change the PRIMARY, REQUIRED, DEFAULT, and SUMMARY values in the usage.
#DEFAULT and SUMMARY can change IF they contin default values that were
#inflenced by PRIMARY and/or REQUIRED values.  Other variables are also edited
#if PRIMARY and/or REQUIRED change: values in $usage_array,
#$suffix_primary_vals, $required_outfile_types, & $required_suffix_types
sub createSuffixOutfileTagteam
  {
    my $suffix_id     = $_[0];
    my $outfile_id    = $_[1];
    my $skip_existing = defined($_[2]) ? $_[2] : 0; #See addDefaultFileOptions
    my $ttid          = -1 - scalar(keys(%$outfile_tagteams));

    if(!defined($suffix_id) ||
       scalar(@$suffix_id_lookup) <= $suffix_id ||
       !defined($suffix_id_lookup->[$suffix_id]))
      {
	error("Invalid suffix ID: [",
	      (defined($suffix_id) ? $suffix_id : 'undef'),"].");
	return(undef);
      }
    else
      {debug({LEVEL => -2},"suffix ID: [$suffix_id] is in the ",
	     "suffix_id_lookup and has: [",
	     join(',',@{$suffix_id_lookup->[$suffix_id]}),"].")}

    if(!defined($outfile_id) ||
       scalar(@$suffix_id_lookup) <= $outfile_id ||
       !defined($suffix_id_lookup->[$outfile_id]))
      {
	error("Invalid outfile ID: [",
	      (defined($outfile_id) ? $outfile_id : 'undef'),"].");
	return(undef);
      }
    else
      {debug({LEVEL => -2},"outfile ID: [$outfile_id] is in the ",
	     "suffix_id_lookup and has: [",
	     join(',',@{$suffix_id_lookup->[$outfile_id]}),"].")}

    #Outfile defaults are saved in default_infiles_array, but there is no save
    #of any default suffixes.  The defaults are needed by getOutfile in order
    #to know the difference between a default suffix/outfile and an explicitly
    #supplied suffix/outfile so that it can return the correct type of outfile.
    #If one has a default, but the other was supplied on the command line, the
    #supplied one is what must be returned.  Thus, we must save the default
    #suffix:
    my $infile_index         = $suffix_id_lookup->[$suffix_id]->[0];
    my $suffix_index         = $suffix_id_lookup->[$suffix_id]->[1];
    my $outfile_index        = $suffix_id_lookup->[$outfile_id]->[0];
    my $outfile_suffix_index = $suffix_id_lookup->[$outfile_id]->[1];

    #If this is being called from addDefaultFileOptions, figure out which
    #type was not default-added (if any) so that we can change the tagteam ID
    #to it (because the user won't otherwise have a way of retrieving the
    #default-added outfile type)
    my $outf_explicit = 1;
    my $suff_explicit = 1;
    if(isCaller('addDefaultFileOptions'))
      {
	my $def_outf_suff_id = '';
	if($default_outfile_added)
	  {$def_outf_suff_id = (getSuffixIDs($default_outfile_id))[0]}

	if($default_outfile_suffix_added && $default_outfile_added &&
	   $def_outf_suff_id eq $outfile_id &&
	   $default_outfile_suffix_id eq $suffix_id)
	  {
	    $ttid = 0;
	    $outf_explicit = 0;
	    $suff_explicit = 0;
	  }
	elsif($default_outfile_suffix_added && !$default_outfile_added &&
	      $default_outfile_suffix_id eq $suffix_id)
	  {
	    $ttid = $outfile_id;
	    $suff_explicit = 0;
	  }
	elsif($default_outfile_added && !$default_outfile_suffix_added &&
	      $def_outf_suff_id eq $outfile_id)
	  {
	    $ttid = $suffix_id;
	    $outf_explicit = 0;
	  }
      }

    #Make sure these IDs aren't involved in any other tagteams
    my $dupe = 0;
    if(scalar(grep {$_->{SUFFID} eq $suffix_id} values(%$outfile_tagteams)))
      {
	my $already_outf_index =
	  $suffix_id_lookup->[(grep {$_->{SUFFID} eq $suffix_id}
			       values(%$outfile_tagteams))[0]->{OUTFID}]->[0];
	error("The outfile suffix supplied as [",
	      getOutfileSuffixFlag($suffix_id),"] already belongs to an ",
	      "outfile tagteam with outfiles supplied as [",
	      getOutfileFlag($already_outf_index),"].  Unable to add to ",
	      "another tagteam.") unless($skip_existing);
	$dupe = 1;
      }
    if(scalar(grep {$_->{OUTFID} eq $outfile_id} values(%$outfile_tagteams)))
      {
	my $already_suff_id = (grep {$_->{OUTFID} eq $outfile_id}
			       values(%$outfile_tagteams))[0]->{SUFFID};
	error("Outfiles supplied as [",getOutfileFlag($outfile_index),
	      "] already belong to an outfile tagteam with outfiles created ",
	      "with suffixes supplied as [",
	      getOutfileSuffixFlag($already_suff_id),"].  Unable to add ",
	      "to another tagteam.") unless($skip_existing);
	$dupe = 1;
      }
    if($dupe)
      {return(undef)}

    #If the suffix ID is not from addOutfileSuffixOption
    if(exists($outfile_types_hash->{$infile_index}))
      {
	error("The outfile suffix ID submitted: [$suffix_id] does not appear ",
	      "to be an outfile suffix ID, as the file option it is linked ",
	      "to is an output file: [",getOutfileFlag($infile_index),
	      "], and not an input file as expected.");
	return(undef);
      }
    if(!exists($outfile_types_hash->{$outfile_index}))
      {
	error("The outfile ID submitted: [$outfile_id] does not appear to be ",
	      "an outfile ID, as the file option it is linked to is an ",
	      "input file, [",getInfileFlag($outfile_index),"], and not an ",
	      "output file as expected.");
	return(undef);
      }

    if(scalar(@$outfile_suffix_array) <= $infile_index ||
       scalar(@{$outfile_suffix_array->[$infile_index]}) <= $suffix_index)
      {
	error("Could not find the suffix for suffix ID: [$suffix_id].");
	return(undef);
      }

    #Make sure that if the outfile option has a PAIR_WITH value, it is the same
    #as the FILETYPEID of the suffix option, otherwise - fatal error.
    if(scalar(grep {$outfile_index == $_->[0] &&
		      (!defined($_->[1]) || $infile_index != $_->[1])}
	      @$required_relationships))
      {
	my $relat_index = (map {$_->[1]} grep {$outfile_index == $_->[0]}
			   @$required_relationships)[0];
	if(defined($relat_index))
	  {error('Outfile tagteam error: suffix [',
		 getOutfileSuffixFlag($suffix_id),'] and outfile(s) [',
		 getOutfileFlag($outfile_index),'] are not associated with ',
		 'the same input file(s): [',getInfileFlag($infile_index),
		 '] and [',getInfileFlag($relat_index),'], respectively.',
		 {DETAIL => ('An outfile tagteam must be between an outfile ' .
			     "suffix type [ID: $suffix_id] and an outfile " .
			     "type [ID: $outfile_id OUTFILE INDEX: " .
			     "$outfile_index] that are associated with the " .
			     'same input file type [INFILE INDEX ' .
			     "$infile_index != PAIR_RELAT $relat_index].")})}
	else
	  {error('Outfile tagteam error: suffix [',
		 getOutfileSuffixFlag($suffix_id),'] and outfile(s) [',
		 getOutfileFlag($outfile_index),'] are not associated with ',
		 'the same input file(s): [',getInfileFlag($infile_index),
		 '] versus [no input file type relationship defined] ',
		 'respectively.',
		 {DETAIL => ('An outfile tagteam must be between an outfile ' .
			     "suffix type [ID: $suffix_id] and an outfile " .
			     "type [ID: $outfile_id OUTFILE INDEX: " .
			     "$outfile_index] that are associated with the " .
			     'same input file type [INFILE INDEX ' .
			     "$infile_index != PAIR_RELAT $relat_index].")})}
	return(undef);
      }
    #Else if a relationship wasn't saved at all
    elsif(scalar(grep {$outfile_index == $_->[0]}
		 @$required_relationships) == 0)
      {addRequiredRelationship($outfile_index,
			       $infile_index,
			       getRelationStr('1:1orM'))}

    my $default_suffix =
      $outfile_suffix_array->[$infile_index]->[$suffix_index];

    #Grab all the usage info for the outfile and suffix options
    my $of_usage     = getFileUsageHash($outfile_index,'outfile');
    my $ofsuff_usage = getFileUsageHash($outfile_id,   'suffix');
    my $sf_usage     = getFileUsageHash($suffix_id,    'suffix');

    #Set $primary from the file IDs
    debug({LEVEL => -2},"Arbitrarily setting PRIMARY to the value from ",
	  "the ",($outf_explicit ? 'outfile' : 'suffix')," option.");
    #Suffix's primary value is the default
    my $primary = ($outf_explicit ? $of_usage->{PRIMARY} :
		   ($suff_explicit ? $sf_usage->{PRIMARY} : 1));

    #Make sure PRIMARY agrees with the options supplied
    if($of_usage->{PRIMARY} != $primary)
      {
	warning("Tagteam outfile conflict for PRIMARY output settings.  ",
		"An outfile tagteam is set as ",($primary ? '' : 'NOT '),
		"PRIMARY, but outfiles supplied as [",
		getOutfileFlag($outfile_index),"] were explicitly and ",
		"independently set as ",($of_usage->{PRIMARY} ? '' : 'NOT '),
		"PRIMARY.")
	  if($outf_explicit);

	$of_usage->{PRIMARY} = $primary;

	#If the default was automatically set based on its own primary value,
	#reset it based on the value supplied here
	if($of_usage->{DEFAULT} eq 'STDOUT' ||
	   $of_usage->{DEFAULT} eq '')
	  {$of_usage->{DEFAULT} = ($primary ? 'STDOUT' : '')}

	$suffix_primary_vals->[$outfile_index]->[$outfile_suffix_index] =
	  $primary;

	$ofsuff_usage->{PRIMARY} = $primary;
      }
    #This one can be assumed to be the same as the above, but we'll double-
    #check it if the above matches
    elsif($ofsuff_usage->{PRIMARY} != $primary)
      {
	warning("Tagteam outfile's hidden suffix conflict for PRIMARY ",
		"output settings.  The tagteam output is set as ",
		($primary ? '' : 'NOT '),"PRIMARY, but its suffix [",
		getOutfileSuffixFlag($outfile_id),"] is set as ",
		($ofsuff_usage->{PRIMARY} ? '' : 'NOT '),"PRIMARY.")
	  if($outf_explicit);

	$suffix_primary_vals->[$outfile_index]->[$outfile_suffix_index] =
	  $primary;

	$ofsuff_usage->{PRIMARY} = $primary;
      }
    if($sf_usage->{PRIMARY} != $primary)
      {
	warning("Tagteam suffix conflict for PRIMARY output settings.  ",
		"The tagteam output is set as ",($primary ? '' : 'NOT '),
		"PRIMARY, but the settings for its suffix [",
		getOutfileSuffixFlag($suffix_id),"] is set as ",
		($sf_usage->{PRIMARY} ? '' : 'NOT '),"PRIMARY.")
	  if($suff_explicit);

	$suffix_primary_vals->[$infile_index]->[$suffix_index] = $primary;

	$sf_usage->{PRIMARY} = $primary;
      }

    #Set $required from the file IDs
    debug({LEVEL => -2},"Arbitrarily setting REQUIRED to the value ",
	  ($outf_explicit ? "from the outfile option [$of_usage->{REQUIRED}]" :
	   ($suff_explicit ? "from the suffix option [$sf_usage->{REQUIRED}]" :
	    'to 0')),'.');
    #Suffix's required value is the default
    my $required = ($outf_explicit ? $of_usage->{REQUIRED} :
		    ($suff_explicit ? $sf_usage->{REQUIRED} : 0));

    #Check each option's REQUIRED value and issue a warning if either is true
    if(!$required && $of_usage->{REQUIRED})
      {
	warning("Tagteam outfile conflict for REQUIRED output settings.  ",
		"An outfile tagteam is set as ",($required ? '' : 'NOT '),
		"REQUIRED, but outfiles supplied as [",
		getOutfileFlag($outfile_index),"] were explicitly and ",
		"independently set as ",($of_usage->{REQUIRED} ? '' : 'NOT '),
		"REQUIRED.")
	  if($outf_explicit);

	#We will leave the SUMMARY for the usage as-is, since we want required
	#options (especially if the user added it explicitly as required) to
	#show in the summary usage
      }
    if(!$required && $sf_usage->{REQUIRED})
      {
	warning("Tagteam suffix conflict for REQUIRED output settings.  ",
		"The tagteam output is set as ",($required ? '' : 'NOT '),
		"REQUIRED, but the settings for its suffix [",
		getOutfileSuffixFlag($suffix_id),"] is set as ",
		($sf_usage->{REQUIRED} ? '' : 'NOT '),"REQUIRED.")
	  if($suff_explicit);

	#We will leave the SUMMARY for the usage as-is, since we want required
	#options (especially if the user added it explicitly as required) to
	#show in the summary usage
      }

    #Set the options' REQUIRED value to false
    #Regardless of the value of required for the tagteam, the individual
    #options will always be set to not be required so that the tagteam
    #requirement can be enforced without individual required options will not
    #interfere..
    if($of_usage->{REQUIRED})
      {
	#Remove this type from the required outfile types
	@$required_outfile_types =
	  grep {$_ != $outfile_index} @$required_outfile_types;
      }
    $of_usage->{REQUIRED} = 0;
    if($ofsuff_usage->{REQUIRED})
      {
	#Remove this type from the required suffix types
	@$required_suffix_types =
	  grep {$_->[2] != $outfile_id} @$required_suffix_types;
      }
    $ofsuff_usage->{REQUIRED} = 0;
    if($sf_usage->{REQUIRED})
      {
	#Remove this type from the required suffix types
	@$required_suffix_types =
	  grep {$_->[2] != $suffix_id} @$required_suffix_types;
      }
    $sf_usage->{REQUIRED} = 0;

    #Check whether any options are hidden
    my $hidden = $of_usage->{HIDDEN} + $sf_usage->{HIDDEN};

    if($required && !$primary && $hidden == 2)
      {
	warning("The suffix [",getOutfileSuffixFlag($suffix_id),
		"] and outfile(s) [",getOutfileFlag($outfile_index),
		"] involved in a tagteam cannot both be hidden and ",
		"required unless the output is primary.  Un-hiding.  Please ",
		"unhide at least one of the two options or change the ",
		"required state of the tagteam to false/0 to eliminate this ",
		"warning.",
		{DETAIL =>
		 join(',',('If both options that specify where output should ',
			   'go are required and not primary (note: primary ',
			   'output goes to STDOUT when no file is ',
			   'specified), they cannot be hidden from the usage ',
			   'output because the user has no way to know how ',
			   'to supply the required option(s).'))});
	$of_usage->{HIDDEN} = 0;
	$sf_usage->{HIDDEN} = 0;
      }

    #Append cross-referenced statements that mention that these options are
    #mutually exclusive unless one of them is hidden.
    if($hidden != 1)
      {
	$of_usage->{DETAILS} .= ($of_usage->{DETAILS} eq '' ? '' : "\n\n") .
	  "Mutually exclusive with [" . getOutfileSuffixFlag($suffix_id) .
	    "] (both options specify an outfile name in different ways for " .
	      "the same output).";
	$sf_usage->{DETAILS} .= ($sf_usage->{DETAILS} eq '' ? '' : "\n\n") .
	  "Mutually exclusive with [" . getOutfileFlag($outfile_index) .
	    "] (both options specify an outfile name in different ways for " .
	      "the same output).";

	if($required)
	  {
	    #NOTE: "^" is used in the required column of the usage in this same
	    #condition to reference the following note about one of the tagteam
	    #options being required
	    $of_usage->{DETAILS} .= "\n^ Required if outfile suffix [" .
	      getOutfileSuffixFlag($suffix_id) . "] is not supplied.";
	    $sf_usage->{DETAILS} .= "\n^ Required if outfile [" .
	      getOutfileFlag($outfile_index) . "] is not supplied.";
	  }
      }

    #We do not want to include a note about 1 of 2 options being required if
    #the other option is hidden (or rather 1 of the options is hidden).  Note,
    #both cannot be hidden and required.
    $of_usage    ->{TTHIDN} = $hidden == 1;
    $ofsuff_usage->{TTHIDN} = $hidden == 1;
    $sf_usage    ->{TTHIDN} = $hidden == 1;

    #Mark a flag as to whether it's required as a part of a tagteam for the
    #usage output
    $of_usage    ->{TTREQD} = $required;
    $ofsuff_usage->{TTREQD} = $required;
    $sf_usage    ->{TTREQD} = $required;

    #Mark these items as being involved in a tagteam, so they can be skipped in
    #customHelp
    $of_usage    ->{TAGTEAM} = 1;
    $ofsuff_usage->{TAGTEAM} = 1;
    $sf_usage    ->{TAGTEAM} = 1;

    #Save the tagteam ID so that it can be looked up during the processing of
    #the usage_array hashes
    $of_usage    ->{TAGTEAMID} = $ttid;
    $ofsuff_usage->{TAGTEAMID} = $ttid;
    $sf_usage    ->{TAGTEAMID} = $ttid;

    #These are the hash keys of the hashes in the usage_array that are used in
    #the customHelp method.  The same keys will be created in the
    #outfile_tagteams hash: HIDDEN, OPTFLAG, PRIMARY, OPTTYPE, & FORMAT
    #The options will still appear individually in the usage output (though
    #they were edited above to do things like append mutual-exclusion cross-
    #references and required messages).
    my $flags = ($hidden == 1 && $of_usage->{HIDDEN} ?
		 [] : [@{$of_usage->{OPTFLAG}}]);
    if($hidden != 1 || !$sf_usage->{HIDDEN})
      {push(@$flags,@{$sf_usage->{OPTFLAG}})}

    my $type = (!$hidden ? 'tagteam' : ($of_usage->{HIDDEN} ?
					'suffix' : 'outfile'));

    my $format = ($outf_explicit && defined($of_usage->{FORMAT}) ?
		  $of_usage->{FORMAT} :
		  ($suff_explicit && defined($sf_usage->{FORMAT}) ?
		   $sf_usage->{FORMAT} : ''));

    $outfile_tagteams->{$ttid} = {SUFFID   => $suffix_id,
				  OUTFID   => $outfile_id,
				  REQUIRED => $required,
				  PRIMARY  => $primary,

				  #TODO: This is here to allow the teagteam
				  #code to know whether the user supplied a
				  #value different from the hard-coded default
				  #so that it can decide whether to use the
				  #suffix or the outfile or whether the user
				  #inappropriately used both mutually exclusive
				  #flags.  This really should be handled the
				  #same way the default_outfiles_array is
				  #handled.  See requirement #289.
				  SUFFDEF  => $default_suffix,

				  HIDDEN   => $hidden == 2,
				  OPTFLAG  => $flags,
				  OPTTYPE  => $type,
				  FORMAT   => $format};

    return($ttid);
  }

#This sub is intended to be called after user defaults have been processed
#It updates the SUFFDEF values in the outfile_tagteams hash and clears out any
#defaults stored in default_infiles_array if the user supplied a default of
#their own to either the suffix or the outfile.  It also transfers the default
#output file values that end up in the input_files_array to the
#default_input_files
##TODO: Do not manipulate the default values like this.  See requirement #289
##TODO: Save defaults in the usage_array.  See requirement #288
sub updateTagteamDefaults
  {
    foreach my $ttid (keys(%$outfile_tagteams))
      {
	#In order to evaluate whether the SUFFID option was supplied a value or
	#has a default value, we need the 2 indexes into the
	#outfile_suffix_array to obtain the value to compare to the SUFFDEF
	#key's value in the outfile_tagteams hash
	my $suffid_infile_index =
	  $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{SUFFID}]->[0];
	my $suffid_suffix_index =
	  $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{SUFFID}]->[1];
	#Same for the OUTFID
	my $outfid_infile_index =
	  $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{OUTFID}]->[0];
	my $outfid_suffix_index =
	  $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{OUTFID}]->[1];

	#Retrieve the default values
	my $suff_default = $outfile_tagteams->{$ttid}->{SUFFDEF};
	my $outf_default = []; #A 2D array reference
	if($outfid_infile_index < scalar(@$default_infiles_array) &&
	   defined($default_infiles_array->[$outfid_infile_index]) &&
	   scalar(@{$default_infiles_array->[$outfid_infile_index]}) &&
	   scalar(grep {defined($_)} map {@$_}
		  @{$default_infiles_array->[$outfid_infile_index]}))
	  {$outf_default = $default_infiles_array->[$outfid_infile_index]}

	#Retrieve the post-user-default-load values
	my $suff_value = $outfile_suffix_array->[$suffid_infile_index]
	  ->[$suffid_suffix_index];
	my $outf_value = $input_files_array->[$outfid_infile_index];

	my $is_suff_default = (defined($suff_default) &&
			       $suff_default eq $suff_value);
	my $is_outf_default =
	  (defined($outf_value) && scalar(@$outf_value) > 0 &&
	   defined($outf_default) &&
	   scalar(@$outf_value) == scalar(@$outf_default) &&
	   scalar(grep {scalar(@{$outf_value->[$_]}) !=
			  scalar(@{$outf_default->[$_]})}
		  (0..$#{$outf_value})) == 0 &&
	   scalar(grep {my $i=$_;scalar(grep {$outf_value->[$i]->[$_] ne
						$outf_default->[$i]->[$_]}
					(0..$#{$outf_value->[$i]}))}
		  (0..$#{$outf_value})) == 0);

	#If the user saved a default for both mutually exclusive options
	if(!$is_suff_default && defined($suff_value) &&
	   !$is_outf_default && defined($outf_value) &&
	   scalar(@$outf_value) > 0)
	  {
	    error("Invalid user defaults saved.  Mutually exclusive options ",
		  "have been saved in the user defaults.");
	    quit(-72);
	  }
	elsif(!$is_suff_default && defined($suff_value))
	  {
	    $outfile_tagteams->{$ttid}->{SUFFDEF} = $suff_value;
	    $outfile_suffix_array->[$suffid_infile_index]
	      ->[$suffid_suffix_index] = $suff_value;
	    debug({LEVEL => -2},"New (user) default suffix: [$suff_value].");
	    if(defined($outf_default) && scalar(@$outf_default))
	      {
		debug({LEVEL => -1},"Clearing out old outfile default.");
		@{$default_infiles_array->[$outfid_infile_index]} = ();
	      }
	  }
	elsif(!$is_outf_default &&
	      defined($outf_value) && scalar(@$outf_value) > 0)
	  {
	    @{$default_infiles_array->[$outfid_infile_index]} =
	      @{$input_files_array->[$outfid_infile_index]};

	    #Clear out the input files array because defaults are added after
	    #the user has added stuff to it from the command line (instead of
	    #how suffix defaults are handled - just check if the value is the
	    #same as the default)
	    @{$input_files_array->[$outfid_infile_index]} = ();

	    debug({LEVEL => -1},"New (user) default outfiles: [",
		  join(' ',map {@$_}
		       @{$default_infiles_array->[$outfid_infile_index]}),
		  "].");

	    if(defined($suff_default))
	      {
		$outfile_tagteams->{$ttid}->{SUFFDEF} = undef;
		#The value for the suffix has to be manipulated because the
		#default is stored in the actual array for the values.
		$outfile_suffix_array->[$suffid_infile_index]
		  ->[$suffid_suffix_index] = undef;
	      }
	  }
	else
	  {debug({LEVEL => -1},"Tagteam [$ttid] doesn't have an option that ",
		 "was changed by user defaults.")}
      }
  }

#This clears out the programmer's array variables so that the user can supply
#default values or explicit values on the command line that replace the
#defaults.  This should be called just before loading the user defaults.
sub clearArrayDefaults
  {
    #Update the default array and 2D array options in case the user supplied
    #defaults.
    foreach my $array_ref (keys(%$array_defaults_hash))
      {if(scalar(@{$array_defaults_hash->{$array_ref}->{VALUES}}))
	 {@{$array_defaults_hash->{$array_ref}->{VALUES}} = ()}}
  }


#This sub is intended to be called after user defaults are loaded, but before
#the command line is processed so that default values can be transferred.  It
#saves any default values and clears out their variables so that if the user
#explicitly supplies any, they will replace the default values instead of add
#to them
sub updateDefaults
  {
    my $user_defaults_exist = $_[0];

    if($user_defaults_exist)
      {
	updateTagteamDefaults();

	#Update the default array and 2D array options in case the user
	#supplied defaults.  If they didn't, the defaults will be added back
	#later in loadDefaults.
	foreach my $array_ref (keys(%$array_defaults_hash))
	  {
	    if(scalar(@{$array_defaults_hash->{$array_ref}->{VALUES}}))
	      {
		@{$array_defaults_hash->{$array_ref}->{DEFAULTS}} =
		  @{$array_defaults_hash->{$array_ref}->{VALUES}};
		@{$array_defaults_hash->{$array_ref}->{VALUES}} = ();
	      }
	  }
      }

    #Update the file options to clear them out.  They will be added back later
    #in loadDefault
    foreach my $file_type_id (0..$#{$input_files_array})
      {
	#If there were any user defaults supplied for the in/outfiles
	if(scalar(@{$input_files_array->[$file_type_id]}))
	  {
	    #Replace any programmer-supplied defaults with the user defaults
	    @{$default_infiles_array->[$file_type_id]} =
	      @{$input_files_array->[$file_type_id]};
	    #Clear the user defaults out of the input_files_array
	    @{$input_files_array->[$file_type_id]} = ();
	  }
      }

    #Update the outdir options to clear them out.  They will be added back
    #later in loadDefault
    #If there were any user defaults supplied for the in/outfiles
    if(scalar(@$outdirs_array))
      {
	#Replace any programmer-supplied defaults with the user defaults
	@$default_outdirs_array = @$outdirs_array;
	#Clear the user defaults out of the outdirs_array
	@$outdirs_array = ();
      }
  }

#Takes an outfile type index and returns the suffix IDs associated with it
sub getSuffixIDs
  {
    my $file_type_index = $_[0];
    if(!defined($file_type_index) ||
       $file_type_index >= scalar(@$input_files_array))
      {
	error("Invalid file type index: [",
	      (defined($file_type_index) ? $file_type_index : 'undef'),
	      "].");
	return(wantarray ? () : []);
      }
    my $suffix_ids = [grep {$suffix_id_lookup->[$_]->[0] == $file_type_index}
		      0..$#{$suffix_id_lookup}];
    return(wantarray ? @$suffix_ids : $suffix_ids);
  }

#Takes an file type index and a suffix index and returns the suffix ID

sub getSuffixID
  {
    my $file_type_index = $_[0];
    my $suffix_index    = $_[1];
    if(!defined($file_type_index) ||
       $file_type_index >= scalar(@$input_files_array))
      {
	error("Invalid file type index: [",
	      (defined($file_type_index) ? $file_type_index : 'undef'),
	      "].");
	return(undef);
      }
    elsif(!defined($suffix_index) ||
	  $suffix_index >=
	  scalar(@{$outfile_suffix_array->[$file_type_index]}))
      {
	error("Invalid suffix index: [",
	      (defined($suffix_index) ? $suffix_index : 'undef'),"].");
	return(undef);
      }
    my $suffix_ids = [grep {$suffix_id_lookup->[$_]->[0] == $file_type_index &&
			      $suffix_id_lookup->[$_]->[1] == $suffix_index}
		      0..$#{$suffix_id_lookup}];
    if(scalar(@$suffix_ids) != 1)
      {
	error("Unable to determine suffix ID from outfile index ",
	      "[$file_type_index] and suffix index [$suffix_index] because ",
	      "it matches [",scalar(@$suffix_ids),"] IDs.");
	return(undef);
      }
    return($suffix_ids->[0]);
  }

#Returns whether any of the submitted subroutine names are in the stack trace
sub isCaller
  {
    my @subs = @_;

    my $stack_level = 0;
    while(my @caller_info = caller($stack_level))
      {
	my $calling_sub = $caller_info[3];
	if(defined($calling_sub))
	  {
	    $calling_sub =~ s/^.*?::(.+)$/$1/;
	    if(scalar(grep {$calling_sub eq $_} @subs))
	      {return(1)}
	  }
	$stack_level++;
      }

    return(0);
  }

sub addOutdirOption
  {
    my @in = getSubParams([qw(FLAG|GETOPTKEY REQUIRED DEFAULT HIDDEN
			      SMRY|SMRY_DESC|SHORT_DESC
			      DETAIL|DETAIL_DESC|LONG_DESC FLAGLESS ADVANCED)],
			  [scalar(@_) ? qw(FLAG|GETOPTKEY) : ()],
			  [@_]);
    my $get_opt_str = $in[0]; #e.g. 'outdir=s'
    my $required    = $in[1]; #Is outdir required?: 0 (false) or non-0 (true)
    my $default     = $in[2]; #e.g. 'output_directory'
    my $hidden      = $in[3]; #0 or non-0. Requires a default. Excludes from
                              #usage output.
    my $smry_desc   = $in[4]; #e.g. 'Input file(s).  See --help for format.'
                              #Empty/undefined = exclude from short usage
    my $detail_desc = $in[5]; #e.g. 'Input file(s).  Space separated,...'
    my $flagless    = $in[6]; #Whether the option can be supplied sans flag
    my $advanced    = $in[7]; #Advanced options print when extended >= 2

    #Trim leading & trailing hard returns and white space characters (from
    #using '<<')
    $smry_desc   =~ s/^\s+//s if(defined($smry_desc));
    $smry_desc   =~ s/\s+$//s if(defined($smry_desc));
    $detail_desc =~ s/^\s+//s if(defined($detail_desc));
    $detail_desc =~ s/\s+$//s if(defined($detail_desc));

    if($command_line_processed)
      {
	error("You cannot add command line options (i.e. call ",
	      "addOutdirOption()) after the command line has already ",
	      "been processed (i.e. processCommandLine()) without at ",
	      "least re-initializing (i.e. calling _init()).");
	return(undef);
      }

    #Defaults mode - Only call with no params once.
    my $adding_default = (scalar(@in) == 0);
    if($adding_default)
      {
	if($default_outdir_added)
	  {
	    error('The default output directory type has already been added.');
	    return(undef);
	  }

	$get_opt_str = removeDupeFlags($default_outdir_opt);
	if(!defined($get_opt_str) || $get_opt_str eq '')
	  {
	    error('Unable to add default output directory type ',
		  "[$default_outdir_opt] due to redundant flags: [",
		  join(',',getDupeFlags($get_opt_str)),'].');
	    $default_outdir_opt = $get_opt_str;
	    return(undef);
	  }
	$default_outdir_opt = $get_opt_str;

	$default_outdir_added = 1;
	$required             = 0;

	if(!visibleOutfileExists())
	  {$hidden = 1}
	#The descriptions are added below
      }

    if(defined($required) && $required !~ /^\d+$/)
      {error("Invalid REQUIRED parameter: [$required].")}

    #Allow the flag to be an array of scalars and turn it into a get opt str
    $get_opt_str = makeGetOptKey($get_opt_str,'outdir',1,'addOutdirOption');

    $get_opt_str = fixStringOpt($get_opt_str);

    if(!isGetOptStrValid($get_opt_str,'outdir'))
      {
	if($adding_default)
	  {warning("Unable to add default output directory option.")}
	else
	  {
	    error("Invalid GetOpt parameter flag definition: [$get_opt_str] ",
		  "for outdir type.");
	    quit(-75);
	  }
	return(undef);
      }

    my $flags = [getOptStrFlags($get_opt_str)];
    my $flag  = getDefaultFlag($flags);

    if($outdirs_added)
      {outdirLimitation(1)}

    $outdirs_added = 1;

    if($hidden && !defined($default) && (defined($required) && $required))
      {
	warning("Cannot hide option [$flag] if",
		(!defined($default) ? ' no default provided' : ''),
		((!defined($default) && defined($required) && $required) ?
		 ' and if' : ''),
		(defined($required) && $required ? ' it is required' : ''),
		".  Setting as not hidden.");
	$hidden = 0;
      }

    #Since multiple outdirs are supported by the code and the default is
    #limited to 1, just make sure the limit is enforced.
    if(defined($default) && ref(\$default) ne 'SCALAR')
      {
	error("Default value supplied must be a scalar.  A [",ref($default),
	      "] was encountered.  Ignoring.");
	undef($default);
      }

    if(defined($default))
      {push(@$default_outdirs_array,[$default])}

    debug({LEVEL=>-1},"Creating an outdir option.");

    #The anonymous sub below references a package variable ($outdirs_array) in
    #the scope of this subroutine.  The interpreter captures only the lexical
    #variables in the scope of this subrotine when it rubs the anonymous sub,
    #thus we must bring the package variable into this scope using our()
    #explicitly because the sub does not otherwise use this variale.  I'm
    #geeking out so hard on this.
    ##TODO: Note, this won't be necessary in the future when I allow more than
    ##      1 outdir type.  See req 212.
    my $tmp = scalar(@$outdirs_array);
    #our($outdirs_array);

    my $getoptsub = 'sub {push(@$outdirs_array,[sglob($_[1])])}';
    $GetOptHash->{$get_opt_str} = eval($getoptsub);

    ##TODO: The outdir flags are messed up and need to be fixed. See req 178
    $outdir_flag_array->[0] = $flag;

    #If no summary usage was provided for this option
    if(!defined($smry_desc) || $smry_desc eq '')
      {
	#If it's a required option, add a default summary
	if($required)
	  {$smry_desc = 'Output directory.'}
	else
	  {$smry_desc = ''}
      }

    if(!defined($detail_desc) || $detail_desc eq '')
      {
	if(defined($smry_desc) && $smry_desc ne '')
	  {$detail_desc = $smry_desc}
	else
	  {$detail_desc =
	     join('',
		  ('Directory in which to put output files.  Creates ',
		   'directories specified, but not recursively.  Also see ',
		   '--extended --help for advanced usage examples.'))}
      }

    if(!defined($default))
      {$default = ''}

    $required_outdirs = $required;

    if(defined($flagless) && $flagless)
      {
	if(defined($flagless_multival_type) && $flagless_multival_type > -1)
	  {
	    error("An additional multi-value option has been designated as ",
		  "'flagless': [$get_opt_str]: [$flagless].  Only 1 is ",
		  "allowed.",
		  {DETAIL => "First flagless option was: [" .
		   getDefaultFlag($usage_array->[$flagless_multival_type]
				  ->{OPTFLAG}) . "]."});
	    return(undef);
	  }

	$getoptsub = 'sub {checkFileOpt($_[0],1);push(@$outdirs_array,' .
	  '[sglob($_[0])])}';
	$GetOptHash->{'<>'} = eval($getoptsub);

	#This assumes that the call to addToUsage a few lines below is the
	#immediate next call to addToUsage
	$flagless_multival_type = getNextUsageIndex();
      }

    addToUsage($get_opt_str,
	       $flags,
	       $smry_desc,
	       $detail_desc,
	       $required,
	       $default,
	       undef,
	       $hidden,
	       'outdir',
	       0,
	       $advanced);
  }

sub outdirLimitation
  {
    my $fatal = $_[0];
    my $flag  = getOutdirFlag();
    my $msg =
      join('',('Currently, only 1 outdir option is supported, however ',
	       'multiple outdirs can be supplied using the 1 outdir option: ',
	       "[$flag].  Files of different output types cannot currently ",
	       'be put in different outdirs, but different sets can go in ',
	       'different dirctories.  See `--help --extended` for examples ',
	       "using the sample $flag option."));
    if($fatal)
      {
	error($msg);
	quit(-7);
      }
    else
      {warning($msg)}
  }

#Returns a boolean as to whether there exists an outfile type that is visible
#(i.e. not hidden)
#Globals used: usage_array
sub visibleOutfileExists
  {
    if(scalar(grep {($_->{OPTTYPE} eq 'outfile' ||
		     $_->{OPTTYPE} eq 'suffix') && !$_->{HIDDEN}}
	      @$usage_array))
      {return(1)}

    return(0);
  }

#Returns a boolean as to whether there exists an outdir type that is visible
#(i.e. not hidden)
#Globals used: usage_array
sub visibleOutdirExists
  {
    if(scalar(grep {($_->{OPTTYPE} eq 'outdir') && !$_->{HIDDEN}}
	      @$usage_array))
      {return(1)}

    return(0);
  }

sub addOption
  {
    my @in = getSubParams([qw(FLAG|GETOPTKEY VARREF|GETOPTVAL TYPE REQUIRED
			      DEFAULT HIDDEN SMRY|SMRY_DESC|SHORT_DESC
			      DETAIL|DETAIL_DESC|LONG_DESC ACCEPTS ADVANCED
			      INTERNAL_ARRAY_REF)],
			  [qw(FLAG|GETOPTKEY VARREF|GETOPTVAL)],
			  [@_]);
    my $get_opt_str     = $in[0]; #e.g. 'o|suffix=s'
    my $get_opt_ref     = $in[1]; #e.g. \$my_option - A reference to a var/sub
    my $type            = $in[2]; #bool,negbool,string,integer,float,enum,count
    my $required        = $in[3]; #Is option required?: 0=false, non-0=true
    my $default         = $in[4]; #e.g. '1'
    my $hidden          = $in[5]; #0 or non-0. non-0 requires a default.
                                  #Excludes from usage output.
    my $smry_desc       = $in[6]; #e.g. Input file(s).  See --help for format.
                                  #Empty/undefined = exclude from short usage
    my $detail_desc     = $in[7]; #e.g. 'Input file(s).  Space separated,...'
    my $accepts         = $in[8]; #e.g. ['yes','no','maybe']
    my $advanced        = $in[9]; #Advanced options print when extended >= 2
    my $internal_array  = $in[10];#For internal use only
    my $internal_delim  = $in[11];#For internal use only

    #Trim leading & trailing hard returns and white space characters (from
    #possibly having used '<<' to define these values)
    $smry_desc   =~ s/^\s+//s if(defined($smry_desc));
    $smry_desc   =~ s/\s+$//s if(defined($smry_desc));
    $detail_desc =~ s/^\s+//s if(defined($detail_desc));
    $detail_desc =~ s/\s+$//s if(defined($detail_desc));

    if($command_line_processed)
      {
	error("You cannot add command line options (i.e. call ",
	      "addOption()) after the command line has already ",
	      "been processed (i.e. processCommandLine()) without at ",
	      "least re-initializing (i.e. calling _init()).");
	return(undef);
      }

    if(defined($required) && $required !~ /^\d+$/)
      {error("Invalid REQUIRED parameter: [$required].")}

    #This validates the type passed in or sets a default if no type info
    #present
    $type = getOptType($type,$get_opt_str,$accepts,$get_opt_ref);
    my $save_getoptstr = $get_opt_str;
    $get_opt_str = makeGetOptKey($get_opt_str,$type,1,'addOption');

    if(!defined($get_opt_str))
      {
	error("Invalid flag definition: [$save_getoptstr].");
	quit(-99);
      }

    my $flags = [getOptStrFlags($get_opt_str)];
    my $flag  = getDefaultFlag($flags);

    if($hidden && !defined($default) && (defined($required) && $required))
      {
	warning("Cannot hide option [$flag] if",
		(!defined($default) ? ' no default provided' : ''),
		((!defined($default) && defined($required) && $required) ?
		 ' and if' : ''),
		(defined($required) && $required ? ' it is required' : ''),
		".  Setting as not hidden.");
	$hidden = 0;
      }

    #Do no check getop str if called by addArrayOption or add2DArrayOption
    my @caller_info = caller(1);
    my $calling_sub = scalar(@caller_info) < 4 ? '' : $caller_info[3];
    debug({LEVEL => -2},"Called by $calling_sub");
    #Array options have already been added, so they have been checked for
    #validity and thus they don't need to have isGetOptStrValid called on them
    my $is_array_opt =
      ($calling_sub =~ /^CommandLineInterface::add(2D)?ArrayOption$/g);
    #Variable options should be checked for validity, but not for duplicates.
    #They are always present though as of the initial _init call, though not
    #always presented in the interface, thus the check should allow duplicates.
    my $is_builtin_opt =
      ($calling_sub =~ /^CommandLineInterface::add(RunMode|Builtin)Options$/g);

    debug({LEVEL => -2},"Allowing duplicates?: $is_builtin_opt");

    if(!$is_array_opt &&
       !isGetOptStrValid($get_opt_str,'general',$is_builtin_opt))
      {
	if($is_builtin_opt)
	  {warning("Unable to add builtin option.",
		   {DETAIL => "GetOptStr: [$get_opt_str]."})}
	else
	  {
	    error("Invalid GetOpt parameter flag definition: [$get_opt_str] ",
		  "for general type.");
	    quit(-76);
	  }
	return(undef);
      }

    #If no summary usage was provided for this option
    if(!defined($smry_desc) || $smry_desc eq '')
      {
	#If it's a required option, add a default summary
	if($required)
	  {$smry_desc = 'No usage summary provided for this option.'}
	else
	  {$smry_desc = ''}
      }

    #If no detailed usage was provided for this option
    if(!defined($detail_desc) || $detail_desc eq '')
      {$detail_desc = 'No usage provided for this option.'}

    if(defined($accepts) &&
       (ref($accepts) ne 'ARRAY' ||
	scalar(@$accepts) != scalar(grep {ref(\$_) eq 'SCALAR'} @$accepts)))
      {
	error("Invalid accepts value passed in.  Only a reference to an ",
	      "array of scalars is valid.  Received a reference to a",
	      (ref($accepts) eq 'ARRAY' ? 'n ARRAY of (' .
	       join(',',map {ref(\$_)} @$accepts) . ')' : ' ' . ref($accepts)),
	      "] instead.");
	return(undef);
      }

    if(defined($accepts))
      {$accepts_hash->{$get_opt_ref} = $accepts}

    $GetOptHash->{$get_opt_str} = $get_opt_ref;

    if(!$is_array_opt)
      {
	if($required)
	  {requireGeneralOption($get_opt_ref,$get_opt_str,$default)}

	$general_flag_hash->{$get_opt_ref} = $flag;
      }

    if(!defined($type))
      {$type = getGeneralOptType($get_opt_str)}

    if(defined($default) && $default ne '' && $detail_desc !~ /^\[/ &&
       showDefault($type,$get_opt_ref,$default))
      {$detail_desc = "[$default] $detail_desc"}

    addToUsage($get_opt_str,
	       $flags,
	       $smry_desc,
	       $detail_desc,
	       $required,
	       $default,
	       $accepts,
	       $hidden,
	       $type,
	       0,
	       $advanced,
	       $internal_array,
	       $internal_delim);
  }

#Checks the validity of values (ignores undefs because they're handled by the
#requirement checking code)
#Globals used: $usage_array, $GetOptHash
sub validateNonFileOptions
  {
    my $checktypehash = {%$genopt_types};
    my $status = 1;

    #For every option that's been supplied a defined reference of a known type
    foreach my $usghash (grep {exists($GetOptHash->{$_->{GETOPTKEY}}) &&
				 defined($GetOptHash->{$_->{GETOPTKEY}}) &&
				   defined($_->{OPTTYPE}) &&
				     exists($checktypehash->{$_->{OPTTYPE}})}
			 @$usage_array)
      {
	my $varref  = $GetOptHash->{$usghash->{GETOPTKEY}};
	my $aryref  = $usghash->{GETOPTREF};
	my $opttype = $usghash->{OPTTYPE};
	my $flag    = getDefaultFlag($usghash->{OPTFLAG});
	my $accepts = $usghash->{ACCEPTS};

	#The following types do not need to be checked because either Getopt::
	#Long checks them or we don't have a reference to the variable (e.g. we
	#have a reference to a subroutine) so we don't have a value to
	#interrogate:
	#bool,negbool, integer,float,string

	if($opttype eq 'enum' && ref($varref) ne 'CODE')
	  {
	    if(ref($varref) ne 'SCALAR')
	      {
		error("Invalid enum reference [",ref($varref),
		      "] supplied to [$flag].",
		      {DETAIL => 'Should be a scalar reference.'});
		$status = 0;
	      }
	    elsif(defined($$varref) && !validateEnum($$varref,$accepts,$flag))
	      {$status = 0}
	  }
	elsif($opttype =~ /_array$/)
	  {
	    if(ref($aryref) ne 'ARRAY' ||
	       scalar(grep {ref($_) ne ''} @$aryref))
	      {
		error("Invalid array [",
		      (ref($aryref) eq 'ARRAY' ? 'ARRAY REF of ' .
		       join(',',map {ref($_) eq '' ?
				       'SCALAR' : ref($_) . ' REF'} @$aryref) :
		       ref($aryref)),"] supplied to [$flag].",
		      {DETAIL => ('Should be a reference to an ARRAY of ' .
				  'SCALARs.')});
		$status = 0;
	      }
	    else
	      {
		if($opttype eq 'float_array')
		  {
		    my $bads = [grep {!isFloat($_)} @$aryref];
		    if(scalar(@$bads))
		      {
			error("Invalid float value(s) [",join(',',@$bads),
			      "] supplied to [$flag].");
			$status = 0;
		      }
		  }
		elsif($opttype eq 'integer_array')
		  {
		    my $bads = [grep {!isInt($_)} @$aryref];
		    if(scalar(@$bads))
		      {
			error("Invalid integer value(s) [",join(',',@$bads),
			      "] supplied to [$flag].");
			$status = 0;
		      }
		  }
		elsif($opttype eq 'string_array')
		  {
		    #Nothing to check.  Anything goes.
		  }
		elsif($opttype eq 'enum_array')
		  {
		    if(scalar(grep {!validateEnum($_,$accepts,$flag)}
			      @$aryref))
		      {$status = 0}
		  }
	      }
	  }
	elsif($opttype =~ /_array2d$/)
	  {
	    if(ref($aryref) ne 'ARRAY' ||
	       scalar(grep {my $ar=$_;
			    (defined($ar) && ref($ar) ne 'ARRAY') ||
			      (defined($ar) &&
			       scalar(grep {defined($_) &&
					      ref($_) ne ''} @$ar))} @$aryref))
	      {
		error("Invalid 2D array [",
		      (ref($aryref) eq 'ARRAY' ?
		       'ARRAY REF of ' .
		       join(';',
			    map {my $ar=$_;
				 ref($ar) eq 'ARRAY' ?
				   'ARRAY REF of ' .
				     join(',',
					  map {ref($_) eq '' ?
						 'SCALAR' : ref($_) . ' REF'}
					  @$ar) :
					    (ref($ar) eq '' ?
					     'SCALAR' : ref($ar) . ' REF')}
			    @$aryref) :
		       (ref($aryref) eq '' ?
			'SCALAR' : ref($aryref) . ' REF')),
		      "] supplied to [$flag].",
		      {DETAIL => ('Should be an ARRAY REF of ARRAY REFs of ' .
				  'SCALARs.')});
		$status = 0;
	      }
	    else
	      {
		if($opttype eq 'integer_array2d')
		  {
		    if(scalar(grep {!isInt($_)}
			      map {my $ar=$_;grep {defined($_)} @$ar}
			      grep {my $ar=$_;defined($ar) &&
				      scalar(grep {defined($_)} @$ar)}
			      @$aryref))
		      {
			my $bads = [grep {!isInt($_)}
				    map {my $ar=$_;grep {defined($_)} @$ar}
				    grep {my $ar=$_;defined($ar) &&
					    scalar(grep {defined($_)} @$ar)}
				    @$aryref];
			error("Invalid integer value(s) [",join(',',@$bads),
			      "] supplied to [$flag].");
			$status = 0;
		      }
		  }
		elsif($opttype eq 'float_array2d')
		  {
		    if(scalar(grep {!isFloat($_)}
			      map {my $ar=$_;grep {defined($_)} @$ar}
			      grep {my $ar=$_;defined($ar) &&
				      scalar(grep {defined($_)} @$ar)}
			      @$aryref))
		      {
			my $bads = [grep {!isInt($_)}
				    map {my $ar=$_;grep {defined($_)} @$ar}
				    grep {my $ar=$_;defined($ar) &&
					    scalar(grep {defined($_)} @$ar)}
				    @$aryref];
			error("Invalid integer value(s) [",join(',',@$bads),
			      "] supplied to [$flag].");
			$status = 0;
		      }
		  }
		elsif($opttype eq 'string_array2d')
		  {
		    #Nothing to check.  Anything goes.
		  }
		elsif($opttype eq 'enum_array2d')
		  {
		    if(scalar(grep {!validateEnum($_,$accepts,$flag)}
			      map {my $ar=$_;grep {defined($_)} @$ar}
			      grep {my $ar=$_;defined($ar) &&
				      scalar(grep {defined($_)} @$ar)}
			      @$aryref))
		      {
			my $bads = [grep {!isInt($_)}
				    map {my $ar=$_;grep {defined($_)} @$ar}
				    grep {my $ar=$_;defined($ar) &&
					    scalar(grep {defined($_)} @$ar)}
				    @$aryref];
			error("Invalid integer value(s) [",join(',',@$bads),
			      "] supplied to [$flag].");
			$status = 0;
		      }
		  }
	      }
	  }
      }

    verbose({LEVEL => 3},"All supplied values validated.") if($status);

    return($status);
  }

#Returns true if value is undefined or (defined and is in the accepts array)
sub validateEnum
  {
    my $value   = $_[0];
    my $accepts = $_[1];
    my $flag    = $_[2]; #For error reporting
    my $status  = 1; #validated

    if(defined($accepts))
      {
	if(ref($accepts) ne 'ARRAY' || scalar(@$accepts) == 0)
	  {
	    error("Invalid or unsupplied ACCEPTS array supplied to ",
		  "[$flag].");
	    $status = 0;
	  }
	elsif(scalar(grep {$_ eq $value} @$accepts) == 0)
	  {
	    error("Unrecognized value [$value] supplied to [$flag].  Must be ",
		  "one of: [",join(',',@$accepts),"].");
	    $status = 0;
	  }
      }
    else
      {
	error("ACCEPTS array is required for TYPE enum for the ",
	      "option defined by [$flag].",
	      {DETAIL => ('Add a value for ACCEPTS to the call to ' .
			  'addOption() for [$flag].')});
	$status = 0;
      }

    return($status);
  }

#Returns one of the following strings: bool,negbool,count,scalar,unk.
#Used by addToUsage and getSummaryOptStr
sub getGeneralOptType
  {
    my $get_opt_str = $_[0];
    if(!defined($get_opt_str) || $get_opt_str eq '')
      {return('unk')}
    elsif($get_opt_str =~ /\!$/)
      {return('negbool')}
    elsif($get_opt_str =~ /=i$/)
      {return('integer')}
    elsif($get_opt_str =~ /=f$/)
      {return('float')}
    elsif($get_opt_str =~ /=\S$/)
      {return('string')}
    elsif($get_opt_str =~ /\+$/)
      {return('count')}
    elsif($get_opt_str !~ /[:!\+=]/)
      {return('bool')}
    else
      {return('unk')}
  }

sub addArrayOption
  {
    my @in = getSubParams([qw(FLAG|GETOPTKEY VARREF|GETOPTVAL TYPE REQUIRED
			      DEFAULT HIDDEN SMRY|SMRY_DESC|SHORT_DESC
			      DETAIL|DETAIL_DESC|LONG_DESC DELIMITER ACCEPTS
			      FLAGLESS INTERPOLATE ADVANCED)],
			  [qw(FLAG|GETOPTKEY VARREF|GETOPTVAL)],
			  [@_]);
    my $get_opt_str = $in[0]; #e.g. 'o|suffix=s'
    my $get_opt_ref = $in[1]; #e.g. $my_option - A reference to an array
    my $type        = $in[2]; #e.g. [string],integer,float,enum
    my $required    = $in[3]; #Is option required?: 0=false, non-0=true
    my $default     = $in[4]; #e.g. '1'
    my $hidden      = $in[5]; #0 or non-0. non-0 requires a default.
                              #Excludes from usage output.
    my $smry_desc   = $in[6]; #e.g. Input file(s).  See --help for format.
                              #Empty/undefined = exclude from short usage
    my $detail_desc = $in[7]; #e.g. 'Input file(s).  Space separated,...'
    my $delimiter   = $in[8]; #Split what is supplied if defined. Defaults
                              #to non-number chars if type is integer or
                              #float, non-accepts chars if enum, and undef
                              #if string
    my $accepts     = $in[9]; #e.g. ['yes','no']
    my $flagless    = $in[10];#Whether the option can be supplied sans flag
    my $interpolate = $in[11];#For backward compatibility
    my $advanced    = $in[12];#Advanced options print when extended >= 2

    #Trim leading & trailing hard returns and white space characters (from
    #using '<<')
    $smry_desc   =~ s/^\s+//s if(defined($smry_desc));
    $smry_desc   =~ s/\s+$//s if(defined($smry_desc));
    $detail_desc =~ s/^\s+//s if(defined($detail_desc));
    $detail_desc =~ s/\s+$//s if(defined($detail_desc));

    #Validate the accepts parameter
    if(defined($accepts) &&
       (ref($accepts) ne 'ARRAY' ||
	scalar(@$accepts) != scalar(grep {ref(\$_) eq 'SCALAR'} @$accepts)))
      {
	error("Invalid accepts value passed in.  Only a reference to an ",
	      "array of scalars is valid.  Received a reference to a",
	      (ref($accepts) eq 'ARRAY' ? 'n ARRAY of (' .
	       join(',',map {ref(\$_)} @$accepts) . ')' : ' ' . ref($accepts)),
	      "] instead.");
	return(undef);
      }

    #Validate or set the default of the type parameter
    if(defined($type) && $type ne 'string' && $type ne 'integer' &&
       $type ne 'float' && $type ne 'enum')
      {
	error("Invalid TYPE [$type].  Only string, integer, float, or enum ",
	      "are allowed.");
	quit(-96);
      }
    elsif(!defined($type))
      {
	if(ref($get_opt_str)    eq '' && $get_opt_str =~ /=i$/)
	  {$type = 'integer'}
	elsif(ref($get_opt_str) eq '' && $get_opt_str =~ /=f$/)
	  {$type = 'float'}
	elsif(defined($accepts))
	  {$type = 'enum'}
	else
	  {$type = 'string'}
      }

    #Allow the flag to be an array of scalars and turn it into a get opt str
    my $save_getoptstr = $get_opt_str;
    $get_opt_str = makeGetOptKey($get_opt_str,$type,1,'addArrayOption');

    if(defined($get_opt_str))
      {$get_opt_str = fixStringOpt($get_opt_str,1)}

    if(!isGetOptStrValid($get_opt_str,'1darray'))
      {quit(-77)}

    #Validate the type & accepts combo
    if($type eq 'enum' && (!defined($accepts) || scalar(@$accepts) == 0))
      {
	error("ACCEPTS is required if TYPE is enum.");
	return(undef);
      }
    elsif($type ne 'enum' && defined($accepts))
      {
	warning("ACCEPTS is ignored when TYPE is not enum.",
		{DETAIL => ('Remove the ACCEPTS parameter to eliminate this ' .
			    'warning.')});
	undef($accepts);
      }

    #Set the default delimiter based on the type
    if(!defined($delimiter))
      {
	if($type eq 'integer')
	  {$delimiter = '[^\d+\-eE]+'}
	elsif($type eq 'float')
	  {$delimiter = '[^\d+\-eE\.]+'}
	elsif($type eq 'enum')
	  {$delimiter = '[^' . join('',@$accepts) . ']+'}
	elsif(defined($interpolate) && $interpolate)
	  {$delimiter = '\s+'}
	#No default delimiter defined for type str
      }
    elsif(length($delimiter) == 1)
      {$delimiter = "$delimiter+"}
    elsif(length($delimiter) > 1)
      {$delimiter = "(?:$delimiter)+"}

    #Strip junk off the get opt str
    $get_opt_str =~ s/[=+:\@\%!].*//;
    #Make type a string so multiple vals can be parsed with a non-num delimiter
    $get_opt_str .= '=s';

    if($command_line_processed)
      {
	error("You cannot add command line options (i.e. call ",
	      "addArrayOption()) after the command line has already ",
	      "been processed (i.e. processCommandLine()) without at ",
	      "least re-initializing (i.e. calling _init()).");
	return(undef);
      }

    if(defined($required) && $required !~ /^\d+$/)
      {error("Invalid REQUIRED parameter: [$required].")}

    my $flags = [getOptStrFlags($get_opt_str)];
    my $flag  = getDefaultFlag($flags);

    if($hidden && !defined($default) && (defined($required) && $required))
      {
	warning("Cannot hide option [$flag] if",
		(!defined($default) ? ' no default provided' : ''),
		((!defined($default) && defined($required) && $required) ?
		 ' and if' : ''),
		(defined($required) && $required ? ' it is required' : ''),
		".  Setting as not hidden.");
	$hidden = 0;
      }

    #If no summary usage was provided for this option
    if(!defined($smry_desc) || $smry_desc eq '')
      {
	#If it's a required option, add a default summary
	if($required)
	  {$smry_desc = 'No usage summary provided for this option.'}
	else
	  {$smry_desc = ''}
      }

    #If no detailed usage was provided for this option
    if(!defined($detail_desc) || $detail_desc eq '')
      {$detail_desc =
	 join('',('No detailed usage provided for this array option.'))}

    my $disp_delim = getDisplayDelimiter($delimiter,$type,$accepts);
    if(defined($disp_delim) && length($disp_delim) > 1)
      {$detail_desc .= "\n\nValues are delimited using this perl regular " .
	 "expression: [$disp_delim]."}

    my $sub;
    if(defined($get_opt_ref) && ref($get_opt_ref) eq 'ARRAY')
      {
	if(!defined($delimiter))
	  {$sub = sub {push(@$get_opt_ref,$_[1])}}
	else
	  {$sub = sub {push(@$get_opt_ref,split(/$delimiter/,$_[1]))}}
      }
    else
      {
	error("Invalid array variable.  The second parameter must be a ",
	      "reference to an array, but got a reference to [",
	      ref($get_opt_ref),"].");
	return(undef);
      }

    #addOption would add the sub I send it, which can't be checked for required
    #values having been supplied, so we'll do it here and prevent it in
    #addOption
    if($required)
      {requireGeneralOption($get_opt_ref,$get_opt_str,$default)}

    $general_flag_hash->{$get_opt_ref} = $flag;

    #Save any default values, but don't clear out the programmer's variable
    #(yet - see loadUserDefaults)
    $array_defaults_hash->{$get_opt_ref}->{DEFAULTS} = [@$get_opt_ref];
    $array_defaults_hash->{$get_opt_ref}->{VALUES}   = $get_opt_ref;

    my $def_str = $default;
    if(ref($default) eq 'ARRAY' && scalar(grep {ref($_) ne ''} @$default) == 0)
      {$def_str = join(',',map {defined($_) ? $_ : 'undef'} @$default)}
    elsif(ref($def_str) ne '')
      {warning("Default value supplied to addArrayOption should either be a ",
	       "scalar or a reference to an array of scalars.")}

    if(defined($flagless) && $flagless)
      {
	if(defined($flagless_multival_type) && $flagless_multival_type > -1)
	  {
	    error("An additional multi-value option has been designated as ",
		  "'flagless': [$get_opt_str]: [$flagless].  Only 1 is ",
		  "allowed.",
		  {DETAIL => "First flagless option was: [" .
		   getDefaultFlag($usage_array->[$flagless_multival_type]
				  ->{OPTFLAG}) . "]."});
	    return(undef);
	  }

	my $getoptsub;
	if(defined($delimiter))
	  {$getoptsub = sub {push(@$get_opt_ref,split(/$delimiter/,$_[0]))}}
	else
	  {$getoptsub = sub {push(@$get_opt_ref,$_[0])}}
	#No need to do an else, because it would have caused a return above
	$GetOptHash->{'<>'} = $getoptsub;

	#This assumes that the call to addToUsage a few lines below is the
	#immediate next call to addToUsage
	$flagless_multival_type = getNextUsageIndex();
      }

    addOption($get_opt_str,
	      $sub,
	      $type . '_array',
	      $required,
	      $def_str,
	      $hidden,
	      $smry_desc,
	      $detail_desc,
	      $accepts,
	      $advanced,
	      $get_opt_ref,
	      $delimiter);
  }

#Returns a single character that will work as a delimiter because it matches
#the regular expression the programmer supplied
sub getDisplayDelimiter
  {
    my $delim   = $_[0];
    my $type    = $_[1];
    my $accepts = $_[2];

    if(!defined($delim))
      {return(undef)}
    if($delim eq '')
      {return($delim)}

    my $dispdelims = [',', ';', ':', '|', '~', ' '];
    my $dispdelim  = $delim;

    if($type eq 'enum')
      {
	my $enumchars = join('',@$accepts);
	if($enumchars =~ /$delim/)
	  {
	    error("Delimiter [$delim] matches one or more of the characters ",
		  "in the enumeration values: [",join(' ',@$accepts),"].");
	    quit(-103);
	  }

	if($delim =~ /^(.)\+$/)
	  {return($1)}

	foreach my $potentialdispdelim (@$dispdelims)
	  {
	    if($potentialdispdelim =~ /$delim/ &&
	       $enumchars !~ /\Q$potentialdispdelim\E/)
	      {
		$dispdelim = $potentialdispdelim;
		last;
	      }
	  }
      }
    else
      {
	if($delim =~ /^(.)\+$/)
	  {return($1)}

	foreach my $potentialdispdelim (@$dispdelims)
	  {
	    if($potentialdispdelim =~ /$delim/)
	      {
		$dispdelim = $potentialdispdelim;
		last;
	      }
	  }
      }

    return($dispdelim);
  }

sub add2DArrayOption
  {
    my @in = getSubParams([qw(FLAG|GETOPTKEY VARREF|GETOPTVAL TYPE REQUIRED
			      DEFAULT HIDDEN SMRY|SMRY_DESC|SHORT_DESC
			      DETAIL|DETAIL_DESC|LONG_DESC ACCEPTS FLAGLESS
			      DELIMITER ADVANCED)],
			  [qw(FLAG|GETOPTKEY VARREF|GETOPTVAL)],
			  [@_]);
    my $get_opt_str = $in[0]; #e.g. 'o|suffix=s'
    my $get_opt_ref = $in[1]; #e.g. $my_option - A reference to an array
    my $type        = $in[2]; #e.g. [string],integer,float,enum
    my $required    = $in[3]; #Is option required?: 0=false, non-0=true
    my $default     = $in[4]; #e.g. '1'
    my $hidden      = $in[5]; #0 or non-0. non-0 requires a default.
                              #Excludes from usage output.
    my $smry_desc   = $in[6]; #e.g. Input file(s).  See --help for format.
                              #Empty/undefined = exclude from short usage
    my $detail_desc = $in[7]; #e.g. 'Input file(s).  Space separated,...'
    my $accepts     = $in[8]; #e.g. ['yes','no']
    my $flagless    = $in[9]; #Whether the option can be supplied sans flag
    my $delimiter   = $in[10];#Split what is supplied if defined. Defaults
                              #to non-number chars if type is integer or
                              #float, non-accepts chars if enum, and space
                              #if string
    my $advanced    = $in[12];#Advanced options print when extended >= 2

    #Trim leading & trailing hard returns and white space characters (from
    #using '<<')
    $smry_desc   =~ s/^\s+//s if(defined($smry_desc));
    $smry_desc   =~ s/\s+$//s if(defined($smry_desc));
    $detail_desc =~ s/^\s+//s if(defined($detail_desc));
    $detail_desc =~ s/\s+$//s if(defined($detail_desc));

    #Validate the accepts parameter
    if(defined($accepts) &&
       (ref($accepts) ne 'ARRAY' ||
	scalar(@$accepts) != scalar(grep {ref(\$_) eq 'SCALAR'} @$accepts)))
      {
	error("Invalid accepts value passed in.  Only a reference to an ",
	      "array of scalars is valid.  Received a reference to a",
	      (ref($accepts) eq 'ARRAY' ? 'n ARRAY of (' .
	       join(',',map {ref(\$_)} @$accepts) . ')' : ' ' . ref($accepts)),
	      "] instead.");
	return(undef);
      }

    #Validate or set the default of the type parameter
    if(defined($type) && $type ne 'string' && $type ne 'integer' &&
       $type ne 'float' && $type ne 'enum')
      {
	error("Invalid TYPE [$type].  Only string, integer, float, or enum ",
	      "are allowed.");
	quit(-97);
      }
    elsif(!defined($type))
      {
	if(ref($get_opt_str)    eq '' && $get_opt_str =~ /=i$/)
	  {$type = 'integer'}
	elsif(ref($get_opt_str) eq '' && $get_opt_str =~ /=f$/)
	  {$type = 'float'}
	elsif(defined($accepts))
	  {$type = 'enum'}
	else
	  {$type = 'string'}
      }

    #Allow the flag to be an array of scalars and turn it into a get opt str
    $get_opt_str = makeGetOptKey($get_opt_str,$type,1,'add2DArrayOption');

    #Validate the type & accepts combo
    if($type eq 'enum' && (!defined($accepts) || scalar(@$accepts) == 0))
      {
	error("ACCEPTS is required if TYPE is enum.");
	return(undef);
      }
    elsif($type ne 'enum' && defined($accepts))
      {
	warning("ACCEPTS is ignored when TYPE is not enum.",
		{DETAIL => ('Remove the ACCEPTS parameter to eliminate this ' .
			    'warning.')});
	undef($accepts);
      }

    #Set the default delimiter based on the type
    if(!defined($delimiter))
      {
	if($type eq 'integer')
	  {$delimiter = '[^\d+\-eE]+'}
	elsif($type eq 'float')
	  {$delimiter = '[^\d+\-eE\.]+'}
	elsif($type eq 'enum')
	  {$delimiter = '[^' . join('',@$accepts) . ']+'}
	else
	  {$delimiter = '\s+'}
      }
    elsif(length($delimiter) == 1)
      {$delimiter = "$delimiter+"}
    elsif(length($delimiter) > 1)
      {$delimiter = "(?:$delimiter)+"}

    if(defined($get_opt_str))
      {
	#Strip junk off the get opt str
	$get_opt_str =~ s/[=+:\@\%!].*//;
	#Make type a string so multiple vals can be parsed with a non-num
	#delimiter
	$get_opt_str .= '=s';
      }

    if($command_line_processed)
      {
	error("You cannot add command line options (i.e. call ",
	      "add2DArrayOption()) after the command line has already ",
	      "been processed (i.e. processCommandLine()) without at ",
	      "least re-initializing (i.e. calling _init()).");
	return(undef);
      }

    if(defined($required) && $required !~ /^\d+$/)
      {error("Invalid REQUIRED parameter: [$required].")}

    $get_opt_str = fixStringOpt($get_opt_str,1);

    if(!isGetOptStrValid($get_opt_str,'2darray'))
      {
	error("Invalid GetOpt parameter flag definition: [$get_opt_str] for ",
	      "2darray type.");
	quit(-78);
      }

    my $flags = [getOptStrFlags($get_opt_str)];
    my $flag  = getDefaultFlag($flags);

    if($hidden && !defined($default) && (defined($required) && $required))
      {
	warning("Cannot hide option [$flag] if",
		(!defined($default) ? ' no default provided' : ''),
		((!defined($default) && defined($required) && $required) ?
		 ' and if' : ''),
		(defined($required) && $required ? ' it is required' : ''),
		".  Setting as not hidden.");
	$hidden = 0;
      }

    #If no summary usage was provided for this option
    if(!defined($smry_desc) || $smry_desc eq '')
      {
	#If it's a required option, add a default summary
	if($required)
	  {$smry_desc = 'No usage summary provided for this option.'}
	else
	  {$smry_desc = ''}
      }

    #If no detailed usage was provided for this option
    if(!defined($detail_desc) || $detail_desc eq '')
      {$detail_desc =
	 join('',('No detailed usage provided for this 2D array option.'))}

    my $disp_delim = getDisplayDelimiter($delimiter,$type,$accepts);
    if(defined($disp_delim) && length($disp_delim) > 1)
      {$detail_desc .= "\n\nInner array elements are delimited from the " .
	 "value given to a single flag using this perl regular expression: " .
	   "[$disp_delim]."}

    my $sub;
    if(defined($get_opt_ref) &&
       ref($get_opt_ref) eq 'SCALAR' && ref($$get_opt_ref) eq 'ARRAY')
      {$sub = sub {push(@{$$get_opt_ref},[split(/$delimiter/,$_[1])])}}
    elsif(defined($get_opt_ref) && ref($get_opt_ref) eq 'ARRAY')
      {$sub = sub {push(@{$get_opt_ref},[split(/$delimiter/,$_[1])])}}
    else
      {
	error("Invalid array variable.  The second option must be a ",
	      "reference to an array which was instantiated before calling ",
	      "this method.");
	return(undef);
      }

    #addOption would add the sub I send it, which can't be checked for required
    #values having been supplied, so we'll do it here and prevent it in
    #addOption
    if($required)
      {requireGeneralOption($get_opt_ref,$get_opt_str,$default)}

    $general_flag_hash->{$get_opt_ref} = $flag;

    #Save any default values, but don't clear out the programmer's variable
    #(yet - see loadUserDefaults)
    $array_defaults_hash->{$get_opt_ref}->{DEFAULTS} = [@$get_opt_ref];
    $array_defaults_hash->{$get_opt_ref}->{VALUES}   = $get_opt_ref;

    my $def_str = $default;
    if(ref($default) eq 'ARRAY' &&
       scalar(grep {ref($_) ne 'ARRAY'} @$default) == 0 &&
       scalar(grep {my $a=$_;scalar(grep {ref($_) ne ''} @$a)} @$default) == 0)
      {$def_str =
	 '(' . join('),(',map {my $a=$_;'(' .
				 join('),(',map {defined($_) ? $_ : 'undef'}
				      @$a) . ')'} @$default) . ')'}
    elsif(ref($def_str) ne '')
      {warning("Default value supplied to addArrayOption should either be a ",
	       "scalar or a reference to an array of references to arrays of ",
	       "scalars.")}

    if(defined($flagless) && $flagless)
      {
	if(defined($flagless_multival_type) && $flagless_multival_type > -1)
	  {
	    error("An additional multi-value option has been designated as ",
		  "'flagless': [$get_opt_str]: [$flagless].  Only 1 is ",
		  "allowed.",
		  {DETAIL => "First flagless option was: [" .
		   getDefaultFlag($usage_array->[$flagless_multival_type]
				  ->{OPTFLAG}) . "]."});
	    return(undef);
	  }

	my $getoptsub;
	if(defined($get_opt_ref) &&
	   ref($get_opt_ref) eq 'SCALAR' && ref($$get_opt_ref) eq 'ARRAY')
	  {$getoptsub =
	     sub {push(@{$$get_opt_ref},[split(/$delimiter/,$_[0])])}}
	elsif(defined($get_opt_ref) && ref($get_opt_ref) eq 'ARRAY')
	  {$getoptsub = sub {push(@{$get_opt_ref},[split(/$delimiter/,$_[0])])}}
	#No need to do an else, because it would have caused a return above
	$GetOptHash->{'<>'} = $getoptsub;

	#This assumes that the call to addToUsage a few lines below is the
	#immediate next call to addToUsage
	$flagless_multival_type = getNextUsageIndex();
      }

    addOption($get_opt_str,
	      $sub,
	      $type . '_array2d',
	      $required,
	      $def_str,
	      $hidden,
	      $smry_desc,
	      $detail_desc,
	      $accepts,
	      $advanced,
	      $get_opt_ref,
	      $delimiter);
  }

sub requireGeneralOption
  {
    my $ref = $_[0];
    my $key = $_[1];
    my $def = $_[2];

    push(@$required_opt_refs,[$ref,$key,$def]);
  }

sub wasGeneralOptionSupplied
  {
    my $opt_info = $_[0];

    my $opt_ref = $opt_info->[0];

    if(!defined($opt_ref))
      {return(0)}

    #Note, these are best guesses.  For example if the option takes an
    #array, and it's intended to be a 2D array and an empty inner
    #array is added to start, this would think values have been
    #supplied when essentially they haven't.  I should more
    #intelligently handle defaults for all types instead of just
    #default strings for usage display (e.g. 'none' for no default).
    #TODO: See req 214

    if(ref($opt_ref) eq 'SCALAR' && !defined($$opt_ref))
      {return(0)}
    #Arrays are cleared out before & after user defaults are loaded
    #and then re-loaded in loadDefaults, which may not have been
    #called yet, so we're checking for defaults here...
    elsif(ref($opt_ref) eq 'ARRAY' && scalar(@$opt_ref) == 0 &&
	  scalar(@{$array_defaults_hash->{$opt_ref}->{DEFAULTS}}) == 0)
      {return(0)}
    elsif(ref($opt_ref) eq 'HASH' && scalar(keys(%$opt_ref)) == 0)
      {return(0)}
    elsif(ref($opt_ref) ne 'SCALAR' && ref($opt_ref) ne 'ARRAY' &&
	  ref($opt_ref) ne 'HASH')
      {
	my $def = $opt_info->[2];
	#We're going to trust that if the user supplied a default string, they
	#are handling the default after-the-fact themselves
	if(defined($def))
	  {return(1)}

	my @flags = getOptStrFlags($opt_info->[1]);
	if(scalar(grep {my $arg=$_;scalar(grep {$_ eq $arg} @flags)}
		  @$preserve_args) == 0)
	  {return(0)}
      }

    return(1);
  }

sub addOptions
  {
    my @in = getSubParams([qw(GETOPTHASH REQUIRED OVERWRITE RENAME ADVANCED)],
			  [qw(GETOPTHASH)],
			  [@_]);
    my $getopthash = $in[0];
    my $required   = $in[1]; #Are all these opts required?: 0=false, non-0=true
                             #Call once for all required opts & once for others
    my $commandeer = $in[2]; #Deactivate a default option that you wish to
                             #handle yourself. If a key in the getopthash
                             #matches a pre-existing key, delete and overwrite
                             #it. The associated code will run or not run based
                             #on the built-in default value.
    my $rename     = $in[3]; #0=false, >0=true, <0=ignore. If the reference to
                             #the variable already exists as a value in the
                             #getopts hash, delete and remake the key-value
                             #pair using the existing key.
    my $advanced   = $in[4]; #Advanced options print when extended >= 2

    if($command_line_processed)
      {
	error("You cannot add command line options (i.e. call ",
	      "addOptions()) after the command line has already ",
	      "been processed (i.e. processCommandLine()) without at ",
	      "least re-initializing (i.e. calling _init()).");
	return(undef);
      }

    if(!defined($getopthash) || ref($getopthash) ne 'HASH')
      {
	error("Required first parameters (GETOPTHASH) must be a reference to ",
	      "a HASH, but [",
	      (defined($getopthash) ?
	       (ref($getopthash) eq '' ?
		'a non-reference' :
		'a reference to a [' . ref($getopthash) . ']') :
	       'an undefined value'),"] was sent in.");
	quit(-8);
      }

    if(defined($required) && $required !~ /^\d+$/)
      {error("Invalid REQUIRED parameter: [$required].")}

    foreach my $get_opt_str (keys(%$getopthash))
      {
	if(!isGetOptStrValid($get_opt_str,'general'))
	  {
	    error("Invalid GetOpt parameter flag definition: [$get_opt_str] ",
		  "for general type.");
	    quit(-79);
	  }

	if((!defined($commandeer) || !$commandeer) &&
	   exists($GetOptHash->{$get_opt_str}))
	  {
	    error("Option [$get_opt_str] is a built-in option.  Set ",
		  "\$commandeer to true to supply your own functionality.  ",
		  "Note to also set the built-in function's default to ",
		  "deactivate it.");
	    next;
	  }

	my $delkeys = [grep {$GetOptHash->{$_} eq $getopthash->{$get_opt_str}}
		       keys(%$GetOptHash)];
	if(scalar(@$delkeys))
	  {
	    if(defined($rename) && $rename > 0)
	      {delete($GetOptHash->{$delkeys->[$_]}) foreach(@$delkeys)}
	    elsif(!defined($rename) || $rename == 0)
	      {
		error("These options [",join(', ',@$delkeys),"] point to the ",
		      "same variable reference as new option ",
		      "[$get_opt_str].  Set \$rename to either ignore (and ",
		      "allow multiple options to control the same variable) ",
		      "or to replace the option name.");
		next;
	      }
	  }

	if($required)
	  {requireGeneralOption($getopthash->{$get_opt_str},
				$get_opt_str,
				undef)}

	$GetOptHash->{$get_opt_str} = $getopthash->{$get_opt_str};

	my $genopttype = getGeneralOptType($get_opt_str);

	#Let's do what we can...
	my $default = getDefaultStr($getopthash->{$get_opt_str});
	my $flags = [getOptStrFlags($get_opt_str)];
	my $desc = (!showDefault($genopttype,$getopthash->{$get_opt_str},
				 $default) ? '' :
		    (!defined($default) ? '[] ' :
		     ($default eq '' ? "[''] " : "[$default] "))) .
		       'No description supplied.  Programmer note: Use ' .
			 'addOption() instead of addOptions(), or use ' .
			   'addToUsage() to supply a usage.';

	addToUsage($get_opt_str,
		   $flags,
		   undef,
		   $desc,
		   0,
		   (ref($getopthash->{$get_opt_str}) eq 'SCALAR' ?
		    ${$getopthash->{$get_opt_str}} :
		    $getopthash->{$get_opt_str}),
		   undef,
		   0,
		   getGeneralOptType($get_opt_str),
		   0,
		   $advanced);
      }
  }

sub getDefaultStr
  {
    my $ref = $_[0];
    my($str);

    if(ref($ref) eq 'SCALAR')
      {$str = $$ref}
    elsif(ref($ref) eq 'ARRAY' &&
	  scalar(@$ref) == scalar(grep {ref(\$_) eq 'SCALAR'} @$ref))
      {$str = join(',',@$ref)}
    elsif(ref($ref) eq 'HASH' && scalar(keys(%$ref)) ==
	  scalar(grep {ref(\$_) eq 'SCALAR'} values(%$ref)))
      {$str = join(',',map {"$_=$ref->{$_}"} keys(%$ref))}

    my $def_str = clipStr($str,30);

    return($def_str);
  }

#Truncates a string to a given length and adds an elipsis to indicate it was
#truncated (if the trim length is long enough)
sub clipStr
  {
    my $str = defined($_[0]) ? $_[0] : 'undef';
    my $len = $_[1];

    if(!defined($len) || $len < 1)
      {return($str)}

    my $elipsis = '...';

    if($len < 6)
      {$elipsis = ''}

    my $elen = length($elipsis);

    if(length($str) > $len)
      {$str = substr($str,0,($len-$elen)) . $elipsis}

    return($str);
  }

sub addToUsage
  {
    my $getoptkey   = $_[0];
    my $flags_array = $_[1];
    my $smry_desc   = $_[2];
    my $detail_desc = $_[3];
    my $required    = $_[4];
    my $default     = $_[5];
    my $accepts     = $_[6]; #Array of scalars
    my $hidden      = $_[7];
    my $opttype     = defined($_[8]) ? $_[8] : 'string';
    my $flagless    = $_[9];
    my $advanced    = $_[10];

    #For 1D & 2D array options
    my $varref      = $_[11];
    my $delim       = $_[12];

    #For in/out file types (used in help output)
    my $primary     = defined($_[13]) ? $_[13] : '';
    my $format_desc = $_[14];
    my $file_id     = $_[15];

    if(!defined($flags_array))
      {
	error("Flags array undefined.");
	return(0);
      }

    #To be backward compatible, convert a string to an array using comma delim
    if(ref($flags_array) ne 'ARRAY')
      {
	error("Invalid flags array passed in.",
	      {DETAIL => 'Must be a reference to an array of scalars'});
	quit(-102);
      }

    my $usage_index = scalar(@$usage_array);

    push(@$usage_array,{GETOPTKEY => $getoptkey,
			GETOPTREF => $varref,   #Currently only used for arrays
			OPTFLAG   => $flags_array,
			SUMMARY   => (defined($smry_desc) ? $smry_desc : ''),
			DETAILS   => (defined($detail_desc) ? $detail_desc:''),
			REQUIRED  => (defined($required) ? $required : 0),
			DEFAULT   => $default,
			ACCEPTS   => $accepts,
		        HIDDEN    => (defined($hidden) ? $hidden : 0),
			OPTTYPE   => $opttype,  #bool,negbool,count,integer,
                                                #float,string,enum,integer_
                                                #array,float_array,string_
                                                #array,enum_array,integer_
                                                #array2d,float_array2d,string_
                                                #array2d,enum_array2d,
                                                #infile,outfile,outdir,suffix,
			FLAGLESS  => $flagless, #1, 0, or undef
			ADVANCED  => $advanced,
			DELIMITER => $delim,

			#File option info
			PRIMARY   => $primary, #primary means stdin/out default
			FORMAT    => $format_desc,
		        FILEID    => $file_id,
			TAGTEAM   => 0,   #Involved in a tagteam pair
			TAGTEAMID => '',
		        TTREQD    => 0,   #Required as a part of a tagteam pair
		        TTHIDN    => 0}); #& set in createSuffixOutfileTagteam.
                                          #TTHIDN indicates whether 1 is hidden

    $usage_lookup->{$getoptkey} = $usage_array->[-1];

    return($usage_index);
  }

#Supply a getoptkey and get back a usage hash
sub getUsageHash
  {
    my $getoptkey = $_[0];
    if(!defined($getoptkey) || ref($getoptkey) ne '')
      {error('Invalid GETOPTKEY: [',
	     (defined($getoptkey) ? ref($getoptkey) : 'undef'),'].',
	     {DETAIL => 'Must be a scalar value.'})}
    if(exists($usage_lookup->{$getoptkey}) &&
       defined($usage_lookup->{$getoptkey}))
      {return($usage_lookup->{$getoptkey})}
    error("GETOPTKEY [$getoptkey] not found.");
    return({});
  }

sub getNextUsageIndex
  {return(scalar(@$usage_array))}

#Globals used: $usage_array
sub getFileUsageHash  {
    my $file_id = $_[0];
    my $type    = $_[1]; #infile,outfile
    if(scalar(@_) != 2)
      {
	error("getFileUsageHash requires exactly 2 parameters: a file ID & a ",
	      "type.");
	return({});
      }
    my @hashes = grep {exists($_->{FILEID}) && defined($_->{FILEID}) &&
			 $_->{FILEID} == $file_id && $_->{OPTTYPE} eq $type}
      @$usage_array;
    if(scalar(@hashes) == 1)
      {return($hashes[0])}
    error("Could not determine usage hash for file ID: [$file_id].");
    return({});
  }

#Converts a getopt key string into an array of associated flag strings
sub getOptStrFlags
  {
    my $get_opt_str = $_[0];
    my $genopttype  = getGeneralOptType($get_opt_str);
    $get_opt_str =~ s/[=:\!].*$//;
    my @flags =
      map {(length($_) > 1 ? '--' : '-') . $_} split(/\|/,$get_opt_str);
#    if($genopttype eq 'negbool')
#      {push(@flags,map {"--no$_"} split(/\|/,$get_opt_str))}
    return(wantarray ? @flags : [@flags]);
  }

#Returns the first 2 character flag or the first flag if a 2-character flag is
#not present
sub getDefaultFlag
  {
    my $flag_array = $_[0];
    if(!defined($flag_array) || ref($flag_array) ne 'ARRAY')
      {
	error("Invalid flag array: [",
	      (defined($flag_array) ?
	       (ref($flag_array) eq '' ? 'SCALAR' : ref($flag_array) . ' REF')
	       : 'undef'),"]");
	return('');
      }

    my $first_flag = '';
    foreach my $flag (@$flag_array)
      {
	if($first_flag eq '' && $flag =~ /^-/)
	  {$first_flag = $flag}
	if($flag =~ /^-[^\-]$/)
	  {return($flag)}
      }

    return($first_flag);
  }

sub getInfile
  {
    my @in           = getSubParams([qw(FILETYPEID ITERATE)],[],[@_]);
    my $file_type_id = $in[0];
    my $iterate      = defined($in[1]) ? $in[1] : $auto_file_iterate;

    unless($processCommandLine_called)
      {processCommandLine()}

    if(!defined($file_set_num))
      {
	$file_set_num = 0;
	if(!defined($max_set_num))
	  {$max_set_num = 0}
      }

    if($file_set_num >= scalar(@$input_file_sets))
      {
	$file_set_num = 0;
	return(undef);
      }

    #Allow file_type_id to be optional when there's only 1 infile type
    ##TODO: Create an iterator to cycle through the types when no type ID is
    ##      supplied.  See requirement 181
    if(!defined($file_type_id) && (getNumInfileTypes() == 1 || !wantarray))
      {
	#Even if we're returning a list, we'll set a file that will
	#unnecessarily go through a conditional below to check for validity -
	#just so this sub will work in both contexts
	$file_type_id = (getInfileIndexes())[0];

	if(!defined($file_type_id))
	  {
	    error("No input file options could be found.");
	    return(undef);
	  }
      }
    elsif(!defined($file_type_id) && !wantarray)
      {
	error("A file type ID is required.");
	return(undef);
      }

    my @return_files = ();
    if(wantarray && !defined($file_type_id))
      {
	##TODO: Reconsider this in such a way that the user knows the type of
	##   each file returned. Cannot use position here since we are grepping
	##   See requirement 182.
	@return_files = map {$input_file_sets->[$file_set_num]->[$_]}
	  grep {defined($input_file_sets->[$file_set_num]) &&
		  defined($input_file_sets->[$file_set_num]->[$_]) &&
		    !exists($outfile_types_hash->{$_})}
	    (0..$#{$input_files_array});
      }

    my $repeated = 0;
    if((defined($file_type_id) && fileReturnedBefore($file_type_id)) ||
       !defined($file_type_id) && wantarray &&
       scalar(grep {fileReturnedBefore($_)} @return_files))
      {$repeated = 1}

    if($repeated)
      {
	if($iterate)
	  {nextFileCombo()}
	else
	  {warning("Repeated requests for the same file detected.  Call ",
		   "nextFileCombo() between calls to getInfile().")}
	if(!defined($file_set_num))
	  {return(undef)}
      }

    if(defined($file_type_id) &&
       ($file_type_id >= scalar(@$input_files_array) ||
	exists($outfile_types_hash->{$file_type_id}) ||
	$file_type_id >= scalar(@{$input_file_sets->[$file_set_num]})))
      {
	error("Invalid input file type ID: [$file_type_id].");
	return(undef);
      }

    return(wantarray && !defined($file_type_id) ? @return_files :
	   $input_file_sets->[$file_set_num]->[$file_type_id]);
  }

#Globals used: $suffix_id_lookup
sub isSuffixPrimary
  {
    my $suffix_id = $_[0];

    #If the suffix ID provided does not exist
    if(!defined($suffix_id) ||
       (defined($suffix_id) &&
	($suffix_id >= scalar(@$suffix_id_lookup) ||
	 !defined($suffix_id_lookup->[$suffix_id]) ||
	 ref($suffix_id_lookup->[$suffix_id]) ne 'ARRAY' ||
	 scalar(@{$suffix_id_lookup->[$suffix_id]}) != 2)))
      {
	error("Invalid suffix ID: [",
	      (defined($suffix_id) ? $suffix_id : 'undef'),"].");
	return(undef);
      }

    #The third element of each suffix_id_lookup array is the primary value that
    #was stored here by the addOutfileSuffixOption sub
    return(isTypeSuffixPrimary($suffix_id_lookup->[$suffix_id]->[0],
			       $suffix_id_lookup->[$suffix_id]->[1]));
  }

#Note: This could be way more efficient if everything went through the usage
#array and usage array indexes were the types passed around for everything
#Globals used: required_suffix_types
sub isSuffixRequired
  {
    my $suffix_id = $_[0];
    foreach my $suff_ary (@$required_suffix_types)
      {return(1) if($suffix_id == $suff_ary->[2])}
    return(0);
  }

#Determines whether a suffix is defined or not.  By "defined", what is meant
#depends on how the output file was defined by the programmer.  If the outfile
#type was created using addOutfileSuffixOption, then the result is whether or
#not the value for the suffix is defined (the straight-forward possibility).
#If however, the outfile type was defined by addOutfileOption, then the suffix
#is a hidden one with an empty string as a value and the suffix is "defined" if
#any files were supplied by the user for that option.
sub isSuffixDefined
  {
    my $file_index = $_[0];
    my $suff_index = $_[1];
    my $is_defined = 0;

    #If this is a suffix of an outfile type added by addOutfileOption
    if(exists($outfile_types_hash->{$file_index}))
      {
	#Return true if there's anything in this outfile type's input files
	#array
	$is_defined =
	  scalar(grep {my $a=$_;defined($a) && scalar(grep {defined($_)} @$a)}
		 @{$input_files_array->[$file_index]});
      }
    else
      {$is_defined =
	 defined($outfile_suffix_array->[$file_index]->[$suff_index])}

    return($is_defined);
  }

#Given an input file type index and a suffix index, returns whether the output
#for files with that suffix is primary or not (i.e. whether, when no suffix is
#supplied, output should go to STDOUT.  The structure of $suffix_primary_vals
#is built inside addOutFileSuffixOption
#Globals used: $suffix_primary_vals
sub isTypeSuffixPrimary
  {
    my $type_index   = $_[0];
    my $suffix_index = $_[1];

    if(scalar(@$suffix_primary_vals) <= $type_index ||
       scalar(@{$suffix_primary_vals->[$type_index]}) <= $suffix_index)
      {return(undef)}

    return($suffix_primary_vals->[$type_index]->[$suffix_index]);
  }

sub getOutfile
  {
    my @in        = getSubParams([qw(SUFFIXID ITERATE)],[],[@_]);
    my $suffix_id = $in[0];
    my $iterate   = defined($in[1]) ? $in[1] : $auto_file_iterate;

    unless($processCommandLine_called)
      {processCommandLine()}

    #If this is the first time we've returned any files, set up the file set
    #counter
    if(!defined($file_set_num))
      {
	$file_set_num = 0;
	if(!defined($max_set_num))
	  {$max_set_num = 0}
      }

    #If we're past the number of files supplied by the user, reset the file set
    #counter and return undef
    if($file_set_num >= scalar(@$input_file_sets))
      {
	$file_set_num = 0;
	return(undef);
      }

    ##
    ## Error-check or provide a default suffix ID
    ##

    #If the suffix ID is actually a tagteam ID, change it to whichever has been
    #supplied (or a default if none were supplied)
    if(defined($suffix_id) && exists($outfile_tagteams->{$suffix_id}))
      {$suffix_id = tagteamToSuffixID($suffix_id)}

    #If the suffix ID provided does not exist.  Note, this works for both
    #outfile suffix types and outfile types (because it has a hidden suffix ID)
    if(defined($suffix_id) &&
       ($suffix_id >= scalar(@$suffix_id_lookup) ||
	!defined($suffix_id_lookup->[$suffix_id]) ||
	ref($suffix_id_lookup->[$suffix_id]) ne 'ARRAY' ||
	scalar(@{$suffix_id_lookup->[$suffix_id]}) != 2))
      {
	error("Invalid suffix ID: [$suffix_id].");
	return(undef);
      }
    #Else if no ID was provided and there's only one existing suffix ID
    elsif(!defined($suffix_id) &&
	  scalar(grep {scalar(@$_)} @$suffix_id_lookup) == 1)
      {$suffix_id = 0}
    #Else if no ID was provided and there's only 1 output file type supplied
    #on the command line
    elsif(!defined($suffix_id) &&
	  scalar(grep {scalar(@$_) &&
			 defined($output_file_sets->[$file_set_num]
				 ->[$_->[0]]->[$_->[1]])}
		 @$suffix_id_lookup) == 1)
      {
	$suffix_id = (grep {scalar(@{$suffix_id_lookup->[$_]}) &&
			      defined($output_file_sets->[$file_set_num]
				      ->[$suffix_id_lookup->[$_]->[0]]
				      ->[$suffix_id_lookup->[$_]->[1]])}
		      (0..$#{$suffix_id_lookup}))[0];
      }
    #Else if no ID was provided and no output files have been supplied (for
    #this set - which implies none specified for *any* set)
    elsif(!defined($suffix_id) &&
	  scalar(grep {scalar(@$_) &&
			 defined($output_file_sets->[$file_set_num]
				 ->[$_->[0]]->[$_->[1]])}
		 @$suffix_id_lookup) == 0)
      {
	#If all output file types are primary, return '-'
	if(scalar(@$suffix_id_lookup) ==
	   scalar(grep {isSuffixPrimary($_->[2])} @$suffix_id_lookup))
	  {return('-')}
	#Else return undef
	return(undef);
      }
    #Else if no ID was provided and no output file types have been defined
    elsif(!defined($suffix_id) &&
	  scalar(grep {scalar(@$_)} @$suffix_id_lookup) == 0)
      {
	error("No output file (or suffix) options have been added to the ",
	      "command line interface.");
	return(undef);
      }
    #Else if no ID was provided and there are multiple outfile types defined
    #and supplied
    elsif(!defined($suffix_id) &&
	  scalar(grep {scalar(@$_)} @$suffix_id_lookup) > 1)
      {
	debug({LEVEL => -2},"There are [",
	      scalar(grep {scalar(@$_)} @$suffix_id_lookup),
	      "] possible suffixes, for file types [",
	      join(',',map {$_->[0]} grep {scalar(@$_)} @$suffix_id_lookup),
	      "] respectively, and each with these suffix indexes: [",
	      join(',',map {$_->[1]} grep {scalar(@$_)} @$suffix_id_lookup),
	      "].  There are [",
	      scalar(@{$output_file_sets->[$file_set_num]}),
	      "] output file types existing in the output file sets array.  ",
	      "Each type has this many suffixes: [",
	      join(',',
		   map {scalar(@$_)} @{$output_file_sets->[$file_set_num]}),
	      "].  This many of them have defined outfile names (i.e. were ",
	      "provided on the command line): [",
	      scalar(grep {scalar(@$_) &&
			     defined($output_file_sets->[$file_set_num]
				     ->[$_->[0]]->[$_->[1]])}
		     @$suffix_id_lookup),
	      "].  The outfile names are: [",
	      join(',',map {$output_file_sets->[$file_set_num]
			      ->[$_->[0]]->[$_->[1]]}
		   grep {scalar(@$_) &&
			   defined($output_file_sets->[$file_set_num]
				   ->[$_->[0]]->[$_->[1]])}
		   @$suffix_id_lookup),
	      "].");

	#If there are only 2 outfile types, at least 1 is a default, and both
	#types were supplied on the command line
	if(scalar(grep {scalar(@$_)} @$suffix_id_lookup) == 2 &&
	   ($default_outfile_suffix_added || $default_outfile_added) &&
	   scalar(#The suffix is defined
		  grep {isSuffixDefined($_->[0],$_->[1])}

		  #Convert to an array of file and suff indexes
		  map {my $fi=$_;map {[$fi,$_]}
			 (0..$#{$outfile_suffix_array->[$fi]})}

		  #The associated infile array is populated (i.e. -i or
		  #--outfile because it's saved as an infile and marked in the
		  #outfile_types_hash)
		  grep {defined($input_files_array->[$_]) &&
			  scalar(@{$input_files_array->[$_]})}

		  #Indexes of the outfile suffixes array
		  0..$#{$outfile_suffix_array}) == 2)
	  {
	    error("Outfile tagteam options are mutually exclusive.  Cannot ",
		  "supply both an outfile suffix [",
		  getOutfileSuffixFlag($default_outfile_suffix_added ?
				       $default_outfile_suffix_id :
				       ($default_outfile_id == 0 ? 1 : 0)),
		  "] and outfile(s) [",
		  getOutfileFlag($default_outfile_added ? $default_outfile_id :
				 ($default_outfile_suffix_id == 0 ? 1 : 0)),
		  "] at the same time.  Please use one or the other.",
		  {DETAIL => 'Note: Double-check to make sure one or the ' .
		   'other does not have a default value specified.'});
	    return(undef);
	  }
	#Else if there are only 2 outfile types and a tagteam exists
	elsif(scalar(grep {scalar(@$_)} @$suffix_id_lookup) == 2 &&
	      scalar(keys(%$outfile_tagteams)) == 1)
	  {
	    my $ttid = (keys(%$outfile_tagteams))[0];
	    $suffix_id = tagteamToSuffixID($ttid);
	  }
	else
	  {
	    error("Suffix ID is required when there is more than one output ",
		  "file type defined & supplied on the command line.",
		  {DETAIL =>
		   join('',("E.g. Outfiles can be defined by supplying a ",
			    "suffix appended to an input file, by file name, ",
			    "or (in the absence of output flags) by the fact ",
			    "that an options is 'primary', in which case ",
			    "output defaults to STDOUT when not defined on ",
			    "the command line.  There are [",
			    scalar(grep {scalar(@$_) &&
					   defined($output_file_sets
						   ->[$file_set_num]->[$_->[0]]
						   ->[$_->[1]])}
				   @$suffix_id_lookup),"] output ",
			    "file types that have either been defined and ",
			    "supplied on the command line or which are ",
			    "primary (and will go to STDOUT when not ",
			    "supplied on the command line) with values [",
			    join(',',map {$output_file_sets->[$file_set_num]
					    ->[$_->[0]]->[$_->[1]]}
				 grep {scalar(@$_) &&
					 defined($output_file_sets
						 ->[$file_set_num]->[$_->[0]]
						 ->[$_->[1]])}
				 @$suffix_id_lookup),"]."))});
	    return(undef);
	  }
      }

    if($suffix_id > $#{$suffix_id_lookup})
      {error("Suffix ID out of bounds.")}
    debug({LEVEL => -99},
	  "Suffix ID is [",(defined($suffix_id) ? $suffix_id : 'undef'),"].");

    my $file_type_index = $suffix_id_lookup->[$suffix_id]->[0];
    my $suffix_index    = $suffix_id_lookup->[$suffix_id]->[1];

    if(fileReturnedBefore($file_type_index,$suffix_index))
      {
	if($iterate)
	  {nextFileCombo()}
	else
	  {warning("Repeated requests for the same file detected.  Call ",
		   "nextFileCombo() between calls to getOutfile().")}
	if(!defined($file_set_num))
	  {return(undef)}
      }

    if($file_type_index >= scalar(@{$output_file_sets->[$file_set_num]}) ||
       $suffix_index >=
       scalar(@{$output_file_sets->[$file_set_num]->[$file_type_index]}))
      {
	error("Output file was not set up.");
	return(undef);
      }

    #If the output file name is not defined and no output files of this type
    #were specified by the user, manipulate the file name to either '-' if the
    #suffix type is primary (otherwise, keep undef)
    my($convert_undefs);
    if(!defined($output_file_sets->[$file_set_num]->[$file_type_index]
		->[$suffix_index]) &&
       scalar(grep {scalar(@$_) &&
		      defined($_->[$file_type_index]->[$suffix_index])}
	      @$output_file_sets) == 0 && isSuffixPrimary($suffix_id))
      {$convert_undefs = '-'}

    debug({LEVEL => -99},"Returning outfile for set [$file_set_num], file ",
	  "type (index) [$file_type_index], and suffix index [$suffix_index",
	  "].");

    my $outfile = $output_file_sets->[$file_set_num]->[$file_type_index]
      ->[$suffix_index];

    return($convert_undefs && !defined($outfile) ? $convert_undefs : $outfile);
  }

#This subroutine takes a tagteam ID and returns a suffix ID.  The suffix ID
#will either be the one created by addOutfileSuffixOption or (via)
#addOutfileOption.  It determines which to return by checking whether the
#suffix or outfile was actually supplied on the command line (assuming only one
#was because processCommandLine validates this).  If neither was explicitly
#supplied on the command line and one has a default value (assuming both can't
#have a default value - again because of validation elsewhere), the suffix ID
#of the one with the default is returned.  Note that the suffix stored for the
#OUTFID key always has a default (an empty string), so only SUFFID will be
#checked and if it does not have a default, the OUTFID is returned without
#checking whether it has a default.
sub tagteamToSuffixID
  {
    my $ttid = $_[0];

    if(!defined($ttid))
      {
	if(scalar(keys(%$outfile_tagteams)) == 1)
	  {$ttid = (keys(%$outfile_tagteams))[0]}
	else
	  {
	    error("Invalid tagteam ID: [undef].");
	    return(undef);
	  }
      }

    if(!validateTagteam($ttid)) #Generates errors if invalid
      {return($ttid)}

    if(exists($tagteam_to_supplied_oid->{$ttid}))
      {return($tagteam_to_supplied_oid->{$ttid})}
    else
      {
	error("Tagteam ID: [$ttid] not found.");
	return(undef);
      }
  }

#Determines if the suffix of a tagteam partner is defined.  Takes a file index
#and suffix index of the suffix whose partner we want to look up.
#Globals used: $outfile_suffix_array, $outfile_tagteams, $suffix_id_lookup
sub isTagteamPartnerDefined
  {
    my $file_index = $_[0];
    my $suff_index = $_[1];
    my $suffix_id  = getSuffixID($file_index,$suff_index);

    #Find the hash containing the suffix ID.  (NOTE: A suffix can only be
    #involed in one tagteam.)
    my $tthashes = [grep {$_->{SUFFID} == $suffix_id ||
			    $_->{OUTFID} == $suffix_id}
		    values(%$outfile_tagteams)];
    if(scalar(@$tthashes) == 0)
      {
	#Suffix is not in a tagteam.  It doesn't have a partner, so it can't be
	#defined
	return(0);
      }
    elsif(scalar(@$tthashes) > 1)
      {
	error("INTERNAL ERROR: Multiple matching tagteams found for suffix ",
	      "ID: [$suffix_id].");
	quit(-71);
      }
    my $tthash = $tthashes->[0];
    my $is_partner_outf = ($tthash->{SUFFID} == $suffix_id ? 1 : 0);
    my($partner_defined);
    my $partner_suffix_id = ($tthash->{SUFFID} == $suffix_id ?
			     $tthash->{OUTFID} : $tthash->{SUFFID});
    my $partner_file_index = $suffix_id_lookup->[$partner_suffix_id]->[0];
    my $partner_suff_index = $suffix_id_lookup->[$partner_suffix_id]->[1];
    if($is_partner_outf)
      {
	#Return true if there's anything in this outfile type's input files
	#array
	$partner_defined =
	  scalar(grep {my $a=$_;defined($a) && scalar(grep {defined($_)} @$a)}
		 @{$input_files_array->[$partner_file_index]});
      }
    else
      {$partner_defined = defined($outfile_suffix_array->[$partner_file_index]
				  ->[$partner_suff_index])}
    debug({LEVEL => -1},"Partner is: [",
	  ($partner_defined ?
	   $outfile_suffix_array->[$partner_file_index]->[$partner_suff_index]
	   : 'undef'),"].  Returning [$partner_defined].");
    return($partner_defined);
  }

#This not only validates tagteams by checking that the supplied ID is present
#and by making sure the options that were made into a tagteam are compatible
#(taking default-added options into account), but also populates the
#tagteam_to_supplied_oid that is used by tagteamToSuffixID
sub validateTagteam
  {
    #Note: the tagteam ID could be a suffix ID depending on how it was created
    my $ttid = $_[0];

    #If the tagteam ID is not defined, return failure
    if(!defined($ttid))
      {return(0)}

    #If the tagteam ID doesn't exist return failure
    if(!exists($outfile_tagteams->{$ttid}))
      {
	error("Invalid tagteam ID: [$ttid].");
	return(0);
      }

    #If already validated, return success
    if(exists($tagteam_to_supplied_oid->{$ttid}))
      {return(1)}

    #Validate the suffix IDs for this tagteam
    if(scalar(@$suffix_id_lookup) <= $outfile_tagteams->{$ttid}->{SUFFID})
      {
	error("The suffix ID: [$outfile_tagteams->{$ttid}->{SUFFID}] for ",
	      "tagteam ID: [$ttid] does not exist in the suffix ID lookup.");
	return(0);
      }
    elsif(scalar(@$suffix_id_lookup) <= $outfile_tagteams->{$ttid}->{OUTFID})
      {
	error("The outfile ID: [$outfile_tagteams->{$ttid}->{OUTFID}] for ",
	      "tagteam ID: [$ttid] does not exist in the outfile ID lookup.");
	return(0);
      }

    #In order to evaluate whether the SUFFID option was supplied a value or has
    #a default value, we need the 2 indexes into the outfile_suffix_array to
    #obtain the value to compare to the SUFFDEF key's value in the
    #outfile_tagteams hash
    my $suffid_infile_index =
      $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{SUFFID}]->[0];
    my $suffid_suffix_index =
      $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{SUFFID}]->[1];
    #Same for the OUTFID
    my $outfid_infile_index =
      $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{OUTFID}]->[0];
    my $outfid_suffix_index =
      $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{OUTFID}]->[1];

    #Retrieve the default values
    my $suff_default = $outfile_tagteams->{$ttid}->{SUFFDEF};
    my $outf_default = []; #A 2D array reference
    if($outfid_infile_index < scalar(@$default_infiles_array) &&
       defined($default_infiles_array->[$outfid_infile_index]) &&
       scalar(@{$default_infiles_array->[$outfid_infile_index]}) &&
       scalar(grep {defined($_)} map {@$_}
	      @{$default_infiles_array->[$outfid_infile_index]}))
      {$outf_default = $default_infiles_array->[$outfid_infile_index]}

    #Retrieve the post-commandline-processed values potentially supplied by the
    #user
    my $suff_value =
      $outfile_suffix_array->[$suffid_infile_index]->[$suffid_suffix_index];
    my $outf_value = $input_files_array->[$outfid_infile_index];

    my $is_suff_default = (defined($suff_default) &&
			   $suff_default eq $suff_value);
    my $is_outf_default =
      (defined($outf_value) && defined($outf_default) &&
       scalar(@$outf_value) > 0 &&
       scalar(@$outf_value) == scalar(@$outf_default) &&
       scalar(grep {scalar(@{$outf_value->[$_]}) !=
		      scalar(@{$outf_default->[$_]})}
	      (0..$#{$outf_value})) == 0 &&
       scalar(grep {my $i=$_;scalar(grep {$outf_value->[$i]->[$_] ne
					    $outf_default->[$i]->[$_]}
				    (0..$#{$outf_value->[$i]}))}
	      (0..$#{$outf_value})) == 0);

    debug({LEVEL => -1},"Suffix [",
	  getOutfileSuffixFlag($outfile_tagteams->{$ttid}->{SUFFID},-1),
	  "] default value in the tagteam pair, is [",
	  (defined($suff_default) ? $suff_default : 'undef'),"].  Suff val: [",
	  (defined($suff_value) ? $suff_value : 'undef'),"]  Outf val: [",
	  (defined($outf_value) ? $outf_value : 'undef'),"]  Is Suff def: ",
	  "[",($is_suff_default ? 1 : '0'),"]  Is outf def: [",
	  ($is_outf_default ? 1 : '0'),"]");

    #If the suffix has a value and it is not a default value and either outf
    #has no value (i.e. is empty) or is the default value
    if(defined($suff_value) && !$is_suff_default &&
       (!defined($outf_value) || scalar(@$outf_value) == 0 ||
	$is_outf_default))
      {
	$tagteam_to_supplied_oid->{$ttid} =
	  $outfile_tagteams->{$ttid}->{SUFFID};
	return(1);
      }
    #Else if the outfile has a value and it's not a default value and either
    #suff is not defined or is the default
    elsif(defined($outf_value) && scalar(@$outf_value) && !$is_outf_default &&
	  (!defined($suff_value) || $is_suff_default))
      {
	$tagteam_to_supplied_oid->{$ttid} =
	  $outfile_tagteams->{$ttid}->{OUTFID};
	return(1);
      }
    #Else if both were supplied
    elsif(defined($suff_value) && !$is_suff_default &&
	  defined($outf_value) && scalar(@$outf_value) && !$is_outf_default)
      {
	error("Outfile tagteam options are mutually exclusive.  Cannot ",
	      "supply both an outfile suffix [",
	      getOutfileSuffixFlag($outfile_tagteams->{$ttid}->{SUFFID}),
	      "] and outfiles [",getOutfileFlag($outfid_infile_index),
	      "] at the same time.  ",
	      "Use --force to surpass this fatal error and arbitrarily use [",
	      ($outfile_tagteams->{$ttid}->{SUFFID} <
	       $outfile_tagteams->{$ttid}->{OUTFID} ?
	       getOutfileSuffixFlag($outfile_tagteams->{$ttid}->{SUFFID}) :
	       getOutfileFlag($suffid_infile_index)),
	      "], ignoring the other option.");
	quit(-67);
	$tagteam_to_supplied_oid->{$ttid} =
	  ($outfile_tagteams->{$ttid}->{SUFFID} <
	   $outfile_tagteams->{$ttid}->{OUTFID} ?
	   $outfile_tagteams->{$ttid}->{SUFFID} :
	   $outfile_tagteams->{$ttid}->{OUTFID});
	return(0);
      }
    #Else if only the suffix has a defined default value
    elsif($is_suff_default && !$is_outf_default)
      {
	$tagteam_to_supplied_oid->{$ttid} =
	  $outfile_tagteams->{$ttid}->{SUFFID};
	return(1);
      }
    #Else if only the outfile has a defined default value
    elsif($is_outf_default && !$is_suff_default)
      {
	$tagteam_to_supplied_oid->{$ttid} =
	  $outfile_tagteams->{$ttid}->{OUTFID};
	return(1);
      }
    #Else if both have default values
    elsif($is_outf_default && $is_suff_default)
      {
	error("Outfile tagteam options are mutually exclusive.  Cannot have ",
	      "default values for both an outfile suffix [",
	      getOutfileSuffixFlag($outfile_tagteams->{$ttid}->{SUFFID}),
	      "] (default: [",
	      (defined($suff_default) ? $suff_default : 'undef'),
	      "]) and an outfile [",getOutfileFlag($outfid_infile_index),
	      "] (default: [(",join('),(',map {join(',',@$_)} @$outf_default),
	      ")]) at the same time.  ",
	      "Use --force to surpass this fatal error and arbitrarily use [",
	      ($outfile_tagteams->{$ttid}->{SUFFID} <
	       $outfile_tagteams->{$ttid}->{OUTFID} ?
	       getOutfileSuffixFlag($outfile_tagteams->{$ttid}->{SUFFID}) :
	       getOutfileFlag($suffid_infile_index)),
	      "], ignoring the other option.");
	quit(-90);
	$tagteam_to_supplied_oid->{$ttid} =
	  ($outfile_tagteams->{$ttid}->{SUFFID} <
	   $outfile_tagteams->{$ttid}->{OUTFID} ?
	   $outfile_tagteams->{$ttid}->{SUFFID} :
	   $outfile_tagteams->{$ttid}->{OUTFID});
	return(0);
      }

    ##
    ## At this point, neither was supplied and neither have default values...
    ##

    #Else if only the suffix was default added
    elsif($default_outfile_suffix_added && !$default_outfile_added)
      {$tagteam_to_supplied_oid->{$ttid} =
	 $outfile_tagteams->{$ttid}->{OUTFID}}
    #Else if the outfile only was default added
    elsif($default_outfile_added && !$default_outfile_suffix_added)
      {$tagteam_to_supplied_oid->{$ttid} =
	 $outfile_tagteams->{$ttid}->{SUFFID}}
    #Else both or neither were default added - return the lesser ID
    else
      {$tagteam_to_supplied_oid->{$ttid} =
	 ($outfile_tagteams->{$ttid}->{SUFFID} <
	  $outfile_tagteams->{$ttid}->{OUTFID} ?
	  $outfile_tagteams->{$ttid}->{SUFFID} :
	  $outfile_tagteams->{$ttid}->{OUTFID})}

    return(1);
  }

#Returns any required tagteam deficiencies, but also quits if 2 mutually
#exclusive tagteam options are supplied.
sub getMissingConflictingTagteamFlags
  {
    my $missing_flag_combos = [];
    my $conflicting_flags = [];

    #For every required tagteam
    foreach my $ttid (keys(%$outfile_tagteams))
      {
	my $outfile_id = $outfile_tagteams->{$ttid}->{OUTFID};
	my $outfile_index =
	  $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{OUTFID}]->[0];
	my $suffix_id  = $outfile_tagteams->{$ttid}->{SUFFID};
	my $infile_index =
	  $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{SUFFID}]->[0];
	my $suffix_index =
	  $suffix_id_lookup->[$outfile_tagteams->{$ttid}->{SUFFID}]->[1];
	my $oflag = getOutfileFlag($outfile_index);
	my $sflag = getOutfileSuffixFlag($suffix_id);

	#Determine whether the the value of the outfiles is the default or was
	#supplied by the user
	##TODO: This is similar to #281, but here, the values from the
	#command line have already been read in and the default values assigned
	#to the array.  So here, the fact that an outfile has been supplied or
	#not has been lost.  What should really happen is that whether a value
	#has been supplied on the command line or not should be saved.  I
	#should really be creating option IDs and storing stuff like this in an
	#option structure (an expansion of the usage_array, really).  See
	#requirement #288.
	my $outf_default = []; #A 2D array reference
	if($outfile_index < scalar(@$default_infiles_array) &&
	   defined($default_infiles_array->[$outfile_index]) &&
	   scalar(@{$default_infiles_array->[$outfile_index]}) &&
	   scalar(grep {defined($_)} map {@$_}
		  @{$default_infiles_array->[$outfile_index]}))
	  {$outf_default = $default_infiles_array->[$outfile_index]}
	my $outf_value = $input_files_array->[$outfile_index];
	my $is_outf_default =
	  (defined($outf_value) && defined($outf_default) &&
	   scalar(@$outf_value) > 0 &&
	   scalar(@$outf_value) == scalar(@$outf_default) &&
	   scalar(grep {scalar(@{$outf_value->[$_]}) !=
			  scalar(@{$outf_default->[$_]})}
		  (0..$#{$outf_value})) == 0 &&
	   scalar(grep {my $i=$_;scalar(grep {$outf_value->[$i]->[$_] ne
						$outf_default->[$i]->[$_]}
					(0..$#{$outf_value->[$i]}))}
		  (0..$#{$outf_value})) == 0);
	my $outfile_supplied = (defined($outf_value) &&
				scalar(@$outf_value) > 0 &&
				!$is_outf_default ? 1 : 0);
	my $outfile_hasdef = defined($outf_default) && scalar(@$outf_default);

	#The outer and inner arrays are guaranteed/assumed to be there
	my $suffix_supplied = (defined($outfile_suffix_array->[$infile_index]
				       ->[$suffix_index]) &&
			       (!defined($outfile_tagteams->{$ttid}
					 ->{SUFFDEF}) ||
				(defined($outfile_tagteams->{$ttid}
					 ->{SUFFDEF}) &&
				 $outfile_suffix_array->[$infile_index]
				 ->[$suffix_index] ne
				 $outfile_tagteams->{$ttid}->{SUFFDEF}))) ?
				   1 : 0;
	my $suffix_hasdef =
	  defined($outfile_tagteams->{$ttid}->{SUFFDEF}) ? 1 : 0;

	debug({LEVEL => -2},"TTID: [$ttid] Required?: ",
	      "[$outfile_tagteams->{$ttid}->{REQUIRED}] Outfile has ",
	      "default?: [$outfile_hasdef] Supplied?: [$outfile_supplied] ",
	      "Suffix has default?: [$suffix_hasdef] Supplied?: ",
	      "[$suffix_supplied]");

	if($outfile_tagteams->{$ttid}->{REQUIRED} &&
	   !$outfile_tagteams->{$ttid}->{PRIMARY} &&
	   !$outfile_supplied && !$suffix_supplied && !$suffix_hasdef &&
	   !$outfile_hasdef
	   #TODO: Do a version of this if/when requirement 11b is implemented
	   #&& ($req_type != $primary_outfile_type ||
	   #    isStandardOutputToTerminal())
	  )
	  {push(@$missing_flag_combos,
		(defined($oflag) && $oflag ne '' &&
		 defined($sflag) && $sflag ne '' ?
		 "[$oflag] or [$sflag]" : 'internal error'))}
	elsif($outfile_supplied && $suffix_supplied)
	  {push(@$conflicting_flags,
		(defined($oflag) && $oflag ne '' &&
		 defined($sflag) && $sflag ne '' ?
		 "[$sflag] (" .
		 "$outfile_suffix_array->[$infile_index]->[$suffix_index]) " .
		 "and [$oflag] ('" .
		 substr(join("' $oflag '",
			     map {join(' ',@$_)}
			     @{$input_files_array->[$outfile_index]}),0,20) .
		 "...')" :
		 'internal error'))}
      }

    return($missing_flag_combos,$conflicting_flags);
  }

sub nextFileCombo
  {
    unless($processCommandLine_called)
      {processCommandLine()}

    if($auto_file_iterate)
      {
	my $called_implicitly = 0;
	if(isCaller('getInfile','getOutfile'))
	  {$called_implicitly = 1}
	if(!$called_implicitly)
	  {
	    $auto_file_iterate = 0;
	    if(defined($file_set_num) &&
	       $file_set_num < scalar(@$input_file_sets))
	      {warning("File set iteration has gone from implicit to ",
		       "explicit.  ",
		       ($extended ?
			("Input and/or output files may have been skipped.  " .
			 "Please use nextFileCombo to iterate over all sets " .
			 "of files provided on the command that are " .
			 "processed together.  Do not call openOut,  openIn " .
			 "getInfile, or getOutfile before the first call to " .
			 "nextFileCombo.") :
			"Run with --extended for more detail."))}
	    debug({LEVEL=>-1},"nextFileCombo was called explicitly, not ",
		  "through getInfile or getOutfile.  Turning off auto-",
		  "iterate.");
	  }
	else
	  {$auto_file_iterate = 1}
      }

    if(!defined($file_set_num))
      {
	$file_set_num = 0;
	if(!defined($max_set_num))
	  {$max_set_num = 0}
      }
    elsif($file_set_num < scalar(@$input_file_sets) - 1)
      {
	$file_set_num++;
	if($max_set_num < $file_set_num)
	  {$max_set_num = $file_set_num}
      }
    else
      {
	$file_set_num         = undef;
	$file_returned_before = {};
	$auto_file_iterate    = 1;
      }

    debug({LEVEL=>-1},"Returning file set num: [",
	  (defined($file_set_num) ? "$file_set_num + 1" : 'undef'),"].");

    #Must return a non-zero value for this to work in a while loop
    return(defined($file_set_num) ? $file_set_num + 1 : $file_set_num);
  }

sub fileReturnedBefore
  {
    my $file_type_index = $_[0];
    my $suffix_index    = $_[1]; #Supply this for outfiles but not for infiles

    if(!defined($file_set_num))
      {
	$file_set_num = 0;
	if(!defined($max_set_num))
	  {$max_set_num = 0}
      }

    #If this is an output file
    if(defined($suffix_index))
      {
	if(exists($file_returned_before->{OUT}->{$file_set_num}) &&
	   exists($file_returned_before->{OUT}->{$file_set_num}
		  ->{$file_type_index}) &&
	   exists($file_returned_before->{OUT}->{$file_set_num}
		  ->{$file_type_index}->{$suffix_index}) &&
	   $file_returned_before->{OUT}->{$file_set_num}->{$file_type_index}
	   ->{$suffix_index})
	  {return(1)}
	else
	  {
	    $file_returned_before->{OUT}->{$file_set_num}->{$file_type_index}
	      ->{$suffix_index} = 1;
	    return(0);
	  }
      }
    elsif(!defined($file_type_index))
      {return(0)}
    else
      {
	if(exists($file_returned_before->{IN}->{$file_set_num}) &&
	   exists($file_returned_before->{IN}->{$file_set_num}
		  ->{$file_type_index}) &&
	   $file_returned_before->{IN}->{$file_set_num}->{$file_type_index})
	  {return(1)}
	else
	  {
	    $file_returned_before->{IN}->{$file_set_num}->{$file_type_index} =
	      1;
	    return(0);
	  }
      }
  }

sub addDefaultFileOptions
  {
    #If the programmer did not add any input file types, add a default
    if(scalar(grep {!exists($outfile_types_hash->{$_})}
	      (0..$#{$input_files_array})) == 0)
      {addInfileOption()}

    my $def_prim_inf_type = getDefaultPrimaryInfileID();

    #If the programmer did not assign a primary input file type and the number
    #of explicitly non-primary infile types is not all of the infile types,
    #pick a default
    if(!defined($primary_infile_type) && defined($def_prim_inf_type))
      {
	#We will mark this as the primary infile ID even if the programmer may
	#have explicitly said that it's not to be primary, just to we can do
	#default linking of outfile types.
	$primary_infile_type = $def_prim_inf_type;

	#If the non-primary status was not set explicitly to 0
	if($usage_array->[$usage_file_indexes->[$def_prim_inf_type]]->{PRIMARY}
	   ne '0')
	  {
	    $usage_array->[$usage_file_indexes->[$def_prim_inf_type]]
	      ->{PRIMARY} = 1;
	    if(!defined($usage_array
			->[$usage_file_indexes->[$def_prim_inf_type]]
			->{DEFAULT}))
	      {$usage_array->[$usage_file_indexes->[$def_prim_inf_type]]
		 ->{DEFAULT} = ''}
	    elsif($usage_array->[$usage_file_indexes->[$def_prim_inf_type]]
		  ->{DEFAULT} eq '')
	      {$usage_array->[$usage_file_indexes->[$def_prim_inf_type]]
		 ->{DEFAULT} = "''"}
	  }
      }

    #If there was an error during setup (implied by cleanup_mode > 1) and there
    #is no usage entry for the primary infile type, skip all this and return
    if($cleanup_mode > 1 && $primary_infile_type > $#{$usage_file_indexes})
      {return(0)}

    #If the programmer did not assign any multi-value option as 'flagless', set
    #the primary input file as flagless (if it is defined and not explicitly
    #set to not be flagless)
    if((!defined($flagless_multival_type) || $flagless_multival_type < 0) &&
       defined($primary_infile_type) &&
       ((defined($usage_array->[$usage_file_indexes->[$primary_infile_type]]
		 ->{FLAGLESS}) &&
	 $usage_array->[$usage_file_indexes->[$primary_infile_type]]
	 ->{FLAGLESS}) ||
	!defined($usage_array->[$usage_file_indexes->[$primary_infile_type]]
		 ->{FLAGLESS})))
      {
	#Keep track globally of which option is the multi-value flagless one
	$flagless_multival_type = $usage_file_indexes->[$primary_infile_type];

	my $getoptsub =
	  'sub {checkFileOpt($_[0],1);push(@{$input_files_array->[' .
	    $primary_infile_type . ']},[sglob($_[0])])}';
	$GetOptHash->{'<>'} = eval($getoptsub);

	$usage_array->[$usage_file_indexes->[$primary_infile_type]]
	  ->{FLAGLESS} = 1;
      }

    my $num_outfile_types = scalar(keys(%$outfile_types_hash));
    my $num_suffix_types  = getNumSuffixTypes();

    #Add a default outfile suffix type if none was added and either no outfile
    #types were added or the first primary outfile type has something other
    #than a 1:M relationship
    my $add_outf_suff =
      ($num_suffix_types == 0 &&
       ($num_outfile_types == 0 || !isDefaultPrimaryOut1toMorUnrelated()));

    #If the programmer did not add an outfile suffix option and one is
    #appropriate
    if($add_outf_suff)
      {
	debug({LEVEL => -1},"Adding default outfile suffix option because ",
	      "the number of suffix types added [$num_suffix_types] == 0 and ",
	      "(the number of outfile types [$num_outfile_types] == 0 or the ",
	      "first primary outfile type had [",
	      (isDefaultPrimaryOut1toMorUnrelated() ? 'at least 1' : 'no'),
	      "] 1:M relationships or no relationship defined with input ",
	      "files.");
	addOutfileSuffixOption();
      }
    else
      {debug({LEVEL => -1},"Not adding default outfile suffix option because ",
	     "the number of suffix types added [$num_suffix_types] != 0 or ",
	     "(the number of outfile types [$num_outfile_types] != 0 and the ",
	     "first primary outfile type had [",
	     (isDefaultPrimaryOut1toMorUnrelated() ? 'at least 1' : 'no'),
	     "] 1:M relationships or no relationship defined with input ",
	     "files.")}

    #If the programmer did not add an outfile option
    if($num_outfile_types == 0)
      {addOutfileOption()}

    #If one of the default outfile types was added, create a tagteam with it
    #and the first primary outfile/suffix type
    if($default_outfile_added || $default_outfile_suffix_added)
      {
	my $def_outf_suff_id = '';
	if($default_outfile_added)
	  {$def_outf_suff_id = (getSuffixIDs($default_outfile_id))[0]}
	if($default_outfile_added && $default_outfile_suffix_added)
	  {
	    if(!$default_tagteam_added)
	      {createSuffixOutfileTagteam($default_outfile_suffix_id,
					  $def_outf_suff_id)}
	  }
	elsif($default_outfile_suffix_added)
	  {
	    my $prim_outf_usg_hash = getDefaultPrimaryOutUsageHash(0);
	    debug({LEVEL => -1},"The first primary out usage hash has [",
		  scalar(keys(%$prim_outf_usg_hash)),"] keys,",
		  (exists($prim_outf_usg_hash->{FILEID}) ? '' : ' but not'),
		  " including FILEID.  The hash is: [\n",
		  join("\n",map {"$_\t" .
				   (defined($prim_outf_usg_hash->{$_}) ?
				    $prim_outf_usg_hash->{$_} : 'undef')}
		       keys(%$prim_outf_usg_hash)),"\n].");

	    my $outf_linked_inf_id =
	      (map {$_->[1]} grep {$prim_outf_usg_hash->{FILEID} == $_->[0]}
	       @$required_relationships)[0];
	    my $suff_linked_inf_id =
	      $suffix_id_lookup->[$default_outfile_suffix_id]->[0];

	    #If both outfile types are linked to the same input file type, go
	    #ahead and create the tagteam, otherwise, skip it.  Note: Defined
	    #state is checked because an outfile type can be created without
	    #linking it to an input file.
	    if(defined($outf_linked_inf_id) &&
	       $outf_linked_inf_id == $suff_linked_inf_id)
	      {
		my $outf_ids = getSuffixIDs($prim_outf_usg_hash->{FILEID});
		my $outf_id = $outf_ids->[0];
		if(scalar(@$outf_ids) > 1)
		  {warning("Unexpected number of suffix IDs associated with ",
			   "outfile type: [$prim_outf_usg_hash->{FILEID}].")}
		createSuffixOutfileTagteam($default_outfile_suffix_id,
					   $outf_id);
	      }
	    else
	      {debug({LEVEL => -1},"Skipping tagteam creation because each ",
		     "outfile type is linked to different infiles.")}
	  }
	elsif($default_outfile_added)
	  {
	    my $prim_suff_usg_hash = getDefaultPrimaryOutUsageHash(1);
	    my $outf_linked_inf_id =
	      (map {$_->[1]}
	       grep {$suffix_id_lookup->[$def_outf_suff_id]->[0] == $_->[0]}
	       @$required_relationships)[0];
	    my $suff_linked_inf_id =
	      $suffix_id_lookup->[$prim_suff_usg_hash->{FILEID}]->[0];

	    #If both outfile types are linked to the same input file type, go
	    #ahead and create the tagteam, otherwise, skip it.
	    if($outf_linked_inf_id == $suff_linked_inf_id)
	      {createSuffixOutfileTagteam($prim_suff_usg_hash->{FILEID},
					  $def_outf_suff_id)}
	  }
      }

    #If the programmer did not add an outdir option, add a default
    if(!$outdirs_added)
      {
	addOutdirOption();

	my $od_usg_hash = getOutdirUsageHash();

	#Append notes to detail_descs of default-added outfile types and
	#outfile suffix types (if the outdir type created above is not hidden)
	#to indicate that they will deposit their files in the supplied outdir

	if(!$od_usg_hash->{HIDDEN})
	  {
	    if($default_outfile_suffix_added)
	      {
		my $suf_usg_hash =
		  getOutfileUsageHash($default_outfile_suffix_id);
		$suf_usg_hash->{DETAILS} .= "  Does not replace extensions.  " .
		  "Output files are placed in the same directory as each " .
		    "input file (unless [" . getOutdirFlag() . "] is " .
		      "supplied).  Will not overwrite without --overwrite.";
	      }

	    if($default_outfile_added)
	      {
		#This assumes there's only 1 (hidden) suffix when the type is
		#outfile
		my $of_usg_hash =
		  getOutfileUsageHash((getSuffixIDs($default_outfile_id))[0]);
		$of_usg_hash->{DETAILS} .= "  Output files are placed in " .
		  "the current directory (unless [" . getOutdirFlag() .
		    "] is supplied).  Will not overwrite without --overwrite.";
	      }
	  }
      }
    else
      {
	my $od_usg_hash = getOutdirUsageHash();

	#Tell user where output will go if hidden and there's a default
	if($od_usg_hash->{HIDDEN} && defined($od_usg_hash->{DEFAULT}) &&
	   $od_usg_hash->{DEFAULT} ne '')
	  {
	    if($default_outfile_suffix_added)
	      {
		my $suf_usg_hash =
		  getOutfileUsageHash($default_outfile_suffix_id);
		$suf_usg_hash->{DETAILS} .= "\n\nOutput files will be " .
		  "placed in [$od_usg_hash->{DEFAULT}].";
	      }

	    if($default_outfile_added)
	      {
		#This assumes there's only 1 (hidden) suffix when the type is
		#outfile
		my $of_usg_hash =
		  getOutfileUsageHash((getSuffixIDs($default_outfile_id))[0]);
		$of_usg_hash->{DETAILS} .= "\n\nOutput files will be placed " .
		  "in [$od_usg_hash->{DEFAULT}].  Output file paths are not " .
		    "allowed unless the default output directory is removed.";
	      }
	  }
      }
  }

#Returns true if the first (primary/required/unhidden) outfile type is 1:M or
#is not linked/related to an input file
sub isDefaultPrimaryOut1toMorUnrelated
  {
    my $prim_suff_usg_hash = getDefaultPrimaryOutUsageHash(0);

    #If there was no hash returned, return false
    if(scalar(keys(%$prim_suff_usg_hash)) == 0)
      {
	debug({LEVEL => -1},"No outfile types defined.");
	return(0);
      }

    my($file_index,$suffix_index);
    if($prim_suff_usg_hash->{OPTTYPE} eq 'suffix')
      {
	($file_index,$suffix_index) =
	  @{$suffix_id_lookup->[$prim_suff_usg_hash->{FILEID}]};
      }
    else
      {
	$file_index   = $prim_suff_usg_hash->{FILEID};
	$suffix_index = 0;
      }

    my $relats = [map {$_->[2]}
		  grep {$file_index == $_->[0]}
		  @$required_relationships];
    my $relat = (scalar(@$relats) ? $relats->[0] : '');

    debug({LEVEL => -1},"Relationship of primary out type [$file_index]: ",
	  "[$relat].");

    if($relat eq '1:M' || $relat eq '1' || $relat eq '')
      {return(1)}

    return(0);
  }

#Globals used: $usage_hash, $outfile_types_hash
sub getDefaultPrimaryOutUsageHash
  {
    my $get_suffix = $_[0];
    foreach my $usage_hash (sort {
      #Primary options first.  Of primary options, required first. Of primary-
      #required options, unhidden first.  The first primary required unhidden
      #option will be returned
      $b->{PRIMARY} <=> $a->{PRIMARY} || $b->{REQUIRED} <=> $a->{REQUIRED} ||
	$a->{HIDDEN} <=> $b->{HIDDEN}}
			    grep {$get_suffix ? ($_->{OPTTYPE} eq 'suffix') :
				    ($_->{OPTTYPE} eq 'outfile')}
			    @$usage_array)
      {
	#If we're looking for a purely suffix type and this is the hidden
	#suffix type of an outfile type, skip it
	if($get_suffix && $usage_hash->{FILEID} < scalar(@$suffix_id_lookup) &&
	   exists($outfile_types_hash->{$suffix_id_lookup
					->[$usage_hash->{FILEID}]->[0]}))
	  {next}
	return($usage_hash);
      }
    debug({LEVEL => -1},"There were no suffix IDs found for outfile type ",
	  "defined by ",($get_suffix ? 'suffix' : 'outfile name'));
    return({});
  }

#This returns the default primary out's suffix type's FILETYPEID or outfile
#type's PAIR_WITH ID - whichever is the default primary out type.  Returns
#undef if PAIR_WITH is not defined or if no outfile types have been defined
sub getDefaultPrimaryLinkedInfileID
  {
    my $outfile_usage_hash = getDefaultPrimaryOutUsageHash();
    my $outfile_index = (defined($outfile_usage_hash) ?
			 $outfile_usage_hash->{FILEID} : undef);
    debug({LEVEL => -1},"Outfile index selected as default primary: [",
	  (defined($outfile_index) ? $outfile_index : 'undef'),
	  "] which belongs to [",
	  (defined($outfile_index) ? getOutfileFlag($outfile_index,-1) :
	   'undef'),"] and [",($outfile_usage_hash->{PRIMARY} ?
			       'is' : 'is not'),"] primary.");
    #I need the outfile_id to tell which one is the lesser between it and the
    #suffix ID...
    #There should be only 1 ID for this type since it's an outfile type, or at
    #least the first one will be the relevant one (if I ever add the ability to
    #add other suffixes to outfile types)
    my $outfile_id = (defined($outfile_index) ?
		      (getSuffixIDs($outfile_index))[0] : undef);
    my($linked_index1);
    if(defined($outfile_index) &&
       scalar(grep {$_->[0] == $outfile_index} @$required_relationships))
      {$linked_index1 =
	 (grep {$_->[0] == $outfile_index} @$required_relationships)[0]->[1]}

    my $suffix_usage_hash  = getDefaultPrimaryOutUsageHash(1);
    my $suffix_id = (defined($suffix_usage_hash) ?
		     $suffix_usage_hash->{FILEID} : undef);
    debug({LEVEL => -1},"Suffix ID selected as default primary: [",
	  (defined($suffix_id) ? $suffix_id : 'undef'),
	  "] which belongs to [",
	  (defined($suffix_id) ? getOutfileSuffixFlag($suffix_id,-1) :
	   'undef'),"] and [",($suffix_usage_hash->{PRIMARY} ?
			       'is' : 'is not'),"] primary.");
    my $linked_index2 = (defined($suffix_id) ?
			 $suffix_id_lookup->[$suffix_id]->[0] : undef);

    my($primary_linked_index);
    if(defined($outfile_id) && defined($suffix_id))
      {$primary_linked_index = ($outfile_id < $suffix_id ?
				$linked_index1 : $linked_index2)}
    elsif(defined($outfile_id))
      {$primary_linked_index = $linked_index1}
    #Else - either linked_index2 is defined and primary or undefined and there
    #is no primary
    else
      {$primary_linked_index = $linked_index2}

    debug({LEVEL => -1},"Returning primary linked index: [",
	  (defined($primary_linked_index) ? $primary_linked_index : 'undef'),
	  "] for infile type [",
	  (defined($primary_linked_index) ?
	   getInfileFlag($primary_linked_index) : 'undef'),"].");
    return($primary_linked_index);
  }

sub getDefaultPrimaryInfileID
  {
    #If the primary infile type has already been defined
    if(defined($primary_infile_type))
      {return($primary_infile_type)}
    #If there are no input file types
    elsif(getNumInfileTypes() == 0)
      {return(undef)}

    #Return the first after sorting by ascending explicitly-set non-primary
    #status (i.e. if the programmer explicitly set a file type to not be
    #primary, it's the LAST choice if *every* file type is not primary),
    #descending primary status (though all should be 0 - we'll do this as a
    #safeguard), descending required status, ascending hidden status, or order
    #in which they were created
    return((sort {my $ua = getInfileUsageHash($a);
		  my $ub = getInfileUsageHash($b);
		  exists($exp_nonprimary_inf_types->{$a}) <=>
		    exists($exp_nonprimary_inf_types->{$b}) ||
		      $ub->{PRIMARY} <=> $ua->{PRIMARY} ||
			$ub->{REQUIRED} <=> $ua->{REQUIRED} ||
			  $ua->{HIDDEN} <=> $ub->{HIDDEN} || $a <=> $b}
	    grep {!exists($outfile_types_hash->{$_})}
	    (0..$#{$input_files_array}))[0])
  }

sub getNumInfileTypes
  {
    my $ifa = (defined($_[0]) ? $_[0] : $input_files_array);

    #getFileSets, called at the bottom of processCommandLine (just before
    #$command_line_processed is set to 2) adds an outdirs array to the
    #input_files_array, thus if any outdirs exist, we must subtract 1 from the
    #total

    return(scalar(@$ifa)                            #Num file types
	   - scalar(keys(%$outfile_types_hash))     #Num outfile types
	   - ($command_line_processed == 2 && scalar(@$outdirs_array) ? 1 : 0));
  }

sub getInfileIndexes
  {
    my $ifa = (defined($_[0]) ? $_[0] : $input_files_array);

    #getFileSets, called at the bottom of processCommandLine (just before
    #$command_line_processed is set to 2) adds an outdirs array to the
    #input_files_array, thus if any outdirs exist, we must subtract 1 from the
    #total

    my $indexes =
      [grep {!exists($outfile_types_hash->{$_})}
       (0..($#{$input_files_array} - ($command_line_processed == 2 &&
				      scalar(@$outdirs_array) ? 1 : 0)))];
    return(wantarray ? @$indexes : $indexes);
  }

sub getNumSuffixTypes
  {
    my $num = 0;

    foreach my $inf_type (0..$#{$outfile_suffix_array})
      {
	next if(exists($outfile_types_hash->{$inf_type}));
	$num += scalar(@{$outfile_suffix_array->[$inf_type]});
      }

    return($num);
  }

#Variable options are those whose availability varies based on the
#default_run_mode.  They include: --run, --dry-run, --usage, & --help.  This
#method adds --usage, --help, --run, and/or --dry-run to accommodate the
#default_run_mode.
#
#NOTE: various calls to addOption will set a value in the global GetOptHash,
#but those values already exist for the options this method adds (e.g. --help).
#That's fine.  The values were pre-added so that user defaults could be read in
#to establish a user-defined default run mode.
#
#Uses globals: $default_run_mode, $run, $dry_run, $explicit_dry_run,
#              $explicit_run, $explicit_usage, $explicit_help, $GetOptHash
sub addRunModeOptions
  {
    my $help_smry      = ('Print general info and file formats.');
    my $help_desc      = ('Print general info and file format ' .
			  'descriptions.  Includes advanced usage examples ' .
			  'with --extended.');
    my $usage_smry     = ('');
    my $usage_desc     = ('Print this usage message.');
    my $run_smry       = ('Run the script.');
    my $run_desc       = ('This option runs the script.  It is only ' .
			  'necessary to supply this option if the script ' .
			  'contains no required options or when all ' .
			  'required options have default values that are ' .
			  'either hard-coded, or provided via --save-args.');
    my $dry_run_smry   = ('');
    my $dry_run_desc   = ('Run without generating output files.');

    if($default_run_mode ne 'run'  && $default_run_mode ne 'usage' &&
       $default_run_mode ne 'help' && $default_run_mode ne 'dry-run')
      {
	error("Invalid DEFRUNMODE: [$default_run_mode].  Must be one of ",
	      "['run','dry-run','usage','help'].  See ",
	      "setDefaults(DEFRUNMODE => ...).");
	quit(-9);
      }

    #Determine whether required options exist - assumes user defaults are set
    my $status = getRunModeStatus(); #Returns: ready(0), not_ready(1), or
                                     #unknown(-1)

    my $usage_hidden   = 0;
    my $help_hidden    = 0;
    my $run_hidden     = 0;
    my $dry_run_hidden = 0;

    if($status == 1) #Required opts exist without default values
      {
	if($default_run_mode eq 'usage' || $default_run_mode eq 'run')
	  {
	    $usage_hidden = 1;
	    $run_hidden   = 1;
	  }
	elsif($default_run_mode eq 'dry-run')
	  {
	    $usage_hidden   = 1;
	    $dry_run_hidden = 1;
	  }
	elsif($default_run_mode eq 'help')
	  {
	    $help_hidden = 1;
	    $run_hidden  = 1;
	  }

	#Add --usage as shown optional opt using addOption
	addOption(GETOPTKEY   => 'usage',
		  GETOPTVAL   => \$explicit_usage,
		  TYPE        => 'bool',
		  REQUIRED    => 0,
		  HIDDEN      => $usage_hidden,
		  SMRY_DESC   => $usage_smry,
		  DETAIL_DESC => $usage_desc);

	#Add --help as a hidden optional opt using addOption
	addOption(GETOPTKEY   => 'help',
		  GETOPTVAL   => \$explicit_help,
		  TYPE        => 'bool',
		  REQUIRED    => 0,
		  HIDDEN      => $help_hidden,
		  SMRY_DESC   => ($default_run_mode eq 'help' && $help &&
				  defined($help_smry) && $help_smry ne '' ?
				  '[On] ' : '') . $help_smry,
		  DETAIL_DESC => (($default_run_mode eq 'help' ?
				   '[On] ' : '') .
				  $help_desc));

	#Add --run as a hidden optional opt using addOption
	addOption(GETOPTKEY   => 'run',
		  GETOPTVAL   => \$explicit_run,
		  TYPE        => 'bool',
		  REQUIRED    => 0,
		  HIDDEN      => $run_hidden,
		  SMRY_DESC   => $run_smry,
		  DETAIL_DESC => $run_desc);

	#Add --dry-run as a shown optional opt using addOption
	addOption(GETOPTKEY   => 'dry-run',
		  GETOPTVAL   => \$explicit_dry_run,
		  TYPE        => 'bool',
		  REQUIRED    => 0,
		  HIDDEN      => $dry_run_hidden,
		  SMRY_DESC   => $dry_run_smry,
		  DETAIL_DESC => $dry_run_desc);
      }
    elsif($status == 0) #No required opts or all reqd opts have defaults
      {
	if($default_run_mode eq 'run')
	  {
	    #Add --run as a hidden optional opt using addOption
	    addOption(GETOPTKEY   => 'run',
		      GETOPTVAL   => \$explicit_run,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 1,
		      SMRY_DESC   => ($run &&
				      defined($run_smry) && $run_smry ne '' ?
				      '[On] ' : '') . $run_smry,
		      DETAIL_DESC => '[On] ' . $run_desc);

	    #Add --dry-run as a shown optional opt using addOption
	    addOption(GETOPTKEY   => 'dry-run',
		      GETOPTVAL   => \$explicit_dry_run,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 0,
		      SMRY_DESC   => $dry_run_smry,
		      DETAIL_DESC => $dry_run_desc);
	  }
	elsif($default_run_mode eq 'dry-run')
	  {
	    #Add --run as a shown optional opt using addOption
	    addOption(GETOPTKEY   => 'run',
		      GETOPTVAL   => \$explicit_run,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 0,
		      SMRY_DESC   => $run_smry,
		      DETAIL_DESC => $run_desc);

	    #Add --dry-run as a hidden optional opt using addOption
	    addOption(GETOPTKEY   => 'dry-run',
		      GETOPTVAL   => \$explicit_dry_run,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 1,
		      SMRY_DESC   => ($dry_run &&
				      (defined($dry_run_smry) &&
				       $dry_run_smry ne '' ? '[On] ' : '') .
				      $dry_run_smry),
		      DETAIL_DESC => '[On] ' . $dry_run_desc);
	  }
	else
	  {
	    #Add --run as a shown optional opt using addOption
	    addOption(GETOPTKEY   => 'run',
		      GETOPTVAL   => \$explicit_run,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 0,
		      SMRY_DESC   => $run_smry,
		      DETAIL_DESC => $run_desc);

	    #Add --dry-run as a shown optional opt using addOption
	    addOption(GETOPTKEY   => 'dry-run',
		      GETOPTVAL   => \$explicit_dry_run,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 0,
		      SMRY_DESC   => $dry_run_smry,
		      DETAIL_DESC => $dry_run_desc);
	  }

	if($default_run_mode eq 'help')
	  {
	    #Add --usage as a shown optional opt using addOption
	    addOption(GETOPTKEY   => 'usage',
		      GETOPTVAL   => \$explicit_usage,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 0,
		      SMRY_DESC   => $usage_smry,
		      DETAIL_DESC => $usage_desc);

	    #Add --help as a hidden optional opt using addOption
	    addOption(GETOPTKEY   => 'help',
		      GETOPTVAL   => \$explicit_help,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 1,
		      SMRY_DESC   => (($help && defined($help_smry) &&
				       $help_smry ne '' ? '[On] ' : '') .
				      $help_smry),
		      DETAIL_DESC => '[On] ' . $help_desc);
	  }
	elsif($default_run_mode eq 'usage')
	  {
	    #Add --usage as a hidden optional opt using addOption
	    addOption(GETOPTKEY   => 'usage',
		      GETOPTVAL   => \$explicit_usage,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 1,
		      SMRY_DESC   => (($usage && defined($usage_smry) &&
				       $usage_smry ne '' ? '[On] ' : '') .
				      $usage_smry),
		      DETAIL_DESC => $usage_desc);

	    #Add --help as a shown optional opt using addOption
	    addOption(GETOPTKEY   => 'help',
		      GETOPTVAL   => \$explicit_help,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 0,
		      SMRY_DESC   => $help_smry,
		      DETAIL_DESC => $help_desc);
	  }
	else
	  {
	    #Add --usage as a shown optional opt using addOption
	    addOption(GETOPTKEY   => 'usage',
		      GETOPTVAL   => \$explicit_usage,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 0,
		      SMRY_DESC   => (($default_run_mode eq 'usage' &&
				       $usage && defined($usage_smry) &&
				       $usage_smry ne '' ? '[On] ' : '') .
				      $usage_smry),
		      DETAIL_DESC => $usage_desc);

	    #Add --help as a shown optional opt using addOption
	    addOption(GETOPTKEY   => 'help',
		      GETOPTVAL   => \$explicit_help,
		      TYPE        => 'bool',
		      REQUIRED    => 0,
		      HIDDEN      => 0,
		      SMRY_DESC   => $help_smry,
		      DETAIL_DESC => $help_desc);
	  }
      }
    else #status=-1 - Reqd opts exist but we don't know if they all have values
      {
	#Add --usage as shown optional opt using addOption
	addOption(GETOPTKEY   => 'usage',
		  GETOPTVAL   => \$explicit_usage,
		  TYPE        => 'bool',
		  REQUIRED    => 0,
		  HIDDEN      => 0,
		  SMRY_DESC   => $usage_smry,
		  DETAIL_DESC => $usage_desc);

	#Add --help as a shown optional opt using addOption
	addOption(GETOPTKEY   => 'help',
		  GETOPTVAL   => \$explicit_help,
		  TYPE        => 'bool',
		  REQUIRED    => 0,
		  HIDDEN      => 0,
		  SMRY_DESC   => $help_smry,
		  DETAIL_DESC => $help_desc);

	#Add --run as a shown optional opt using addOption
	addOption(GETOPTKEY   => 'run',
		  GETOPTVAL   => \$explicit_run,
		  TYPE        => 'bool',
		  REQUIRED    => 0,
		  HIDDEN      => 0,
		  SMRY_DESC   => $run_smry,
		  DETAIL_DESC => $run_desc);

	#Add --dry-run as a shown optional opt using addOption
	addOption(GETOPTKEY   => 'dry-run',
		  GETOPTVAL   => \$explicit_dry_run,
		  TYPE        => 'bool',
		  REQUIRED    => 0,
		  HIDDEN      => 0,
		  SMRY_DESC   => $dry_run_smry,
		  DETAIL_DESC => $dry_run_desc);
      }
  }

#This adds all the builtin options like verbose, overwrite, etc..  All these
#options are highly integrated into all functionality and cannot be disabled.
#However future versions of this module may allow them to be hidden.
#Globals used: $overwrite,$skip_existing,$append,$force,$verbose,$quiet,$DEBUG,
#              $extended,$version,$header,$error_limit,$use_as_default,
#              $user_collide_mode,$pipeline_mode,$error_limit_default
sub addBuiltinOptions
  {
    #short_descs extended 0
    my $extended_short = 'Print detailed usage.';

    #long_descs extended 1
    my $verbose_long   = 'Verbose mode.';

    my $quiet_long     = 'Quiet mode.';

    my $overwrite_long = join('',('Overwrite existing output files.  By ',
				  'default, existing output files will not ',
				  'be over-written.  Mutually exclusive with ',
				  '--skip and --append.'));

    my $skip_long      = join('',('Skip existing output files.  Mutually ',
				  'exclusive with --overwrite and --append.'));

    my $header_long    = join('',('Outfile header flag.  Headers are ',
				  "commented with '#' and include script ",
				  'version, date, and command line call at',
				  ' the top of every output file.  See ',
				  '--extended.'));

    my $version_long   = 'Print version info.  See --extended.';

    my $extended_long  = join('',('Print extended usage/help/version/header ',
				  '(and errors/ warnings where noted).  ',
				  'Supply alone for extended usage.  ',
				  'Includes extended version in output file ',
				  'headers.  Incompatible with --noheader.  ',
				  'See --help & --version.'));

    #long_descs - extended 2 (advanced)
    my $force_long     = join('',('Prevent script-exit upon fatal error.  ',
				  'Use with extreme caution.  Will not ',
				  'override overwrite protection (see ',
				  '--overwrite or --skip).'));

    my $debug_long     = join('',('Debug mode.  Prepends trace to warning/',
				  'error messages.  Prints debug() messages ',
				  'based on debug level.  Values less than 0 ',
				  'debug the CommandLineInterface module ',
				  'used by this script.'));

    #If there are user defaults, include --save-args in the short usage
    my $save_args_def  = join(' ',getUserDefaults());
    my $save_args_shrt = ($save_args_def ne '' ? 'Save accompanying command ' .
			  'line arguments as defaults.' : '');
    my $save_args_long = join('',('Save accompanying command line arguments ',
				  'as defaults to be used in every call of ',
				  'this script.  Replaces previously saved ',
				  'args.  Supply without other args to ',
				  'removed saved args.'));

    my $pipeline_long  = join('',('Supply --pipeline to include the script ',
				  'name in errors, warnings, and debug ',
				  'messages.  If not supplied (and no ',
				  'default set), the script will ',
				  'automatically determine if it is running ',
				  'within a series of piped commands or as a ',
				  'part of a parent script.  Note, supplying ',
				  'either flag will prevent that check from ',
				  'happening.'));

    my $errlim_long    = join('',('Limits each type of error/warning to this ',
				  'number of outputs.  Intended to declutter ',
				  'output.  Note, a summary of warning/error ',
				  'types is printed when the script ',
				  'finishes, if one occurred or if in ',
				  'verbose mode.  0 = no limit.  See also ',
				  '--quiet.'));

    my $append_long    = join('',('Append mode.  Appends output to all ',
				  'existing output files instead of skipping ',
				  'or overwriting them.  This is useful for ',
				  'checkpointed jobs on a cluster.  Mutually ',
				  'exclusive with --overwrite and --skip.'));

    #long_descs - hidden
    my $cd = (#Case 1: User default (set via --save-args)
	      defined($user_collide_mode) ? '' :
	      (#Case 2: Programmer default (set via setDefaults)
	       defined($def_collide_mode) ? '' :
	       #Case 3: Default depends on out type
	       "\n\n* The default differs based on whether the output file " .
	       "is specified by an outfile suffix (in which case the " .
	       "default is [$def_collide_mode_suff]) or by a full output " .
	       "file name (in which case the default is " .
	       "[$def_collide_mode_outf])."));
    my $collision_long = join('',('DEPRECATED.  When multiple input files ',
				  'output to the same output file, this ',
				  'option specifies what to do.  Merge mode ',
				  'will concatenate output in the common ',
				  'output file.  Rename mode (valid only if ',
				  'this script accepts multiple types of ',
				  'input files) will create a unique output ',
				  'file name by appending a unique ',
				  'combination ofinput file names together ',
				  '(with a delimiting dot).  Rename mode ',
				  'will throw an error if a unique file name ',
				  'cannot be constructed (e.g. when 2 input ',
				  'files of the same name in different ',
				  'directories are outputting to a common ',
				  'directory).  Error mode causes the script ',
				  'to quit with an error if multiple input ',
				  'files are detected to output to the same ',
				  "output file.${cd}\n\nTHIS OPTION IS ",
				  'DEPRECATED AND HAS BEEN REPLACED BY ',
				  'SUPPLYING COLLISION MODE VIA ',
				  'addOutFileSuffixOptionAND ',
				  'addOutfileOption.  THIS OPTION HOWEVER ',
				  'WILL OVERRIDE THE COLLISION MODE OF ALL ',
				  'OUTFILE OPTIONS AND APPLY TO FILES THAT ',
				  'ARE NOT DEFINED BY addOutFileSuffixOption ',
				  'OR addOutfileOption IF OPENED MULTIPLE ',
				  'TIMES UNLESS SET EXPLICITLY IN THE ',
				  'openOut CALL.'));

    addOption(FLAG       => 'verbose',
	      VARREF     => \$verbose,
	      TYPE       => 'count',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $verbose_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 0);
    addOption(FLAG       => 'quiet',
	      VARREF     => \$quiet,
	      TYPE       => 'bool',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $quiet_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 0);
    addOption(FLAG       => 'overwrite',
	      VARREF     => \$overwrite,
	      TYPE       => 'count',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $overwrite_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 0);
    addOption(FLAG       => 'skip',
	      VARREF     => \$skip_existing,
	      TYPE       => 'bool',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $skip_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 0);
    addOption(FLAG       => 'header',
	      VARREF     => \$header,
	      TYPE       => 'negbool',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $header_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 0);
    addOption(FLAG       => 'version',
	      VARREF     => \$version,
	      TYPE       => 'bool',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $version_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 0);
    addOption(FLAG       => 'extended',
	      VARREF     => \$extended,
	      TYPE       => 'count',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => $extended_short,
	      LONG_DESC  => $extended_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 0);
    addOption(FLAG       => 'force',
	      VARREF     => \$force,
	      TYPE       => 'count',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $force_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 1);
    addOption(FLAG       => 'debug',
	      VARREF     => \$DEBUG,
	      TYPE       => 'count',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $debug_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 1);
    addOption(FLAG       => 'save-args',
	      VARREF     => \$use_as_default,
	      TYPE       => 'bool',
	      REQUIRED   => 0,
	      DEFAULT    => $save_args_def,
	      HIDDEN     => 0,
	      SHORT_DESC => $save_args_shrt,
	      LONG_DESC  => $save_args_long,
	      ACCEPTS    => undef,
	      ADVANCED   => ($save_args_shrt eq '' ? 1 : 0));
    addOption(FLAG       => 'pipeline',
	      VARREF     => \$pipeline_mode,
	      TYPE       => 'negbool',
	      REQUIRED   => 0,
	      DEFAULT    => undef,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $pipeline_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 1);
    addOption(FLAG       => 'error-limit',
	      VARREF     => \$error_limit,
	      TYPE       => 'integer',
	      REQUIRED   => 0,
	      DEFAULT    => $error_limit_default,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $errlim_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 1);
    addOption(FLAG       => 'append',
	      VARREF     => \$append,
	      TYPE       => 'bool',
	      REQUIRED   => 0,
	      DEFAULT    => 0,
	      HIDDEN     => 0,
	      SHORT_DESC => '',
	      LONG_DESC  => $append_long,
	      ACCEPTS    => undef,
	      ADVANCED   => 1);
    addOption(FLAG       => 'collision-mode',
	      VARREF     => \$user_collide_mode,
	      TYPE       => 'enum',
	      REQUIRED   => 0,
	      DEFAULT    => (#Case 1: User default (set via --save-args)
			     defined($user_collide_mode) ? $user_collide_mode :
			     (#Case 2: Programmer default (set via setDefaults)
			      defined($def_collide_mode) ? $def_collide_mode :
			      #Case 3: Default depends on out type
			      "$def_collide_mode_suff|$def_collide_mode_outf*")
			    ),
	      HIDDEN     => 1,
	      SHORT_DESC => '',
	      LONG_DESC  => $collision_long,
	      ACCEPTS    => ['merge','rename','error'],
	      ADVANCED   => 1);
  }

#This sub mainly adds little details to the usage and help output to explain
#various built-in behaviors, relationships, and settings.  Should only be
#called once.  E.g. It appends the location of the defaults_dir to the
#--save-args usage.
sub applyOptionAddendums
  {
    #Append the location of the defaults directory to the --save-args option
    my $defdir = (defined($defaults_dir) ?
		  $defaults_dir : (sglob('~/.rpst'))[0]);
    $defdir = 'undefined' if(!defined($defdir));
    my $saveargs_usg = getUsageHash('save-args');
    $saveargs_usg->{DETAILS} .= "  Values are stored in [$defdir].";

    #Append overwrite's outdir abilities if an outdir option exists
    my $odf = getOutdirFlag();
    my $overwrite_usg = getUsageHash('overwrite:+');
    $overwrite_usg->{DETAILS} .= join('',('  Supply twice to safely remove ',
					  'pre-existing output directories ',
					  "(See $odf).  This will not remove ",
					  'a directory containing manually ',
					  'touched files.'));
  }

#Uses globals: $explicit_dry_run, $explicit_run, $explicit_usage,
#              $explicit_help, $run, $dry_run, $help, $usage
sub determineRunMode
  {
    my $determine_default_run_mode = (defined($_[0]) ? $_[0] : 0);

    #If the user explicitly set the run mode, there's nothing to be done
    if(setUserRunMode($determine_default_run_mode))
      {return()}

    my $real_args = argsOrPipeSupplied();
    my $status    = ($determine_default_run_mode ? getRunModeStatus() :
		     doUnsetRequiredOptionsExist());

    debug({LEVEL => -1},"Default? [$determine_default_run_mode] ",
	  "doUnsetRequiredOptionsExist: [$status].");

    $run     = 0;
    $dry_run = 0;
    $usage   = 0;
    $help    = 0;

    if($default_run_mode eq 'run')
      {
	if($status == 0) #No required opts or all have values
	  {$run = 1}
	else #Required opts not supplied
	  {
	    if(!$real_args) #No opts supplied
	      {$usage = 1}
	    else
	      {$usage = 2}
	  }
      }
    elsif($default_run_mode eq 'dry-run')
      {
	if($status == 0) #No required opts or all have values
	  {$dry_run = 1}
	else #Required opts not supplied
	  {
	    if(!$real_args) #No opts supplied
	      {$usage = 1}
	    else
	      {$usage = 2}
	  }
      }
    elsif($default_run_mode eq 'usage')
      {
	if($status == 0) #No required opts or all have values
	  {
	    if($real_args)
	      {$run = 1}
	    else
	      {$usage = 1}
	  }
	else #Required opts not supplied
	  {
	    if(!$real_args) #No opts supplied
	      {$usage = 1}
	    else
	      {$usage = 2}
	  }
      }
    elsif($default_run_mode eq 'help')
      {
	if($status == 0) #No required opts or all have values
	  {
	    if($real_args)
	      {$run = 1}
	    else
	      {$help = 1}
	  }
	else #Required opts not supplied
	  {
	    if(!$real_args) #No opts supplied
	      {$help = 1}
	    else
	      {$usage = 2}
	  }
      }

    if((($help ? 1 : 0) + ($usage ? 1 : 0) + ($run ? 1 : 0) +
	($dry_run ? 1 : 0)) > 1)
      {error("Internal error: Ambigous run mode.")}

    debug({LEVEL => -1},"Values of: --usage $usage --run $run --dry-run ",
	  "$dry_run --help $help.  Mode: $default_run_mode Args: $real_args ",
	  "Status: $status");
  }

#This sub determines whether required options without (global default values or
#user-supplied default values) exist.  Assumes user defaults have already been
#set and that the command line has not been processed yet (but user defaults
#have).
#Globals used: $required_infile_types, $required_suffix_types,
#              $required_outfile_types, $required_outdirs, $required_opt_refs
sub getRunModeStatus
  {
    #The following list of variables that track required options will be
    #checked for default values.  If a required option exists with no default,
    #returns 1(=not ready to run).  If no required options exist or all
    #required options have defaults, returns 0(=ready to run).  If for some
    #reason (e.g. a required value is a sub that it passed to GetOpt::Long),
    #required options exist, but whether they have a value or not cannot be
    #determined, returns -1(=unknown)
    #$required_infile_types,   #Array of indexes
    #$required_suffix_types,   #Array of arrays like [$idx,$suff_idx,$suff_id]
    #$required_outfile_types,  #Array of indexes
    #$required_outdirs,        #Integer/number
    #$required_opt_refs        #Array of arrays of [references to ? - must
    #                                               check,getoptstr,defstr]

    #If there are required input files
    if(scalar(@$required_infile_types) > 0)
       {
	 #For each input file type
	 foreach my $index (@$required_infile_types)
	   {
	     #default_infiles_array contains either undefined or validated 2D
	     #arrays that may or may not be populated based on the user.  If
	     #it's defined and populated, we can return true.
	     if(scalar(@$default_infiles_array) < ($index + 1) ||
	        !defined($default_infiles_array->[$index]) ||
	        scalar(@{$default_infiles_array->[$index]}) == 0)
	       {return(1)}
	     else
	       {
		 foreach my $inner_array (@{$default_infiles_array->[$index]})
		   {
		     if(scalar(@$inner_array) == 0)
		       {return(1)}
		   }
	       }
	   }
       }
    #If there are required suffixes
    if(scalar(@$required_suffix_types) > 0)
       {
	 #For each suffix type
	 foreach my $suffix_array (@$required_suffix_types)
	   {
	     my $infile_index = $suffix_array->[0];
	     my $suffix_index = $suffix_array->[1];

	     #Note, this will process outfiles as well, which contain
	     #artificial empty string (i.e. defined) suffixes, but that's OK.
	     #It won't affect the result and outfiles are checked for defaults
	     #later.

	     #The outer and inner arrays are guaranteed/assumed to be there
	     if(!defined($outfile_suffix_array->[$infile_index]
			 ->[$suffix_index]))
	       {return(1)}
	   }
       }
    #If there are required output files
    if(scalar(@$required_outfile_types) > 0)
       {
	 #For each output file type
	 foreach my $index (@$required_outfile_types)
	   {
	     #This is processed the exact same way as the infiles because that
	     #array is overloaded to contain outfiles as well.  Plus, the
	     #default is saved in the same way and an artificial empty string
	     #suffix is added.

	     #default_infiles_array contains either undefined or validated 2D
	     #arrays that may or may not be populated based on the user.  If
	     #it's defined and populated, we can return true.
	     if(scalar(@$default_infiles_array) < ($index + 1) ||
	        !defined($default_infiles_array->[$index]) ||
	        scalar(@{$default_infiles_array->[$index]}) == 0)
	       {return(1)}
	     else
	       {
		 foreach my $inner_array (@{$default_infiles_array->[$index]})
		   {
		     if(scalar(@$inner_array) == 0)
		       {return(1)}
		   }
	       }
	   }
       }
    #If there are required output directories
    if(defined($required_outdirs) && $required_outdirs > 0)
       {
	 #TODO: Add support for more outdir types.  See req 212
	 #Currently only 1 outdir type is supported.
	 if(!defined($default_outdirs_array) ||
	    scalar(@$default_outdirs_array) == 0)
	   {return(1)}
       }
    #If there are required general options
    if(scalar(@$required_opt_refs) > 0)
       {
	 #For each general option type
	 foreach my $opt_info (@$required_opt_refs)
	   {if(!wasGeneralOptionSupplied($opt_info))
	      {return(1)}}
       }

    return(0);
  }

#This sub determines whether required options without (global default values or
#user-supplied default values) exist.  Assumes user defaults have already been
#set.
#Globals used: $required_infile_types, $required_suffix_types,
#              $required_outfile_types, $required_outdirs, $required_opt_refs
sub doUnsetRequiredOptionsExist
  {
    #The following list of variables that track required options will be
    #checked for default values.  If a required option exists with no default,
    #resturns true, otherwise false.
    #$required_infile_types,   #Array of indexes
    #$required_suffix_types,   #Array of arrays like [$idx,$suff_idx,$suff_id]
    #$required_outfile_types,  #Array of indexes
    #$required_outdirs,        #Integer/number
    #$required_opt_refs        #Array of references to ? - must check

    #If there are required input files
    if(scalar(@$required_infile_types) > 0)
       {
	 #For each input file type
	 foreach my $index (@$required_infile_types)
	   {
	     #input_files_array contains either undefined or validated 2D
	     #arrays that may or may not be populated based on the user.  If
	     #it's defined and populated, we can return true.
	     if(scalar(@$input_files_array) < ($index + 1) ||
	        !defined($input_files_array->[$index]) ||
	        scalar(@{$input_files_array->[$index]}) == 0)
	       {return(1)}
	     else
	       {
		 foreach my $inner_array (@{$input_files_array->[$index]})
		   {
		     if(scalar(@$inner_array) == 0)
		       {return(1)}
		   }
	       }
	   }
       }
    #If there are required suffixes
    if(scalar(@$required_suffix_types) > 0)
       {
	 #For each suffix type
	 foreach my $suffix_array (@$required_suffix_types)
	   {
	     my $infile_index = $suffix_array->[0];
	     my $suffix_index = $suffix_array->[1];

	     #Note, this will process outfiles as well, which contain
	     #artificial empty string (i.e. defined) suffixes, but that's OK.
	     #It won't affect the result and outfiles are checked for defaults
	     #later.

	     #The outer and inner arrays are guaranteed/assumed to be there
	     if(!defined($outfile_suffix_array->[$infile_index]
			 ->[$suffix_index]))
	       {return(1)}
	   }
       }
    #If there are required output files
    if(scalar(@$required_outfile_types) > 0)
       {
	 #For each output file type
	 foreach my $index (@$required_outfile_types)
	   {
	     #This is processed the exact same way as the infiles because that
	     #array is overloaded to contain outfiles as well.  Plus, the
	     #default is saved in the same way and an artificial empty string
	     #suffix is added.

	     #default_infiles_array contains either undefined or validated 2D
	     #arrays that may or may not be populated based on the user.  If
	     #it's defined and populated, we can return true.
	     if(scalar(@$input_files_array) < ($index + 1) ||
	        !defined($input_files_array->[$index]) ||
	        scalar(@{$input_files_array->[$index]}) == 0)
	       {return(1)}
	     else
	       {
		 foreach my $inner_array (@{$input_files_array->[$index]})
		   {
		     if(scalar(@$inner_array) == 0)
		       {return(1)}
		   }
	       }
	   }
       }
    #If there are required output directories
    if(defined($required_outdirs) && $required_outdirs > 0)
       {
	 #TODO: Add support for more outdir types.  See req 212
	 #Currently only 1 outdir type is supported.
	 if(!defined($outdirs_array) || scalar(@$outdirs_array) == 0)
	   {return(1)}
       }
    #If there are required general options
    if(scalar(@$required_opt_refs) > 0)
       {foreach my $opt_info (@$required_opt_refs)
	  {if(!wasGeneralOptionSupplied($opt_info))
	     {return(1)}}}

    return(0);
  }

#Globals used: $GetOptHash
sub loadUserDefaults
  {
    debug({LEVEL => -1},"Default run mode before user: [$default_run_mode]");

    my @user_defaults = getUserDefaults();

    if(scalar(@user_defaults) == 0)
      {return(0)}

    debug({LEVEL => -1},"Loading user defaults: [",join(' ',@user_defaults),
	  "].");

    #Set user-saved defaults
    GetOptionsFromArray([@user_defaults],%$GetOptHash);

    #Run mode may have been changed by the user via --save-args
    setDefaultRunMode();

    updateDefaults(scalar(@user_defaults));

    debug({LEVEL => -1},"Default run mode after user: [$default_run_mode]");

    return(0);
  }

#This sets the default_run_mode based on flags supplied either on the command
#line or from a user saved default
sub setDefaultRunMode
  {
    my $num_exclusive_opts = (defined($explicit_dry_run) +
			      defined($explicit_run)     +
			      defined($explicit_usage)   +
			      defined($explicit_help));
    if($num_exclusive_opts > 1)
      {
	my @culprits = ();
	push(@culprits,'--run')     if(defined($explicit_run));
	push(@culprits,'--dry-run') if(defined($explicit_dry_run));
	push(@culprits,'--usage')   if(defined($explicit_usage));
	push(@culprits,'--help')    if(defined($explicit_help));
	error('The following supplied options are mutually exclusive: [',
	      join(',',@culprits),'].  Please provide only one.  If you ',
	      'supplied only 1 or none, please check your saved user ',
	      'defaults (reported at the bottom of the --usage output).');
	quit(-10);
      }

    if(defined($explicit_run))
      {$default_run_mode = 'run'}
    elsif(defined($explicit_dry_run))
      {$default_run_mode = 'dry-run'}
    elsif(defined($explicit_help))
      {$default_run_mode = 'help'}
    elsif(defined($explicit_usage))
      {$default_run_mode = 'usage'}

    #Clear out the explicit values so when we read the actual command line, we
    #know what was actually supplied
    undef($explicit_run);
    undef($explicit_dry_run);
    undef($explicit_help);
    undef($explicit_usage);

    debug({LEVEL => -1},"Default Run Mode: [$default_run_mode].");
  }

#This sets the default_run_mode based on flags supplied either on the command
#line or from a user saved default
sub setUserRunMode
  {
    my $determine_default_run_mode = $_[0];

    my $setit = 0;

    my $num_exclusive_opts = (defined($explicit_dry_run) +
			      defined($explicit_run)     +
			      defined($explicit_usage)   +
			      defined($explicit_help));
    if($num_exclusive_opts > 1)
      {
	my @culprits = ();
	push(@culprits,'--run')     if(defined($explicit_run));
	push(@culprits,'--dry-run') if(defined($explicit_dry_run));
	push(@culprits,'--usage')   if(defined($explicit_usage));
	push(@culprits,'--help')    if(defined($explicit_help));
	error('The following supplied options are mutually exclusive: [',
	      join(',',@culprits),'].  Please provide only one.  If you ',
	      'supplied only 1 or none, please check your saved user ',
	      'defaults (reported at the bottom of the --usage output).');
	unless($determine_default_run_mode)
	  {usage(1)}
	quit(-11,$determine_default_run_mode);
      }

    $run = $dry_run = $usage = $help = 0;

    if(defined($explicit_run))
      {
	$run   = 1;
	$setit = 1;
      }
    elsif(defined($explicit_dry_run))
      {
	$dry_run = 1;
	$setit   = 1;
      }
    elsif(defined($explicit_help))
      {
	$help  = 1;
	$setit = 1;
      }
    elsif(defined($explicit_usage))
      {
	$usage = 1;
	$setit = 1;
      }

    if((($help ? 1 : 0) + ($usage ? 1 : 0) + ($run ? 1 : 0) +
	($dry_run ? 1 : 0)) > 1)
      {error("Internal error: Ambigous run mode.")}

    return($setit);
  }

sub getOptions
  {
    #Get the input options & catch any errors in option parsing
    if(!GetOptions(%$GetOptHash))
      {
	#Try to guess which arguments GetOptions is complaining about
	my @possibly_bad = grep {!(-e $_)} grep {$_ ne '-'} map {@$_} map {@$_}
	  map {$input_files_array->[$_]}
	    grep {!exists($outfile_types_hash->{$_})}
	      (0..$#{$input_files_array});

	#We're quitting, so let's set the various options to false so
	#the buffered debug statements do not puke out on the terminal
	$DEBUG       = 0 if(!defined($DEBUG));
	$verbose     = 0 if(!defined($verbose));
	$quiet       = 0 if(!defined($quiet));
	$error_limit = 0 if(!defined($error_limit));
	$extended    = 0 if(!defined($extended));

	#This will set the usage, run, etc vars in a pinch
	determineRunMode(1);

	error('Getopt::Long::GetOptions reported an error while parsing the ',
	      'command line arguments.  The warning should be above.  Please ',
	      'correct the offending argument(s) and try again.');
	usage(1);
	quit(-12,0);
      }
    #Else if there are no flagless options but unprocessed arguments
    elsif((!defined($flagless_multival_type) || $flagless_multival_type < 0) &&
       scalar(@ARGV))
      {warning("Unprocessed/unrecognized command line arguments: [",
	       join(' ',map {/\s/ ? "'$_'" : $_} @ARGV),"].")}

    #Set defaults if not defined - assumes command line has already been parsed
    $default_stub        = 'STDIN' unless(defined($default_stub));
    $DEBUG               = 0       unless(defined($DEBUG));
    $quiet               = 0       unless(defined($quiet));
    $dry_run             = 0       unless(defined($dry_run));
    $help                = 0       unless(defined($help));
    $version             = 0       unless(defined($version));
    $use_as_default      = 0       unless(defined($use_as_default));
    $skip_existing       = 0       unless(defined($skip_existing));
    $overwrite           = 0       unless(defined($overwrite));
    $append              = 0       unless(defined($append));
    $verbose             = 0       unless(defined($verbose));
    $force               = 0       unless(defined($force));
    $header              = 0       unless(defined($header));
    $extended            = 0       unless(defined($extended));
    $error_limit_default = 5       unless(defined($error_limit_default));
    $error_limit         = $error_limit_default unless(defined($error_limit));
    $defaults_dir        =(sglob('~/.rpst'))[0] unless(defined($defaults_dir));
    $preserve_args       = [@ARGV]   unless(defined($preserve_args));
    $created_on_date     = 'UNKNOWN' unless(defined($created_on_date));
    $script_version_number = 'UNKNOWN'
      unless(defined($script_version_number));

    #If pipeline mode is not defined and I know it will be needed (i.e. we
    #anticipate there will be messages printed on STDERR because either verbose
    #or DEBUG is true), guess - otherwise, do it lazily (in the warning or
    #error subs) because pgrep & lsof can be slow sometimes
#    if(!defined($pipeline_mode) && ($verbose || $DEBUG))
#      {$pipeline_mode = inPipeline()}

    #Now that all the vars are set, flush the buffer if necessary
    flushStderrBuffer();

    return(0);
  }

sub processCommandLine
  {
    #Only ever run once (unless _init has been called)
    if($processCommandLine_called)
      {
	error("processCommandLine() has been called more than once ",
	      "without re-initializing.");
	return(0);
      }
    else
      {$processCommandLine_called = 1}

    #In case the programmer did not add any in/out files/dirs, add defaults
    addDefaultFileOptions();

    #Add the builtin options after the programmer's and default file opts
    addBuiltinOptions();

    #Clear out array defaults so that user defaults and user supplied values
    #don't append to them, but rather set the arrays from scratch.  We will re-
    #load them in loadDefaults (if the user didn't supply values).  We're doing
    #this here instead of earlier because we have references to array variables
    #in main and don't want to change them until the last moment (during
    #processCommandLine) so that the programmer can access the default values
    #they set before the user changes them.  And we need to do it before
    #loading the user defaults so they won't be appended together with the
    #programmer's defaults.
    clearArrayDefaults();

    #Set user-saved defaults
    loadUserDefaults();

    #Set the defaults for the usage
    $extended_def      = $extended;
    $verbose_def       = $verbose;
    $DEBUG_def         = $DEBUG;
    $force_def         = $force;
    $overwrite_def     = $overwrite;
    $pipeline_mode_def = $pipeline_mode;

    #Determine the default run mode (based possibly on user defaults)
    determineRunMode(1);

    #Adds --usage --run --help and/or --dry-run (see setDefaults(DEFRUNMODE =>
    #...)).  We're doing this after setting user defaults because if required
    #options have defaults, we don't want the script to run without an explicit
    #option manually provided.
    addRunModeOptions();

    #Certain options need to get addendums or be modified after user defaults
    #have been processed.  Mostly, these are automated notes added to the usage
    applyOptionAddendums();

    #Get the input options & catch any errors in option parsing
    my $status_code = getOptions();
    if($status_code && (!defined($force) || !$force))
      {return($status_code)}

    #Set the fact that the command line has been processed (after having added
    #the default options above with the calls to addDefaultFileOptions and
    #addRunModeOptions (because adding options checks this value to
    #decide whether adding options is valid))
    $command_line_processed = 1;

    #If we're in cleanup mode after a fatal error has occurred, quit has
    #already been called and all we needed to do was make sure all the command
    #line options had been added so that getOptions doesn't issue irrelevant
    #warnings.
    if($cleanup_mode > 1)
      {
	$command_line_processed = 2;
	return(0);
      }

    ##
    ## Validate Options
    ##

    #Load all the previously saved default values for input files, output
    #files, output directories, arrays, and 2D arrays
    loadDefaults();

    #Allow the user to over-ride the run mode explicitly
    determineRunMode();

    debug({LEVEL => -1},"Processing default options.");

    #Process & validate default options (supply whether there will be outfiles)
    processDefaultOptions(scalar(@$outfile_suffix_array));

    #If processCommandLine was called from quit (e.g. via the END block), calls
    #to quit (e.g. when usage or help modes are active) will not work (because
    #quit has already been called), so we must return here in either of those
    #cases to not generate weird errors.
    if($help || $usage == 1)
      {return(0)}

    debug({LEVEL => -1},"Done processing default options.");

    #The addRunModeOptions determineRunMode methods, (each
    #called earlier/above) establish whether the script should proceed or not
    #using $run and $dry_run.  We're going to evaluate the result here.
    if(!defined($run) || !defined($dry_run))
      {
	error("Fatal internal error - internal variables \$run and/or ",
	      "$dry_run should have had a default set.  Aborting run.  Use ",
	      "--force to get past this error.");
	quit(-13);
      }

    #If run and dry run are both false and this isn't an error state that will
    #be caught below (e.g. missing required params), error & quit
    if($usage != 2 && !$run && !$dry_run)
      {
	debug({LEVEL => -1},"Running with --usage [$usage] --help [$help] ",
	      "--run [$run] --dry-run [$dry_run]");

	#We're going to assume that this will only happen if --run is provided
	#as an option in the usage output.
	error("Either --run or --dry-run are required to run this script.  ",
	      "See --usage for details.  Note: --force will not circumvent ",
	      "this error.");
	#Do not allow the user to --force their way past this error
	$force = 0;
	quit(-14);
      }

    #Make sure there is input
    if(scalar(grep {!exists($outfile_types_hash->{$_})}
	      (0..$#{$input_files_array})) == 0 &&
       !isThereInputOnSTDIN() && (scalar(@$required_infile_types)))
      {
	error('No input detected.');
	usage(1);
	quit(-15);
      }

    #Make sure that the tagteams' suffix and outfile options' mutual
    #exclusivity is enforced.  This also records which option was supplied on
    #the command line in tagteam_to_supplied_oid
    foreach my $ttkey (keys(%$outfile_tagteams))
      {validateTagteam($ttkey)}

    #This makes sure that required tagteams had 1 of their 2 linked options
    #supplied
    my($missing_flags,$conflicting_flags) =
      getMissingConflictingTagteamFlags();
    my $requirement_defficiency = scalar(@$missing_flags);

    debug({LEVEL => -1},"Checking [",scalar(@$required_infile_types),
	  "] required input file types");

    foreach my $req_type (@$required_infile_types)
      {
	if(getNumInfileTypes() == 0 ||
	   (scalar(@{$input_files_array->[$req_type]}) == 0 &&
	    (defined($primary_infile_type) &&
	     ($req_type != $primary_infile_type || !isThereInputOnSTDIN()))))
	  {
	    my $iflag = getInfileFlag($req_type);
	    push(@$missing_flags,
		 (defined($iflag) && $iflag ne '' ?
		  $iflag : 'internal error'));
	    $requirement_defficiency = 1;
	  }
      }

    foreach my $req_type (@$required_suffix_types)
      {
	if(scalar(@$outfile_suffix_array) == 0 ||
	   !defined($outfile_suffix_array->[$req_type->[0]]) ||
	   scalar(@{$outfile_suffix_array->[$req_type->[0]]}) == 0 ||
	   !defined($outfile_suffix_array->[$req_type->[0]]->[$req_type->[1]]))
	  {
	    push(@$missing_flags,getOutfileSuffixFlag($req_type->[2]));
	    $requirement_defficiency = 1;
	  }
      }

    foreach my $req_type (@$required_outfile_types)
      {
	if(scalar(@{$input_files_array->[$req_type]}) == 0
	   #TODO: Do a version of this if/when requirement 11b is implemented
	   #&& ($req_type != $primary_outfile_type ||
	   #    isStandardOutputToTerminal())
	  )
	  {
	    my $iflag = getInfileFlag($req_type);
	    push(@$missing_flags,
		 (defined($iflag) && $iflag ne '' ?
		  $iflag : 'internal error'));
	    $requirement_defficiency = 1;
	  }
      }

    if($required_outdirs)
      {
	if(scalar(@$outdirs_array) == 0)
	  {
	    push(@$missing_flags,getOutdirFlag());
	    $requirement_defficiency = 1;
	  }
      }

    #Now let's check other options
    #If there are required general options
    if(scalar(@$required_opt_refs) > 0)
       {
	 #For each general option type
	 foreach my $opt_info (@$required_opt_refs)
	   {
	     if(!wasGeneralOptionSupplied($opt_info))
	       {
		 $requirement_defficiency = 1;
		 push(@$missing_flags,
		      (exists($general_flag_hash->{$opt_info->[0]}) &&
		       defined($general_flag_hash->{$opt_info->[0]}) ?
		       $general_flag_hash->{$opt_info->[0]} :
		       'internal error'));
	       }
	   }
       }

    #Require input file(s)
    if($requirement_defficiency || scalar(@$conflicting_flags))
      {
	if(scalar(@$conflicting_flags))
	  {error("The following pairs of options are mutually exclusive: [",
		 join(',',@$conflicting_flags),"].",
		 {DETAIL =>
		  join('These pairs of flags each specify a different way of ',
		       'naming output files for the same output.  You can ',
		       'either specify an output file using a suffix to be ',
		       'appended to an input file name or you can supply a ',
		       'full filename, but not both at the same time.')});
	 }

	if($requirement_defficiency)
	  {error('Missing required options: [',join(',',@$missing_flags),'].')}

	usage(1);
	quit(-17,0);
      }

    if(scalar(@$required_relationships))
      {requireFileRelationships()}

    #Require an outfile suffix if an outdir has been supplied
    if(scalar(@$outdirs_array) && scalar(@$outfile_suffix_array) == 0)
      {
	#We're quitting, so let's set the various options to false so
	#the buffered debug statements do not puke out on the terminal
	$DEBUG       = 0 if(!defined($DEBUG));
	$verbose     = 0 if(!defined($verbose));
	$quiet       = 0 if(!defined($quiet));
	$error_limit = 0 if(!defined($error_limit));

	error("An outfile suffix is required if an output directory is ",
	      "supplied.");
	quit(-18,0);
      }

    unless(validateNonFileOptions())
      {quit(-94)}

    #If there are no files and we're in cleanup mode, we have already processed
    #the options to get things like verbose, debug, etc. and that's all we
    #need. We can assume that since quit has been called without having
    #processed the command line options, that the user is not using this module
    #for file processing, so return
    if($cleanup_mode && scalar(grep {scalar(@$_)} @$input_files_array) == 0)
      {
	$command_line_processed = 2;
	return(0);
      }

    ($input_file_sets,  #getFileSets(3DinfileArray,2DsuffixArray,2DoutdirArray)
     $output_file_sets) = getFileSets($input_files_array,
				      $outfile_suffix_array,
				      $outdirs_array,
				      $collid_modes_array);

    #Create the output directories
    mkdirs(@$outdirs_array);

    #If standard output is to a redirected file and the header flag has been
    #specified and there exists an undefined outfile suffix (which means that
    #output will go to STDOUT, print the header to STDOUT
    if($header && !isStandardOutputToTerminal() &&
       scalar(grep {!defined($_)} map {@$_} grep {defined($_)}
	      @$outfile_suffix_array))
      {
	#Open STDOUT to /dev/stdout because that's what the programmer's
	#supplied file handle will be opened to and we need it to go to the same
	#stream so that the header printed here is guaranteed to be at the top
	open(STDOUT,'>>/dev/stdout');
	print STDOUT (getHeader());
      }

    #Really done with command line processing
    $command_line_processed = 2;

    return(0);
  }

#After the command line has been parsed, supply default values to any options
#that weren't supplied on the command line
sub loadDefaults
  {
    loadDefaultArrays();

    #Supply default input & output file(s) (indicated by the programmer) so
    #that we can determine the run mode (e.g. run if all required options have
    #values)
    loadDefaultFiles();
    loadDefaultOutdirs();
  }

sub loadDefaultArrays
  {
    foreach my $array_ref (keys(%$array_defaults_hash))
      {if(scalar(@{$array_defaults_hash->{$array_ref}->{VALUES}}) == 0 &&
	  scalar(@{$array_defaults_hash->{$array_ref}->{DEFAULTS}}))
	 {@{$array_defaults_hash->{$array_ref}->{VALUES}} =
	    @{$array_defaults_hash->{$array_ref}->{DEFAULTS}}}}
  }

sub loadDefaultFiles
  {
    #If there are no default input files of any type (or default_infiles_array
    #is not an array reference)
    if(!defined($default_infiles_array)       ||
       ref($default_infiles_array) ne 'ARRAY' ||
       scalar(@$default_infiles_array) == 0)
      {return()}

    my $error_status  = 0;
    my $got_some      = 0;
    my $all_err_globs = '';
    my $some_required = 0;

    #Cycle through the default_infiles_array's indexes
    #This assumes that default_infiles_array is properly populated.
    #Specifically, it assumes that it's a 3D array and that the outer array
    #elements are either undefined (i.e. no defaults present) or defined and
    #containing a 2D array of defined non-empty-string file name/glob strings
    foreach my $i (0..$#{$default_infiles_array})
      {
	#This assumes that the first element will be populated if there were
	#any files at all supplied on the command line
	if(#There are defaults defined
	   defined($default_infiles_array->[$i]) &&
	   #The defaults object at this index is an array (sanity check)
	   ref($default_infiles_array->[$i]) eq 'ARRAY' &&
	   #The defaults array for this type is populated
	   scalar(@{$default_infiles_array->[$i]}) &&

	   ##
	   ## Now check to see if the user did not supply files of this type
	   ##

	   (#The input files array is not defined OR
	    !defined($input_files_array) ||

	    #The input files array is smaller than the defaults
	    (ref($input_files_array) eq 'ARRAY' &&
	     scalar(@$input_files_array) < ($i + 1)) ||

	    #The contained input files 2D array is not an array
	    (ref($input_files_array) eq 'ARRAY' &&
	     ref($input_files_array->[$i]) ne 'ARRAY') ||

	    #The contained input files 2D array is size 0
	    (ref($input_files_array) eq 'ARRAY' &&
	     ref($input_files_array->[$i]) eq 'ARRAY' &&
	     scalar(@{$input_files_array->[$i]}) == 0) ||

	    #Its first element is not defined
	    (ref($input_files_array) eq 'ARRAY' &&
	     ref($input_files_array->[$i]) eq 'ARRAY' &&
	     !defined($input_files_array->[$i]->[0])) ||

	    #Its first element is not an array
	    (ref($input_files_array) eq 'ARRAY' &&
	     ref($input_files_array->[$i]) eq 'ARRAY' &&
	     ref($input_files_array->[$i]->[0]) ne 'ARRAY') ||

	    #Its first element's array is size 0
	    (ref($input_files_array) eq 'ARRAY' &&
	     ref($input_files_array->[$i]) eq 'ARRAY' &&
	     ref($input_files_array->[$i]->[0]) eq 'ARRAY' &&
	     scalar(@{$input_files_array->[$i]->[0]}) == 0)))
	  {
	    #Add the defaults to the input_files_array
	    foreach my $flag_instance_array (@{$default_infiles_array->[$i]})
	      {
		my $files     = [];
		my $err_globs = '';
		my $an_error  = 0;

		#Require a matching/existing file for each infile glob string
		#supplied separately (no match required for output file string)
		foreach my $globstr (@$flag_instance_array)
		  {
		    #Glob the default glob str and make sure the return value
		    #is defined and is an existing file unless this is an
		    #output file type.
		    my $newfiles =
		      [grep {defined($_) &&
			       (exists($outfile_types_hash->{$i}) ? 1 : -e $_)}
		       sglob($globstr)];
		    if(scalar(@$newfiles))
		      {
			$got_some = 1;
			push(@$files,@$newfiles);
		      }
		    else
		      {
			#Keep track of the glob strings that didn't match
			$err_globs .= ($an_error ? ' ' : '') . $globstr;
			$an_error   = 1;
		      }
		  }

		if($an_error)
		  {
		    $all_err_globs .= ($error_status ? ' ' : '') . $err_globs;
		    $error_status = 1;

		    if(scalar(grep {$_ == $i} @$required_infile_types))
		      {$some_required = 1}
		  }
		else
		  {push(@{$input_files_array->[$i]},$files)}
	      }
	  }
      }

    #If there was an error (e.g. some default files not found)
    if($error_status)
      {
	#If a portion of the patterns did match existing files
	if($got_some)
	  {
	    error("Some of the expected default input files were not found: ",
		  "[$all_err_globs].  Unable to proceed.  Please create the ",
		  "default files.");
	    usage();
	    quit(-19);
	  }
	#If one of the file types is a required option
	elsif($some_required)
	  {
	    error("Expected required default input files were not found: ",
		  "[$all_err_globs].  Unable to proceed.  Please create the ",
		  "default files.");
	    usage();
	    quit(-20);
	  }
      }
  }

sub loadDefaultOutdirs
  {
    #If there is no outdir option or no default outdirs, return
    if(!$outdirs_added || scalar(@$default_outdirs_array) == 0)
      {return()}

    #If there were no outdirs supplied on the command line
    if(scalar(@$outdirs_array) == 0)
      {@$outdirs_array = @$default_outdirs_array}
  }

sub requireFileRelationships
  {
    my $relationship_violation = 0;

    foreach my $rel_array (@$required_relationships)
      {
	my $test_ftype   = $rel_array->[0];
	my $valid_ftype  = $rel_array->[1];
	my $relationship = $rel_array->[2];

	debug({LEVEL => -1},"Checking relationship of file types ",
	      "[$test_ftype,",(defined($valid_ftype) ? $valid_ftype : 'undef'),
	      "] is: [$relationship].");

	my $test_files = $input_files_array->[$test_ftype];

	#If the test file type is not required and there are none, skip
	if(scalar(@$test_files) == 0)
	  {
	    if(isFileTypeRequired($test_ftype))
	      {
		my $hid = isFileTypeHidden($test_ftype);
		if($hid && defined($primary_infile_type) &&
		   $test_ftype == $primary_infile_type)
		  {error("Input file supplied via standard input redirect is ",
			 "required.")}
		elsif(!$hid)
		  {error("Input file(s): [",getInfileFlag($test_ftype),
			 "] are required.")}
		else
		  {
		    #This shouldn't happen, but putting it here just in case
		    error("Input file supplied by hidden flag [",
			  getInfileFlag($test_ftype,-1),"] is required.");
		  }
		$relationship_violation = 1;
	      }
	    next;
	  }

	#If the valid_ftype files do not matter
	if($relationship =~ /^(\d+)$/)
	  {
	    my $static_num_files = $1;
	    if(scalar(@$test_files) != 1 ||
	       scalar(@{$test_files->[0]}) != $static_num_files)
	      {
		my $numf = scalar(map {scalar(@$_)} @$test_files);
		error("Exactly [$static_num_files] file",
		      ($static_num_files > 1 ? "s are " : " is "),
		      "expected via [",getInfileFlag($test_ftype),"], but ",
		      "[$numf] (",join(',',map {scalar(@$_)} @$test_files),
		      ") ",($numf != 1 ? 'were' : 'was')," supplied.");
		$relationship_violation = 1;
	      }
	    next;
	  }

	my $valid_files =
	  defined($valid_ftype) ? $input_files_array->[$valid_ftype] : [];

	##TODO: The following logic does not make sense when the programmer CAN do something with the file type in question and the other type is not supplied (such as a secondary output file).  Case-in-point: codonHomologizer.pl can make a matrix file (1:1orM with sequence files) from a codon usage file, but the sequence files aren't needed to do that.  But is there any circumstance where this check makes sense?  Figure this out.
#	#If there are none of the files in the file type we're testing against,
#	#we cannot enforce the relationship.  This is an error.  Any of the
#	#relationship types require the one it's in a relationship with to be
#	#present.  Like, if file type 1 is supplied, file type 2 can be
#	#supplied with it in a specific relative number. Otherwise, file type 2
#	#by itself makes no sense. Note, it is assumed that global requirements
#	#are checked elsewhere.
#	if(scalar(@$valid_files) == 0)
#	  {
#	    error("File type: [",getInfileFlag($test_ftype),"] requires at ",
#		  "least 1 file of type: [",getInfileFlag($valid_ftype),
#		  "] to be present, however none were supplied.");
#	    $relationship_violation = 1;
#	    next;
#	  }

	if($relationship eq '1:M')
	  {
	    if(!twoDArraysAre1toM($test_files,$valid_files))
	      {
		error("There may be only 1 file supplied as: [",
		      getInfileFlag($test_ftype),"] for each file ",
		      "group supplied as: [",getInfileFlag($valid_ftype),
		      "], however there were: [",
		      join(',',map {scalar(@$_)} @$test_files),"] files ",
		      "supplied with [",scalar(@$valid_files),"] files ",
		      "respectively.");
		$relationship_violation = 1;
	      }
	  }
	elsif($relationship eq '1:1')
	  {
	    #If the outer arrays are not the same size or any of the inner
	    #arrays are not the same size
	    if(!twoDArraysAre1to1($test_files,$valid_files))
	      {
		error("The number and group sizes of files supplied as [",
		      getInfileFlag($test_ftype),"] and [",
		      getInfileFlag($valid_ftype),"] must be the same, but ",
		      "there were [",join(',',map {scalar(@$_)} @$test_files),
		      "] and [",join(',',map {scalar(@$_)} @$valid_files),
		      "] files supplied.");
		$relationship_violation = 1;
	      }
	  }
	elsif($relationship eq '1:1orM')
	  {
	    if(!twoDArraysAre1to1($test_files,$valid_files) &&
	       !twoDArraysAre1toM($test_files,$valid_files) &&
	       #Mixed state option:
	       #The outer arrays are the same size but inner test_files arrays
	       #are not a combo of equal and size 1
	       (scalar(@$test_files) == scalar(@$valid_files) &&
		scalar(grep {scalar(@{$test_files->[$_]}) != 1 &&
			       scalar(@{$test_files->[$_]}) !=
				 scalar(@{$valid_files->[$_]})}
		       0..$#{$test_files})))
	      {
		error("The number and group sizes of files supplied as [",
		      getInfileFlag($test_ftype),"] and [",
		      getInfileFlag($valid_ftype),"] must either be the ",
		      "same or have a one to many relationship, but there ",
		      "were [",join(',',map {scalar(@$_)} @$test_files),
		      "] and [",join(',',map {scalar(@$_)} @$valid_files),
		      "] files supplied.");
		$relationship_violation = 1;
	      }
	  }
	#NOTE: Requirement 140 needs to be implemented to properly support M:M
	elsif($relationship eq 'M:M')
	  {
	    #Since we already checked that some of each file are present,
	    #there's nothing to check here.  Anything goes.
	  }
	else
	  {
	    error("Invalid relationship type (PAIR_RELAT): ",
		  "[$relationship].  Unable to enforce relationship between ",
		  "file types supplied as: [",getInfileFlag($test_ftype),
		  "(ID:[$test_ftype])",getInfileFlag($valid_ftype),
		  "(ID:[$valid_ftype])].");
	  }
      }

    if($relationship_violation)
      {quit(-21)}
  }

#For use with testing the matching dimensionality of 2D file arrays
sub twoDArraysAre1toM
  {
    my $test_arrays  = $_[0];
    my $valid_arrays = $_[1];

    if((#There is 1 test group and multiple valid groups AND
	scalar(@$test_arrays) == 1 && scalar(@$valid_arrays) > 1 &&
	(#There is more than 1 file in the test group AND
	 scalar(@{$test_arrays->[0]}) > 1 &&
	 #The size of the test group is not equal to the number of grps
	 scalar(@{$test_arrays->[0]}) != scalar(@$valid_arrays))) ||
       (#There is 1 test group and 1 valid group AND
	scalar(@$test_arrays) == 1 && scalar(@$valid_arrays) == 1 &&
	#There is more than 1 test file
	scalar(@{$test_arrays->[0]}) > 1) ||
       (#There are multiple test groups AND
	scalar(@$test_arrays) > 1 &&
	(#A group is not equal to 1 in size OR
	 scalar(grep {scalar(@$_) != 1} @$test_arrays) ||
	 #The number of groups is not the same
	 scalar(@$test_arrays) != scalar(@$valid_arrays))))
      {return(0)}
    return(1);
  }

#For use with testing the matching dimensionality of 2D file arrays
sub twoDArraysAre1to1
  {
    my $test_arrays  = $_[0];
    my $valid_arrays = $_[1];

    if(scalar(@$test_arrays) != scalar(@$valid_arrays) ||
       scalar(grep {scalar(@{$test_arrays->[$_]}) !=
		      scalar(@{$valid_arrays->[$_]})} 0..$#{$test_arrays}))
      {return(0)}
    return(1);
  }

#This sub, given an input file type ID, will return the group of files that
#were all submitted with a single command line flag (e.g. -i 'file1 file2' -i
#'file3 file4') as an array of file names.
sub getNextFileGroup
  {
    my @in = getSubParams([qw(FILETYPEID)],[],[@_]);
    my $file_type_id = $in[0];

    unless($processCommandLine_called)
      {processCommandLine()}

    #Allow file_type_id to be optional when there's only 1 infile type
    #OR allow file_type_id to be optional when called in list context
    ##TODO: Create an iterator to cycle through the types when no type ID is
    ##      supplied.  See requirement 181.
    if(!defined($file_type_id) && (getNumInfileTypes() == 1 || wantarray))
      {
	#Even if we're returning a list, we'll set a file that will
	#unnecessarily go through a conditional below to check for validity -
	#just so this sub will work in both contexts
	$file_type_id = (getInfileIndexes())[0];

	if(!defined($file_type_id))
	  {
	    error("No input file options could be found.");
	    return(undef);
	  }
      }

    if(!defined($file_group_num) || !defined($file_group_num->[$file_type_id]))
      {$file_group_num->[$file_type_id] = 0}
    else
      {$file_group_num->[$file_type_id]++}

    #If the file group number is greater than the number of groups of files
    #(i.e. the number of times the input file's flag was supplied) return undef
    if($file_group_num->[$file_type_id] >=
       scalar(@{$input_file_sets->[$file_type_id]}))
      {return(undef)}

    if(wantarray)
      {return(@{$input_files_array->[$file_type_id]
		  ->[$file_group_num->[$file_type_id]]})}

    return([@{$input_files_array->[$file_type_id]
		->[$file_group_num->[$file_type_id]]}]);
  }

sub resetFileGroupIterator
  {
    my @in = getSubParams([qw(FILETYPEID)],[],[@_]);
    my $file_type_id = $in[0];

    unless($processCommandLine_called)
      {processCommandLine()}

    #Allow file_type_id to be optional when there's only 1 infile type
    #OR allow file_type_id to be optional when called in list context
    ##TODO: Create an iterator to cycle through the types when no type ID is
    ##      supplied.  See requirement 181.
    if(!defined($file_type_id) && (getNumInfileTypes() == 1 || wantarray))
      {
	#Even if we're returning a list, we'll set a file that will
	#unnecessarily go through a conditional below to check for validity -
	#just so this sub will work in both contexts
	$file_type_id = (getInfileIndexes())[0];

	if(!defined($file_type_id))
	  {
	    error("No input file options could be found.");
	    return(undef);
	  }
      }

    $file_group_num->[$file_type_id] = -1;
  }

#This sub, given an input file type ID, will return an array of groups of files
#that were submitted with all instances of a command line flag
#(e.g. -i 'file1 file2' -i 'file3 file4') results in a 2D array:
#[[file1,file2],[file3,file4]].
sub getAllFileGroups
  {
    my @in = getSubParams([qw(FILETYPEID)],[],[@_]);
    my $file_type_id = $in[0];

    unless($processCommandLine_called)
      {processCommandLine()}

    #Allow file_type_id to be optional when there's only 1 infile type
    #OR allow file_type_id to be optional when called in list context
    ##TODO: Create an iterator to cycle through the types when no type ID is
    ##      supplied.  See requirement 181.
    if(!defined($file_type_id) && (getNumInfileTypes() == 1 || wantarray))
      {
	#Even if we're returning a list, we'll set a file that will
	#unnecessarily go through a conditional below to check for validity -
	#just so this sub will work in both contexts
	$file_type_id = (getInfileIndexes())[0];

	if(!defined($file_type_id))
	  {
	    error("No input file options could be found.");
	    return(undef);
	  }
      }

    if(wantarray)
      {return(map {[@$_]} @{$input_files_array->[$file_type_id]})}

    return([map {[@$_]} @{$input_files_array->[$file_type_id]}]);
  }

sub getNumFileGroups
  {
    debug({LEVEL => -10},"getNumFileGroups called.");
    my @in = getSubParams([qw(FILETYPEID)],[],[@_]);
    my $file_type_id = $in[0];

    unless($processCommandLine_called)
      {processCommandLine()}

    #Allow file_type_id to be optional when there's only 1 infile type
    #OR allow file_type_id to be optional when called in list context
    ##TODO: Create an iterator to cycle through the types when no type ID is
    ##      supplied.  See requirement 181.
    if(!defined($file_type_id) && (getNumInfileTypes()  == 1 || wantarray))
      {
	#Even if we're returning a list, we'll set a file that will
	#unnecessarily go through a conditional below to check for validity -
	#just so this sub will work in both contexts
	$file_type_id = (getInfileIndexes())[0];

	if(!defined($file_type_id))
	  {
	    error("No input file options could be found.");
	    return(undef);
	  }
      }

    debug({LEVEL => -10},"Returning number of files for type: ",
	  "[$file_type_id] as: [",
	  scalar(@{$input_files_array->[$file_type_id]}),
	  "] with first file: [$input_files_array->[$file_type_id]->[0]].");

    return(scalar(grep {my $a = $_;scalar(@$a) !=
			  scalar(grep {!defined($_)} @$a)}
		  @{$input_files_array->[$file_type_id]}));
  }

sub getFileGroupSizes
  {
    my @in = getSubParams([qw(FILETYPEID)],[],[@_]);
    my $file_type_id = $in[0];

    unless($processCommandLine_called)
      {processCommandLine()}

    #Allow file_type_id to be optional when there's only 1 infile type
    #OR allow file_type_id to be optional when called in list context
    ##TODO: Create an iterator to cycle through the types when no type ID is
    ##      supplied.  See requirement 181.
    if(!defined($file_type_id) &&
       (getNumInfileTypes() == 1 || wantarray))
      {
	#Even if we're returning a list, we'll set a file that will
	#unnecessarily go through a conditional below to check for validity -
	#just so this sub will work in both contexts
	$file_type_id = (getInfileIndexes())[0];

	if(!defined($file_type_id))
	  {
	    error("No input file options could be found.");
	    return(undef);
	  }
      }

    if(wantarray)
      {return(map {scalar(@$_)} @{$input_files_array->[$file_type_id]})}

    return([map {scalar(@$_)} @{$input_files_array->[$file_type_id]}]);
  }

##
## ORIGINAL TEMPLATE CODE MODIFIED TO BE A MODULE
##

#Copies all hash arguments' contents from the parameter array into 1 hash.
#All other arguments must be scalars - otherwise generates an error.  This sub
#is intended to be used by methods which take a series of strings, such as
#error(), warning(), and debug().
sub getStrSubParams
  {
    my $keys_array = [];
    #If a list of keys to search for was not provided
    if(scalar(@_) < 1 || ref($_[0]) ne 'ARRAY' ||
       scalar(grep {ref(\$_) ne 'SCALAR'} @{$_[0]}))
      {
	#Issue a warning and allow it to proceed for backward compatibility
	warning("A minimum of 1 parameter is required, and the first must be ",
		"an array reference with scalar values.",
		(scalar(@_) ? ("  Returning the contents of all hashes for " .
			       "backward compatibility.") : ''));
      }
    else
      {$keys_array = shift(@_)}

    my $opts   = {};
    my @params = ();
    foreach my $param (@_)
      {
	if(!defined($param) || ref($param) ne 'HASH' ||
	   (scalar(@$keys_array) &&
	    scalar(grep {exists($param->{$_})} @$keys_array) == 0))
	  {
	    push(@params,$param);
	    next;
	  }
	my $opthash = $param;

	foreach my $optname (keys(%$opthash))
	  {
	    if(exists($opts->{$optname}))
	      {error("Multiple options with the same name: [$optname].  ",
		     "Overwriting.")}
	    $opts->{$optname} = $opthash->{$optname};
	  }
      }

    #If keys were not found, set them to undef
    foreach my $key (@$keys_array)
      {if(!exists($opts->{$key}))
	 {$opts->{$key} = undef}}

    return($opts,@params);
  }

#This method exists for backward compatibility - to support methods
#which expect parameters submitted in a specific order.  It processes
#parameters submitted to a method by taking those parameters and a list of
#hash keys (in order in which the method assigns the values in the returned
#array) and extracts the values to return them in an ordered array.  Undef is
#substituted for any missing parameters.
#It also checks for required parameters by taking a list of required hash keys.
#If the user has submitted parameters as an array instead of a hash, the number
#of required paraeters is used as a minimum number of parameters.
sub getSubParams
  {
    if(scalar(@_) != 3 && scalar(@_) != 4)
      {
	error("Three parameters are required: all keys, required keys, and ",
	      "the parameters submitted to the method.  An boolean ",
	      "'strict' parameter is an optional fourth parameter.");
	return(undef);
      }

    my $keys   = shift(@_);
    my $reqd   = shift(@_);
    my $unproc = shift(@_);
    my $strict = (scalar(@_) ? shift(@_) : 0);
    my $sub;
    my $stack = 0;
    while(my @info = caller($stack))
      {
	$stack++;
	$sub = $info[3];
	$sub =~ s/.*://;
	last if($sub ne 'getSubParams');
      }
    $sub = '' unless($sub);
    my($params);

    debug({LEVEL => -9},"Keys passed in: [",join(',',@$keys),"].");
    debug({LEVEL => -9},"Required keys passed in: [",join(',',@$reqd),"].");

    if(ref($keys) ne 'ARRAY' || scalar(grep {ref($_) ne ''} @$keys))
      {
	error("Invalid keys parameter.  The first parameter must be a ",
	      "reference to an array of hash keys.");
	return(undef);
      }

    if(ref($reqd) ne 'ARRAY' || scalar(grep {ref($_) ne ''} @$reqd))
      {
	error("Invalid required keys parameter.  The second parameter must ",
	      "be a reference to an array of required hash keys.");
	return(undef);
      }

    #For backward-compatibility, assume this is a method call from a script
    #written using an older version of CommandLineInterface (or
    #perl_script_template.pl)
    if(!$strict && (scalar(@$unproc) % 2) == 1)
      {
	debug({LEVEL => -1},
	      "Returning params as-is for backward compatibility because ",
	      "there is an odd number: [",scalar(@$unproc),"] of parameters: ",
	      "[",join(',',map {defined($_) ? $_ : 'undef'} @$unproc),"].");

	if(scalar(@$unproc) < scalar(@$reqd))
	  {
	    error("$sub requires at least [",scalar(@$reqd),"] parameters (",
		  join(',',@$reqd),"), but only [",scalar(@$unproc),
		  "] were sent in.");
	    quit(-22);
	  }

	return(@$unproc);
      }
    elsif(defined($DEBUG) && $DEBUG <= -1)
      {debug({LEVEL => -9},"Returning parsed parameters: [",
	     join(',',map {defined($_) ? $_ : 'undef'} @$unproc),"].\n")}

    my $checks = {};

    foreach my $key (map {split(/\|/,$_)} @$keys)
      {$checks->{$key} = 0}

    if(scalar(map {split(/\|/,$_)} @$reqd) !=
       scalar(grep {exists($checks->{$_})} map {split(/\|/,$_)} @$reqd))
      {
	error("Invalid required keys parameter.  The required keys must be a ",
	      "subset of all keys provided in the first parameter, but these ",
	      "keys were not present: [",
	      join(',',(grep {!exists($checks->{$_})} map {split(/\|/,$_)}
			@$reqd)),"].");

	quit(-23);
      }

    #If the alleged keys in the hash are not scalars or are undefined
    if(scalar(grep {($_ % 2) == 0 && (!defined($unproc->[$_]) ||
				      ref($unproc->[$_]) ne '')}
	      (0..$#{$unproc})))
      {
	debug({LEVEL => -1},"Non-scalar or undefined keys found, so ",
	      "returning all params for backward compatibility.");

	if(scalar(@$unproc) < scalar(@$reqd))
	  {
	    error("$sub requires at least [",scalar(@$reqd),"] parameters (",
		  join(',',@$reqd),"), but only [",scalar(@$unproc),
		  "] were sent in.");
	    quit(-24);
	  }

	if($strict)
	  {
	    error("Invalid or undefined keys passed in.");
	    return(undef);
	  }
	return(@$unproc);
      }
    else
      {
	my $a_match    = scalar(grep {exists($checks->{$_})}
				map {$unproc->[$_]}
				grep {$_ % 2 == 0} (0..$#{$unproc}));
	my @nonmatches = grep {!exists($checks->{$_})} map {$unproc->[$_]}
	  grep {$_ % 2 == 0} (0..$#{$unproc});

	if(!$a_match)
	  {
	    debug({LEVEL => -1},"No matching keys passed to $sub: [",
		  join(',',@$keys),"], so returning all params [",
		  join(',',map {defined($_) ? $_ : 'undef'} @$unproc),
		  "] for backward compatibility.\n") unless($strict);

	    if(scalar(@$unproc) < scalar(@$reqd))
	      {
		error("$sub requires at least [",scalar(@$reqd),
		      "] parameters (",join(',',@$reqd),"), but only [",
		      scalar(@$unproc),"] were sent in.");
		quit(-25);
	      }

	    if($strict)
	      {
		error("No matching matching keys passed to $sub: [",
		      join(',',@$keys),"] found.");
		return(undef);
	      }
	    elsif(scalar(@$unproc) &&
		  scalar(grep {$unproc->[$_] =~ /^[A-Z_]{3,}$/}
			 grep {$_ % 2 == 0} (0..$#{$unproc})) ==
		  scalar(grep {$_ % 2 == 0} (0..$#{$unproc})))
	      {
		warning("No matching matching keys passed to $sub: [",
			join(',',@$keys),"] found.  Assuming they are valid ",
			"parameters not in hash format.");
	      }

	    return(@$unproc);
	  }
	elsif(scalar(@nonmatches))
	  {
	    error("Unrecognized hash key(s) encountered in parameters passed ",
		  "to $sub: [",join(',',@nonmatches),"].");

	    if($strict)
	      {
		@$unproc = map {$unproc->[$_],$unproc->[$_ + 1]}
		  grep {exists($checks->{$unproc->[$_]})}
		    grep {$_ % 2 == 0} (0..$#{$unproc});
	      }
	  }
	debug({LEVEL => -9},"A match? [$a_match] Non-matches? [",
	      scalar(@nonmatches),"].");
      }

    #It should now be safe to instantiate a hash
    my $hash = {@$unproc};

    #Check for missing required parameters
    my @missing = ();
    foreach my $rkey (@$reqd)
      {
	my @aliases = split(/\|/,$rkey);
	my $occurrences = scalar(grep {exists($hash->{$_})} @aliases);
	if($occurrences == 0)
	  {push(@missing,$rkey)}
      }

    #Check for duplicate parameters that are the result of using multiple
    #aliases for the same parameter.
    my @dupes = ();
    foreach my $key (@$keys)
      {
	my @aliases = split(/\|/,$key);
	my $occurrences = scalar(grep {exists($hash->{$_})} @aliases);
	if($occurrences > 1)
	  {push(@dupes,$key)}
      }

    if(scalar(@missing) || scalar(@dupes))
      {
	if(scalar(@missing))
	  {error("$sub: Required parameters missing: [",join(',',@missing),
		 "].",($processCommandLine_called ?
		       '  Use --force to get past this error.' : ''))}
	if(scalar(@dupes))
	  {error("$sub: Duplicate parameter aliases encountered: [",
		 join(',',@missing),"].",
		 ($processCommandLine_called ?
		  '  Use --force to get past this error.  Note, the value ' .
		  'of the aliases will be randomly selected.' : ''))}
	quit(-26);
      }

    #Convert each key into its supplied value (or undef)
    $params = [map {my @als = split(/\|/,$_);my($r);
		    foreach my $flg (@als)
		      {if(exists($checks->{$flg}) && exists($hash->{$flg}))
			 {$r = $hash->{$flg};last;}}
		    $r}
	       @$keys];

    if(wantarray)
      {return(@$params)}

    return($params);
  }

##
## Method that prints formatted verbose messages.  Specifying a 1 as the
## first argument prints the message in overme mode (meaning subsequence
## verbose, error, warning, or debug messages will write over the message
## printed here.  However, specifying a hard return as the first character will
## override the status of the last line printed and keep it.  Global variables
## keep track of print length so that previous lines can be cleanly
## overwritten.  Note, this method buffers output until $verbose is defined
## in main.  The buffer will be emptied the first time verbose() is called
## after $verbose has been defined.  The purpose of this is to still output
## verbose messages that were generated before the command line --verbose flag
## has been processed.
##
sub verbose
  {
    if(defined($verbose) && !$verbose)
      {
	flushStderrBuffer() if(defined($stderr_buffer));
	return(0);
      }

    #Grab the options from the parameter array
    my($opts,@params) = getStrSubParams(['OVERME','LEVEL','FREQUENCY'],@_);
    my $overme_flag   = (exists($opts->{OVERME}) && defined($opts->{OVERME}) ?
			 $opts->{OVERME} : 0);
    my $message_level = (exists($opts->{LEVEL}) && defined($opts->{LEVEL}) ?
			 $opts->{LEVEL} : 1);
    my $frequency     = (exists($opts->{FREQUENCY}) &&
			 defined($opts->{FREQUENCY}) &&
			 $opts->{FREQUENCY} > 0 ? $opts->{FREQUENCY} : 1);

    if($frequency =~ /\./)
      {
	warning("The frequency value: [$frequency] must be an integer (e.g. ",
		"print every 100th line).");
	$frequency = ($frequency < 1 ? 1 : int($frequency));
      }

    #If we're not printing every one of these verbose messages
    if($frequency > 1)
      {
	#Determine what line the verbose call was made from so we can track
	#how many times it has been called
	my(@caller_info,$line_num);
	my $stack_level = 0;
	while(@caller_info = caller($stack_level))
	  {
	    $line_num = $caller_info[2];
	    last if(defined($line_num));
	    $stack_level++;
	  }

	#Initialize the frequency hash to track number of calls from this line
	#of code
	if(!defined($verbose_freq_hash))
	  {$verbose_freq_hash->{$line_num} = 1}
	else
	  {$verbose_freq_hash->{$line_num}++}

	#If the number of calls is evenly divisible by the frequency
	return(0) if($verbose_freq_hash->{$line_num} % $frequency != 0);
      }

    #Return if $verbose is greater than a negative level at which this message
    #is printed or if $verbose is less than a positive level at which this
    #message is printed.  Negative levels are for template diagnostics.
    return(0) if(defined($verbose) &&
		 (($message_level < 0 && $verbose > $message_level) ||
		  ($message_level > 0 && $verbose < $message_level)));

    #Grab the message from the parameter array
    my $verbose_message = join('',map {defined($_) ? $_ : 'undef'} @params);

    #Turn on the overwrite flag automatically if carriage returns are found
    $overme_flag = 1 if(!$overme_flag && $verbose_message =~ /\r/);

    #Initialize globals if not done already
    $last_verbose_size  = 0 if(!defined($last_verbose_size));
    $last_verbose_state = 0 if(!defined($last_verbose_state));
    $verbose_warning    = 0 if(!defined($verbose_warning));

    #Determine the message length
    my($verbose_length);
    if($overme_flag)
      {
	$verbose_message =~ s/\r$//;
	if(!$verbose_warning && $verbose_message =~ /\n|\t/)
	  {
	    warning('Hard returns and tabs cause overme mode to not work ',
		    'properly.');
	    $verbose_warning = 1;
	  }
      }
    else
      {chomp($verbose_message)}

    #If this message is not going to be over-written (i.e. we will be printing
    #a \n after this verbose message), we can reset verbose_length to 0 which
    #will cause $last_verbose_size to be 0 the next time this is called
    if(!$overme_flag)
      {$verbose_length = 0}
    #If there were \r's in the verbose message submitted (after the last \n)
    #Calculate the verbose length as the largest \r-split string
    elsif($verbose_message =~ /\r[^\n]*$/)
      {
	my $tmp_message = $verbose_message;
	$tmp_message =~ s/.*\n//;
	($verbose_length) = sort {$b <=> $a} map {length($_)}
	  split(/\r/,$tmp_message);
      }
    #Otherwise, the verbose_length is the size of the string after the last \n
    elsif($verbose_message =~ /([^\n]*)$/)
      {$verbose_length = length($1)}

    #If the buffer is not being flushed, the verbose output doesn't start with
    #a \n, and output is to the terminal, make sure we don't over-write any
    #STDOUT output
    #NOTE: This will not clean up verbose output over which STDOUT was written.
    #It will only ensure verbose output does not over-write STDOUT output
    #NOTE: This will also break up STDOUT output that would otherwise be on one
    #line, but it's better than over-writing STDOUT output.  If STDOUT is going
    #to the terminal, it's best to turn verbose off.
    if(!$| && $verbose_message !~ /^\n/ && isStandardOutputToTerminal())
      {
	#The number of characters since the last flush (i.e. since the last \n)
	#is the current cursor position minus the cursor position after the
	#last flush (thwarted if user prints \r's in STDOUT)
	#NOTE:
	#  tell(STDOUT) = current cursor position
	#  sysseek(STDOUT,0,1) = cursor position after last flush (or undef)
	my $num_chars = sysseek(STDOUT,0,1);
	if(defined($num_chars))
	  {$num_chars = tell(STDOUT) - $num_chars}
	else
	  {$num_chars = 0}

	#If there have been characters printed since the last \n, prepend a \n
	#to the verbose message so that we do not over-write the user's STDOUT
	#output
	if($num_chars > 0)
	  {$verbose_message = "\n$verbose_message"}
      }

    #Write over the previous verbose message by appending spaces before the
    #first hard return in the verbose message IF THE VERBOSE MESSAGE DOESN'T
    #BEGIN WITH A HARD RETURN.  However note that the length stored as the
    #last_verbose_size is the length of the last line printed in this message.
    if($verbose_message =~ /^([^\n]*)/ && $last_verbose_state &&
       $verbose_message !~ /^\n/)
      {
	my $spacelen = (defined($last_verbose_size) ? $last_verbose_size : 0) -
	  length($1);
	$spacelen = 0 if($spacelen < 0);
	my $addendum = ' ' x $spacelen;
	unless($verbose_message =~ s/\n/$addendum\n/)
	  {$verbose_message .= $addendum}
      }

    #If you don't want to write over the last verbose message in a series of
    #overwritten verbose messages, you can begin your verbose message with a
    #hard return.  This tells verbose() to not write over the last line
    #printed in overme mode.

    if(defined($verbose))
      {
	#Flush the buffer if it is defined
	flushStderrBuffer() if(defined($stderr_buffer));

	#Print the current message to standard error
	print STDERR ($verbose_message,
		      ($overme_flag ? "\r" : "\n"));
      }
    else
      {
	#Store the message in the stderr buffer until $verbose has been defined
	#by the command line options (using Getopts::Long)
	push(@{$stderr_buffer},
	     ['verbose',
	      $message_level,
	      join('',($verbose_message,
		       ($overme_flag ? "\r" : "\n")))]);
      }

    #Record the state
    $last_verbose_size  = $verbose_length;
    $last_verbose_state = $overme_flag;

    #Return success
    return(0);
  }

sub verboseOverMe
  {verbose({OVERME=>1},@_)}

##
## Method that prints errors with a leading program identifier containing a
## trace route back to main to see where all the method calls were from,
## the line number of each call, an error number, and the name of the script
## which generated the error (in case scripts are called via a system call).
## Globals used: $error_limit, $quiet, $verbose, $pipeline_mode, $extended
##
sub error
  {
    if(defined($quiet) && $quiet)
      {
	#This will empty the buffer if there's something in it based on $quiet
	flushStderrBuffer() if(defined($stderr_buffer));
	return(0);
      }

    if(!defined($pipeline_mode))
      {$pipeline_mode = inPipeline()}

    #Extract any possible parameters
    my($opts,@params) = getStrSubParams(['DETAIL'],@_);
    my $detail        = $opts->{DETAIL};
    my $detail_alert  = "Supply --extended for additional details.";

    #Gather and concatenate the error message and split on hard returns
    my @error_message = split(/\n/,join('',grep {defined($_)} @params));
    push(@error_message,'') unless(scalar(@error_message));
    pop(@error_message) if(scalar(@error_message) > 1 &&
			   $error_message[-1] !~ /\S/);

    #If DETAIL was supplied/defined and $quiet is defined (implying that the
    #command line has been processed), append a detailed message based on the
    #value of $extended
    if(defined($detail) && defined($quiet))
      {
	if($extended)
	  {push(@error_message,$detail)}
	else
	  {push(@error_message,$detail_alert)}
      }

    $error_number++;
    my $leader_string = "ERROR$error_number:";
    my $simple_leader = $leader_string;
    my $leader_string_pipe = $leader_string;
    my $simple_leader_pipe = $leader_string;

    my $caller_string = getTrace();
    my $script = $0;
    $script =~ s/^.*\/([^\/]+)$/$1/;

    #If $DEBUG hasn't been defined or is true, or we're in a pipeline,
    #prepend a call-trace
    if(defined($pipeline_mode) && $pipeline_mode)
      {
	$leader_string .= "$script:";
	$simple_leader .= "$script:";
      }
    $leader_string_pipe .= "$script:";
    $simple_leader_pipe .= "$script:";

    if(!defined($DEBUG) || $DEBUG)
      {$leader_string .= $caller_string}

    $leader_string   .= ' ';
    $simple_leader   .= ' ';
    $leader_string_pipe .= ' ';
    $simple_leader_pipe .= ' ';
    my $leader_length = length($leader_string);
    my $simple_length = length($simple_leader);
    my $leader_length_pipe = length($leader_string_pipe);
    my $simple_length_pipe = length($simple_leader_pipe);

    #Figure out the length of the first line of the error
    my $error_length = length(($error_message[0] =~ /\S/ ?
			       $leader_string : '') .
			      $error_message[0]);
    my $simple_err_len = length(($error_message[0] =~ /\S/ ?
				 $simple_leader : '') .
				$error_message[0]);
    my $error_length_pipe = length(($error_message[0] =~ /\S/ ?
				    $leader_string_pipe : '') .
				   $error_message[0]);
    my $simple_err_len_pipe = length(($error_message[0] =~ /\S/ ?
				      $simple_leader_pipe : '') .
				     $error_message[0]);

    #Clean up any previous verboseOverMe output that may be longer than the
    #first line of the error message, put leader string at the beginning of
    #each line of the message, and indent each subsequent line by the length
    #of the leader string
    my $tmp_msg_ln = shift(@error_message);
    my $error_string = $leader_string . $tmp_msg_ln .
      (defined($verbose) && $verbose && defined($last_verbose_state) &&
       $last_verbose_state ?
       ' ' x ($last_verbose_size - $error_length) : '') . "\n";
    my $simple_string = $simple_leader . $tmp_msg_ln .
      (defined($verbose) && $verbose && defined($last_verbose_state) &&
       $last_verbose_state ?
       ' ' x ($last_verbose_size - $simple_err_len) : '') . "\n";
    my $error_string_pipe = $leader_string_pipe . $tmp_msg_ln .
      (defined($verbose) && $verbose && defined($last_verbose_state) &&
       $last_verbose_state ?
       ' ' x ($last_verbose_size - $error_length_pipe) : '') . "\n";
    my $simple_string_pipe = $simple_leader_pipe . $tmp_msg_ln .
      (defined($verbose) && $verbose && defined($last_verbose_state) &&
       $last_verbose_state ?
       ' ' x ($last_verbose_size - $simple_err_len_pipe) : '') . "\n";
    foreach my $line (@error_message)
      {
	$error_string       .= (' ' x $leader_length) . $line . "\n";
	$simple_string      .= (' ' x $simple_length) . $line . "\n";
	$error_string_pipe  .= (' ' x $leader_length_pipe) . $line . "\n";
	$simple_string_pipe .= (' ' x $simple_length_pipe) . $line . "\n";
      }

    #If the global error hash does not yet exist, store the first example of
    #this error type
    if(!defined($error_hash) ||
       !exists($error_hash->{$caller_string}))
      {
	$error_hash->{$caller_string}->{EXAMPLE}    = $simple_string;
	$error_hash->{$caller_string}->{EXAMPLENUM} = $error_number;

	$error_hash->{$caller_string}->{EXAMPLE} =~ s/\n */ /g;
	$error_hash->{$caller_string}->{EXAMPLE} =~ s/ $//g;
	$error_hash->{$caller_string}->{EXAMPLE} =~ s/^(.{100}).+/$1.../;

	#If debug is not defined or is non-zero, the example will default to
	#debug-style leaders, otherwise.
	if(!defined($DEBUG) || $DEBUG)
	  {
	    $error_hash->{$caller_string}->{EXAMPLEDEBUG} = $error_string;
	    $error_hash->{$caller_string}->{EXAMPLEDEBUG} =~ s/\n */ /g;
	    $error_hash->{$caller_string}->{EXAMPLEDEBUG} =~ s/ $//g;
	    $error_hash->{$caller_string}->{EXAMPLEDEBUG} =~
	      s/^(.{100}).+/$1.../;
	  }

	$error_hash->{$caller_string}->{EXAMPLEPIPE} = $simple_string_pipe;
	$error_hash->{$caller_string}->{EXAMPLEPIPE} =~ s/\n */ /g;
	$error_hash->{$caller_string}->{EXAMPLEPIPE} =~ s/ $//g;
	$error_hash->{$caller_string}->{EXAMPLEPIPE} =~ s/^(.{100}).+/$1.../;

	$error_hash->{$caller_string}->{EXAMPLEDEBUGPIPE} =
	  $error_string_pipe;
	$error_hash->{$caller_string}->{EXAMPLEDEBUGPIPE} =~
	  s/\n */ /g;
	$error_hash->{$caller_string}->{EXAMPLEDEBUGPIPE} =~
	  s/ $//g;
	$error_hash->{$caller_string}->{EXAMPLEDEBUGPIPE} =~
	  s/^(.{100}).+/$1.../;
      }

    #Increment the count for this error type
    $error_hash->{$caller_string}->{NUM}++;

    #Flush the buffer if it is defined and either quiet is defined and true or
    #defined, false, and error_limit is defined
    flushStderrBuffer() if((defined($quiet) &&
			    ($quiet || defined($error_limit))) &&
			   defined($stderr_buffer));

    #Print the error unless it is over the limit for its type
    if(!defined($error_limit) || $error_limit == 0 ||
       $error_hash->{$caller_string}->{NUM} <= $error_limit)
      {
	#Let the user know if we're going to start suppressing errors of
	#this type
	if(defined($error_limit) && $error_limit &&
	   $error_hash->{$caller_string}->{NUM} == $error_limit)
	  {
	    $error_string .=
	      join('',
		   ($leader_string,"NOTE: Further errors of this type will ",
		    "be suppressed.\n$leader_string",
		    "Set --error-limit to 0 to turn off error suppression\n"));
	    $simple_string .=
	      join('',
		   ($simple_leader,"NOTE: Further errors of this type will ",
		    "be suppressed.\n$simple_leader",
		    "Set --error-limit to 0 to turn off error suppression\n"));
	  }

	if(defined($quiet))
	  {
	    #The following assumes we'd not have gotten here if quiet was true
	    print STDERR ($error_string);
	  }
	else
	  {
	    #Store the message in the stderr buffer until $quiet has been
	    #defined by the command line options (using Getopts::Long)
	    push(@{$stderr_buffer},
		 ['error',
		  $error_hash->{$caller_string}->{NUM},
		  $error_string,
		  $leader_string,
		  $simple_string,
		  $simple_leader,
		  $detail,
		  $detail_alert]);
	  }
      }

    #Reset the verbose states if verbose is true
    if(defined($verbose) && $verbose)
      {
	$last_verbose_size  = 0;
	$last_verbose_state = 0;
      }

    #Return success
    return(0);
  }

##
## Method that prints warnings with a leader string containing a warning
## number
##
## Globals used: $error_limit, $quiet, $verbose, $pipeline_mode, $extended
##
sub warning
  {
    if(defined($quiet) && $quiet)
      {
	#This will empty the buffer if there's something in it based on $quiet
	flushStderrBuffer() if(defined($stderr_buffer));
	return(0);
      }

    if(!defined($pipeline_mode))
      {$pipeline_mode = inPipeline()}

    $warning_number++;

    #Extract any possible parameters
    my($opts,@params) = getStrSubParams(['DETAIL'],@_);
    my $detail        = $opts->{DETAIL};
    my $detail_alert  = "Supply --extended for additional details.";

    #Gather and concatenate the warning message and split on hard returns
    my @warning_message = split(/\n/,join('',grep {defined($_)} @params));
    push(@warning_message,'') unless(scalar(@warning_message));
    pop(@warning_message) if(scalar(@warning_message) > 1 &&
			     $warning_message[-1] !~ /\S/);

    #If DETAIL was supplied/defined and $quiet is defined (implying that the
    #command line has been processed), append a detailed message based on the
    #value of $extended
    if(defined($detail) && defined($quiet))
      {
	if($extended)
	  {push(@warning_message,$detail)}
	else
	  {push(@warning_message,$detail_alert)}
      }

    #If this is from our sig_warn handler, join the last 2 values of the array
    #(effectively chomping the warn message)
    if(defined($warning_message[0]) && scalar(@warning_message) > 1 &&
       $warning_message[0] =~ /^Runtime warning: \[/)
      {$warning_message[-2] .= pop(@warning_message)}

    my $leader_string = "WARNING$warning_number:";
    my $simple_leader = $leader_string;
    my $leader_string_pipe = $leader_string;
    my $simple_leader_pipe = $leader_string;

    my $caller_string = getTrace();
    my $script = $0;
    $script =~ s/^.*\/([^\/]+)$/$1/;

    #If $DEBUG hasn't been defined or is true, or we're in a pipeline,
    #prepend a call-trace
    if(defined($pipeline_mode) && $pipeline_mode)
      {
	$leader_string .= "$script:";
	$simple_leader .= "$script:";
      }
    $leader_string_pipe .= "$script:";
    $simple_leader_pipe .= "$script:";
    if(!defined($DEBUG) || $DEBUG)
      {$leader_string .= $caller_string}

    $leader_string      .= ' ';
    $simple_leader      .= ' ';
    $leader_string_pipe .= ' ';
    $simple_leader_pipe .= ' ';
    my $leader_length = length($leader_string);
    my $simple_length = length($simple_leader);
    my $leader_length_pipe = length($leader_string_pipe);
    my $simple_length_pipe = length($simple_leader_pipe);

    #Figure out the length of the first line of the error
    my $warning_length = length(($warning_message[0] =~ /\S/ ?
				 $leader_string : '') .
				$warning_message[0]);
    my $simple_warn_len = length(($warning_message[0] =~ /\S/ ?
				  $simple_leader : '') .
				 $warning_message[0]);
    my $warning_length_pipe = length(($warning_message[0] =~ /\S/ ?
				      $leader_string_pipe : '') .
				     $warning_message[0]);
    my $simple_warn_len_pipe = length(($warning_message[0] =~ /\S/ ?
				       $simple_leader_pipe : '') .
				      $warning_message[0]);

    #Clean up any previous verboseOverMe output that may be longer than the
    #first line of the warning message, put leader string at the beginning of
    #each line of the message and indent each subsequent line by the length
    #of the leader string
    my $tmp_msg_ln = shift(@warning_message);
    my $spacelen = (defined($last_verbose_size) ? $last_verbose_size : 0) -
      $warning_length;
    $spacelen = 0 if($spacelen < 0);
    my $warning_string = $leader_string . $tmp_msg_ln .
      (defined($verbose) && $verbose && defined($last_verbose_state) &&
       $last_verbose_state ?
       ' ' x $spacelen : '') . "\n";
    $spacelen = (defined($last_verbose_size) ? $last_verbose_size : 0) -
      $simple_warn_len;
    $spacelen = 0 if($spacelen < 0);
    my $simple_string = $simple_leader . $tmp_msg_ln .
      (defined($verbose) && $verbose && defined($last_verbose_state) &&
       $last_verbose_state ?
       ' ' x $spacelen : '') . "\n";
    $spacelen = (defined($last_verbose_size) ? $last_verbose_size : 0) -
      $warning_length_pipe;
    $spacelen = 0 if($spacelen < 0);
    my $warning_string_pipe = $leader_string_pipe . $tmp_msg_ln .
      (defined($verbose) && $verbose && defined($last_verbose_state) &&
       $last_verbose_state ?
       ' ' x $spacelen : '') . "\n";
    $spacelen = (defined($last_verbose_size) ? $last_verbose_size : 0) -
      $simple_warn_len_pipe;
    $spacelen = 0 if($spacelen < 0);
    my $simple_string_pipe = $simple_leader_pipe . $tmp_msg_ln .
      (defined($verbose) && $verbose && defined($last_verbose_state) &&
       $last_verbose_state ?
       ' ' x $spacelen : '') . "\n";
    foreach my $line (@warning_message)
      {
	$warning_string      .= (' ' x $leader_length) . $line . "\n";
	$simple_string       .= (' ' x $simple_length) . $line . "\n";
	$warning_string_pipe .= (' ' x $leader_length_pipe) . $line . "\n";
	$simple_string_pipe  .= (' ' x $simple_length_pipe) . $line . "\n";
      }

    #If the global warning hash does not yet exist, store the first example of
    #this warning type
    if(!defined($warning_hash) ||
       !exists($warning_hash->{$caller_string}))
      {
	$warning_hash->{$caller_string}->{EXAMPLE}    = $simple_string;
	$warning_hash->{$caller_string}->{EXAMPLENUM} = $warning_number;

	$warning_hash->{$caller_string}->{EXAMPLE} =~ s/\n */ /g;
	$warning_hash->{$caller_string}->{EXAMPLE} =~ s/ $//g;
	$warning_hash->{$caller_string}->{EXAMPLE} =~ s/^(.{100}).+/$1.../;

	#If debug is not defined or is non-zero, the example will default to
	#debug-style leaders, otherwise.
	if(!defined($DEBUG) || $DEBUG)
	  {
	    $warning_hash->{$caller_string}->{EXAMPLEDEBUG} = $warning_string;
	    $warning_hash->{$caller_string}->{EXAMPLEDEBUG} =~ s/\n */ /g;
	    $warning_hash->{$caller_string}->{EXAMPLEDEBUG} =~ s/ $//g;
	    $warning_hash->{$caller_string}->{EXAMPLEDEBUG} =~
	      s/^(.{100}).+/$1.../;
	  }

	$warning_hash->{$caller_string}->{EXAMPLEPIPE} = $simple_string_pipe;
	$warning_hash->{$caller_string}->{EXAMPLEPIPE} =~ s/\n */ /g;
	$warning_hash->{$caller_string}->{EXAMPLEPIPE} =~ s/ $//g;
	$warning_hash->{$caller_string}->{EXAMPLEPIPE} =~ s/^(.{100}).+/$1.../;

	$warning_hash->{$caller_string}->{EXAMPLEDEBUGPIPE} =
	  $warning_string_pipe;
	$warning_hash->{$caller_string}->{EXAMPLEDEBUGPIPE} =~
	  s/\n */ /g;
	$warning_hash->{$caller_string}->{EXAMPLEDEBUGPIPE} =~
	  s/ $//g;
	$warning_hash->{$caller_string}->{EXAMPLEDEBUGPIPE} =~
	  s/^(.{100}).+/$1.../;
      }

    #Increment the count for this warning type
    $warning_hash->{$caller_string}->{NUM}++;

    #Flush the buffer if it is defined and either quiet is defined and true or
    #defined, false, and error_limit is defined
    flushStderrBuffer() if((defined($quiet) &&
			    ($quiet || defined($error_limit))) &&
			   defined($stderr_buffer));

    #Print the warning unless it is over the limit for its type
    if(!defined($error_limit) || $error_limit == 0 ||
       $warning_hash->{$caller_string}->{NUM} <= $error_limit)
      {
	#Let the user know if we're going to start suppressing errors of
	#this type
	if(defined($error_limit) && $error_limit &&
	   $warning_hash->{$caller_string}->{NUM} == $error_limit)
	  {
	    $warning_string .=
	      join('',
		   ($leader_string,"NOTE: Further warnings of this type will ",
		    "be suppressed.\n$leader_string",
		    "Set --error-limit to 0 to turn off error suppression\n"));
	    $simple_string .=
	      join('',
		   ($simple_leader,"NOTE: Further warnings of this type will ",
		    "be suppressed.\n$simple_leader",
		    "Set --error-limit to 0 to turn off error suppression\n"));
	  }

	if(defined($quiet))
	  {
	    #The following assumes we'd not have gotten here if quiet was true
	    print STDERR ($warning_string);
	  }
	else
	  {
	    #Store the message in the stderr buffer until $quiet has been
	    #defined by the command line options (using Getopts::Long)
	    push(@{$stderr_buffer},
		 ['warning',
		  $warning_hash->{$caller_string}->{NUM},
		  $warning_string,
		  $leader_string,
		  $simple_string,
		  $simple_leader,
		  $detail,
		  $detail_alert]);
	  }
      }

    #Reset the verbose states if verbose is true
    if(defined($verbose) && $verbose)
      {
	$last_verbose_size  = 0;
	$last_verbose_state = 0;
      }

    #Return success
    return(0);
  }

##
## Method that gets a line of input and accounts for carriage returns that
## many different platforms use instead of hard returns.  Note, it uses a
## global array reference variable ($infile_line_buffer) to keep track of
## buffered lines from multiple file handles.
##
sub getLine
  {
    my @in = getSubParams([qw(HANDLE VERBOSELEVEL VERBOSEFREQ)],
			  [qw(HANDLE)],
			  [@_]);
    my $file_handle   = $in[0];
    my $verbose_level = defined($in[1]) ? $in[1] : 2;
    my $verbose_freq  = defined($in[2]) ? $in[2] : 100;

    if(!defined($file_handle))
      {
	error("File handle sent in undefined.");
	return(undef);
      }

    #Set a global array variable if not already set
    $infile_line_buffer = {} if(!defined($infile_line_buffer));
    if(!exists($infile_line_buffer->{$file_handle}))
      {$infile_line_buffer->{$file_handle}->{FILE} = []}

    #If this sub was called in array context
    if(wantarray)
      {
	#Check to see if this file handle has anything remaining in its buffer
	#and if so return it with the rest
	if(scalar(@{$infile_line_buffer->{$file_handle}->{FILE}}) > 0)
	  {
	    return(@{$infile_line_buffer->{$file_handle}->{FILE}},
		   map
		   {
		     my $item = $_;

		     #If carriage returns were substituted and we haven't
		     #already issued a carriage return warning for this file
		     #handle
		     if(s/\r\n|\n\r|\r/\n/g &&
			!exists($infile_line_buffer->{$file_handle}->{WARNED}))
		       {
			 $infile_line_buffer->{$file_handle}->{WARNED}
			   = 1;
			 warning('Carriage returns were found in your file ',
				 'and replaced with hard returns.');
		       }

		     map {$infile_line_buffer->{$file_handle}->{COUNT}++;
			  verboseOverMe({LEVEL     => $verbose_level,
					 FREQUENCY => $verbose_freq},
					"Reading line ",$infile_line_buffer
					->{$file_handle}->{COUNT},".");
			  $_}
		     split(/(?<=\n)/,$item);
		   } <$file_handle>);
	  }

	#Otherwise return everything else
	return(map
	       {
		 my $item = $_;

		 #If carriage returns were substituted and we haven't already
		 #issued a carriage return warning for this file handle
		 if(s/\r\n|\n\r|\r/\n/g &&
		    !exists($infile_line_buffer->{$file_handle}->{WARNED}))
		   {
		     $infile_line_buffer->{$file_handle}->{WARNED}
		       = 1;
		     warning('Carriage returns were found in your file ',
			     'and replaced with hard returns.');
		   }

		 map {$infile_line_buffer->{$file_handle}->{COUNT}++;
		      verboseOverMe({LEVEL     => $verbose_level,
				     FREQUENCY => $verbose_freq},
				    "Reading line ",$infile_line_buffer
				    ->{$file_handle}->{COUNT},".");
		      $_}
		 split(/(?<=\n)/,$item);
	       } <$file_handle>);
      }

    #If the file handle's buffer is empty, put more on
    if(scalar(@{$infile_line_buffer->{$file_handle}->{FILE}}) == 0)
      {
	my $line = <$file_handle>;
	#The following is to deal with files that have the eof character at the
	#end of the last line.  I may not have it completely right yet.
	if(defined($line))
	  {
	    if($line =~ s/\r\n|\n\r|\r/\n/g &&
	       !exists($infile_line_buffer->{$file_handle}->{WARNED}))
	      {
		$infile_line_buffer->{$file_handle}->{WARNED} = 1;
		warning('Carriage returns were found in your file and ',
			'replaced with hard returns.');
	      }

	    @{$infile_line_buffer->{$file_handle}->{FILE}} =
	      map {$infile_line_buffer->{$file_handle}->{COUNT}++;
		   verboseOverMe({LEVEL     => $verbose_level,
				  FREQUENCY => $verbose_freq},"Reading line ",
				 $infile_line_buffer->{$file_handle}->{COUNT},
				 ".");
		   $_}
		split(/(?<=\n)/,$line);
	  }
	else
	  {@{$infile_line_buffer->{$file_handle}->{FILE}} = ($line)}
      }

    #Shift off and return the first thing in the buffer for this file handle
    return($_ = shift(@{$infile_line_buffer->{$file_handle}->{FILE}}));
  }

##
## This method allows the user to print debug messages containing the line
## of code where the debug print came from and a debug number.  Debug prints
## will only be printed (to STDERR) if the debug option is supplied on the
## command line.
##
sub debug
  {
    if(defined($DEBUG) && !$DEBUG)
      {
	flushStderrBuffer() if(defined($stderr_buffer));
	return(0);
      }

    #Grab the options from the parameter array
    my($opts,@params)  = getStrSubParams(['LEVEL','DETAIL'],@_);
    my $message_level  = (exists($opts->{LEVEL}) && defined($opts->{LEVEL}) ?
			  $opts->{LEVEL} : 1);
    my $detail         = $opts->{DETAIL};
    my $detail_alert   = "Supply --extended for additional details.";

    #Return if $DEBUG level is greater than a negative message level at which
    #this message is printed or if $DEBUG level is less than a positive message
    #level at which this message is printed.  Negative levels are for template
    #diagnostics.
    return(0) if(defined($DEBUG) &&
		 (($message_level < 0 && $DEBUG > $message_level) ||
		  ($message_level > 0 && $DEBUG < $message_level)));

    $debug_number++;

    #Gather and concatenate the error message and split on hard returns
    my @debug_message =
      split(/\n/,join('',map {defined($_) ? $_ : 'undef'} @params));
    push(@debug_message,'') unless(scalar(@debug_message));
    pop(@debug_message) if(scalar(@debug_message) > 1 &&
			   $debug_message[-1] !~ /\S/);

    #If DETAIL was supplied/defined and $quiet is defined (implying that the
    #command line has been processed), append a detailed message based on the
    #value of $extended
    if(defined($detail) && defined($quiet))
      {
	if($extended)
	  {push(@debug_message,$detail)}
	else
	  {push(@debug_message,$detail_alert)}
      }

    my $leader_string = "DEBUG$debug_number:";
    my $simple_leader = $leader_string;

    my $caller_string = getTrace();
    my $script = $0;
    $script =~ s/^.*\/([^\/]+)$/$1/;

    ##TODO: Add pipeline mode string later in flushStderrBuffer if true.  See
    ##      requirement 184
    if(defined($pipeline_mode) && $pipeline_mode)
      {
	$leader_string .= "$script:";
	$simple_leader .= "$script:";
      }

    my $full_trace = $caller_string;
    my $short_trace = $caller_string;
    $short_trace =~ s/:.*/:/;
    $leader_string .= (defined($DEBUG) && abs($DEBUG) == 1 ?
		       $short_trace : $full_trace);
    $simple_leader .= $short_trace;

    #Figure out the length of the first line of the error
    my $debug_length = length(($debug_message[0] =~ /\S/ ?
			       $leader_string : '') .
			      $debug_message[0]);
    my $simple_dbg_length = length(($debug_message[0] =~ /\S/ ?
				    $simple_leader : '') .
				   $debug_message[0]);

    #Contstruct the debug message string
    #The first line should contain a trace and clean up verbose-over-me stuff
    my $tmp_msg_ln = shift(@debug_message);
    my $debug_str =
      join('',($leader_string,
	       $tmp_msg_ln,
	       (defined($verbose) && $verbose &&
		defined($last_verbose_state) &&
		$last_verbose_state ?
		' ' x (($last_verbose_size - $debug_length) < 0 ? 0 :
		       ($last_verbose_size - $debug_length)) : ''),
	       "\n"));
    my $simple_string =
      join('',($simple_leader,
	       $tmp_msg_ln,
	       (defined($verbose) && $verbose &&
		defined($last_verbose_state) &&
		$last_verbose_state ?
		' ' x ($last_verbose_size - $simple_dbg_length) : ''),
	       "\n"));
    #Subsequent lines will be indented by the length of the leader string
    my $leader_length = length($leader_string);
    my $simple_length = length($simple_leader);
    foreach my $line (@debug_message)
      {
	$debug_str      .= (' ' x $leader_length) . $line . "\n";
	$simple_string  .= (' ' x $simple_length) . $line . "\n";
      }

    if(defined($DEBUG))
      {
	flushStderrBuffer() if(defined($stderr_buffer));

	print STDERR ($debug_str);
      }
    else
      {
	#Store the message in the stderr buffer until $quiet has been
	#defined by the command line options (using Getopts::Long)
	push(@{$stderr_buffer},
	     ['debug',
	      $message_level,
	      $debug_str,
	      $leader_string,
	      $simple_string,
	      $simple_leader,
	      $detail,
	      $detail_alert]);
      }

    #Reset the verbose states if verbose is true
    if(defined($verbose) && $verbose)
      {
	$last_verbose_size  = 0;
	$last_verbose_state = 0;
      }

    #Return success
    return(0);
  }

##
## This sub marks the time (which it pushes onto an array) and in scalar
## context returns the time since the last mark by default or supplied mark
## (optional).
## A mark is not made if a mark index is supplied
## Uses a global time_marks array reference
##
sub markTime
  {
    my @in = getSubParams([qw(MARKINDEX)],[],[@_]);

    #Record the time
    my $time = time();

    #Set a global array variable if not already set to contain (as the first
    #element) the time the program started (NOTE: "$^T" is a perl variable that
    #contains the start time of the script)
    $time_marks = [$^T] if(!defined($time_marks));

    #Read in the time mark index or set the default value
    my $mark_index = (defined($in[0]) ? $in[0] : -1);  #Optional Default: -1

    #Error check the time mark index sent in
    if($mark_index > (scalar(@$time_marks) - 1))
      {
	error('Supplied time mark index is larger than the size of the ',
	      "time_marks array.\nThe last mark will be set.");
	$mark_index = -1;
      }

    #Calculate the time since the time recorded at the time mark index
    my $time_since_mark = $time - $time_marks->[$mark_index];

    #Add the current time to the time marks array
    push(@$time_marks,$time)
      if(!defined($in[0]) || scalar(@$time_marks) == 0);

    #Return the time since the time recorded at the supplied time mark index
    return($time_since_mark);
  }

##
## This method reconstructs the command entered on the command line
## (excluding standard input and output redirects).  The intended use for this
## method is for when a user wants the output to contain the input command
## parameters in order to keep track of what parameters go with which output
## files.
##
#Globals used: $preserve_args
sub getCommand
  {
    my @in = getSubParams([qw(INCLUDE_PERL_PATH NO_DEFAULTS
			      INC_DEFMODE)],[],[@_]);
    my $perl_path_flag        = $in[0];
    my $no_defaults           = $in[1];
    my $include_default_modes = $in[2];
    my($command);
    my @return_args = ();

    #Determine the script name
    my $script = $0;
    $script =~ s/^.*\/([^\/]+)$/$1/;

    #Put quotes around any parameters containing un-escaped spaces, asterisks,
    #or quotes
    my $arguments = defined($preserve_args) ? [@$preserve_args] : [];
    foreach my $arg (@$arguments)
      {
	if($arg =~ /(?<!\\)[\s\*"']/ || $arg =~ /^<|>|\|(?!\|)/ ||
	   $arg eq '' || $arg =~ /[\{\}\[\]\(\)]/)
	  {
	    if($arg =~ /(?<!\\)["]/)
	      {$arg = "'" . $arg . "'"}
	    else
	      {$arg = '"' . $arg . '"'}
	  }
      }

    #Determine the perl path used (dependent on the `which` unix built-in)
    if($perl_path_flag)
      {
	$command = `which $^X`;
	push(@return_args,$command);
	chomp($command);
	$command .= ' ';
      }

    #Build the original command
    $command .= join(' ',($0,@$arguments));
    push(@return_args,($0,@$arguments));

    #Add any default flags that were previously saved
    my @default_options = getUserDefaults();
    if(!$no_defaults && scalar(@default_options))
      {
	my(@tmp_default_options,@defrunmodes);
	if(!defined($include_default_modes) || !$include_default_modes)
	  {
	    @tmp_default_options =
	      grep {$_ ne '--usage' && $_ ne '--help' && $_ ne '--run' &&
		      $_ ne '--dry-run'} @default_options;
	  }
	else
	  {@tmp_default_options = @default_options}

	@defrunmodes =
	  grep {$_ eq '--usage' || $_ eq '--help' || $_ eq '--run' ||
		  $_ eq '--dry-run'} @default_options;

	$command .= ' -- [USER DEFAULTS ADDED: ';
	$command .= join(' ',@tmp_default_options);
	$command .= ']';

	if(scalar(@defrunmodes))
	  {
	    $command .= ' [USER DEFAULT RUN MODE: ';
	    $command .= join(' ',@defrunmodes);
	    $command .= ']';
	  }

	push(@return_args,@tmp_default_options);
      }

    return(wantarray ? @return_args : $command);
  }

##
## This method performs a more reliable glob than perl's built-in, which
## fails for files with spaces in the name, even if they are escaped.  The
## purpose is to allow the user to enter input files using double quotes and
## un-escaped spaces as is expected to work with many programs which accept
## individual files as opposed to sets of files.  If the user wants to enter
## multiple files, it is assumed that space delimiting will prompt the user to
## realize they need to escape the spaces in the file names.  This version
## works with a mix of unescaped and escaped spaces, as well as glob
## characters.  It will also split non-files on unescaped spaces and uses a
## helper sub (globCurlyBraces) to mitigate truncations from long strings.
##
sub sglob
  {
    #Convert possible 'Getopt::Long::CallBack' to SCALAR by wrapping in quotes:
    my $command_line_string = "$_[0]";
    if(!defined($command_line_string))
      {
	warning("Undefined command line string encountered.");
	return($command_line_string);
      }
    #The command_line_string is 1 existing file (possibly w/ unescaped spaces)
    elsif(-e $command_line_string)
      {
	debug({LEVEL => -3},
	      "Returning argument string: [($command_line_string)].");
	return($command_line_string);
      }
    #Else if the string contains unescaped spaces, does not contain escaped
    #spaces, and does not contain quotes, see if it's a single file (possibly
    #with glob characters)
    elsif($command_line_string =~ /(?<!\\) / &&
	  $command_line_string !~ /\\ / && $command_line_string !~ /["']/)
      {
	my $x = [bsd_glob($command_line_string,GLOB_CSH)];

	#If glob didn't truncate a pattern, there were multiple things returned
	#or there was 1 thing returned that exists
	if(notAGlobTruncation($command_line_string,$x) &&
	   scalar(@$x) > 1 || ((scalar(@$x) == 1 && -e $x->[0])))
	  {
	    debug({LEVEL => -2},
		  "Returning files with spaces: [(@$x)].");
	    return(@$x);
	  }
      }

    my(@partials);

    #Sometimes, the glob string is larger than GLOB_LIMIT (even though
    #the shell sent in the long string to begin with).  When that
    #happens, bsd_glob just silently chops off everything except the
    #directory, so we will split the strings up here in perl (to expand
    #any '{X,Y,...}' patterns) before passing them to bsd_glob.  This
    #will hopefully shorten each individual file string for bsd_glob to
    #be able to handle.  Since doing this will break filenames/paths that have
    #spaces in them, we'll only do it if there are more than 1024 non-white-
    #space characters in a row.  It would be nice to handle escaped spaces too,
    #but se la vie.

    #If the command line string is short or doesn't contain curly braces
    if($command_line_string !~ /\S{1025}/ || $command_line_string !~ /\{.*\}/)
      {@partials = split(/(?<!\\)\s+/,$command_line_string)}
    #Else if there are curly braces anywhere, do the trick to expand them in
    #perl to avoid the glob limit issue
    else
      {@partials = map {sort {$a cmp $b} globCurlyBraces($_)}
	 split(/(?<!\\)\s+/,$command_line_string)}

    debug({LEVEL => -5},"Partials being sent to bsd_glob: [",
	  join(',',@partials),"].");

    #Note, when bsd_glob gets a string with a glob character it can't expand,
    #it drops the string entirely.  Those strings are returned with the glob
    #characters so the surrounding script can report an error.  The GLOB_ERR
    #posix flag is not used because of the way the patterns are manipulated
    #before getting to bsd_glob - which could cause a valid expansion to
    #nothing that bsd_glob would complain about.
    my @arguments =
      map
	{
	  #Expand the string from the command line using a glob
	  my $v = $_;
	  my $x = [bsd_glob($v,GLOB_CSH)];
	  #If the expansion didn't truncate a file glob pattern to a directory
	  if(notAGlobTruncation($v,$x))
	    {
	      debug({LEVEL => -5},"Not a glob truncation: [$v] -> [@$x].");
	      @$x;
	    }
	  else
	    {
	      debug({LEVEL => -5},"Is a glob truncation: [$v] -> [@$x].");
	      $v;
	    }
	} @partials;

    #If the value was something like a perl regular expression (including curly
    #braces), then the above code would have expanded that to a number of non-
    #existing "files" with the curly braces removed.  This is to prevent that.
    #Test case: -s '(AUAU|UAUA).{25,50}GGG|GGG.{25,50}(AUAU|UAUA)'
    if($command_line_string =~ /\{.*\}/ &&
       scalar(grep {-e $_} @arguments) == 0)
      {
	#If the command line string had unescaped spaces (and the curlies
	#required above), then either the curlies were perl-expanded or glab-
	#expanded, but none of the resulting strings were existing files, so
	#let's just split on the unescaped spaces
	if($command_line_string =~ /(?<!\\)\s/)
	  {
	    debug({LEVEL => -2},"Returning original command line string ",
		  "split on unescaped spaces since it didn't expand to ",
		  "existing files: [$command_line_string].");
	    return(split(/(?<!\\)\s+/,$command_line_string));
	  }

	debug({LEVEL => -2},"Returning original command line string since it ",
	      "didn't expand to existing files and had no unescaped spaces: ",
	      "[$command_line_string].");
	return($command_line_string);
      }

    debug({LEVEL => -2},
	  "Returning split args: [(",join('),(',@arguments),
	  ")] parsed from string: [$command_line_string].");

    #Return the split arguments.  We're assuming that if the command line
    #string was a real file, it would not get here.
    return(@arguments);
  }

#This method takes a string and the result of calling bsd_glob on it and
#determines whether the expansion was successful or whether glob truncated the
#file name leaving just the directory.
sub notAGlobTruncation
  {
    my $preproc_str    = $_[0];
    my $expanded_array = $_[1];

    return(scalar(@$expanded_array) > 1 ||

	   (#There's only 1 expanded result and neither exists
	    scalar(@$expanded_array) == 1 && !-e $expanded_array->[0] &&
	    !-e $preproc_str) ||

	   (#There's only 1 expanded and existing result AND
	    scalar(@$expanded_array) == 1 && -e $expanded_array->[0] &&

	    #If the glob string was too long, everything after the last
	    #directory can be truncated, so we want to avoid returning
	    #that truncated value, thus...

	    (#The expanded value is not a directory OR
	     !-d $expanded_array->[0] ||

	     #Assumed: it is a directory and...

	     (#The pre-expanded value was a valid directory string already
	      #or ended with a slash (implying the dir had glob characters
	      #in its name/path) or the last expanded string's character
	      #is not a slash (implying the end of a pattern wasn't
	      #chopped off by bsd_glob, which would leave a slash).
	      -d $preproc_str || $preproc_str =~ m%/$% ||
	      $expanded_array->[0] !~ m%/$%))));
  }

sub globCurlyBraces
  {
    my $nospace_string = $_[0];

    if($nospace_string =~ /(?<!\\)\s+/)
      {
	error("Unescaped spaces found in input string: [$nospace_string].");
	return($nospace_string);
      }
    elsif(scalar(@_) > 1)
      {
	error("Too many [",scalar(@_),"] parameters sent in.  Expected 1.");
	return(@_);
      }

    #Keep updating an array to be the expansion of a file pattern to
    #separate files
    my @expanded = ($nospace_string);

    #If there exists a '{X,Y,...}' pattern in the string
    if($nospace_string =~ /\{[^\{\}]+\}/)
      {
	#While the first element still has a '{X,Y,...}' pattern
	#(assuming everything else has the same pattern structure)
	while($expanded[0] =~ /\{[^\{\}]+\}/)
	  {
	    #Accumulate replaced file patterns in @g
	    my @buffer = ();
	    foreach my $str (@expanded)
	      {
		#If there's a '{X,Y,...}' pattern, split on ','
		if($str =~ /\{([^\{\}]+)\}/)
		  {
		    my $substr     = $1;
		    my $before     = $`;
		    my $after      = $';
		    my @expansions = split(/,/,$substr);
		    push(@buffer,map {$before . $_ . $after} @expansions);
		  }
		#Otherwise, push on the whole string
		else
		  {push(@buffer,$str)}
	      }

	    #Reset @f with the newly expanded file strings so that we
	    #can handle additional '{X,Y,...}' patterns
	    @expanded = @buffer;
	  }
      }

    #Pass the newly expanded file strings through
    return(wantarray ? @expanded : [@expanded]);
  }

#Globals used: $script_version_number, $created_on_date, $extended
sub getVersion
  {
    my @in             = getSubParams([qw(COMMENT EXTENDED)],[],[@_]);
    my $comment        = defined($in[0]) ? $in[0] : 0;
    my $local_extended = defined($_[1]) ? $_[1] : $extended;

    my $version_message = '';
    my $script          = $0;
    $script             =~ s/^.*\/([^\/]+)$/$1/;
    my $lmd             = (-e $script ?
			   localtime((stat($script))[9]) :
			   localtime(time()));

    if(!defined($script_version_number) || $script_version_number !~ /\S/)
      {
	warning("Script version number not supplied.");
	$script_version_number = 'unknown';
      }

    if((!defined($created_on_date) || $created_on_date eq 'DATE HERE') &&
       $0 !~ /perl_script_template$/)
      {
	warning('This script\'s $created_on_date variable unset/missing.  ',
		'Please edit the script to add a script creation date.');
	$created_on_date = 'unknown';
      }

    if(!defined($script_author))
      {$script_author = 'UNKNOWN'}
    if(!defined($script_contact))
      {$script_contact = 'UNKNOWN'}
    if(!defined($script_company))
      {$script_company = 'UNKNOWN'}
    if(!defined($script_license))
      {$script_license = 'UNKNOWN'}

    #If extended has any non-zero value, include the script name
    if($local_extended > 0)
      {$version_message = ($comment ? '#' : '') . "$script Version "}
    else
      {$version_message = ($comment ? '#' : '')}

    #Always include the version number
    $version_message .= $script_version_number;

    #If extended is 2 or larger, include more info about the script
    if($local_extended > 1)
      {
	$version_message .= "\n" . ($comment ? '#' : '') .
	  join("\n" . ($comment ? '#' : ''),
	       (" Created: $created_on_date",
		" Last modified: $lmd",
		" Author: $script_author",
		" Contact: $script_contact",
		" Company: $script_company",
		" License: $script_license"));
      }

    #If version is 3 or larger, include module info
    if($local_extended > 2)
      {
	#Add template version
	$version_message .= "\n" . ($comment ? '#' : '') .
	  "Generated using CommandLineInterface.pm Version $VERSION";

	$version_message .= "\n" . ($comment ? '#' : '') .
	  join("\n" . ($comment ? '#' : ''),
	       (' Created: 5/8/2006',
		' Author:  Robert W. Leach',
		' Contact: rleach@princeton.edu',
		' Company: Princeton University',
		' Copyright: 2018'));
      }

    return($version_message);
  }

#This method is a check to see if input is user-entered via a TTY (result
#is non-zero)
sub isStandardInputFromTerminal
  {return(-t STDIN)}

#This is not fool-proof.  If called in a script, it might pick up an STDIN
#handle on which no one is sending input.
sub isThereInputOnSTDIN
  {
    my $forced = defined($_[0]) ? $_[0] : 0;
    my $fn = fileno(STDIN);
    return(defined($fn) && $fn =~ /\d/ && $fn > -1 &&
	   !-t STDIN && (amIPipedTo($forced) || amIRedirectedTo($forced)));
  }

#This method is a check to see if prints are going to a TTY.  Note,
#explicit prints to STDOUT when another output handle is selected are not
#considered and may defeat this method.
sub isStandardOutputToTerminal
  {return(-t STDOUT && select() eq 'main::STDOUT')}

#This method exits the current process.  Note, you must clean up after
#yourself before calling this.  Does not exit if $force is true.  Takes the
#error number to supply to exit().
sub quit
  {
    my @in = getSubParams([qw(ERRNO REPORT)],[],[@_]);
    my $errno  = $in[0];
    my $report = $in[1];

    my $forced_past = 0;

    #If not in cleanup mode, explicit_quit is true, and force is not defined or
    #not true, it means quit has already been called and that subsequent calls
    #to quit are coming from printRunReport, flushStderrBuffer, or some deep
    #sub that they called, so just return so that the first call to quit can
    #finish.
    if(!$cleanup_mode && $explicit_quit && (!defined($force) || !$force))
      {return($forced_past)}

    #If no exit code was provided, quit even if force is indicated. We're over-
    #riding '-1' here, which is a special case for not quitting in an overwrite
    #situation
    if(!defined($errno))
      {$errno = -1}
    elsif($errno !~ /^[+\-]?\d+$/)
      {
	error("Invalid argument: [$errno].  Only integers are accepted.  Use ",
	      "error() or warning() to supply a message, then call quit() ",
	      "with an error number.");
	$errno = -1;
      }

    #We will not allow fatal quits to be forced
    if($errno && $cleanup_mode && defined($force) && $force)
      {error("Unable to force past a fatal error during command line cleanup/",
	     "exit.",
	     {DETAIL => join('',('To (possibly) force past this error, you ',
				 'must be sure to call processCommandLine ',
				 'explicitly in your code before quit is ',
				 'first called (which may be in the END ',
				 'block if you do not call it ',
				 'explicitly).'))})}

    #If there were no errors, we are not in force mode, (we are in force
    #mode and the error is -1 (meaning an overwrite situation)), or we're in
    #cleanup mode (i.e. we've been here before), allow quit to happen
    if($errno == 0 || !defined($force) || !$force ||
       (defined($force) && $force && $errno == -1) ||
       (defined($cleanup_mode) && $cleanup_mode))
      {
	#If quit is called and gets here, setting this value prevents END from
	#calling quit (creating a potential loop)
	$explicit_quit = 1;

	#Record whether or not we were in cleanup mode when we got here
	my $prior_cleanup_mode = $cleanup_mode;

	#During quitting upon successful completion of the script, we need to
	#know whether to flush the buffer, print the run report, etc, so if the
	#command line options have not been processed (possibly because the
	#programmer didn't write any code to process files), and there was no
	#error, fully process the command line and allow the report to be
	#generated (if deemed necessary later)
	if(!$cleanup_mode && $errno == 0 && !$processCommandLine_called)
	  {
	    debug({LEVEL => -1},
		  "Calling processCommandLine during successful quit.");

	    #Set cleanup mode so that if a fatal error happens from here, it
	    #will cause an exit even if in force mode
	    $cleanup_mode = 1;

	    #Set the error code to whatever processCommandLine returns, in case
	    #a fatal error occurs
	    $errno = processCommandLine();

	    debug({LEVEL => -1},
		  "quit: processCommandLine returned [$errno].");
	  }
	#Fail-safe to determine whether to flush the buffer - It is inferred
	#that something went wrong in processing the default options or before
	#all the options were setup if we've gotten here and processCommandLine
	#was called yet the command line wasn't processed.
	elsif(!$cleanup_mode && !$command_line_processed)
	  {
	    #Set cleanup mode so that if a fatal error happens from here, it
	    #will cause an exit even if in force mode
	    $cleanup_mode = ($errno ? 2 : 1);

	    if(!$processCommandLine_called)
	      {
		debug({LEVEL => -1},
		      "Calling processCommandLine during successful quit.");
		if(!$errno)
		  {$errno = processCommandLine()}
		else
		  {processCommandLine()}
	      }

	    if(!$command_line_processed)
	      {
		debug({LEVEL => -1},
		      "Calling getOptions during successful quit.");
		getOptions();
	      }

	    #In this instance, we have not run the programmer's code, so
	    #there's really no need for a run report
	    $report = 0;
	  }

	#If there was no error, files were supplied by the user, but the file
	#sets were not all iterated over, issue a warning
	if($errno == 0 && scalar(@$input_file_sets) && $unproc_file_warn &&
	   ((!defined($max_set_num) &&
	     scalar(grep {my $s=$_;scalar(grep {defined($_)} @$s)}
		    @$input_file_sets)) ||
	    (defined($max_set_num) && $max_set_num < $#{$input_file_sets})))
	  {warning((scalar(@$input_file_sets) && defined($max_set_num) ?
		    $#{$input_file_sets} - $max_set_num :
		    scalar(@$input_file_sets))," of ",
		   scalar(@$input_file_sets)," file sets were not processed.",
		   {DETAIL =>
		    join('',('Unprocessed sets: [',
			     join(';',
				  map {my $s=$_;join(',',map {defined($_) ?
								$_ : 'undef'}
						     @$s)} @$input_file_sets),
			     '].  This can happen when input and/or output ',
			     'files supplied on the command line are not all ',
			     'retrieved for processing upon the successful ',
			     'end of the script.  If there was an error, ',
			     'quit(ERRNO => #) should be used to avoid this ',
			     'warning.  If there were no errors, and not ',
			     'processing all files is a valid outcome, use ',
			     'setDefaults(UNPROCFILEWARN => 0).'))})}

	#Re-check the same exit conditions as were checked to get in here, just
	#in case an error occurred during command line processing in the first
	#case above (in which case, prior_cleanup_mode will be true - instead
	#of cleanup_mode).
	if($errno == 0 || !defined($force) || !$force ||
	   (defined($force) && $force && $errno == -1) ||
	   (defined($prior_cleanup_mode) && $prior_cleanup_mode))
	  {
	    debug({LEVEL => -1},"Exit status: [$errno].  Report: [",
		  (defined($report) ? $report : 'undef'),"].");

	    printRunReport($errno) if(!defined($report) || $report);

	    #Force-flush the buffers before quitting
	    flushStderrBuffer(1);

	    #Exit if there were no errors or we are not in force mode or (we
	    #are in force mode and the error is -1 (meaning an overwrite
	    #situation))
	    exit($errno);
	  }
	else
	  {$explicit_quit = 0}
      }

    $forced_past = 1;

    debug({LEVEL => -1},"quit returning.");

    return(1);
  }

#Generates/prints a report only if we're not in quiet mode and either we're in
#verbose mode, we're in debug mode, there was an error, or there was a warning.
#If $verbose is not defined and (local_quiet wasn't supplied as a parameter,
#we're not in debug mode, there were no errors, and there were no warnings), no
#report will be generated, nor is the report buffered (since this message can
#be considered a part of the warning/error output or verbose output).  If
#$quiet is not defined in main, it will be assumed to be false.
#Globals used: $quiet, $verbose, $DEBUG
sub printRunReport
  {
    my @in = getSubParams([qw(ERRNO)],[],[@_]);
    my $errno          = $in[0];
    my $global_verbose = defined($verbose) ? $verbose : 0;
    my $global_quiet   = defined($quiet)   ? $quiet   : 0;
    my $global_debug   = defined($DEBUG)   ? $DEBUG   : 0;

    #Return if quiet or there's nothing to report (or there's something to
    #report, but the programmer's code never ran, so all the user sees is the
    #error (i.e. $command_line_processed == 1))
    return(0) if($global_quiet || (!$global_verbose &&
				   !$global_debug &&
				   (!defined($error_number) ||
				    $command_line_processed == 1) &&
				   !defined($warning_number) &&
				   #We are exiting with success status
				   (!defined($errno) || $errno == 0 ||
				    $command_line_processed == 1)));

    #Before printing a message saying to scroll up for error details, force-
    #flush the stderr buffer
    flushStderrBuffer(1);

    #Report the number of errors, warnings, and debugs on STDERR
    print STDERR ("\n",'Done.  STATUS: [',
		  (defined($errno) ? "EXIT-CODE: $errno " : ''),
		  'ERRORS: ',
		  ($error_number ? $error_number : 0),' ',
		  'WARNINGS: ',
		  ($warning_number ? $warning_number : 0),
		  ($global_debug ?
		   ' DEBUGS: ' .
		   ($debug_number ? $debug_number : 0) : ''),' ',
		  'TIME: ',markTime(0),"s]");

    #Print an extended report if requested or there was an error or warning
    if((defined($error_number)   && $error_number) ||
       (defined($warning_number) && $warning_number))
      {
	print STDERR " SUMMARY:\n";

	#If there were errors
	if(defined($error_number) && $error_number)
	  {
	    foreach my $err_type
	      (sort {$error_hash->{$a}->{EXAMPLENUM} <=>
		       $error_hash->{$b}->{EXAMPLENUM}}
	       keys(%$error_hash))
	      {print STDERR ("\t",$error_hash->{$err_type}->{NUM},
			     " ERROR",
			     ($error_hash->{$err_type}->{NUM} > 1 ?
			      'S' : '')," LIKE: [",
			     (defined($DEBUG) && !$DEBUG ?
			      (defined($pipeline_mode) && !$pipeline_mode ?
			       $error_hash->{$err_type}->{EXAMPLE} :
			       $error_hash->{$err_type}->{EXAMPLEPIPE}) :
			      (defined($pipeline_mode) && !$pipeline_mode ?
			       $error_hash->{$err_type}->{EXAMPLEDEBUG} :
			       $error_hash->{$err_type}->{EXAMPLEDEBUGPIPE})),
			     "]\n")}
	  }

	#If there were warnings
	if(defined($warning_number) && $warning_number)
	  {
	    foreach my $warn_type
	      (sort {$warning_hash->{$a}->{EXAMPLENUM} <=>
		       $warning_hash->{$b}->{EXAMPLENUM}}
	       keys(%$warning_hash))
	      {print STDERR ("\t",$warning_hash->{$warn_type}->{NUM},
			     " WARNING",
			     ($warning_hash->{$warn_type}->{NUM} > 1 ?
			      'S' : '')," LIKE: [",
			     (defined($DEBUG) && !$DEBUG ?
			      (defined($pipeline_mode) && !$pipeline_mode ?
			       $warning_hash->{$warn_type}->{EXAMPLE} :
			       $warning_hash->{$warn_type}->{EXAMPLEPIPE}) :
			      (defined($pipeline_mode) && !$pipeline_mode ?
			       $warning_hash->{$warn_type}->{EXAMPLEDEBUG} :
			       $warning_hash->{$warn_type}->{EXAMPLEDEBUGPIPE})
			     ),"]\n")}
	  }

        print STDERR ("\tScroll up to inspect full errors/warnings in-",
		      "place.\n");
      }
    else
      {print STDERR "\n"}
  }

#This method takes multiple "types" of "sets of input files" in a 3D array
#and returns an array of combination arrays where a combination contains 1 file
#of each type.  The best way to explain the associations is by example.  Here
#are example input file associations without output suffixes or directories.
#Each type is a 2D array contained in the outer type array:

#Example 1:
#input files of type 1: [[1,2,3],[a,b,c]]
#input files of type 2: [[4,5,6],[d,e,f]]
#input files of type 3: [[x,y]]
#resulting associations: [[1,4,x],[2,5,x],[3,6,x],[a,d,y],[b,e,y],[c,f,y]]
#Example 2:
#input files of type 1: [[1,2,3],[a,b,c]]
#input files of type 2: [[4,5,6],[d,e,f]]
#input files of type 3: [[x,y,z]]
#resulting associations: [[1,4,x],[2,5,y],[3,6,z],[a,d,x],[b,e,y],[c,f,z]]
#Example 3:
#input files of type 1: [[1,2,3],[a,b,c]]
#input files of type 2: [[4,5,6],[d,e,f]]
#input files of type 3: [[x],[y]]
#resulting associations: [[1,4,x],[2,5,x],[3,6,x],[a,d,y],[b,e,y],[c,f,y]]
#Example 4:
#input files of type 1: [[1,2,3],[a,b,c]]
#input files of type 2: [[4,5,6],[d,e,f]]
#input files of type 3: [[x],[y],[z]]
#resulting associations: [[1,4,x],[2,5,y],[3,6,z],[a,d,x],[b,e,y],[c,f,z]]
#Example 5:
#input files of type 1: [[1,a],[2,b],[3,c]]
#input files of type 2: [[4,d],[5,e],[6,f]]
#input files of type 3: [[x],[y],[z]]
#resulting associations: [[1,4,x],[2,5,y],[3,6,z],[a,d,x],[b,e,y],[c,f,z]]
#Example 6:
#input files of type 1: [[1],[2]]
#input files of type 2: [[a]]
#resulting associations: [[1,a],[2,a]]

#If you submit a 2D array or 1D array, or even a single string, the method
#will wrap it up into a 3D array for processing.  Note that a 1D array mixed
#with 2D arrays will prompt the method to guess which way to associate that
#series of files in the 1D array(s) with the rest.
#The dimensions of the 2D arrays are treated differently if they are the same
#as when they are different.  First, the method will attempt to match array
#dimensions by transposing (and if a dimension is 1, it will copy elements to
#fill it up to match).  For example, the method detects that the second
#dimension in this example matches, so it will copy the 1D array:

#From this:
#input files of type 1: [[1,2],[a,b]]
#input files of type 2: [[4,5],[d,e]]
#input files of type 3: [[x,y]]       #[x,y] will be copied to match dimensions
#To this:
#input files of type 1: [[1,2],[a,b]]
#input files of type 2: [[4,5],[d,e]]
#input files of type 3: [[x,y],[x,y]]
#resulting associations: [[1,4,x],[2,5,y],[a,d,x],[b,e,y]]

#There are also 2 other optional inputs for creating the second return value
#(an array of output file stubs/names associated with each input file).  The
#two optional inputs are a 1D array of outfile suffixes and a 2D array of
#output directories.

#Associations between output directories will be made in the same way as
#between different input file types.  For example, when suffixes are provided
#for type 1:

#Example 1:
#input files of type 1: [[1,2,3],[a,b,c]]
#input files of type 2: [[4,5,6],[d,e,f]]
#outfile suffixes: [.txt,.tab]
#resulting input file associations: [[1,4],[2,5],[3,6],[a,d],[b,e],[c,f]]
#resulting outfile names:  [[1.txt,4.tab],[2.txt,5.tab],[3.txt,6.tab],
#                           [a.txt,d.tab],[b.txt,e.tab],[c.txt,f.tab]]

#Output directories are associated with combinations of files as if the output
#directory 2D array was another file type.  However, the most common expected
#usage is that all output will go to a single directory, so here's an example
#where only the first input file type generates an output file and all output
#goes to a single output directory:

#input files of type 1: [[1,2,3],[a,b,c]]
#input files of type 2: [[4,5,6],[d,e,f]]
#outfile suffixes: [.txt]
#output directories: [[out]]
#resulting input file associations: [[1,4],[2,5],[3,6],[a,d],[b,e],[c,f]]
#resulting outfile names:  [[1.txt,undef],[2.txt,undef],[3.txt,undef],
#                           [a.txt,undef],[b.txt,undef],[c.txt,undef]]

#Note that this method also detects input on standard input and treats it
#as an input of the same type as the first array in the file types array passed
#in.  If there is only one input file in that array, it will be considered to
#be a file name "stub" to be used to append outfile suffixes.

#Globals used: $skip_existing, $collid_modes_array
sub getFileSets
  {
    my $file_types_array = $_[0]; #A 3D array where the outer array specifies
                                  #file type (e.g. all files supplied by
                                  #instances of -i), the next array specifies
                                  #a specific instance of an option/flag (e.g.
                                  #the first instance of -i on the command
                                  #line) and the inner-most array contains the
                                  #arguments to that instance of that flag.
    my $outfile_suffixes = $_[1]; #OPTIONAL: An array (2D) no larger than
                                  #file_types_array's outer array (multiple
                                  #suffixes per input file type).  The order of
                                  #the suffix types must correspond to the
                                  #order of the input file types.  I.e. the
                                  #outer array of the file_types_array must
                                  #have the same corresponding order of type
                                  #elements (though it may contain fewer
                                  #elements if (e.g.) only 1 type of input file
                                  #has output files).  E.g. If the first type
                                  #in the file_types_array is files submitted
                                  #with -i, the first suffix will be appended
                                  #to files of type 1.  Note that if suffixes
                                  #are provided, any type without a suffix will
                                  #not be present in the returned outfile array
                                  #(there will be an undefined value as a
                                  #placeholder).  If no suffixes are provided,
                                  #the returned outfile array will contain
                                  #outfile stubs for every input file type to
                                  #which you must append your own suffix.
    my $outdir_array     = $_[2]; #OPTIONAL: A 2D array of output directories.
                                  #The dimensions of this array must either be
                                  #1x1, 1xN, or NxM where N or NxM must
                                  #correspond to the dimensions of one of the
                                  #input file types.  See notes above for an
                                  #example.  Every input file combination will
                                  #output to a single output directory.  Also
                                  #note that if suffixes are provided, any type
                                  #without a suffix will not be present in the
                                  #returned outfile array.  If no suffixes are
                                  #provided, the returned outfile array will
                                  #contain outfile stubs to which you must
                                  #append your own suffix.
    my $loc_collid_mode = $_[3];  #The user can over-ride individual settings.
                                  #If user_collide_mode has a value, use it,
                                  #otherwise, if individual collision modes for
                                  #each outfile type were provided, use it/
                                  #them.  Lastly, without any other explicit
                                  #setting, determine a default collision mode
                                  #from getCollisionMode (guaranteed to provide
                                  #a value).  This may change when requirement
                                  #114 is implemented.
                                  #OPTIONAL [error]{merge,rename,error} Output
                                  #conflicts mode determines what to try to do
                                  #when multiple input file combinations output
                                  #to the same output file.  This can be a 2D
                                  #array corresponding to the dimensions of the
                                  #outfile_suffixes array, filled with modes
                                  #for each outfile type (implied by the
                                  #suffixes) or it can be a 1D array (assuming
                                  #there's only one inner outfile suffixes
                                  #array, or it can be a single scalar value
                                  #that is applied to all outfile suffixes.)
    my $outfile_stub = defined($default_stub) ? $default_stub : 'STDIN';

    #eval('use Data::Dumper;1') if($DEBUG < 0);

    debug({LEVEL => -1},"Collision mode sent in: [",
	  (defined($_[3]) ?
	   (ref($_[3]) eq 'SCALAR' ? $_[3] : '(' .
	    join('),(',map {my $tm=$_;(defined($tm) ?
				       join(',',map {defined($_) ?
						       $_ : 'undef'} @$tm) :
				       'undef')} @{$_[3]}) .
	    ')') : 'undef'),"].  Global collide mode: [",getCollisionMode(),
	  "].  User over-ridden collision-mode: [",
	  (defined($user_collide_mode) ? $user_collide_mode : 'undef'),"].  ",
	  "Programmer global collision-mode: [",
	  (defined($def_collide_mode) ? $def_collide_mode : 'undef'),"]");

    debug({LEVEL => -1},"Called with outfile suffixes: [[",
	  join('],[',map {my $a = $_;join(',',map {defined($_) ? $_ : 'undef'}
					  @$a)} @$outfile_suffixes),"]].");

    debug({LEVEL => -99},"Num initial arguments: [",scalar(@_),"].");

    debug({LEVEL => -99},"Initial size of file types array: [",
	  scalar(@$file_types_array),"].");

    ##
    ## Error check/fix the file_types_array (a 3D array of strings)
    ##
    if(ref($file_types_array) ne 'ARRAY')
      {
	#Allow them to submit scalars of everything
	if(ref(\$file_types_array) eq 'SCALAR')
	  {$file_types_array = [[[$file_types_array]]]}
	else
	  {
	    error("Expected an array for the first argument, but got a [",
		  ref($file_types_array),"].");
	    quit(-27);
	  }
      }
    elsif(scalar(grep {ref($_) ne 'ARRAY'} @$file_types_array))
      {
	my @errors = map {ref(\$_)} grep {ref($_) ne 'ARRAY'}
	  @$file_types_array;
	#Allow them to have submitted an array of scalars
	if(scalar(@errors) == scalar(@$file_types_array) &&
	   scalar(@errors) == scalar(grep {$_ eq 'SCALAR'} @errors))
	  {$file_types_array = [[$file_types_array]]}
	else
	  {
	    @errors = map {ref($_) eq '' ? ref(\$_) : ref($_)}
	      grep {ref($_) ne 'ARRAY'}
	      @$file_types_array;
	    error("Expected an array of arrays for the first argument, but ",
		  "found a [",join(',',@errors),"] inside the outer array.");
	    quit(-28);
	  }
      }
    elsif(scalar(grep {my @x=@$_;scalar(grep {ref($_) ne 'ARRAY'} @x)}
		 @$file_types_array))
      {
	#Look for SCALARs
	my @errors = map {my @x=@$_;map {ref(\$_)} @x}
	  grep {my @x=@$_;scalar(grep {ref($_) ne 'ARRAY'} @x)}
	    @$file_types_array;
	debug({LEVEL => -99},"ERRORS ARRAY: [",join(',',@errors),"].");
	#Allow them to have submitted an array of arrays of scalars
	if(scalar(@errors) == scalar(map {@$_} @$file_types_array) &&
	   scalar(@errors) == scalar(grep {$_ eq 'SCALAR'} @errors))
	  {$file_types_array = [$file_types_array]}
	else
	  {
	    #Reset the errors because I'm not looking for SCALARs anymore
	    @errors = map {my @x=@$_;'[' .
			     join('],[',
				  map {ref($_) eq '' ? 'SCALAR' : ref($_)} @x)
			       . ']'}
	      @$file_types_array;
	    error("Expected an array of arrays of arrays for the first ",
		  "argument, but got an array of arrays of [",
		  join(',',@errors),"].");
	    quit(-29);
	  }
      }
    elsif(scalar(grep {my @x = @$_;
		       scalar(grep {my @y = @$_;
				    scalar(grep {ref(\$_) ne 'SCALAR'}
					   @y)} @x)} @$file_types_array))
      {
	my @errors = map {my @x = @$_;map {my @y = @$_;map {ref($_)} @y} @x}
	  grep {my @x = @$_;
		scalar(grep {my @y = @$_;
			     scalar(grep {ref(\$_) ne 'SCALAR'} @y)} @x)}
	    @$file_types_array;
	error("Expected an array of arrays of arrays of scalars for the ",
	      "first argument, but got an array of arrays of [",
	      join(',',@errors),"].");
	quit(-30);
      }

    debug({LEVEL => -99},"Size of file types array after input check/fix: [",
	  scalar(@$file_types_array),"].");

    ##
    ## Error-check/fix the outfile_suffixes array (a 2D array of strings)
    ##
    my $suffix_provided = [map {0} @$file_types_array];
    if(defined($outfile_suffixes))
      {
	if(ref($outfile_suffixes) ne 'ARRAY')
	  {
	    #Allow them to submit scalars of everything
	    if(!defined($outfile_suffixes) ||
	       ref(\$outfile_suffixes) eq 'SCALAR')
	      {
		$suffix_provided->[0] = 1;
		$outfile_suffixes = [[$outfile_suffixes]];
	      }
	    else
	      {
		error("Expected an array for the second argument, but got a [",
		      ref($outfile_suffixes),"].");
		quit(-31);
	      }
	  }
	elsif(scalar(grep {!defined($_) || ref($_) ne 'ARRAY'}
		     @$outfile_suffixes))
	  {
	    my @errors = map {defined($_) ?
				(ref($_) eq '' ? ref(\$_) : ref($_)) : 'undef'}
	      grep {!defined($_) || ref($_) ne 'ARRAY'} @$outfile_suffixes;
	    #Allow them to have submitted an array of scalars
	    if(scalar(@errors) == scalar(@$outfile_suffixes) &&
	       scalar(@errors) == scalar(grep {!defined($_) || $_ eq 'SCALAR'}
					 @errors))
	      {$outfile_suffixes = [$outfile_suffixes]}
	    else
	      {
		error("Expected an array of arrays for the second argument, ",
		      "but got an array containing [",join(',',@errors),"].");
		quit(-32);
	      }
	  }
	elsif(scalar(grep {my @x=@$_;scalar(grep {ref(\$_) ne 'SCALAR'} @x)}
		     @$outfile_suffixes))
	  {
	    #Reset the errors because I'm not looking for SCALARs anymore
	    my @errors = map {my @x=@$_;map {ref($_)} @x}
	      grep {my @x=@$_;scalar(grep {ref($_) ne 'ARRAY'} @x)}
		@$outfile_suffixes;
	    error("Expected an array of arrays of scalars for the second ",
		  "argument, but got an array of arrays of [",
		  join(',',@errors),"].");
	    quit(-33);
	  }

	foreach my $suffix_index (0..$#{$outfile_suffixes})
	  {$suffix_provided->[$suffix_index] =
	     defined($outfile_suffixes->[$suffix_index]) &&
	       scalar(@{$outfile_suffixes->[$suffix_index]})}
      }

    ##
    ## Error-check/fix the outdir_array (a 2D array of strings)
    ##
    my $outdirs_provided = 0;
    if(defined($outdir_array) && scalar(@$outdir_array))
      {
	#Error check the outdir array to make sure it's a 2D array of strings
	if(ref($outdir_array) ne 'ARRAY')
	  {
	    #Allow them to submit scalars of everything
	    if(ref(\$outdir_array) eq 'SCALAR')
	      {
		$outdirs_provided = 1;
		$outdir_array     = [[$outdir_array]];
	      }
	    else
	      {
		error("Expected an array for the third argument, but got a [",
		      ref($outdir_array),"].");
		quit(-34);
	      }
	  }
	elsif(scalar(grep {ref($_) ne 'ARRAY'} @$outdir_array))
	  {
	    my @errors = map {ref(\$_)} grep {ref($_) ne 'ARRAY'}
	      @$outdir_array;
	    #Allow them to have submitted an array of scalars
	    if(scalar(@errors) == scalar(@$outdir_array) &&
	       scalar(@errors) == scalar(grep {$_ eq 'SCALAR'} @errors))
	      {
		$outdirs_provided = 1;
		$outdir_array = [$outdir_array];
	      }
	    else
	      {
		@errors = map {ref($_)} grep {ref($_) ne 'ARRAY'}
		  @$outdir_array;
		error("Expected an array of arrays for the third argument, ",
		      "but got an array of [",join(',',@errors),"].");
		quit(-35);
	      }
	  }
	elsif(scalar(grep {my @x=@$_;scalar(grep {ref(\$_) ne 'SCALAR'} @x)}
		     @$outdir_array))
	  {
	    #Look for SCALARs
	    my @errors = map {my @x=@$_;map {ref($_)} @x}
	      grep {my @x=@$_;scalar(grep {ref(\$_) ne 'SCALAR'} @x)}
		@$outdir_array;
	    error("Expected an array of arrays of scalars for the third ",
		  "argument, but got an array of arrays containing [",
		  join(',',@errors),"].");
	    quit(-36);
	  }
	else
	  {$outdirs_provided = 1}

	#If any outdirs are empty strings, error out & quit
	my $empties_exist = scalar(grep {my @x=@$_;scalar(grep {$_ eq ''} @x)}
				   @$outdir_array);
	if($empties_exist)
	  {
	    error("Output directories may not be empty strings.");
	    quit(-37);
	  }
      }

    #debug({LEVEL => -99},"First output collide mode: ",
    #	  Dumper($user_collide_mode));

    ##
    ## Error-check/fix the loc_collid_mode (a 2D array of strings)
    ##
    #First, we will try to retrieve the defaults
    if(!defined($loc_collid_mode))
      {
	$loc_collid_mode = $collid_modes_array;
	debug({LEVEL => -1},"Collision mode was defined as a [",
	      (ref($loc_collid_mode) eq '' ?
	       'SCALAR' : "Reference to a " . ref($loc_collid_mode)),"].");
      }
    elsif(defined($loc_collid_mode) && ref($loc_collid_mode) eq '')
      {$loc_collid_mode = getCollisionMode(undef,undef,$loc_collid_mode)}
    #If the array is the right structure, confirm the collision modes set, in
    #case the user changed it on the command line
    if(defined($loc_collid_mode) && ref($loc_collid_mode) eq 'ARRAY' &&
       scalar(grep {defined($_) && ref($_) eq 'ARRAY'} @$loc_collid_mode))
      {
	debug({LEVEL => -1},"Filling in missing collision modes with default ",
	      "values.");
	foreach my $fti (0..$#{$outfile_suffixes})
	  {
	    my $sub_array = $outfile_suffixes->[$fti];
	    foreach my $sti (0..$#{$outfile_suffixes->[$fti]})
	      {
		my $suffix_id = getSuffixID($fti,$sti);
		my $urec = getOutfileUsageHash($suffix_id);
		if(!defined($urec))
		  {error("Unable to determine default collision mode for ",
			 "output file type [$fti,$sti].")}
		#If the user supplied --collision-mode, the supplied mode might
		#end up changed
		else
		  {$loc_collid_mode->[$fti]->[$sti] =
		      getCollisionMode(undef,
				       $urec->{OPTTYPE},
				       $loc_collid_mode->[$fti]->[$sti])}
	      }
	  }
      }
    #Now let's check that everything is properly set with the collision modes
    if(ref($loc_collid_mode) ne 'ARRAY')
      {
	#Allow the programmer to submit scalars of everything
	if(ref(\$loc_collid_mode) eq 'SCALAR')
	  {
	    #Copy this value to all places corresponding to outfile_suffixes
	    my $tmp_collid_mode  = $loc_collid_mode;
	    $loc_collid_mode = [];
	    foreach my $sub_array (@$outfile_suffixes)
	      {
		push(@$loc_collid_mode,[]);
		foreach my $suff (@$sub_array)
		  {push(@{$loc_collid_mode->[-1]},
			(defined($suff) ? $tmp_collid_mode : undef))}
	      }
	  }
	else
	  {
	    error("Expected an array or scalar for the fourth argument, but ",
		  "got a [",ref($loc_collid_mode),"].");
	    quit(-38);
	  }
      }
    elsif(scalar(grep {!defined($_) || ref($_) ne 'ARRAY'} @$loc_collid_mode))
      {
	my @errors = map {defined($_) ? ref(\$_) : $_}
	  grep {!defined($_) || ref($_) ne 'ARRAY'} @$loc_collid_mode;
	#Allow them to have submitted an array of scalars
	if(scalar(@errors) == scalar(@$loc_collid_mode) &&
	   scalar(@errors) == scalar(grep {!defined($_) || $_ eq 'SCALAR'}
				     @errors))
	  {$loc_collid_mode = [$loc_collid_mode]}
	else
	  {
	    @errors = map {ref($_)} grep {ref($_) ne 'ARRAY'}
	      @$loc_collid_mode;
	    error("Expected an array of arrays for the fourth argument, ",
		  "but got an array of [",join(',',@errors),"].");
	    quit(-39);
	  }
      }
    elsif(scalar(grep {my @x=@$_;scalar(grep {defined($_) &&
						ref(\$_) ne 'SCALAR'} @x)}
		 @$loc_collid_mode))
      {
	#Reset the errors because I'm not looking for SCALARs anymore
	my @errors = map {my @x=@$_;map {ref($_)} @x}
	  grep {my @x=@$_;scalar(grep {ref($_) ne 'ARRAY'} @x)}
	    @$loc_collid_mode;
	error("Expected an array of arrays of scalars for the fourth ",
	      "argument, but got an array of arrays of [",
	      join(',',@errors),"].");
	quit(-40);
      }

    #Error-check the values of the loc_collid_mode 2D array
    my $conf_errs = [];
    foreach my $conf_array (@$loc_collid_mode)
      {
	foreach my $conf_mode (@$conf_array)
	  {
	    if(!defined($conf_mode) || $conf_mode eq '')
	      {$conf_mode = getCollisionMode()}
	    elsif($conf_mode =~ /^e/i)
	      {$conf_mode = 'error'}
	    elsif($conf_mode =~ /^m/i)
	      {$conf_mode = 'merge'}
	    elsif($conf_mode =~ /^r/i)
	      {$conf_mode = 'rename'}
	    else
	      {push(@$conf_errs,$conf_mode)}
	  }
      }
    if(scalar(@$conf_errs))
      {
	error("Invalid collision modes detected: [",join(',',@$conf_errs),
	      "].  Valid values are: [merge,error,rename].");
	quit(-41);
      }

    debug({LEVEL => -99},
	  "Contents of file types array before adding dash file: [(",
	  join(')(',map {my $t=$_;'{' .
			   join('}{',map {my $e=$_;'[' . join('][',@$e) . ']'}
				@$t) . '}'} @$file_types_array),")].");

    #debug({LEVEL => -99},"Output conf mode after manipulation: ",
    #	  Dumper($loc_collid_mode));

    ##
    ## If standard input is present, ensure it's in the file_types_array
    ##
    if(isThereInputOnSTDIN())
      {
	my $primary = (defined($primary_infile_type) ? $primary_infile_type :
		       (grep {!exists($outfile_types_hash->{$_})}
			(0..$#{$file_types_array}))[0]);

	#The first element of the file types array is specifically the type of
	#input file that can be provided via STDIN.  However, a user may
	#explicitly supply a dash on the command line to have the STDIN go to a
	#different parameter instead of the default
	debug({LEVEL => -99},"file_types_array->[$primary] is [",
	      (defined($file_types_array->[$primary]) ?
	       'defined' : 'undefined'),"].");

	if(!defined($file_types_array->[$primary]))
	  {$file_types_array->[$primary] = []}

	my $input_files = $file_types_array->[$primary];
	my $num_input_files = scalar(grep {$_ ne '-'} map {@$_} @$input_files);
	my $dash_was_explicit =
	  scalar(grep {my $t=$_;scalar(grep {my $e=$_;
					     scalar(grep {$_ eq '-'} @$e)}
				       @$t)} map {$file_types_array->[$_]}
		 grep {!exists($outfile_types_hash->{$_})}
		 (0..$#{$file_types_array}));
	my $type_index_of_dash = 0;
	if($dash_was_explicit)
	  {$type_index_of_dash =
	     (scalar(grep {my $t=$_;scalar(grep {my $e=$_;
						 scalar(grep {$_ eq '-'} @$e)}
					   @{$file_types_array->[$t]})}
		     grep {!exists($outfile_types_hash->{$_})}
		     (0..$#{$file_types_array})))[0]}

	debug({LEVEL => -99},"There are $num_input_files input files.");
	debug({LEVEL => -99},"Outfile stub: $outfile_stub.");

	#If there's only one input file detected, the dash for STDIN was not
	#explicitly provided, and an outfile suffix has been provided, use that
	#input file as a stub for the output file name construction
	if($num_input_files == 1 && !$dash_was_explicit &&
	   defined($outfile_suffixes) && scalar(@$outfile_suffixes) &&
	   defined($outfile_suffixes->[0]))
	  {
	    $outfile_stub = (grep {$_ ne '-'} map {@$_} @$input_files)[0];

	    #Unless the dash was explicitly supplied as a separate file, treat
	    #the input file as a stub only (not as an actual input file
	    @$input_files = ();
	    $num_input_files = 0;

	    #If the stub contains a directory path AND outdirs were supplied
	    if($outfile_stub =~ m%/% &&
	       defined($outdir_array) &&
	       #Assume the outdir is good if
	       ((ref($outdir_array) eq 'ARRAY' && scalar(@$outdir_array)) ||
		ref(\$outdir_array) eq 'SCALAR'))
	      {
		error("You cannot use an output directory [",
		      (ref(\$outdir_array) eq 'SCALAR' ? $outdir_array :
		       join(' ',map {getOutdirFlag() . ' ' .
				       (ref($_) eq 'ARRAY' ?
					join(',',@$_) : $_)}
			    @$outdir_array)),"] and embed a ",
		      "directory path in the file stub [$outfile_stub] at the ",
		      "same time.  Please use one or the other.",
		      {DETAIL =>
		       join('',
			    ('Any input file option (e.g. -i) can be treated ',
			     'as a stub for creating output file names when ',
			     'there is input on standard in and only one ',
			     'value is supplied to the input file option, ',
			     'but it cannot contain a directory path when an ',
			     'output directory is supplied.'))});
		quit(-42);
	      }
	  }
	#If standard input has been redirected in (which is true because we're
	#here) and an outfule_suffix has been defined for the type of files
	#that the dash is in or will be in, inform the user about the name of
	#the outfile using the default stub for STDIN
	elsif(defined($outfile_suffixes) &&
	      scalar(@$outfile_suffixes) > $type_index_of_dash &&
	      defined($outfile_suffixes->[$type_index_of_dash]))
	  {verbose("Input on STDIN will be referred to as [$outfile_stub].")}

	debug({LEVEL => -99},"Outfile stub: $outfile_stub.");

	#Unless the dash was supplied explicitly by the user, push it on
	unless($dash_was_explicit)
	  {
	    debug({LEVEL => -99},"Pushing on the dash file to the other ",
		  "$num_input_files files.");
	    debug({LEVEL => -99},
		  "input_files is ",(defined($input_files) ? '' : 'un'),
		  "defined, is of type [",ref($input_files),
		  "], and contains [",
		  (defined($input_files) ?
		   scalar(@$input_files) : 'undefined'),"] items.");

	    debug({LEVEL => -99},
		  ($input_files eq $file_types_array->[$primary] ?
		   'input_files still references the primary element in the ' .
		   'file types array' : 'input_files has gotten overwritten'));

	    #Create a new 1st input file set with it as the only file member
	    unshift(@$input_files,['-']);

	    debug({LEVEL => -99},
		  ($input_files eq $file_types_array->[$primary] ?
		   'input_files still references the primary element in the ' .
		   'file types array' : 'input_files has gotten overwritten'));
	  }
      }

    debug({LEVEL => -99},
	  "Contents of file types array after adding dash file: [(",
	  join(')(',map {my $t=$_;'{' .
			   join('}{',map {my $e=$_;'[' . join('][',@$e) . ']'}
				@$t) . '}'} @$file_types_array),")].");

    ##
    ## Error-check/fix the file_types_array with the outfile_suffixes array
    ##
    if(scalar(@$file_types_array) < scalar(@$outfile_suffixes))
      {
	error("More outfile suffixes (",scalar(@$outfile_suffixes),"): [",
	      join(',',map {defined($_) ? $_ : 'undef'} @$outfile_suffixes),
	      "] than file types [",scalar(@$file_types_array),"].");
	quit(-43);
      }
    #Elsif the sizes are different, top off the outfile suffixes with undefs
    elsif(scalar(@$file_types_array) > scalar(@$outfile_suffixes))
      {while(scalar(@$file_types_array) > scalar(@$outfile_suffixes))
	 {push(@$outfile_suffixes,undef)}}

    ##
    ## Error-check/fix loc_collid_mode array with the outfile_suffixes array
    ##
    #Make sure that the loc_collid_mode 2D array has the same dimensions as
    #the outfile_suffixes array - assuming any missing values that are defined
    #in the suffixes array default to 'error'.
    #If a subarray is missing and the original first subarray was size 1,
    #default to its value, otherwise default to undef.  E.g. a suffix array
    #such as [[a,b,c][d,e][undef]] and loc_collid_mode of [[error]] will
    #generate a new loc_collid_mode array of:
    #[[error,error,error][error,error][undef]].
    if(scalar(@$loc_collid_mode) > scalar(@$outfile_suffixes))
      {
	error("Collision mode array is out of bounds.  Must have as ",
	      "many or fewer members as the outfile suffixes array.");
	quit(-44);
      }
    my $global_conf_mode = (scalar(@$loc_collid_mode) == 1 &&
			    scalar(@{$loc_collid_mode->[0]}) == 1) ?
			      $loc_collid_mode->[0] : getCollisionMode();
    #Create sub-arrays as needed, but don't make them inadvertently bigger
    while(scalar(@$loc_collid_mode) < scalar(@$outfile_suffixes))
      {
	#Determine what the next index will be
	my $suff_array_index = scalar(@$loc_collid_mode);
	push(@$loc_collid_mode,
	     (defined($outfile_suffixes->[$suff_array_index]) ?
	      (scalar(@{$outfile_suffixes->[$suff_array_index]}) ?
	       [$global_conf_mode] : []) : undef));
      }
    foreach my $suff_array_index (0..$#{$outfile_suffixes})
      {
	next unless(defined($outfile_suffixes->[$suff_array_index]));
	#Make sure it's not bigger than the suffixes subarray
	if(scalar(@{$loc_collid_mode->[$suff_array_index]}) >
	   scalar(@{$outfile_suffixes->[$suff_array_index]}))
	  {
	    error("Collision mode sub-array at index [$suff_array_index] is ",
		  "out of bounds.  Must have as many or fewer members as the ",
		  "outfile suffixes array.");
	    quit(-45);
	  }
	while(scalar(@{$loc_collid_mode->[$suff_array_index]}) <
	      scalar(@{$outfile_suffixes->[$suff_array_index]}))
	  {
	    push(@{$loc_collid_mode->[$suff_array_index]},
		 (scalar(@{$loc_collid_mode->[$suff_array_index]}) ?
		  $loc_collid_mode->[0] : $global_conf_mode));
	  }
      }

    ##
    ## Special case (probably unnecessary now with upgrades in 6/2014)
    ##
    my $one_type_mode = 0;
    #If there's only 1 input file type and (no outdirs or 1 outdir), merge all
    #the sub-arrays
    if(scalar(@$file_types_array) == 1 &&
       (!$outdirs_provided || (scalar(@$outdir_array) == 1 &&
			       scalar(@{$outdir_array->[0]}) == 1)))
      {
	$one_type_mode = 1;
	debug({LEVEL => -99},"Only 1 type of file was submitted, so the ",
	      "array is being preemptively flattened.");

	my @merged_array = ();
	foreach my $row_array (@{$file_types_array->[0]})
	  {push(@merged_array,@$row_array)}
	$file_types_array->[0] = [[@merged_array]];
      }

    debug({LEVEL => -99},
	  "Contents of file types array after merging sub-arrays: [(",
	  join(')(',map {my $t=$_;'{' .
			   join('}{',map {my $e=$_;'[' . join('][',@$e) . ']'}
				@$t) . '}'} @$file_types_array),")].");

    debug({LEVEL => -99},
	  "OUTDIR ARRAY DEFINED?: [",defined($outdir_array),"] SIZE: [",
	  (defined($outdir_array) ? scalar(@$outdir_array) : '0'),"].");

    ##
    ## Prepare to treat outdirs the same as infiles
    ##
    #If output directories were supplied, push them onto the file_types_array
    #so that they will be error-checked and modified in the same way below.
    if($outdirs_provided)
      {push(@$file_types_array,$outdir_array)}

    debug({LEVEL => -99},
	  "Contents of file types array after adding outdirs: [(",
	  join(')(',map {my $t=$_;'{' .
			   join('}{',map {my $e=$_;'[' . join('][',@$e) . ']'}
				@$t) . '}'} @$file_types_array),")].");

    ##
    ## Prepare to error-check file/dir array dimensions
    ##
    my $twods_exist = scalar(grep {my @x = @$_;
			      scalar(@x) > 1 &&
				scalar(grep {scalar(@$_) > 1} @x)}
			     @$file_types_array);
    debug({LEVEL => -99},"2D? = $twods_exist");

    #Determine the maximum dimensions of any 2D file arrays
    my $max_num_rows = (#Sort on descending size so we can grab the largest one
			sort {$b <=> $a}
			#Convert the sub-arrays to their sizes
			map {scalar(@$_)}
			#Grep for arrays larger than 1 with subarrays larger
			#than 1
			grep {my @x = @$_;
			      !$twods_exist ||
				(scalar(@x) > 1 &&
				 scalar(grep {scalar(@$_) > 1} @x))}
			@$file_types_array)[0];

    $max_num_rows = 0 unless(defined($max_num_rows));

    my $max_num_cols = (#Sort on descending size so we can grab the largest one
			sort {$b <=> $a}
			#Convert the sub-arrays to their sizes
			map {my @x = @$_;(sort {$b <=> $a}
					  map {scalar(@$_)} @x)[0]}
			#Grep for arrays larger than 1 with subarrays larger
			#than 1
			grep {my @x = @$_;
			      !$twods_exist ||
				(scalar(@x) > 1 &&
				 scalar(grep {scalar(@$_) > 1} @x))}
			@$file_types_array)[0];

    $max_num_cols = 0 unless(defined($max_num_cols));

    debug({LEVEL => -99},
	  "Max number of rows and columns in 2D arrays: [$max_num_rows,",
	  "$max_num_cols].");

    debug({LEVEL => -99},"Size of file types array: [",
	  scalar(@$file_types_array),"].");

    debug({LEVEL => -99},
	  "Contents of file types array before check/transpose: [(",
	  join(')(',map {my $t=$_;'{' .
			   join('}{',map {my $e=$_;'[' . join('][',@$e) . ']'}
				@$t) . '}'} @$file_types_array),")].");

    ##
    ## Error-check/transpose file/dir array dimensions
    ##
    #Error check to make sure that all file type arrays are either the two
    #dimensions determined above or a 1D array equal in size to either of the
    #dimensions
    my $row_inconsistencies = 0;
    my $col_inconsistencies = 0;
    my $twod_col_inconsistencies = 0;
    my @dimensionalities    = (); #Keep track for checking outfile stubs later
    foreach my $file_type_array (@$file_types_array)
      {
	my @subarrays = @$file_type_array;

	#If it's a 2D array (as opposed to just 1 col or row), look for
	#inconsistencies in the dimensions of the array
	if(scalar(scalar(@subarrays) > 1 &&
		  scalar(grep {scalar(@$_) > 1} @subarrays)))
	  {
	    push(@dimensionalities,2);

	    #If the dimensions are not the same as the max
	    if(scalar(@subarrays) != $max_num_rows)
	      {
		debug({LEVEL => -99},"Row inconsistencies in 2D arrays found");
		$row_inconsistencies++;
	      }
	    elsif(scalar(grep {scalar(@$_) != $max_num_cols} @subarrays))
	      {
		debug({LEVEL => -99},"Col inconsistencies in 2D arrays found");
		$col_inconsistencies++;
		$twod_col_inconsistencies++;
	      }
	  }
	else #It's a 1D array (i.e. just 1 col or row)
	  {
	    push(@dimensionalities,1);

	    #If there's only 1 row
	    if(scalar(@subarrays) == 1)
	      {
		debug({LEVEL => -99},"There's only 1 row of size ",
		      scalar(@{$subarrays[0]}),". Max cols: [$max_num_cols]. ",
		      "Max rows: [$max_num_rows]");
		if(#$twods_exist &&
		   !$one_type_mode &&
		   scalar(@{$subarrays[0]}) != $max_num_rows &&
		   scalar(@{$subarrays[0]}) != $max_num_cols &&
		   scalar(@{$subarrays[0]}) > 1)
		  {
		    debug({LEVEL => -99},
			  "Col inconsistencies in 1D arrays found (size: ",
			  scalar(@{$subarrays[0]}),")");
		    $col_inconsistencies++;
		  }
		#If the 1D array needs to be transposed because it's a 1 row
		#array and its size matches the number of rows, transpose it
		elsif(#$twods_exist &&
		      !$one_type_mode &&
		      $max_num_rows != $max_num_cols &&
		      scalar(@{$subarrays[0]}) == $max_num_rows)
		  {@$file_type_array = transpose(\@subarrays)}
	      }
	    #Else if there's only 1 col
	    elsif(scalar(@subarrays) == scalar(grep {scalar(@$_) == 1}
					       @subarrays))
	      {
		debug({LEVEL => -99},
		      "There's only 1 col of size ",scalar(@subarrays),
		      "\nThe max number of columns is $max_num_cols");
		if(#$twods_exist &&
		   !$one_type_mode &&
		   scalar(@subarrays) != $max_num_rows &&
		   scalar(@subarrays) != $max_num_cols &&
		   scalar(@subarrays) > 1)
		  {
		    debug({LEVEL => -99},"Row inconsistencies in 1D arrays ",
			  "found (size: ",scalar(@subarrays),")");
		    $row_inconsistencies++;
		  }
		#If the 1D array needs to be transposed because it's a 1 col
		#array and its size matches the number of cols, transpose it
		elsif(#$twods_exist &&
		      !$one_type_mode &&
		      $max_num_rows != $max_num_cols &&
		      scalar(@subarrays) == $max_num_cols)
		  {@$file_type_array = transpose(\@subarrays)}
	      }
	    else #There must be 0 cols
	      {
		debug({LEVEL => -99},"Col inconsistencies in 0D arrays found");
		$col_inconsistencies++;
	      }

	    debug({LEVEL => -99},"This should be array references: [",
		  join(',',@$file_type_array),"].");
	  }
      }

    debug({LEVEL => -99},
	  "Contents of file types array after check/transpose: [(",
	  join(')(',map {my $t=$_;'{' .
			   join('}{',map {my $e=$_;'[' . join('][',@$e) . ']'}
				@$t) . '}'} @$file_types_array),")].");

    #Note that if the user has supplied multiple input files that create an
    #output file of the same name, there are a few possible outcomes.  If the
    #collide mode is merge, it is assumed that the user intends the output
    #to be concatenated in a single file.  If in rename mode, the script
    #compounds the the input file names and re-check for uniqueness.  If in
    #error mode, the script will quit with an error about conflicting outfile
    #names.

    ##
    ## Create sets/combos (handling the default stub and prepending outdirs)
    ##
    my($infile_sets_array,$outfiles_sets_array,$stub_sets_array);
    my $source_hash = {};
    if(defined($outdir_array) && scalar(@$outdir_array) &&
       scalar(grep {scalar(@$_)} @$outdir_array))
      {
	debug({LEVEL => -99},"outdir array has [",scalar(@$outdir_array),
	      "] members.");

	my $tmp_infile_sets_array = getMatchedSets($file_types_array);

	foreach my $infile_set (@$tmp_infile_sets_array)
	  {
	    debug({LEVEL => -99},"Infile set with dirname: [",
		  join(',',map {defined($_) ? $_ : 'undef'} @$infile_set),
		  "].");

	    my $stub_set = [];
	    my $dirname = defined($infile_set->[-1]) ? $infile_set->[-1] : '';
	    #For every file (except the last one (which is an output directory)
	    foreach my $fileidx (0..($#{$infile_set} - 1))
	      {
		my $file = $infile_set->[$fileidx];
		my $stub = $file;
		if(defined($stub))
		  {
		    #Use the default outfile stub if this is a redirect
		    $stub = $outfile_stub if($stub eq '-');

		    #Eliminate any path strings from the file name
		    $stub =~ s/.*\///;

		    #Prepend the outdir path
		    my $new_outfile_stub = $dirname .
		      ($dirname =~ /\/$/ ? '' : '/') . $stub;

		    debug({LEVEL => -99},
			  "Prepending directory $new_outfile_stub using [",
			  "$file].");

		    push(@$stub_set,$new_outfile_stub);

		    $source_hash->{$new_outfile_stub}->{$file}++;
		  }
		else
		  {push(@$stub_set,$stub)}
	      }
	    push(@$infile_sets_array,
		 [@{$infile_set}[0..($#{$infile_set} - 1)]]);
	    push(@$stub_sets_array,$stub_set);
	  }
      }
    else
      {
	$infile_sets_array = getMatchedSets($file_types_array);
	$stub_sets_array   = copyArray($infile_sets_array);

	#Replace any dashes with the outfile stub
	foreach my $stub_set (@$stub_sets_array)
	  {
	    foreach my $stub (@$stub_set)
	      {
		$stub = $outfile_stub if(defined($stub) && $stub eq '-');

		$source_hash->{$outfile_stub}->{$outfile_stub}++;
	      }
	  }
      }

    #debug({LEVEL => -1},"Stubs before making them unique: ",
    #	  Dumper($stub_sets_array));

    #makeCheckOutputs returns an outfiles_sets_array and stub_sets_array that
    #have been confirmed to not overwrite each other or existing files.  It
    #quits the script if it finds a conflict.  It uses the output conf mode
    #variable to know when to compound file names to avoid potential
    #overwrites, but either compounds or quits with an error based on the mode
    #(merge, rename, or error).
    my($skip_sets);
    ($outfiles_sets_array,
     $stub_sets_array,
     $skip_sets) = makeCheckOutputs($stub_sets_array,
				    $outfile_suffixes,
				    $loc_collid_mode,
				    $source_hash);

    if($skip_existing && scalar(grep {$_} @$skip_sets))
      {
	@$infile_sets_array = (map {$infile_sets_array->[$_]}
			       grep {!$skip_sets->[$_]}
			       (0..$#{$infile_sets_array}));
	@$outfiles_sets_array = (map {$outfiles_sets_array->[$_]}
				 grep {!$skip_sets->[$_]}
				 (0..$#{$outfiles_sets_array}));
	@$stub_sets_array = (map {$stub_sets_array->[$_]}
			     grep {!$skip_sets->[$_]}
			     (0..$#{$stub_sets_array}));
      }

    #debug({LEVEL => -1},"Stubs after making them unique: ",
    #	  Dumper($stub_sets_array));
    #debug({LEVEL => -1},"Outfiles from the stubs: ",
    #	  Dumper($outfiles_sets_array));

    debug({LEVEL => -1},"Processing input file sets: [(",
	  join('),(',(map {my $a = $_;join(',',map {defined($_) ? $_ : 'undef'}
					   @$a)} @$infile_sets_array)),
	  ")] and output files: [(",
	  join('),(',
               (map {my $a = $_;
                     join(',',map {my $b = $_;defined($b) ?
				     scalar(@$b) == 0 ? '[EMPTY]' :
				       '[' .
					 join('],[',map {defined($_) ?
							   ($_ eq '' ?
							    'EMPTY-STRING' :
							    $_) :
							      'undef'} @$b) .
								']' : 'undef'}
		@$a)} @$outfiles_sets_array)),")].");

    recordOutfileModes($outfiles_sets_array,$loc_collid_mode);

    return($infile_sets_array,$outfiles_sets_array,$stub_sets_array);
  }

#Globals used: collid_modes_array
sub recordOutfileModes
  {
    my $outfiles_sets_array = (defined($_[0]) ? $_[0] : $output_file_sets);
    my $modes_array = (defined($_[1]) ? $_[1] : $collid_modes_array);

    foreach my $set (@$outfiles_sets_array)
      {
	next if(scalar(@$set) == 0);
	foreach my $type_index (grep {defined($set->[$_])} (0..$#{$set}))
	  {
	    next if(scalar(@{$set->[$type_index]}) == 0);
	    foreach my $suff_index (grep {defined($set->[$type_index]->[$_])}
				    (0..$#{$set->[$type_index]}))
	      {
		my $outfile = $set->[$type_index]->[$suff_index];
		$outfile_mode_lookup->{$outfile} =
		  (defined($modes_array) &&
		   defined($modes_array->[$type_index]) &&
		   defined($modes_array->[$type_index]->[$suff_index]) ?
		   $modes_array->[$type_index]->[$suff_index] :
		   getCollisionMode());
	      }
	  }
      }
  }

#Globals used: $user_collide_mode
sub getCollisionMode
  {
    my $outfile       = $_[0];
    my $outfile_type  = $_[1]; #'outfile' or 'suffix', i.e. called from
                               #addOutfile[Suffix]Option
    my $supplied_mode = $_[2];

    if(defined($supplied_mode) && ref($supplied_mode) ne '')
      {error("getCollisionMode - Third option must be a scalar.")}

    #Return the default collision mode is no file name supplied
    if(!defined($outfile))
      {
	if($command_line_processed)
	  {
	    #If the user set the collision mode using --collision-mode
	    if(defined($user_collide_mode))
	      {return($user_collide_mode)}
	    #Else if the mode was defined in the call
	    elsif(defined($supplied_mode))
	      {return($supplied_mode)}
	    #Else if the programmer defined a global mode
	    elsif(defined($def_collide_mode) && $def_collide_mode ne '')
	      {return($def_collide_mode)}
	    #Else if this is being called for a default from an
	    #addOutfile[Suffix]Option method
	    elsif(defined($outfile_type))
	      {
		if($outfile_type eq 'suffix')
		  {return($def_collide_mode_suff)}
		elsif($outfile_type eq 'outfile')
		  {return($def_collide_mode_outf)}
		else
		  {
		    error("Invalid output file type: [$outfile_type].  ",
			  "Returning collision mode: [error]");
		    return('error');
		  }
	      }
	    #Else it's assumed this is a tracked output file type being 'set
	    #later' - return the outfile collide mode default (legacy: error)
	    else
	      {return($def_collide_mode_suff)}
	  }
	else
	  {
	    #If the mode was defined in the call
	    if(defined($supplied_mode))
	      {return($supplied_mode)}
	    #Else if the programmer set the collision mode using setDefaults
	    elsif(defined($def_collide_mode) && $def_collide_mode ne '')
	      {return($def_collide_mode)}
	    #Else if this is a tracked outfile type (implied by a defined type)
	    elsif(defined($outfile_type))
	      {
		#Return undef, meaning determine later via command line setting
		if($outfile_type eq 'suffix' || $outfile_type eq 'outfile')
		  {return(undef)}
		else
		  {
		    error("Invalid output file type: [$outfile_type].  ",
			  "Returning collision mode: [error]");
		    return('error');
		  }
	      }
	    #Else it's assumed this is an untracked output file type - return
	    #the outfile collision mode default (legacy: merge)
	    else
	      {return($def_collide_mode_outf)}
	  }
      }
    else
      {
	#Treat standard out and /dev/null specially
	if($outfile eq '-' || $outfile eq '/dev/null')
	  {return('merge')}
	#Else if the user (or programmer) has set the collide mode explicitly
	##TODO: This will change with requirement 114.  Also see comments in
	##      requirement 219
	elsif(defined($user_collide_mode))
	  {return($user_collide_mode)}
	#Else if the command line has been processed
	elsif($command_line_processed)
	  {
	    #If this is a tracked file
	    if(exists($outfile_mode_lookup->{$outfile}) &&
		  defined($outfile_mode_lookup->{$outfile}))
	      {return($outfile_mode_lookup->{$outfile})}
	    elsif(defined($outfile_type))
	      {
		if($outfile_type eq 'suffix')
		  {return($def_collide_mode_suff)}
		elsif($outfile_type eq 'outfile')
		  {return($def_collide_mode_outf)}
		else
		  {
		    error("Invalid output file type: [$outfile_type].  ",
			  "Returning collision mode: [error]");
		    return('error');
		  }
	      }
	    else
	      {return($def_collide_mode_outf)}
	  }
	#Else the command line has not been processed
	else
	  {
	    #It is assumed to be an untracked file
	    return($def_collide_mode_outf);
	  }
      }
  }

#This method transposes a 2D array (i.e. it swaps rows with columns).
#Assumes argument is a 2D array.  If the number of columns is not the same from
#row to row, it fills in missing elements with an empty string.
sub transpose
  {
    my $twod_array    = $_[0];
    debug({LEVEL => -99},"Transposing: [(",
	  join('),(',map {join(',',@$_)} @$twod_array),")].");
    my $transposition = [];
    my $last_row = scalar(@$twod_array) - 1;
    my $last_col = (sort {$b <=> $a} map {scalar(@$_)} @$twod_array)[0] - 1;
    debug({LEVEL => -99},"Last row: $last_row, Last col: $last_col.");
    foreach my $col (0..$last_col)
      {push(@$transposition,
	    [map {$#{$twod_array->[$_]} >= $col ?
		    $twod_array->[$_]->[$col] : ''}
	     (0..$last_row)])}
    debug({LEVEL => -99},"Transposed: [(",
	  join('),(',map {join(',',@$_)} @$transposition),")].");
    return(wantarray ? @$transposition : $transposition);
  }

#This method takes an array of file names and an outfile suffix and returns
#any file names that already exist in the file system
sub getExistingOutfiles
  {
    my $outfile_stubs_for_input_files = $_[0];
    my $outfile_suffix                = scalar(@_) >= 2 ? $_[1] : ''; #OPTIONAL
                                        #undef means there won't be outfiles
                                        #Empty string means that the files in
                                        #$_[0] are already outfile names
    my $existing_outfiles             = [];

    #Check to make sure previously generated output files won't be over-written
    #Note, this does not account for output redirected on the command line.
    #Also, outfile stubs are checked for future overwrite conflicts in
    #getFileSets (i.e. separate files slated for output with the same name)

    #For each output file *stub*, see if the expected outfile exists
    foreach my $outfile_stub (grep {defined($_)}
			      @$outfile_stubs_for_input_files)
      {if(-e "$outfile_stub$outfile_suffix")
	 {push(@$existing_outfiles,"$outfile_stub$outfile_suffix")}}

    return(wantarray ? @$existing_outfiles : $existing_outfiles);
  }

#This method takes a 1D or 2D array of output directories and creates them
#(Only works on the last directory in a path.)  Returns non-zero if successful
#Globals used: $overwrite, $dry_run, $use_as_default
sub mkdirs
  {
    my @dirs            = @_;
    my $status          = 1;
    my @unwritable      = ();
    my @errored         = ();
    my @undeleted       = ();
    my $local_overwrite = defined($overwrite) ? $overwrite : 0;
    my $local_dry_run   = defined($dry_run)   ? $dry_run   : 0;
    my $seen            = {};

    #If --save-args was supplied, do not create any directories unless it is
    #just the defaults directory, because otherwise the script is only going to
    #save the command line options & quit
    return($status) if(defined($use_as_default) && $use_as_default &&
		       (scalar(@dirs) != 1 || $dirs[0] ne $defaults_dir));

    #Create the output directories
    if(scalar(@dirs))
      {
	foreach my $dir_set (@dirs)
	  {
	    my @dirlist = (ref($dir_set) eq 'ARRAY' ? @$dir_set : $dir_set);

	    foreach my $dir (@dirlist)
	      {
		if(!defined($dir))
		  {
		    error("Undefined directory sent to mkdirs.");
		    next;
		  }

		next if(exists($seen->{$dir}));

		#If the directory exists and we're not going to overwrite it,
		#check it to see if we'll have a problem writing files to it
		#Note: overwrite has to be 2 or more to delete a directory
		if(-e $dir && $local_overwrite < 2)
		  {
		    #If the directory is not writable
		    if(!(-w $dir))
		      {push(@unwritable,$dir)}
		    #Else if we are in overwrite mode
		    elsif($local_overwrite && isDebug())
		      {warning('The --overwrite flag will not empty or ',
			       'delete existing output directories.  If ',
			       'you wish to delete existing output ',
			       'directories, you must do it manually.')}
		  }
		#Else if this isn't a dry run
		elsif(!$local_dry_run)
		  {
		    if($overwrite > 1 && -e $dir)
		      {
			#We're only going to delete files if they have headers
			#indicating that they were created by a previous run of
			#this script

			deletePrevRunDir($dir);
		      }

		    #We didn't delete manually created files above, so the
		    #directory may still exist and not need recreated
		    if(-e $dir)
		      {push(@undeleted,$dir)}
		    else
		      {
			my $tmp_status = mkdir($dir);
			if(!$tmp_status)
			  {
			    $status = 0;
			    push(@errored,"[$dir]: $!");
			  }
		      }
		  }
		#Else, check to see if creation is feasible in dry-run mode
		else
		  {
		    my $encompassing_dir = $dir;
		    $encompassing_dir =~ s%/$%%;
		    $encompassing_dir =~ s/[^\/]+$//;
		    $encompassing_dir = '.'
		      unless($encompassing_dir =~ /./);

		    if(!(-w $encompassing_dir))
		      {error("Unable to create directory: [$dir].  ",
			     "Encompassing directory is not writable.")}
		    else
		      {verbose("[$dir] Directory created.")}
		  }

		$seen->{$dir} = 1;
	      }
	  }

	if(scalar(@unwritable))
	  {error("These output directories do not have write permission: [",
		 join(',',@unwritable),
		 "].  Please change the permissions to proceed.")}

	if(scalar(@errored))
	  {error("These output directories could not be created: [",
		 join(',',@errored),"].")}

	if(scalar(@undeleted))
	  {error("These pre-existing output directories could not be deleted ",
		 "because they contain unverified safe-to-delete files (see ",
		 "--help or --overwrite in the usage): [",join(',',@undeleted),
		 "].")}

	quit(-46)
	  if(scalar(@errored) || scalar(@errored) || scalar(@undeleted));
      }

    return($status);
  }

#This method will crawl through a directory and unlink any files that have
#headers indicating they were created by this script, and the directory itself
#if nothing is left
#Globals used: $overwrite
sub deletePrevRunDir
  {
    my $dir    = $_[0];
    my $status = 1;      #SUCCESS = 1, FAILURE = 0

    if($overwrite < 2)
      {
	$status = 0;
	warning("Removing an existing output directory such as [$dir] ",
		"requires --overwrite to be supplied more then once.");
	return($status);
      }

    my($dh);
    unless(opendir($dh, $dir))
      {
	error("Unable to open directory: [$dir]");
	$status = 0;
	return($status);
      }

    my $total = 0;
    my $deleted = 0;
    while(my $f = readdir($dh))
      {
	next if($f eq '.' || $f eq '..');

	$total++;

	if(-d $f)
	  {$deleted += deletePrevRunDir("$dir/$f")}
	else
	  {
	    my $imadethis = iMadeThisBefore("$dir/$f");
	    if($imadethis && !unlink("$dir/$f"))
	      {
		error("Unable to delete file [$dir/$f] from previous run.  ",
		      $!);
		$status = 0;
	      }
	    elsif($imadethis)
	      {$deleted++}
	  }
      }

    closedir($dh);

    #If everything in the directory was successfully deleted, but we could not
    #delete this directory
    if($total == $deleted && !rmdir($dir))
      {$status = 0}

    return($status)
  }

sub iMadeThisBefore
  {
    my $file            = $_[0];
    my $imadethisbefore = 0;

    #Determine if the file was created while or after this script started
    my $lmdsecs = (stat($file))[9];
    if($lmdsecs > $^T)
      {
	$imadethisbefore = 0;
	return($imadethisbefore);
      }

    #Guess whether the header in this file indicates that this script created
    #the file.  (Depends on whether the run included the header)
    unless(openIn(*DEL,$file,1))
      {
	error("Unable to determine if file [$file] was from a previous run.");
	return($imadethisbefore);
      }

    my $script     = $0;
    $script        =~ s/^.*\/([^\/]+)$/$1/;
    my $script_pat = quotemeta($script);
    my $match_name = 0;
    my $match_pid  = 0;
    my $pid        = '';

    while(getLine(*DEL))
      {
	last unless(/^\s*#/);

	if(/$script_pat/)
	  {$match_name = 1}
	if(/^#PID: (\d+)/)
	  {
	    $pid = $1;
	    $match_pid = 1;
	  }
	last if($match_name && $match_pid);
      }

    $imadethisbefore = ($match_name && $match_pid && $pid ne $$);

    closeIn(*DEL);

    return($imadethisbefore);
  }

#This method checks for existing output files
#Globals used: $overwrite, $skip_existing
sub checkFile
  {
    my $output_file         = defined($_[0]) ? $_[0] : return(1);
    my $input_file_set      = $_[1]; #Optional: Used for verbose/error messages
    my $local_quiet         = scalar(@_) > 2 && defined($_[2]) ? $_[2] : 0;
    my $quit                = scalar(@_) > 3 && defined($_[3]) ? $_[3] : 1;
    my $status              = 1;
    my $local_overwrite     = defined($overwrite) ? $overwrite : 0;
    my $local_skip_existing = defined($skip_existing) ? $skip_existing : 0;

    if(-e $output_file && $output_file ne '/dev/null')
      {
	debug({LEVEL => -2},"Output file: [$output_file] exists.");

	if($local_skip_existing)
	  {
	    verbose("[$output_file] Output file exists.  Skipping",
		    (defined($input_file_set) ?
                     (" input file(s): [",join(',',@$input_file_set),"]") :
                     ''),".") unless($local_quiet);
	    $status = 0;
	  }
	elsif(!$local_overwrite)
	  {
	    error("[$output_file] Output file exists.  Unable to ",
		  "proceed.  ",
                  (defined($input_file_set) ?
                   ("Encountered while processing input file(s): [",
		    join(',',grep {defined($_)} @$input_file_set),
		    "].  ") : ''),
                  "This may have been caused by multiple input files ",
		  "writing to one output file because there were not ",
		  "existing output files when this script started.  If any ",
		  "input files are writing to the same output file, you ",
		  "should have seen a warning about this above.  Otherwise, ",
		  "you may have multiple versions of this script running ",
		  "simultaneously.  Please check your input files and ",
		  "outfile suffixes to fix any conflicts or supply one of ",
		  "the --skip, --overwrite, or --append flags.")
	      unless($local_quiet);

	    #An exit code of -1 will quit even if --force is supplied.  --force
	    #is intended to over-ride programmatic errors.  --overwrite is
	    #intended to over-ride existing files.
	    quit(-1) if($quit);

	    $status = 0;
	  }
      }
    else
      {debug({LEVEL => -2},"Output file: [$output_file] does not exist yet.")}

    return($status);
  }

#Uses globals: $dry_run, $force
sub openOut
  {
    unless($processCommandLine_called)
      {processCommandLine()}

    my @in = getSubParams([qw(HANDLE FILE SELECT QUIET HEADER APPEND MERGE)],
			  [qw(HANDLE FILE)],
			  [@_]);
    my $file_handle     = $in[0];
    my $output_file     = $in[1];
    my $local_select    = (scalar(@in) >= 3 ? $in[2] : undef);
    my $local_quiet     = (scalar(@in) >= 4 && defined($in[3]) ? $in[3] : 0);
    my $local_header    = (scalar(@in) >= 5 && defined($in[4]) ? $in[4] :
			   $header);
    my $explicit_append = $in[5];  #May be undefined
    my $merge_mode      = (scalar(@in) >= 7 && defined($in[6]) ? $in[6] :
			   getCollisionMode($output_file) =~ /^m/i ? 1 : 0);
                          #0 = never append
                          #1 = append after initial open, based on collide_mode
    my $local_dry_run   = defined($dry_run) ? $dry_run : 0;
    my $status          = 1;
    my($select);

    debug({LEVEL => -1},"Collision mode: [",getCollisionMode($output_file),
	  "] for file: [",(defined($output_file) ? $output_file : 'undef'),
	  "] Resulting merge mode: [$merge_mode].");

    if(!defined($output_file))
      {
	#Quietly open /dev/null if not defined so that the programmer doesn't
	#have to check if the user supplied an optional non-primary file type
	$output_file = '/dev/null';
	$status      = 0;
	$local_quiet = 1;
      }

    debug({LEVEL=>-1},"openOut collision mode: [",
	  getCollisionMode($output_file),"] Global append mode: [$append] ",
	  "Append mode: [",
	  (defined($explicit_append) ? $explicit_append : 'undef'),
	  "] Merge mode: [$merge_mode] Original: [",
	  (defined($explicit_append) ? $explicit_append : 'undef'),"].");

    if($output_file ne '-')
      {
	#Silently remove a single leading '>' character
	if($output_file =~ /^\s*>[^>]/)
	  {$output_file =~ s/^\s*>//}
	elsif($output_file =~ /^\s*(\||\+|<|>)/)
	  {
	    if($output_file =~ /^\s*>/)
	      {
		warning("An attempt to enter append mode using '>>' in the ",
			"file name argument was detected in [$output_file].  ",
			"Switching to append mode.  Please edit the code to ",
			"use the append parameter to this method.")
		  unless(defined($explicit_append) && $explicit_append);
		$explicit_append = 1;
	      }
	    else
	      {
		my $errfound = $1;
		error("openOut only supports write mode and expects an ",
		      "output file name as the second argument.  Leading ",
		      "characters to control the output mode, such as ",
		      "[$errfound] in [$output_file] are not supported.");
		$status = 0;
		return($status);
	      }
	  }
	elsif($output_file =~ /\|\s*$/)
	  {
	    my $errfound = $1;
	    error("openOut only supports write mode and expects an output ",
		  "file name as the second argument.  Trailing characters to ",
		  "control the output, such as [$errfound] in [$output_file] ",
		  "are not supported.");
	    $status = 0;
	    return($status);
	  }
      }

    #Determine if we should select the output handle: default to user-specified
    #If not, select the handle if current default is STDOUT, else don't select
    if(defined($local_select) && $local_select != 0)
      {
	debug({LEVEL=>-1},"Explicit select.");
	#An explicit select
	$select = 2;

	my $selected_handle = '*' . select();
	#Confirm that this handle was/is selected before selecting STDOUT
	if(defined($selected_handle) && $selected_handle ne *STDOUT)
	  {
	    if(exists($open_out_handles->{$selected_handle}))
	      {
		my $selected_file =
		  $open_out_handles->{$selected_handle}->{CURFILE};
		debug("WARNING: Only 1 output handle should be selected at a ",
		      "time.  Selecting handle for output file [",
		      ($output_file ne '-' ? $output_file : 'STDOUT'),
		      "] and throwing out the select of the tracked file ",
		      "[$selected_file].");
	      }
	    else
	      {
		debug("WARNING: Only 1 output handle should be selected at a ",
		      "time.  Selecting handle for output file [",
		      ($output_file ne '-' ? $output_file : 'STDOUT'),
		      "] and ignoring the select of the untracked file ",
		      "handle [$selected_handle].");
	      }
	  }
      }
    elsif(defined($local_select) && $local_select == 0)
      {
	debug({LEVEL=>-1},"Explicit no select.");
	#Set an explicit select
	$select = 0;
      }
    #Else if STDOUT is currently selected or the output file is '-'
    #(implying an anonymous file handle is being opened & selected)
    elsif(select() eq *STDOUT || '*' . select() eq *STDOUT ||
	  $output_file eq '-')
      {
	debug({LEVEL=>-1},"Implicit select.");
	#Set an implicit select
	$select = 1;

	if($output_file eq '-')
	  {
	    my $selected_handle = '*' . select();
	    #Confirm that this handle was/is selected before selecting STDOUT
	    if(!defined($selected_handle) || $selected_handle eq *STDOUT)
	      {$select = 1}
	    elsif(exists($open_out_handles->{$selected_handle}))
	      {
		my $selected_file =
		  $open_out_handles->{$selected_handle}->{CURFILE};
		error("Cannot select an anonymous file handle because a ",
		      "handle for output file [$selected_file] is already ",
		      "selected.");
		$status = 0;
		return($status);
	      }
	    else
	      {
		error("Cannot select an anonymous file handle because an ",
		      "untracked file handle [$selected_handle] has been ",
		      "selected.");
		$status = 0;
		return($status);
	      }
	  }
      }
    #Else another handle is currently selected and select is supposed to be
    #implicit, so throw a warning and don't select
    else
      {
	debug({LEVEL=>-1},"No select.");
	my $selected_handle = '*' . select();
	my($selected_file);
	if(exists($open_out_handles->{$selected_handle}))
	  {
	    $selected_file = $open_out_handles->{$selected_handle}->{CURFILE};
	    warning("Only 1 output handle can be selected at a time.",
		    {DETAIL =>
		     join('',("Not selecting handle for output file ",
			      "[$output_file] because an open selected ",
			      "handle exists [$selected_handle] for file ",
			      "[$selected_file].  A code edit to add `SELECT ",
			      "=> 0` to the call to openOut using file ",
			      "handle [$file_handle]."))});
	  }
	else
	  {
	    debug("Rejected outfile handles: [",
		  join(',',keys(%$rejected_out_handles)),"].\n",
		  "Open outfile handles: [",
		  join(',',keys(%$open_out_handles)),"].",{LEVEL => -1});
	    warning("Only 1 output handle can be selected at a time.",
		    {DETAIL =>
		     join('',("Not selecting handle for output file ",
			      "[$output_file] because an untracked file ",
			      "handle [$selected_handle] has been ",
			      "selected.  A code edit to either not call ",
			      "`select($selected_handle)` or to add `SELECT ",
			      "=> 0` to the call to openOut using file ",
			      "handle [$file_handle]."))});
	  }
	$select = 0;
      }

    debug({LEVEL => -3},"Output file is of type [",
	  (ref($output_file) eq '' ? 'SCALAR' : ref($output_file)),'].');

    #If the output file is '-' or they explicitly sent in the STDOUT file
    #handle, assume user is outputting to STDOUT
    if($output_file eq '-' || $file_handle eq *STDOUT)
      {
	debug({LEVEL => -1},"Accepting output file handle(1): [STDOUT]",
	      ($file_handle eq *STDOUT ? '' :
	       " in leiu of [$file_handle], since no outfile provided"),".");
	debug({LEVEL=>-1},"Actually selecting STDOUT");
        select(STDOUT) if($select);

	#Reject/ignore the handle that was passed in.  STDOUT will be opened
	#instead
	if($file_handle ne *STDOUT)
	  {
	    ##TODO: See requirement #312
	    open($file_handle,'>>/dev/stdout');
	    #open(STDOUT,'>>/dev/stdout');
	    $rejected_out_handles->{$file_handle}->{CURFILE} = 'STDOUT';
	    $rejected_out_handles->{$file_handle}->{QUIET} = $local_quiet;
	    $rejected_out_handles->{$file_handle}->{FILES}->{STDOUT} = 0;
	  }

        #If this is the first time encountering the STDOUT open
        if(!defined($open_out_handles) ||
           !exists($open_out_handles->{*STDOUT}))
          {
            verbose('[STDOUT] Opened for all output.') unless($local_quiet);

            #Store info. about the run as a comment at the top of the output
            #file if STDOUT has been redirected to a file and it wasn't already
	    #output via processCommandLine.  processCommandLine does it is the
	    #global $header variable is true.  If it's false, but the local
	    #version of the header variable was explicitly supplied, then print
	    #the header here
            if(!isStandardOutputToTerminal() && ($local_header && !$header))
              {
		my $tfh = (defined($file_handle) ? $file_handle : *STDOUT);
		print $tfh (getHeader());
	      }
          }

	$file_handle = *STDOUT;

	$open_out_handles->{$file_handle}->{CURFILE} = 'STDOUT';
	$open_out_handles->{$file_handle}->{QUIET}   = $local_quiet;
	$open_out_handles->{$file_handle}->{SELECT}  = $select;
	$open_out_handles->{$file_handle}->{FILES}->{STDOUT} = 0;
      }
    #else if we're not in append mode and the output file fails the overwrite
    #protection check
    elsif(!isAppendMode($explicit_append,$merge_mode,$file_handle,
			$output_file) &&
	  !checkFile($output_file,undef,$local_quiet,0))
      {
	debug({LEVEL => -1},"Rejecting output file handle(1): ",
	      "[$file_handle].");
	$status = 0;
	$rejected_out_handles->{$file_handle}->{CURFILE} = $output_file;
	$rejected_out_handles->{$file_handle}->{QUIET}   = $local_quiet;
	$rejected_out_handles->{$file_handle}->{FILES}->{$output_file} = 0;
      }
    #Else if this isn't a dry run and opening the output file fails
    elsif(!$local_dry_run &&
	  !open($file_handle,
		(isAppendMode($explicit_append,$merge_mode,$file_handle,
			      $output_file) ?
		 '>' : '') . ">$output_file"))
      {
	debug({LEVEL => -1},"Rejecting output file handle(2): ",
	      "[$file_handle].");
	#Report an error and iterate if there was an error
	error("Unable to open output file: [$output_file].\n",$!)
          unless($local_quiet);
	$status = 0;
	$rejected_out_handles->{$file_handle}->{CURFILE} = $output_file;
	$rejected_out_handles->{$file_handle}->{QUIET}   = $local_quiet;
	$rejected_out_handles->{$file_handle}->{FILES}->{$output_file} = 0;
      }
    else
      {
	debug({LEVEL => -2},"Accepting output file handle(2): ",
	      "[$file_handle].");
	$open_out_handles->{$file_handle}->{CURFILE} = $output_file;
	$open_out_handles->{$file_handle}->{QUIET}   = $local_quiet;
	$open_out_handles->{$file_handle}->{SELECT}  = $select;
	$open_out_handles->{$file_handle}->{FILES}->{$output_file} = 0;

	if($local_dry_run)
	  {
	    my $encompassing_dir = $output_file;
	    $encompassing_dir =~ s/[^\/]+$//;
	    $encompassing_dir =~ s%/%%;
	    $encompassing_dir = '.' unless($encompassing_dir =~ /./);

	    debug({LEVEL => -1},"Pretending to open output file in --dry-run ",
		  "mode");

	    if(-e $output_file && !(-w $output_file))
	      {error("Output file exists and is not writable: ",
		     "[$output_file].") unless($local_quiet)}
	    elsif(-e $encompassing_dir && !(-w $encompassing_dir))
	      {error("Encompassing directory of output file: ",
		     "[$output_file] exists and is not writable.")
                 unless($local_quiet)}
	    else
	      {verbose("[$output_file] Opened output file.")
                 if(!$local_quiet && $status)}

	    return($status);
	  }

	verbose("[$output_file] Opened output file.")
	  if(!$local_quiet && $status);

	#Select the output file handle
	select($file_handle) if($select);

	#Store info about the run as a comment at the top of the output
	print $file_handle (getHeader()) if($local_header);
      }

    #If we succeeded and there was a selection made, clean up other selection
    #states (should only be one, but just to be safe, we'll check all possible)
    if($status && $select)
      {
	#Mark any other file handles as not selected
	map {$open_out_handles->{$_}->{SELECT} = 0}
	  grep {$_ ne $file_handle && $open_out_handles->{$_}->{SELECT}}
	    keys(%{$open_out_handles});
      }

    return($status);
  }

#Globals: $closed_out_handles, $append
sub isAppendMode
  {
    #>0 = append, 0 = no append, <0 = no append first, append subsequently
    my $explicit_append = $_[0];
    my $merge_mode      = $_[1]; #Whether collision mode is 'merge' or not
    my $file_handle     = $_[2];
    my $output_file     = $_[3];

    if(!defined($merge_mode) || !defined($file_handle) ||
       !defined($output_file))
      {
	error("Invalid parameters sent in.  4 parameters are required.  Only ",
	      "the first one (explicit_append) is allowed to be undefined.");
	quit(-49);
      }

    #Opened (& closed) before
    my $opened_before = defined($closed_out_handles) &&
      exists($closed_out_handles->{$file_handle}) &&
	exists($closed_out_handles->{$file_handle}->{$output_file});

    my $append_mode =
      #This allows the user to over-ride what the programmer may have indicated
      #However it only applies to the first open of a file.
      ($append && !$opened_before) ||
	#Subsequent opens fall back to what the programmer has indicated or...
	(defined($explicit_append) && $explicit_append) ||
	  #what the collision mode is set to (as passed in as $merge_mode)
	  ($merge_mode && $opened_before);

    debug({LEVEL=>-1},"Append mode is [",
	  (defined($append_mode) ? ($append_mode ? 'on' : 'off') : 'undef'),
	  "] for file [$output_file].  Merge mode passed in: [$merge_mode].");

    return($append_mode);
  }

#Globals used: $dry_run
sub closeOut
  {
    my @in = getSubParams([qw(HANDLE)],[qw(HANDLE)],[@_]);
    my $file_handle   = $in[0];
    my $status        = 1;
    my $local_dry_run = defined($dry_run) ? $dry_run : 0;

    debug({LEVEL => -1},"closeOut called with ",
	  (defined($file_handle) ? $file_handle : 'undef'));

    return($status) unless(defined($file_handle));

    #If we're printing to STDOUT, don't close - just issue a checkpoint message
    if($file_handle eq *STDOUT ||
       #Special case for STDOUT opened via filename '-' using a different
       #handle name
       (exists($rejected_out_handles->{$file_handle}) &&
	$rejected_out_handles->{$file_handle}->{CURFILE} eq 'STDOUT'))
      {
	    debug({LEVEL => -1},"STDOUT Checkpoint.");

	verbose("[STDOUT] Output checkpoint.  ",
		"Time taken: [",markTime(),' Seconds].')
	  if(!exists($open_out_handles->{$file_handle}) ||
	     !$open_out_handles->{$file_handle}->{QUIET} ||
	     (exists($rejected_out_handles->{$file_handle}) &&
	      $rejected_out_handles->{$file_handle}->{CURFILE} eq 'STDOUT'));
      }
    #Else if the file handle is rejected or already closed
    elsif(exists($rejected_out_handles->{$file_handle}) ||
	  (!$local_dry_run && (!defined(fileno($file_handle)) ||
			       tell($file_handle) == -1)))
      {
	$status = 0;

	#If we knew it wasn't open because it was rejected
	if(exists($rejected_out_handles->{$file_handle}))
	  {
	    debug({LEVEL => -1},"Cleaning up rejected handle: ",
		  "[$file_handle].");

	    #Assuming this is from a loop, clean up 'closed/rejected' handles
	    delete($rejected_out_handles->{$file_handle});
	  }
	#Else the file handle closed unexpectedly, so report it
	else
	  {
	    error("File handle [$file_handle] submitted to closeOut",
		  (!exists($open_out_handles->{$file_handle}) ? '' :
		   " for file [$open_out_handles->{$file_handle}->{CURFILE}]"),
		  " was not open",
		  (exists($open_out_handles->{$file_handle}) ?
		   "." : " and is untracked."));
	    debug({LEVEL => -1},"Tracked open file handles: [",
		  join(',',keys(%$open_out_handles)),"].\n",
		  "Tracked rejected file handles: [",
		  join(',',keys(%$rejected_out_handles)),"]\n");

	    if(exists($open_out_handles->{$file_handle}))
	      {
		warning("Untracking previously closed (or unopened) file ",
			"handle: ",
			"[$open_out_handles->{$file_handle}->{CURFILE}].");

		my $selected_handle = select();
		#Confirm that this handle was/is supposed to have been selected
		#before selecting STDOUT - if it actually is selected, but is
		#not tracked as such, then they're doing things manually - do
		#not interfere by selecting STDOUT.
		if($open_out_handles->{$file_handle}->{SELECT} &&
		   $selected_handle eq $file_handle && $selected_handle ne
		   *STDOUT)
		  {
		    #Select standard out
		    select(STDOUT);
		  }

		#Copy the handle info to the closed handles and then delete
		$closed_out_handles->{$file_handle}
		  ->{$open_out_handles->{$file_handle}->{CURFILE}} =
		    {%{$open_out_handles->{$file_handle}}};

		delete($open_out_handles->{$file_handle}->{FILES}
		       ->{$open_out_handles->{$file_handle}->{CURFILE}});
		delete($open_out_handles->{$file_handle}->{CURFILE});
		delete($open_out_handles->{$file_handle}->{QUIET});
		delete($open_out_handles->{$file_handle}->{SELECT});
	      }
	    else
	      {
		my $selected_handle = select();
		#Confirm that this handle is selected before selecting STDOUT
		if($selected_handle eq $file_handle &&
		   $selected_handle ne *STDOUT)
		  {
		    #Select standard out
		    select(STDOUT);
		  }
	      }
	  }
      }
    #Else close the handle
    else
      {
	if(!$local_dry_run)
	  {
	    my $selected_handle_pat = '\*?' . quotemeta(select());

	    #Confirm that this handle was/is selected before selecting STDOUT
	    if($file_handle =~ /^$selected_handle_pat$/ &&
	       $file_handle ne *STDOUT)
	      {
		#Select standard out
		select(STDOUT);
	      }

	    #Close the output file handle
	    close($file_handle);
	  }

	verbose("[$open_out_handles->{$file_handle}->{CURFILE}] Output ",
		"file done.  Time taken: [",markTime(),' Seconds].')
	  if(!exists($open_out_handles->{$file_handle}) ||
	     !$open_out_handles->{$file_handle}->{QUIET});

	#Copy the handle info to the closed handles and then delete
	$closed_out_handles->{$file_handle}
	  ->{$open_out_handles->{$file_handle}->{CURFILE}} =
	    {%{$open_out_handles->{$file_handle}}};

	delete($open_out_handles->{$file_handle}->{FILES}
	       ->{$open_out_handles->{$file_handle}->{CURFILE}});
	delete($open_out_handles->{$file_handle}->{CURFILE});
	delete($open_out_handles->{$file_handle}->{QUIET});
	delete($open_out_handles->{$file_handle}->{SELECT});
      }

    return($status);
  }

#Globals used: $force, $default_stub, $dry_run
sub openIn
  {
    unless($processCommandLine_called)
      {processCommandLine()}

    my @in = getSubParams([qw(HANDLE FILE QUIET)],
			  [qw(HANDLE FILE)],
			  [@_]);
    my $file_handle   = $in[0];
    my $input_file    = $in[1];
    my $local_quiet   = (scalar(@in) >= 3 && defined($in[2]) ? $in[2] : 0);
    my $status        = 1;     #Returns true if successful or $force > 1
    my $local_dry_run = defined($dry_run) ? $dry_run : 0;

    if(!defined($input_file))
      {
	#We will return a bad status, but quietly open /dev/null to allow the
	#programmer to not have to check the return value for non-primary
	#optional files
	$input_file = '/dev/null';
	$status = 0;
      }

    #Open the input file
    if(!open($file_handle,$input_file))
      {
	#Report an error and iterate if there was an error
	error("Unable to open input file: [$input_file].  $!") if($status);

	#If force is supplied less than twice, set status to
	#unsuccessful/false, otherwise pretend everything's OK
	$status = 0 if(!defined($force) || $force < 2);
      }
    else
      {
	verbose('[',($input_file eq '-' ?
		     (defined($default_stub) ? $default_stub : 'STDIN') :
		     $input_file),
		'] Opened input file.') if(!$local_quiet && $status);

	$open_in_handles->{$file_handle}->{CURFILE} = $input_file;
	$open_in_handles->{$file_handle}->{QUIET}   = $local_quiet || !$status;
      }

    return($status);
  }

#Given an open input file handle, returns the name and path of the file
#Returns an empty string if it was not found in the open input handles hash
sub getInHandleFileName
  {
    my @in = getSubParams([qw(HANDLE)],[qw(HANDLE)],[@_]);
    my $handle = $in[0];
    if(defined($open_in_handles) && exists($open_in_handles->{$handle}) &&
       exists($open_in_handles->{$handle}->{CURFILE}) &&
       defined($open_in_handles->{$handle}->{CURFILE}))
      {return($open_in_handles->{$handle}->{CURFILE})}
    return('');
  }

sub getOutHandleFileName
  {
    my @in = getSubParams([qw(HANDLE)],[qw(HANDLE)],[@_]);
    my $handle = $in[0];
    if(defined($open_out_handles) && exists($open_out_handles->{$handle}) &&
       exists($open_out_handles->{$handle}->{CURFILE}) &&
       defined($open_out_handles->{$handle}->{CURFILE}))
      {return($open_out_handles->{$handle}->{CURFILE})}
    return('');
  }

#Globals used: $default_stub
sub closeIn
  {
    my @in = getSubParams([qw(HANDLE)],[qw(HANDLE)],[@_]);
    my $file_handle = $in[0];

    if(!defined($file_handle))
      {
	error("File handle sent in undefined.");
	return(undef);
      }

    #Close the input file handle
    close($file_handle);

    verbose('[',($open_in_handles->{$file_handle}->{CURFILE} eq '-' ?
		 (defined($default_stub) ? $default_stub : 'STDIN') :
		 $open_in_handles->{$file_handle}->{CURFILE}),
	    '] Input file done.  Time taken: [',markTime(),
	    ' Seconds].') if(!exists($open_in_handles->{$file_handle}) ||
			     !$open_in_handles->{$file_handle}->{QUIET});

    delete($open_in_handles->{$file_handle});
  }

#Note: Creates a surrounding reference to the submitted array if called in
#scalar context and there are more than 1 elements in the parameter array
sub copyArray
  {
    if(scalar(grep {ref(\$_) ne 'SCALAR' && ref($_) ne 'ARRAY'} @_))
      {
	error("Invalid argument - not an array of scalars.");
	quit(-50);
      }
    my(@copy);
    foreach my $elem (@_)
      {push(@copy,(defined($elem) && ref($elem) eq 'ARRAY' ?
		   [copyArray(@$elem)] : $elem))}
    debug({LEVEL => -99},"Returning array copy of [",
	  join(',',map {defined($_) ? $_ : 'undef'} @copy),"].");
    return(wantarray ? @copy : (scalar(@copy) > 1 ? [@copy] : $copy[0]));
  }

#Globals used: $defaults_dir
sub getUserDefaults
  {
    my @in = getSubParams([qw(REMOVE_QUOTES)],[],[@_]);
    my $remove_quotes = defined($in[0]) ? $in[0] : 0;
    my $script        = $0;
    $script           =~ s/^.*\/([^\/]+)$/$1/;
    my $defaults_file = (defined($defaults_dir) ?
			 $defaults_dir : (sglob('~/.rpst'))[0]) . "/$script";
    my $return_array  = [];

    if(open(DFLTS,$defaults_file))
      {
	@$return_array = map {chomp;if($remove_quotes){s/^['"]//;s/["']$//}
			      join(' ',sglob($_))} <DFLTS>;
	close(DFLTS);
      }
    elsif(-e $defaults_file)
      {error("Unable to open user defaults file: [$defaults_file].  $!")}

    debug({LEVEL=>-2},"User defaults retrieved from [$defaults_file]: [",
	  join(' ',@$return_array),"].");

    return(wantarray ? @$return_array : $return_array);
  }

#Assumes that options have already been read in
#Globals used: $defaults_dir
sub saveUserDefaults
  {
    my @in = getSubParams([qw(ARGV)],[],[@_]);
    my $argv   = $in[0]; #OPTIONAL
    my $status = 1;

    return($status) if(!defined($use_as_default) || !$use_as_default);

    if($version)
      {
	error('--version cannot be saved as a user default flag.  Consider ',
	      'using --header instead, which saves the version number in a ',
	      'header added to each output file.');
	quit(-51,0);
      }

    #Determine if the combo of defaults is valid to be saved
    #Error-check for mutually exclusive flags supplied together
    my $defrunmode =
      scalar(grep {defined($_) && $_} ($explicit_help,$explicit_usage,
				       $explicit_run,$explicit_dry_run));
    if($defrunmode > 1)
      {
	my @culprits = ();
	push(@culprits,'--help')    if(defined($explicit_help) &&
				       $explicit_help);
	push(@culprits,'--usage')   if(defined($explicit_usage) &&
				       $explicit_usage);
	push(@culprits,'--run')     if(defined($explicit_run) &&
				       $explicit_run);
	push(@culprits,'--dry-run') if(defined($explicit_dry_run) &&
				       $explicit_dry_run);
	error('These options are mutually exclusive: [',join(',',@culprits),
	      '] and thus cannot be saved together as defaults.');
	quit(-52);
      }

    my $orig_defaults = getUserDefaults();

    #Grab defaults from getCommand, because it re-adds quotes & other niceties
    if(!defined($argv))
      {
	$argv = [getCommand(0,1)];
	#Remove the script name
	shift(@$argv);
      }

    my $script        = $0;
    $script           =~ s/^.*\/([^\/]+)$/$1/;
    my $defaults_file = (defined($defaults_dir) ?
			 $defaults_dir : (sglob('~/.rpst'))[0]) . "/$script";

    my $save_argv = [grep {$_ ne '--save-args'} @$argv];

    debug({LEVEL => -99},"Defaults dir: [",
	  (defined($defaults_dir) ? $defaults_dir : 'undef'),"].");

    #If the defaults directory does not exist and mkdirs returns an error
    if(defined($defaults_dir) && !(-e $defaults_dir) && !mkdirs($defaults_dir))
      {
	error("Unable to create defaults directory: [$defaults_dir].  $!");
	$status = 0;
      }
    else
      {
	if(open(DFLTS,">$defaults_file"))
	  {
	    print DFLTS (join("\n",@$save_argv));
	    close(DFLTS);
	  }
	else
	  {
	    error("Unable to write to defaults file: [$defaults_file].  $!");
	    $status = 0;
	  }
      }

    if($status)
      {
	print("Old user defaults: [",join(' ',@$orig_defaults),"].\n",
	      "New user defaults: [",join(' ',getUserDefaults()),"].\n");

	if($defrunmode)
	  {
	    my $msg = "will be added-to/remain-in the usage output.\n";

	    my $ready = getRunModeStatus();

	    print("Changing default run mode to ");
	    if($ready == 1) #Required opts without defaults exist
	      {
		if(defined($explicit_help) && $explicit_help)
		  {
		    print("'help'\n");
		    print("  --dry-run $msg");
		    print("  --usage   $msg");
		  }
		elsif(defined($explicit_usage) && $explicit_usage)
		   {
		     print("'usage'\n");
		     print("  --dry-run $msg");
		     print("  --help    $msg");
		   }
		elsif(defined($explicit_run) && $explicit_run)
		  {
		    print("'run'\n");
		    print("  --dry-run $msg");
		    print("  --usage   $msg");
		    print("  --help    $msg");
		  }
		elsif(defined($explicit_dry_run) && $explicit_dry_run)
		  {
		    print("'dry-run'\n");
		    print("  --run   $msg");
		    print("  --usage $msg");
		    print("  --help  $msg");
		  }
	      }
	    else #No ready = 0  - required opts or all have defaults
	      {  #Or ready = -1 - required opts exist, but cannot determine def
		if(defined($explicit_help) && $explicit_help)
		  {
		    print("'help'\n");
		    print("  --run     $msg");
		    print("  --usage   $msg");
		    print("  --dry-run $msg");
		    print("Note: To run with no options other than the ",
			  "defaults, given that there are either no required ",
			  "options or all required options have default ",
			  "values, you must supply (at least) --run or ",
			  "--dry-run.");
		  }
		elsif(defined($explicit_usage) && $explicit_usage)
		  {
		    print("'usage'\n");
		    print("  --run     $msg");
		    print("  --help    $msg");
		    print("  --dry-run $msg");
		    print("Note: To run with no options other than the ",
			  "defaults, given that there are either no required ",
			  "options or all required options have default ",
			  "values, you must supply (at least) --run or ",
			  "--dry-run.");
		  }
		elsif(defined($explicit_run) && $explicit_run)
		  {
		    print("'run'\n");
		    print("  --dry-run $msg");
		    print("  --usage   $msg");
		    print("  --help    $msg");
		  }
		elsif(defined($explicit_dry_run) && $explicit_dry_run)
		  {
		    print("'dry-run'\n");
		    print("  --run     $msg");
		    print("  --usage   $msg");
		    print("  --help    $msg");
		  }
	      }

	    if($ready == -1) #Required opts exist, but cannot determine def
	      {
		warning("Unable to determine if custom options have default ",
			"values or not.  This is a current limitation of ",
			"CommandLineInterface.  This issue will be addressed ",
			"in requirement number 214.  Until then, options ",
			"with unknown default value status will be assumed ",
			"to have a value.");
	      }
	  }
      }

    return($status);
  }

#Globals used: $header
sub getHeader
  {
    return('') if(!defined($header) || !$header);

    debug({LEVEL => -99},"getHeader called.");

    my $version_str = getVersion(1,2);
    $version_str =~ s/\n(?!#|\z)/\n#/sg;

    my $user = exists($ENV{USER}) ? $ENV{USER} : `whoami`;
    chomp($user);
    my $host = exists($ENV{HOST}) ? $ENV{HOST} : `hostname`;
    chomp($host);
    my $pwd = exists($ENV{PWD}) ? $ENV{PWD} : (exists($ENV{CWD}) ? $ENV{CWD} :
					       `pwd`);
    chomp($pwd);

    $header_str = "$version_str\n" .
      "#User: $user\n" .
	'#Time: ' . scalar(localtime($^T)) . "\n" .
	  "#Host: $host\n" .
	    "#PID: $$\n" .
	      "#Directory: $pwd\n" .
		'#Command: ' . scalar(getCommand(1)) . "\n\n";

    return($header_str);
  }

#This sub takes an array reference (which should initially point to an empty
#array) and a reference to an array containing a series of numbers indicating
#the number of available items to choose from for each position.  It returns,
#in order, an array (the size of the second argument (pool_sizes array))
#containing an as-yet unseen combination of values where each value is selected
#from 1 to the pool size at that position.  E.g. If the pool_sizes array is
#[2,3,1], the combos will be ([1,1,1],[1,2,1],[1,3,1],[2,1,1],[2,2,1],[2,3,1])
#on each subsequent call.  Returns undef when all combos have been generated
sub GetNextIndepCombo
  {
    #Read in parameters
    my $combo      = $_[0];  #An Array of numbers
    my $pool_sizes = $_[1];  #An Array of numbers indicating the range for each
                             #position in $combo

    if(ref($combo) ne 'ARRAY' ||
       scalar(grep {/\D/} @$combo))
      {
	print STDERR ("ERROR:ordered_digit_increment.pl:GetNextIndepCombo:",
		      "The first argument must be an array reference to an ",
		      "array of integers.\n");
	return(0);
      }
    elsif(ref($pool_sizes) ne 'ARRAY' ||
	  scalar(grep {/\D/} @$pool_sizes))
      {
	print STDERR ("ERROR:ordered_digit_increment.pl:GetNextIndepCombo:",
		      "The second argument must be an array reference to an ",
		      "array of integers.\n");
	return(0);
      }

    my $set_size   = scalar(@$pool_sizes);

    #Initialize the combination if it's empty (first one) or if the set size
    #has changed since the last combo
    if(scalar(@$combo) == 0 || scalar(@$combo) != $set_size)
      {
	#Empty the combo
	@$combo = ();
	#Fill it with zeroes
        @$combo = (split('','0' x $set_size));
	#Return true
        return(1);
      }

    my $cur_index = $#{$combo};

    #Increment the last number of the combination if it is below the pool size
    #(minus 1 because we start from zero) and return true
    if($combo->[$cur_index] < ($pool_sizes->[$cur_index] - 1))
      {
        $combo->[$cur_index]++;
        return(1);
      }

    #While the current number (starting from the end of the combo and going
    #down) is at the limit and we're not at the beginning of the combination
    while($combo->[$cur_index] == ($pool_sizes->[$cur_index] - 1) &&
	  $cur_index >= 0)
      {
	#Decrement the current number index
        $cur_index--;
      }

    #If we've gone past the beginning of the combo array
    if($cur_index < 0)
      {
	@$combo = ();
	#Return false
	return(0);
      }

    #Increment the last number out of the above loop
    $combo->[$cur_index]++;

    #For every number in the combination after the one above
    foreach(($cur_index+1)..$#{$combo})
      {
	#Set its value equal to 0
	$combo->[$_] = 0;
      }

    #Return true
    return(1);
  }

#This method returns 3 arrays.  It creates an array of output file names, an
#array of output file stubs from the input file names and output directories
#(in case the coder wants to handle output file name construction on their
#own), and a skips array denoting which sets should be skipped because the
#output file already exists.  It checks all the future output files for
#possible overwrite conflicts and checks for existing output files.  It quits
#if it finds a conflict.  It uses the user_collide_modes array to determine whether
#a conflict is actually a conflict or just should be appended to when
#encountered.  If the collision mode is rename, it tries to avoid conflicting
#non-merging output files by joining the input file names with delimiting dots
#(in the order supplied in the stubs array).  It smartly compounds with a
#single file name if that file name is unique, otherwise, it joins all file
#names.
#ASSUMES that user_collide_modes 2D array is properly populated.
sub makeCheckOutputs
  {
    my $stub_sets           = copyArray($_[0]);#REQUIRD 2D array of stub combos
    my $suffixes            = $_[1]; #OPTIONAL (Requires $_[2])
    my $collide_modes       = $_[2];
    my $stub_source_hash    = $_[3];

    my $outfile_source_hash = {};
    my $index_uniq          = [map {{}} @{$stub_sets->[0]}]; #Array of hashes
    my $is_index_unique     = [map {1} @{$stub_sets->[0]}];
    my $delim               = '.';

    debug({LEVEL => -2},"Called.");

    if($DEBUG < 0 && eval('use Data::Dumper;1'))
      {
	my $sd = '';
	my $td = '';
	my $cd = '';
	eval('use Data::Dumper;$sd = Dumper($suffixes);1');
	eval('use Data::Dumper;$td = Dumper($stub_sets);1');
	eval('use Data::Dumper;$cd = Dumper($collide_modes);1');
	debug({LEVEL=>-99},"Stub sets:\n$td\nSuffixes:\n",
	      "$sd\nCollide modes:\n$cd\n");
      }

    #Build the is_index_unique array
    foreach my $stub_set (@$stub_sets)
      {
	foreach my $type_index (0..$#{$stub_set})
	  {
	    if($#{$index_uniq} < $type_index)
	      {
		error("Critical internal error: type index too big.");
		quit(-53);
	      }
	    #Only interested in stubs with defined values
	    if(defined($stub_set->[$type_index]))
	      {
		if(exists($index_uniq->[$type_index]
			  ->{$stub_set->[$type_index]}))
		  {
		    $is_index_unique->[$type_index] = 0;
		    debug({LEVEL => -99},"Index [$type_index] is not unique");
		  }
		$index_uniq->[$type_index]->{$stub_set->[$type_index]} = 1;
	      }
	    else
	      {$is_index_unique->[$type_index] = 0}
	  }
      }

    #Find the first unique index with defined values if one exists.
    #We'll use it to hopefully make other stubs unique
    my($first_unique_index);
    foreach my $index (0..$#{$is_index_unique})
      {
	if($is_index_unique->[$index])
	  {
	    $first_unique_index = $index;
	    debug({LEVEL => -2},"Unique index: [$index].");
	    last;
	  }
      }

    my $outfiles_sets = [];    #This will be the returned 3D outfiles array
    my $unique_hash   = {};    #This will be the check for outfile uniqueness
                               #$unique_hash->{$outfile}->{$type}->{$mrgmode}++
                               #Quit if any file has multiple types or
                               #$unique_hash->{$outfile}->{$type}->{error} > 1

    #For each stub set
    foreach my $stub_set (@$stub_sets)
      {
	push(@$outfiles_sets,[]);
	my $saved_stub_set = copyArray($stub_set);

	#For each file-type/stub index
	foreach my $type_index (0..$#{$stub_set})
	  {
	    push(@{$outfiles_sets->[-1]},[]);

	    debug({LEVEL => -2},"Index $type_index is ",
		  ($is_index_unique->[$type_index] ? '' : 'not '),"unique.");

	    my $name          = $stub_set->[$type_index];
	    my $compound_name = $stub_set->[$type_index];

	    #If collide modes is defined, a collide mode is set for this type
	    #index, there exists a rename collide mode, the stubs @ this index
	    #are not unique, AND this stub is defined, compound the name
	    if(defined($collide_modes) &&
	       defined($collide_modes->[$type_index]) &&
	       scalar(grep {defined($_) && $_ eq 'rename'}
		      @{$collide_modes->[$type_index]}) &&
	       !$is_index_unique->[$type_index] &&
	       defined($stub_set->[$type_index]))
	      {
		debug({LEVEL => -2},
		      "Creating compund name for index $type_index.");
		my $stub = $stub_set->[$type_index];
		$stub =~ s/.*\///;
		my $dir = $stub_set->[$type_index];
		unless($dir =~ s/^(.*\/).*/$1/)
		  {$dir = ''}

		if(defined($first_unique_index))
		  {
		    my $unique_name = $stub_set->[$first_unique_index];
		    $unique_name =~ s/.*\///;

		    #Compound the stub with the unique one in index order

		    #For backward compatibility, change stub in-place
		    if(!defined($collide_modes))
		      {$stub_set->[$type_index] = $dir .
			 ($type_index < $first_unique_index ?
			  $stub . $delim . $unique_name :
			  $unique_name . $delim . $stub)}

		    $compound_name = $dir .
		      ($type_index < $first_unique_index ?
		       $stub . $delim . $unique_name :
		       $unique_name . $delim . $stub);
		  }
		else
		  {
		    #Don't worry if not enough files exist to create a unique
		    #compound name.  Uniqueness is checked after compounding.

		    my $tmp_stub = $stub_set->[0];
		    $tmp_stub =~ s/(.*\/).*/$1/;

		    #For backward compatibility, change stub in-place
		    if(!defined($collide_modes))
		      {$stub_set->[$type_index] =
			 $tmp_stub . join($delim,
					  map {s/.*\///;$_} grep {defined($_)}
					  @$saved_stub_set)}

		    $compound_name =
		      $tmp_stub . join($delim,
				       map {s/.*\///;$_} grep {defined($_)}
				       @$saved_stub_set);
		  }
		debug({LEVEL => -2},"New stub: [$compound_name].");
	      }

	    debug({LEVEL => -2},"Creating file names.");
	    #Create the file names using the suffixes and compound name (though
	    #note that the compound name might not be compounded)
	    #If the stub is defined
	    if(defined($stub_set->[$type_index]))
	      {
		#If suffixes is defined & there are suffixes for this index
		if(defined($suffixes) && $#{$suffixes} >= $type_index &&
		   defined($suffixes->[$type_index]) &&
		   scalar(@{$suffixes->[$type_index]}))
		  {
		    my $cnt = 0;
		    #For each suffix available for this file type
		    foreach my $suff_index (0..$#{$suffixes->[$type_index]})
		      {
			my $suffix = $suffixes->[$type_index]->[$suff_index];
			my $partner_defined =
			  isTagteamPartnerDefined($type_index,$suff_index);
			#Don't add standard out if a suffix has been defined
			#for either this outfile type or of a possible tagteam
			#partner outfile type
			if(!isSuffixDefined($type_index,$suff_index) &&
			   ($partner_defined ||
			    !isTypeSuffixPrimary($type_index,$suff_index)))
			  {
			    debug({LEVEL => -99},"Suffix is not defined.");
			    push(@{$outfiles_sets->[-1]->[$type_index]},
				 $suffix);
			    $cnt++;
			    next;
			  }
			elsif(!isSuffixDefined($type_index,$suff_index) &&
			      !$partner_defined &&
			      isTypeSuffixPrimary($type_index,$suff_index))
			  {
			    #When no suffix is supplied, yet the output type is
			    #a primary type, set the output file name to dash
			    #('-') to indicate output should go to STDOUT
##TODO: This should really also be checking for merge collision mode and erroring out if there is more than one output file going to STDOUT and the mode is not merge.  See requirement 11b.
			    push(@{$outfiles_sets->[-1]->[$type_index]},'-');
			    $cnt++;
			    next;
			  }
			elsif(!defined($suffix))
			  {
			    error('Internal error 44: Should not have gotten ',
				  'here.');
			    quit(-54);
			  }

			#Concatenate the possibly compounded stub and suffix to
			#the new stub set
			push(@{$outfiles_sets->[-1]->[$type_index]},
			     ($collide_modes->[$type_index]->[$cnt] eq
			      'rename' ?
			      $compound_name . $suffix : $name . $suffix));

			$unique_hash
			  ->{$outfiles_sets->[-1]->[$type_index]->[-1]}
			    ->{$type_index}
			      ->{$collide_modes->[$type_index]->[$cnt]}++;

			$outfile_source_hash
			  ->{$outfiles_sets->[-1]->[$type_index]->[-1]} =
			    $stub_source_hash->{$stub_set->[$type_index]};

			$cnt++;
		      }
		  }
	      }
	    else
	      {
		if(defined($suffixes->[$type_index]))
		  {
		    #The stub is added to the new stub set unchanged
		    #For each suffix available for this file type
		    foreach my $suff_index (0..$#{$suffixes->[$type_index]})
		      {
			my $suffix = $suffixes->[$type_index]->[$suff_index];
			debug({LEVEL => -99},"Suffix is not defined 2.  ",
			      "Suffix: [",(defined($suffix) ?
					   $suffix : 'undef'),"].");
			#If the suffix is not defined, but it is primary, add
			#STDOUT to the outfile stubs.  Otherwise, the stub set
			#is not even defined, so add undef, just so we have a
			#placeholder (i.e. can guarantee that a place exists in
			#the suffix array for every suffix that was defined by
			#the programmer)
			push(@{$outfiles_sets->[-1]->[$type_index]},
			     (!isSuffixDefined($type_index,$suff_index) &&
			      isTypeSuffixPrimary($type_index,$suff_index) ?
			      '-' : undef));
		      }
		  }
	      }
	  }
      }

    #Let's make sure that the suffixes for each type are unique
    if(defined($suffixes))
      {
	debug({LEVEL => -2},"Checking suffixes.");
	my $unique_suffs = {};   #$unique_suffs->{$type}->{$suffix}++
	                         #Quit if $unique_suffs->{$type}->{$suffix} > 1
	my $dupe_suffs   = {};
	foreach my $type_index (0..$#{$suffixes})
	  {
	    foreach my $suffix (grep {defined($_)} @{$suffixes->[$type_index]})
	      {
		$unique_suffs->{$type_index}->{$suffix}++;
		if($unique_suffs->{$type_index}->{$suffix} > 1)
		  {$dupe_suffs->{$type_index + 1}->{$suffix} = 1}
	      }
	  }

	if(scalar(keys(%$dupe_suffs)))
	  {
	    my @report_errs = map {my $k = $_;"$k:" .
				     join(",$k:",keys(%{$dupe_suffs->{$k}}))}
	      keys(%$dupe_suffs);
	    @report_errs = (@report_errs[0..8],'...')
	      if(scalar(@report_errs) > 10);
	    error("The following input file types have duplicate output file ",
		  "suffixes (type:suffix): [",join(',',@report_errs),"].  ",
		  "This is a predicted overwrite situation that can only be ",
		  "surpassed by providing unique suffixes for each file type ",
		  "or by using --force combined with either --overwrite or ",
		  "--skip.");
	    quit(-55);
	  }
      }

    my $skip_sets = [map {0} (0..$#{$outfiles_sets})];

    #Now we shall check for uniqueness using unique_hash and the suffixes
    #$unique_hash->{$outfile}->{$type}->{$mrgmode}++
    #Quit if any file has multiple types or
    #$unique_hash->{$outfile}->{$type}->{error} > 1
    if(#The unique hash is populated
       scalar(keys(%$unique_hash)) &&
       #If any file has multiple types
       scalar(grep {scalar(keys(%$_)) > 1} values(%$unique_hash)))
      {
	my @report_errs = grep {scalar(keys(%{$unique_hash->{$_}})) > 1}
	  keys(%$unique_hash);
	@report_errs = (@report_errs[0..8],'...')
	  if(scalar(@report_errs) > 10);
	error("The following output files have conflicting file names from ",
	      "different input file types: [",join(',',@report_errs),"].  ",
	      "Please make sure the corresponding similarly named input ",
	      "files output to different directories.  This error may be ",
	      "circumvented by --force and either --overwrite or ",
	      "--skip, but it is heavily discouraged - only use for testing.");
	quit(-56);
      }
    #Quit if $unique_hash->{$outfile}->{$type}->{error} > 1 or
    #$unique_hash->{$outfile}->{$type}->{rename} (i.e. compounded names are
    #not unique)
    elsif(#The unique hash is populated
	  scalar(keys(%$unique_hash)) &&
	  #There exist error or rename modes
	  scalar(grep {$_ eq 'error' || $_ eq 'rename'} map {@$_}
		 grep {defined($_)} @$collide_modes) &&
	  #There exists an output filename duplicate for an error mode outfile
	  scalar(grep {$_ > 1} map {values(%$_)}
		 grep {exists($_->{error}) || exists($_->{rename})}
		 map {values(%$_)} values(%$unique_hash)))
      {
	my @report_errs =
	  grep {my $k = $_;scalar(grep {(exists($_->{error}) &&
					 $_->{error} > 1) ||
					   (exists($_->{rename}) &&
					    $_->{rename} > 1)}
				  values(%{$unique_hash->{$k}}))}
	    keys(%$unique_hash);
	@report_errs = (@report_errs[0..2],'...')
	  if(scalar(@report_errs) > 3);
	error("Output file name conflict",
	      (scalar(@report_errs) > 1 ? 's' : '')," detected: [",
	      join(',',@report_errs),"].  ",
	      (scalar(@report_errs) > 1 ? 'These files are' : 'This file is'),
	      " generated by multiple input files of the same name: [",
	      join(',',map {'(' .
			      join(',',keys(%{$outfile_source_hash->{$_}})) .
				") -> $_"} grep {$_ ne '...'} @report_errs),
	      "].",
	      {DETAIL =>
	       join('',("Please make sure each input file (from a different ",
			"source directory) outputs to a different output ",
			"directory and that the input file names are not the ",
			"same.  Also, when submitting multiple types of ",
			"input files, there must be a different output file ",
			"associated with each combination of input files.  ",
			"Check your input files for duplicates and that your ",
			"output file type is associated with input files in ",
			"a ONETOONE relationship.  Behavior upon file name ",
			"conflict detection is determined by the collision ",
			"mode set when the output file type was created (see ",
			"addOutfileOption, addOutfileSuffixOption, and ",
			"addOutfileTagteamOption).  At least one of the ",
			"collision modes for the affected files: [(",
			join('),(',map {defined($_) ? join(',',@$_) : 'undef'}
			     @{$collide_modes}),"})] is set to cause an ",
			"error if multiple input files output to the same ",
			"output file.  This error may be circumvented by ",
			"setting the COLLISIONMODE to either 'merge' or ",
			"'rename' via either those methods or by changing ",
			"the default using setDefaults if its not set in one ",
			"of those methods.  Note, 'rename' will only resolve ",
			"conflicts involving multiple types of input files.  ",
			"It will not rename input files that have the same ",
			"name but reside in different source directories, ",
			"even if multiple file types' renamed files ",
			"conflict.  To temporarily change the collision mode ",
			"globally for all output file types, supply ",
			"`--collision-mode VALUE`, where VALUE={error,merge,",
			"rename}.  To force past this error without changing ",
			"the collision mode, use --force and either ",
			"--overwrite or --skip, but this is heavily ",
			"discouraged - only use for testing."))});

	#An exit code of -1 will quit even if --force is supplied.  --force
	#is intended to over-ride programmatic errors.  --overwrite is
	#intended to over-ride existing files.
	quit(-1);
      }
    #Quit if any of the outfiles created already exist
    else
      {
	my(%exist);
	foreach my $i (0..$#{$outfiles_sets})
	  {
	    my $outfile_arrays_combo = $outfiles_sets->[$i];
	    foreach my $outfile_array (@$outfile_arrays_combo)
	      {
		foreach my $outfile (@$outfile_array)
		  {
		    unless(checkFile($outfile,undef,1,0))
		      {
			$exist{$outfile}++;
			$skip_sets->[$i] = 1 unless($append);
		      }
		  }
	      }
	  }

	if(scalar(keys(%exist)))
	  {
	    my $report_exist = [scalar(keys(%exist)) > 10 ?
				((keys(%exist))[0..8],'...') : keys(%exist)];
	    if($skip_existing)
	      {warning("Processing for these pre-existing output files will ",
		       "be skipped: [",join(',',@$report_exist),"].")}
	    elsif($append)
	      {
		debug({LEVEL => -1},"These pre-existing output files will be ",
		      "appended to: [",join(',',@$report_exist),"].");
		if($dry_run)
		  {warning("NOTE: There are pre-existing output files will ",
			   "be appended to: [",join(',',@$report_exist),"].")}
	      }
	    else
	      {
		error("Output files exist: [",join(',',@$report_exist),
		      "].  Use --overwrite, --append, or --skip to continue.");
		quit(-58);
	      }
	  }
      }

    #debug("Unique hash: ",Dumper($unique_hash),"\Collide modes: ",
    #	  Dumper($collide_modes),{LEVEL => -1});
    #debug({LEVEL => -99},"Returning outfiles: ",Dumper($outfiles_sets));

    #If no suffixes were provided, the outfile_sets will essentially be the
    #same as the stubs, only with subarrays inserted.
    return($outfiles_sets,$stub_sets,$skip_sets);
  }

sub getMatchedSets
  {
    my $array = $_[0]; #3D array

    debug({LEVEL => -99},"getMatchedSets called");

    #First, create a list of hashes that contain the effective and actual
    #dimension size and the file type index, as well as the 2D array of file
    #names themselves.  The number of rows is the actual and effective first
    #dimension size and the the number of columns is the second dimension size.
    #The number of columns may be variable.  If the number of columns is the
    #same for every row, the effective and actual second dimension size is the
    #same.  If they are different, the actual second dimension size is a series
    #of number of columns for each row and the effective dimension size is as
    #follows: If The numbers of columns across all rows is either 1 or N, the
    #effective second dimension size is N, else it is the series of numbers of
    #columns across each row (a comma-delimited string).  If an array is empty
    #or contains undef, it will be treated as 1x1.

    #When the effective second dimension size is variable, but only contains
    #sizes of 1 & N, then the first element of each row is copied until all
    #rows have N columns.

    #Create an array of hashes that store the dimension sizes and 2D array data
    my $type_container = [];
    #For each file type index
    foreach my $type_index (0..$#{$array})
      {
	#If any rows are empty, create a column containing a single undef
	#member
	foreach my $row (@{$array->[$type_index]})
	  {push(@$row,undef) if(scalar(@$row) == 0)}
	if(scalar(@{$array->[$type_index]}) == 0)
	  {push(@{$array->[$type_index]},[undef])}

	my $first_dim_size = scalar(@{$array->[$type_index]});

	#A hash tracking the number of second dimension sizes
	my $sd_hash = {};

	#A list of the second dimension sizes
	my $second_dim_sizes = [map {my $s=scalar(@$_);$sd_hash->{$s}=1;$s}
				@{$array->[$type_index]}];

	#Ignore second dimension sizes of 1 in determining the effective second
	#dimension size
	delete($sd_hash->{1});

	#Grab the first second dimension size (or it's 1 if none are left)
	my $first_sd_size =
	  scalar(keys(%$sd_hash)) == 0 ? 1 : (keys(%$sd_hash))[0];

	#The effective second dimension size is the first one from above if
	#there's only 1 of them, otherwise it's variable and stored as a comma-
	#delimited string.  Note, if it's a mix of 1 & some dimension N, the
	#effective second dimension size is N.
	my($effective_sd_size);
	if(scalar(keys(%$sd_hash)) == 1 || scalar(keys(%$sd_hash)) == 0)
	  {$effective_sd_size = $first_sd_size}
	else
	  {$effective_sd_size = join(',',@$second_dim_sizes)}

	debug({LEVEL => -98},"Type [$type_index] is $first_dim_size x ",
	      "$effective_sd_size or [$first_dim_size] x ",
	      "[@$second_dim_sizes]");

	#Change each 2D file array into a hash which stores its type index,
	#actual row size(s), effective row sizes, actual column sizes,
	#effective column sizes, and the actual 2D array of file names
	push(@$type_container,
	     {AF   => [$first_dim_size],       #Actual first dimension sizes
	      AS   => $second_dim_sizes,       #Actual second dimension sizes
	      EF   => $first_dim_size,         #Effective first dimension size
	      ES   => $effective_sd_size,      #Effective second dimension size
	      TYPE => $type_index,             #Type of files contained
	      DATA => scalar(copyArray($array->[$type_index]))});
	                                       #2D array of file names
      }

    #Next, we transpose any arrays based on the following criteria.  Assume FxS
    #is the effective first by second dimension sizes and that the type
    #container array is ordered by precedence(/type).  The first array will not
    #be transposed to start off and will be added to a new synced group.  For
    #each remaining array, if effective dimensions match an existing synced
    #group (in order), it is added to that synced group.  If it matches none,
    #it is the first member of a new synced group.  A group's dimensions match
    #if they are exactly the same, if they are reversed but exactly the same,
    #or 1 dimension is size 1 and the other dimension is not size 1 and matches
    #either F or S.  If a matching array's dimensions are reversed (i.e. F1xS1
    #= S2xF2 or (F1=1 and S1!=1 and S1=F2) or (S1=1 and F1!=1 and F1=S2)) and
    #it can be transposed, transpose it, else if a matching array's dimensions
    #are reversed and all the members of the synced group can be transposed,
    #transpose the members of the synced group.  Then the current array is
    #added to it.  Otherwise, the array is added as the first member of a new
    #synced group.  If the second dimension is a mix of sizes 1 & N only and N
    #matches F or S in the synced group, the 1 member is duplicated to match
    #the other dimension (F or S).

    my $synced_groups = [{EF    => $type_container->[0]->{EF},
			  ES    => $type_container->[0]->{ES},
			  AF    => [@{$type_container->[0]->{AF}}],
			  AS    => [@{$type_container->[0]->{AS}}],
			  GROUP => [$type_container->[0]]  #This is a hash like
			                                   #in the type_
			                                   #container array
			 }];

    #eval('use Data::Dumper;1') if($DEBUG < 0);

    #debug("Initial group with default candidate: ",
    #	  Dumper($synced_groups->[-1]->{GROUP}),"There are [",
    #	  scalar(@$type_container),"] types total.",{LEVEL => -99});

    #For every type_hash_index in the type container except the first one
    foreach my $type_hash_index (1..$#{$type_container})
      {
	my $type_hash = $type_container->[$type_hash_index];

	my $found_match = 0;

	my $candidate_ef = $type_hash->{EF};
	my $candidate_es = $type_hash->{ES};
	my $candidate_af = $type_hash->{AF};
	my $candidate_as = $type_hash->{AS};

	debug({LEVEL => -99},
	      "candidate_ef $candidate_ef candidate_es $candidate_es ",
	      "candidate_af @$candidate_af candidate_as @$candidate_as");

	foreach my $group_hash (@$synced_groups)
	  {
	    my $group_ef = $group_hash->{EF};
	    my $group_es = $group_hash->{ES};
	    my $group_af = $group_hash->{AF};
	    my $group_as = $group_hash->{AS};

	    debug({LEVEL => -99},
		  "group_ef $group_ef group_es $group_es group_af @$group_af ",
		  "group_as @$group_as");

	    #If the candidate and group match (each explained in-line below)
	    if(#Either candidate or group is 1x1 (always a match)
	       ($candidate_ef eq '1' && $candidate_es eq '1') ||
	       ($group_ef     eq '1' && $group_es eq '1') ||

	       #Exact or reverse exact match
	       ($candidate_ef eq $group_ef && $candidate_es eq $group_es) ||
	       ($candidate_ef eq $group_es && $candidate_es eq $group_ef) ||

	       #candidate_ef is 1 and candidate_es is not 1 but matches either
	       ($candidate_ef eq '1' && $candidate_es ne '1' &&
		($candidate_es eq $group_es || $candidate_es eq $group_ef)) ||

	       #candidate_es is 1 and candidate_ef is not 1 but matches either
	       ($candidate_es eq '1' && $candidate_ef ne '1' &&
		($candidate_ef eq $group_es || $candidate_ef eq $group_ef)) ||

	       #group_ef is 1 and group_es is not 1 but matches either
	       ($group_ef eq '1' && $group_es ne '1' &&
		($group_es eq $candidate_es || $group_es eq $candidate_ef)) ||

	       #group_es is 1 and group_ef is not 1 but matches either
	       ($group_es eq '1' && $group_ef ne '1' &&
		($group_ef eq $candidate_es || $group_ef eq $candidate_ef)) ||

	       #First dimensions match exactly and each second dimension is
	       #either an exact corresponding match or one of them is a 1
	       ($candidate_ef eq $group_ef &&
		scalar(grep {$group_as->[$_] == $candidate_as->[$_] ||
			       $group_as->[$_] == 1 ||
				 $candidate_as->[$_] == 1}
		       (0..($group_ef - 1))) == $group_ef))
	      {
		$found_match = 1;

		#If the candidate's dimensions are not the same, the group's
		#dimensions are not the same, and the candidate's dimensions
		#are reversed relative to the group, we need to transpose
		#either the candidate or the group.
		if(#Neither the candidate nor group is a square
		   $candidate_ef ne $candidate_es && $group_ef ne $group_es &&
		   #Either the candidate or group is not variable dimension
		   ($candidate_es !~ /,/ || $group_es !~ /,/) &&
		   #The matching dimension is opposite & not size 1
		   (($candidate_ef eq $group_es && $group_es ne '1') ||
		    ($candidate_es eq $group_ef && $group_ef ne '1')))
		  {
		    #We need to transpose either the candidate or group

		    #If the candidate can be transposed
		    if($candidate_es !~ /,/)
		      {
			#Assuming the number of columns varies between 1 & M,
			#fill up the rows of size 1 to match M before
			#transposing. (Won't hurt if they don't)
			foreach my $row (@{$type_hash->{DATA}})
			  {while(scalar(@$row) < $candidate_es)
			     {push(@$row,$row->[0])}}

			debug({LEVEL => -99},"Transposing candidate.");
			@{$type_hash->{DATA}} = transpose($type_hash->{DATA});
			my $tmp = $candidate_ef;
			$candidate_ef = $type_hash->{EF} = $candidate_es;
			$candidate_es = $type_hash->{ES} = $tmp;
			$candidate_af = $type_hash->{AF} =
			  [scalar(@{$type_hash->{DATA}})];
			$candidate_as = $type_hash->{AS} =
			  [map {scalar(@$_)} @{$type_hash->{DATA}}];
		      }
		    #Else if the group can be transposed
		    elsif($group_es !~ /,/)
		      {
			debug({LEVEL => -99},"Transposing group.");
			#For every member of the group (which is a type hash)
			foreach my $member_type_hash (@{$group_hash->{GROUP}})
			  {
			    #Assuming the number of columns varies between 1 &
			    #M, fill up the rows of size 1 to match M before
			    #transposing. (Won't hurt if they don't)
			    foreach my $row (@{$member_type_hash->{DATA}})
			      {while(scalar(@$row) < $group_es)
				 {push(@$row,$row->[0])}}

			    @{$member_type_hash->{DATA}} =
			      transpose($member_type_hash->{DATA});

			    #Update the type hash's metadata
			    my $tmp = $member_type_hash->{EF};
			    $member_type_hash->{EF} = $member_type_hash->{ES};
			    $member_type_hash->{ES} = $tmp;
			    $member_type_hash->{AF} =
			      [scalar(@{$member_type_hash->{DATA}})];
			    $member_type_hash->{AS} =
			      [map {scalar(@$_)} @{$member_type_hash->{DATA}}];
			  }

			#Update the group metadata (using the first member of
			#the group)
			my $tmp = $group_ef;
			$group_ef = $group_hash->{EF} = $group_es;
			$group_es = $group_hash->{ES} = $tmp;
			$group_af = $group_hash->{AF} =
			  [scalar(@{$group_hash->{GROUP}->[0]->{DATA}})];
			$group_as = $group_hash->{AS} =
			  [map {scalar(@$_)}
			   @{$group_hash->{GROUP}->[0]->{DATA}}];
		      }
		    else
		      {
			error("Critical internal error: Transpose not ",
			      "possible.  This should not be possible.");
			quit(-59);
		      }
		  }

		#Anything that needed transposed has now been transposed, so
		#now we need to even things up by filling any 1-dimensional
		#arrays to match their 2D matches.

		debug({LEVEL => -99},
		      "Add rows if(candidate_ef eq '1' && group_ef ne '1' && ",
		      "group_es ne '1'): if($candidate_ef eq '1' && ",
		      "$group_ef ne '1' && $group_es ne '1')");

		#If we need to add any rows to the candidate
		if($candidate_ef eq '1' && $group_ef ne '1')
		  {
		    debug({LEVEL => -99},"Adding rows to candidate.");
		    foreach(2..$group_ef)
		      {push(@{$type_hash->{DATA}},
			    [@{copyArray($type_hash->{DATA}->[0])}])}

		    #Update the metadata
		    $candidate_ef = $type_hash->{EF} = $group_ef;
		    #The effective second dimension size did not change
		    $candidate_af = $type_hash->{AF} = [$group_ef];
		    $candidate_as = $type_hash->{AS} =
		      [map {scalar(@$_)} @{$type_hash->{DATA}}];
		  }

		debug({LEVEL => -99},
		      "Add columns if(candidate_es eq '1' && group_es ne ",
		      "'1': if($candidate_es eq '1' && $group_es ne '1')");

		#If we need to add any columns to the candidate
		my $col_change = 0;
		foreach my $i (0..$#{$group_as})
		  {
		    my $num_cols = $group_as->[$i];
		    my $row = $type_hash->{DATA}->[$i];
		    while(scalar(@$row) < $num_cols)
		      {
			$col_change = 1;
			push(@$row,$row->[0]);
		      }
		  }
		if($col_change)
		  {
		    debug({LEVEL => -99},"Added columns to candidate.");
		    #Update the metadata
		    #The effective first dimension size did not change
		    $candidate_es = $type_hash->{ES} = $group_es;
		    #The actual first dimension size did not change
		    $candidate_as = $type_hash->{AS} =
		      [map {scalar(@$_)} @{$type_hash->{DATA}}];
		  }
		#If we need to add any rows to the group
		if($group_ef eq '1' && $candidate_ef ne '1')
		  {
		    debug({LEVEL => -99},"Adding rows to group.");
		    foreach my $member_type_hash (@{$group_hash->{GROUP}})
		      {
			#Copy the first row up to the effective first
			#dimension size of the candidate
			foreach(2..$candidate_ef)
			  {push(@{$member_type_hash->{DATA}},
				[@{copyArray($member_type_hash->{DATA}
					     ->[0])}])}

			#Update the member metadata
			$member_type_hash->{EF} = $candidate_ef;
			#Effective second dimension size did not change
			$member_type_hash->{AF} = [$candidate_ef];
			$member_type_hash->{AS} =
			  [map {scalar(@$_)} @{$member_type_hash->{DATA}}];
		      }

		    #Update the group metadata
		    $group_ef = $group_hash->{EF} = $candidate_ef;
		    #Effective second dimension size did not change
		    $group_af = $group_hash->{AF} =
		      [scalar(@{$group_hash->{GROUP}->[0]->{DATA}})];
		    #The actual second dimension size could be different if the
		    #candidate has a variable second dimension size
		    $group_as = $group_hash->{AS} =
		      [map {scalar(@$_)} @{$group_hash->{GROUP}->[0]->{DATA}}];
		  }

		#If we need to add any columns to the group
		$col_change = 0;
		foreach my $member_type_hash (@{$group_hash->{GROUP}})
		  {
		    foreach my $i (0..$#{$candidate_as})
		      {
			my $num_cols = $candidate_as->[$i];
			my $row = $member_type_hash->{DATA}->[$i];
			while(scalar(@$row) < $num_cols)
			  {
			    $col_change = 1;
			    push(@$row,$row->[0]);
			  }
		      }

		    if($col_change)
		      {
			#Update the member metadata
			#The effective first dimension size did not change
			$member_type_hash->{ES} = $candidate_es;
			#The actual first dimension size did not change
			$member_type_hash->{AS} =
			  [map {scalar(@$_)} @{$member_type_hash->{DATA}}];
		      }
		    else #Assume everything in a group is same dimensioned
		      {last}
		  }

		if($col_change)
		  {
		    debug({LEVEL => -99},"Added columns to group.");
		    #Update the metadata
		    #The effective first dimension size did not change
		    $group_es = $group_hash->{ES} = $candidate_es;
		    #The actual first dimension size did not change
		    $group_as = $group_hash->{AS} =
		      [map {scalar(@$_)} @{$group_hash->{GROUP}->[0]->{DATA}}];
		  }

		#Put this candidate in the synced group
		push(@{$group_hash->{GROUP}},$type_hash);

		#debug({LEVEL => -99},"Group after adding candidate: ",
		#      Dumper($group_hash->{GROUP}));

		#We stop when we find a match so that we don't put this
		#candidate in multiple synced groups
		last;
	      }
	  }

	unless($found_match)
	  {
	    #Create a new synced group
	    push(@$synced_groups,{EF    => $candidate_ef,
				  ES    => $candidate_es,
				  AF    => $candidate_af,
				  AS    => $candidate_as,
				  GROUP => [$type_hash]});

	    #debug({LEVEL => -99},"New group after adding candidate: ",
	    #	  Dumper($synced_groups->[-1]->{GROUP}));
	  }
      }

    #debug({LEVEL => -99},"Synced groups contains [",Dumper($synced_groups),
    #	  "].");

    #Now I have a set of synced groups, meaning every hash in the group has the
    #same dimensions described by the group's metadata.  However, I don't need
    #that metadata anymore, so I can condense the groups into 1 big array of
    #type hashes and all I need from those is the TYPE (the first index into
    #$array) and the DATA (The 2D array of files).

    #Each group has F * S paired combos.  In order to generate all possible
    #combinations, I need to string them along in a 1 dimensional array

    my $flattened_groups = []; #Each member is an unfinished combo (a hash with
                               #2 keys: TYPE & ITEM, both scalars

    foreach my $synced_group (@$synced_groups)
      {
	push(@$flattened_groups,[]);
	foreach my $row_index (0..($synced_group->{EF} - 1))
	  {
	    foreach my $col_index (0..($synced_group->{AS}->[$row_index] - 1))
	      {
		my $unfinished_combo = [];

		#foreach type hash in GROUP, add the item at row/col index to a
		#combo
		foreach my $type_hash (@{$synced_group->{GROUP}})
		  {
		    debug({LEVEL => -99},"ITEM should be type '': [",
			  ref($type_hash->{DATA}->[$row_index]->[$col_index]),
			  "].");

		    push(@$unfinished_combo,
			 {TYPE => $type_hash->{TYPE},
			  ITEM => $type_hash->{DATA}->[$row_index]
			  ->[$col_index]});
		  }

		push(@{$flattened_groups->[-1]},$unfinished_combo);
	      }
	  }
      }

    #debug({LEVEL => -99},"Flattened groups contains: [",
    #	  Dumper($flattened_groups),"].");

    my $combos = [];
    my $combo  = [];
    while(GetNextIndepCombo($combo,
			    [map {scalar(@$_)} @$flattened_groups]))
      {
	#The index of combo items corresponds to the index of flattened_groups
	#The values of combo correspond to the index into the array member of
	#flattened_groups

	#Construct this combo from the unfinished combos
	my $finished_combo = [];
	foreach my $outer_index (0..$#{$combo})
	  {
	    my $inner_index = $combo->[$outer_index];

	    push(@$finished_combo,
		 @{$flattened_groups->[$outer_index]->[$inner_index]});
	  }

	#Check the finished combo to see that it contains 1 file of each type
	my $check = {map {$_ => 0} (0..$#{$array})};
	my $unknown = {};
	foreach my $type_index (map {$_->{TYPE}} @$finished_combo)
	  {
	    if(exists($check->{$type_index}))
	      {$check->{$type_index}++}
	    else
	      {$unknown->{$type_index}++}
	  }
	my @too_many = grep {$check->{$_} > 1} keys(%$check);
	if(scalar(@too_many))
	  {
	    error("Critical Internal error: Bad Option Combo.  These option ",
		  "types had more than 1 value: [",join(',',@too_many),
		  "].  Use --force to include all combos by attempting to ",
		  "repair it.");

	    #Jump to the next iteration unless the user chose to force it
	    next if(!defined($force) || !$force);

	    #If they force it, try to repair by eliminating extra ones
	    my $fixed_fin_combo = [];
	    my $done = {};
	    foreach my $hash (@$finished_combo)
	      {
		next if(exists($done->{$hash->{TYPE}}));
		$done->{$hash->{TYPE}} = 1;
		push(@$fixed_fin_combo,$hash);
	      }
	    @$finished_combo = @$fixed_fin_combo;
	  }
	my @missing = grep {$check->{$_} == 0} keys(%$check);
	if(scalar(@missing))
	  {
	    error("Critical Internal error: Bad Option Combo.  These option ",
		  "types were missing: [",join(',',@missing),
		  "].  Use --force to include all combos by attempting to ",
		  "repair it.");

	    next if(!defined($force) || !$force);

	    #If they force it, try to repair by adding undefs
	    foreach my $type_index (@missing)
	      {push(@$finished_combo,{TYPE => $type_index,ITEM => undef})}
	  }
	if(scalar(keys(%$unknown)))
	  {
	    error("Critical Internal error: Bad Option Combo.  These option ",
		  "types are unknown: [",join(',',keys(%$unknown)),
		  "].  Use --force to include all combos by attempting to ",
		  "repair it.");

	    next if(!defined($force) || !$force);

	    #If they force it, try to repair by eliminating unknowns
	    my $fixed_fin_combo = [];
	    foreach my $hash (@$finished_combo)
	      {push(@$fixed_fin_combo,$hash)
		 unless(exists($unknown->{$hash->{TYPE}}))}
	    @$finished_combo = @$fixed_fin_combo;
	  }

	#Save the combo to return it
	push(@$combos,
	     [map {$_->{ITEM}}
	      sort {$a->{TYPE} <=> $b->{TYPE}} @$finished_combo]);
      }

    #debug({LEVEL => -99},"getMatchedSets returning combos: [",
    #	  Dumper($combos),"].");

    return(wantarray ? @$combos : $combos);
  }

#This method is specifically for use with the '<>' Getopt::Long operator
#(which catches flagless options) when used to capture files.  Since all
#unknown options go here, this sub watches for values that do not exist as
#files and begin with a dash followed by a non-number (to be rather forgiving
#of stub usages).  It just issues a warning, but if in strict mode, it will
#call quit.
sub checkFileOpt
  {
    my $alleged_file = $_[0];
    my $strict       = defined($_[1]) ? $_[1] : 0;
    if($alleged_file =~ /^-\D/ && !(-e $alleged_file))
      {
	if($strict)
	  {
	    error("Unknown option: [$alleged_file].");
	    quit(-60);
	  }
	else
	  {warning("Potentially unknown option assumed to be a file name: ",
		   "[$alleged_file].")}
      }
  }

sub processDefaultOptions
  {
    my $outfiles_defined = $_[0];

    #If there's anything in the stderr buffer, it will get emptied from
    #verbose calls below.

    #If the user has asked to save the options, save them & quit.  Saving of
    #--help, --dry-run, --usage, or --run are allowed, so this must be
    #processed before help or usage is printed.
    if($use_as_default)
      {
	saveUserDefaults() && quit(0);

	#Really done with command line processing
	$command_line_processed = 2;

	quit(-61);
      }

    #Print the usage if there are no non-user-default arguments (or it's just
    #the extended flag) and no files directed or piped in.
    #We're going to assume that if not all required options were supplied,
    #specific errors with an exit will be issued below (i.e. when $usage == 2)
    if($usage && $usage != 2)
      {
	usage(0);
	debug({LEVEL => -1},"Quitting with usage.");

	#Really done with command line processing
	$command_line_processed = 2;

	#Return if quit was not forced, which means we were probably called
	#from the END block
	quit(0) || return();
      }

    #Error-check for mutually exclusive flags supplied together
    if(scalar(grep {$_} ($version,$explicit_help,$explicit_usage,$explicit_run,
			 $explicit_dry_run)) > 1)
      {
	my @culprits = ();
	push(@culprits,'--help')    if($explicit_help);
	push(@culprits,'--version') if($version);
	push(@culprits,'--usage')   if($explicit_usage);
	push(@culprits,'--run')     if($explicit_run);
	push(@culprits,'--dry-run') if($explicit_dry_run);
	error('These options are mutually exclusive: [',join(',',@culprits),
	      '].');
	quit(-62);
      }
    elsif(scalar(grep {$_} ($help,$usage,$run,$dry_run)) > 1)
      {
	my @culprits = ();
	push(@culprits,'--help')    if($help);
	push(@culprits,'--usage')   if($usage);
	push(@culprits,'--run')     if($run);
	push(@culprits,'--dry-run') if($dry_run);
	error('Error determining run mode.  These mutually exclusive modes ',
	      'are concurrently set: [',join(',',@culprits),
	      '].');
	quit(-62);
      }

    #If the user has asked for the script version, print it & quit
    if($version)
      {
	print(getVersion(),"\n");

	#Really done with command line processing
	$command_line_processed = 2;

	quit(0);
      }

    #If the user has asked for help, call the help method & quit
    if($help)
      {
	help($extended);

	#Really done with command line processing
	$command_line_processed = 2;

	quit(0);
      }

    #Check validity of verbosity options
    if($quiet && ($verbose || $DEBUG))
      {
	$quiet = 0;
	error('--quiet is mutually exclusive with both --verbose & --debug.');
	quit(-63);
      }

    #Check validity of existing outfile options
    my $outmode_check = 0;
    foreach($skip_existing,$overwrite,$append)
      {$outmode_check++ if($_)}
    if($outmode_check > 1)
      {
	error('--overwrite, --skip, and --append are mutually exclusive.');
	quit(-64);
      }

    if(defined($user_collide_mode) && $user_collide_mode !~ /^[mer]/i)
      {
	error("Invalid --collision-mode: [$user_collide_mode].  Acceptable ",
	      "values are: [merge, rename, or error].  Check usage for an ",
	      "explanation of what these modes do.");
	quit(-65);
      }

    #Warn users when they turn on verbose and output is to the terminal
    #(implied by no outfile suffix & no redirect out) that verbose messages may
    #be messy
    if($verbose && !$outfiles_defined && isStandardOutputToTerminal())
      {warning('You have enabled --verbose, but appear to be outputting to ',
	       'the  terminal.  Verbose messages may interfere with ',
	       'formatting of terminal output making it difficult to read.  ',
	       'You may want to either turn verbose off, redirect output to ',
	       'a file, or supply output files by other means.')}

    if($dry_run)
      {verbose('Starting dry run.')}

    verbose({LEVEL => 2},'Run conditions: ',scalar(getCommand(1)));
    verbose({LEVEL => 2},"Verbose level:  [$verbose].");
    verbose({LEVEL => 2},'Header:         [on].')           if($header);
    verbose({LEVEL => 2},"Debug level:    [$DEBUG].")       if($DEBUG);
    verbose({LEVEL => 2},"Force level:    [$force].")       if($force);
    verbose({LEVEL => 2},"Overwrite:      [$overwrite].")   if($overwrite);
    verbose({LEVEL => 2},'Skip Existing:  [on].')           if($skip_existing);
    verbose({LEVEL => 2},'Append:         [on].')           if($append);
    verbose({LEVEL => 2},"Dry run mode:   [$dry_run].")     if($dry_run);
    verbose({LEVEL => 2},"Collision mode: [$user_collide_mode].")
      if(defined($user_collide_mode));
    verbose({LEVEL => 2},"Error level:    [$error_limit].")
      if($error_limit != $error_limit_default);
  }

sub argsOrPipeSupplied
  {
    my $got_input = isThereInputOnSTDIN();
    my $run_num = scalar(grep {$_ eq '--usage' || $_ eq 'help' ||
				 $_ eq '--run' || $_ eq '--dry-run'}
			 @$preserve_args);
    my $extended_num =
      scalar(grep {$preserve_args->[$_] eq '--extended' ||
		     ($_ > 0 && isInt($preserve_args->[$_]) &&
		      $preserve_args->[$_ - 1] eq '--extended')}
	     (0..$#{$preserve_args}));
    my $debug_num = scalar(grep {$preserve_args->[$_] eq '--debug' ||
				   ($_ > 0 && isInt($preserve_args->[$_]) &&
				    $preserve_args->[$_ - 1] eq '--debug')}
			   (0..$#{$preserve_args}));

    debug({LEVEL => -1},"Pipe: ",($got_input ? '1' : '0'),
	  " || [(",scalar(@$preserve_args),
	  " > ($extended_num + $debug_num + $run_num))].");

    #Should print if run mode is usage and any option other than extended &
    #debug are supplied
    return($got_input ||
	   scalar(@$preserve_args) > ($extended_num + $debug_num + $run_num));
  }

sub isInt
  {
    my $flt = $_[0];
    if($flt =~ /[+\-]?\d+([eE][+\-]?(\d+))?/)
      {return(1)}
    return(0);
  }

sub isFloat
  {
    my $flt = $_[0];
    my $np = '\d+|\d+\.|\d+\.\d+|\.\d+';
    if($flt =~ /[+\-]?($np)([eE][+\-]?($np))?/)
      {return(1)}
    return(0);
  }

#Globals used: $pipeline_mode
sub flushStderrBuffer
  {
    my %in = scalar(@_) % 2 == 0 ? @_ : ();

    #Use the local_force parameter to flush even if the required flags are not
    #defined
    my $local_force = (exists($in{FORCE}) ? $in{FORCE} :
		       (scalar(@_) == 1 && defined($_[0]) && $_[0] ne 'FORCE' ?
			$_[0] : 0));

    #Return if there is nothing in the buffer
    return(0) if(!defined($stderr_buffer));

    my $prints_exist =
      scalar(grep {((#There is a defined error limit
		     defined($error_limit) &&
		     #There are error or warning messages in the buffer
		     ($_->[0] eq 'error' || $_->[0] eq 'warning') &&
		     #The error/warning number is =|under the error limit
		     ($error_limit == 0 || $_->[1] <= $error_limit)) ||

		    (#There is a defined verbose level
		     defined($verbose) &&
		     #There are verbose messages in the buffer
		     $_->[0] eq 'verbose' &&
		      #The message level is =|under the verbose level
		     (($_->[1] > 0 && $_->[1] >= $verbose) ||
		      ($_->[1] < 0 && $_->[1] <= $verbose))) ||

		    (#There is a defined debug level
		     defined($DEBUG) &&
		     #There are debug messages in the buffer
		     $_->[0] eq 'debug' &&
		      #The message level is =|under the debug level
		     (($_->[1] > 0 && $_->[1] >= $DEBUG) ||
		      ($_->[1] < 0 && $_->[1] <= $DEBUG))))}

	     @{$stderr_buffer});

    if($local_force && scalar(@{$stderr_buffer}) &&
       (!defined($verbose) || !defined($quiet) || !defined($DEBUG) ||
	!defined($error_limit)))
      {
	print STDERR ("\nForce-flushing the STDERR buffer because the ",
		      'command line options [verbose: ',
		      (defined($verbose) ? $verbose : 'undef'),' quiet: ',
		      (defined($quiet) ? $quiet : 'undef'),' debug: ',
		      (defined($DEBUG) ? $DEBUG : 'undef'),' error_limit: ',
		      (defined($error_limit) ? $error_limit : 'undef'),
		      '] (which control the STDERR output, e.g. --debug) ',
		      'were not processed in time to catch some output.  If ',
		      'you get this flush every time, you can likely prevent ',
		      'it by adding a call to one or more of the following ',
		      'methods earlier in your code: [nextFileCombo(), ',
		      'getInfile(), getOutfile(), getNextFileGroup(), ',
		      'getAllFileGroups(), or optionally (if your script ',
		      "does not process files): processCommandLine()].\n\n");

	#For debugging purposes...
	if(!defined($DEBUG) || $DEBUG < 0)
	  {print STDERR ("DEBUG-FLUSH-TRACE:",getTrace(),"\n\n")}
      }
    elsif(defined($DEBUG) && $DEBUG < 0 && scalar(@{$stderr_buffer}))
      {print STDERR ("DEBUG-FLUSH-TRACE:",getTrace(),"\n\n")}

    #Return if we're not in force mode, there's nothing in the buffer to print,
    #and none of the stderr variables are defined
    return(0) if(!$local_force &&
		 (!$prints_exist ||
		  !defined($verbose) || !defined($quiet) ||
		  !defined($DEBUG)   || !defined($error_limit)));

    my $script = $0;
    $script =~ s/^.*\/([^\/]+)$/$1/;

    #Don't initialize pipeline_mode if printing usage so the default printed is
    #accurate
    if(!defined($pipeline_mode) && !$usage)
      {$pipeline_mode = inPipeline()}

    my $debug_num         = 0;
    my $replace_debug_num = 0;
    foreach my $message_array (@{$stderr_buffer})
      {
	if(ref($message_array) ne 'ARRAY' || scalar(@$message_array) < 3)
	  {print STDERR ("ERROR: Invalid message found in standard error ",
			 "buffer.  Must be an array with at least 3 ",
			 "elements, but ",
			 (ref($message_array) eq 'ARRAY' ?
			  "only [" . scalar(@$message_array) .
			  "] elements were present." :
			  "a [" . ref($message_array) .
			  "] was sent in instead."))}

	my($type,$level,$message,$leader,$smpl_msg,$smpl_ldr,$detail,
	   $detail_alert) = @$message_array;

	if(defined($detail) && $detail ne '' &&
	   defined($extended) && $extended)
	  {
	    $smpl_msg .= (' ' x length($smpl_ldr)) . $detail . "\n";
	    $message  .= (' ' x length($leader))   . $detail . "\n";
	  }
	elsif(defined($detail) && $detail ne '')
	  {
	    $smpl_msg .= (' ' x length($smpl_ldr)) . $detail_alert . "\n";
	    $message  .= (' ' x length($leader))   . $detail_alert . "\n";
	  }

	if(!defined($pipeline_mode) || $pipeline_mode)
	  {
	    my $pat = quotemeta($script);
	    if($message !~ /(?:DEBUG|WARNING|ERROR)\d+:$pat:/)
	      {$message  =~ s/^((DEBUG|WARNING|ERROR)\d+:)/$1$script:/g}
	    if($smpl_msg !~ /(?:DEBUG|WARNING|ERROR)\d+:$pat:/)
	      {$smpl_msg =~ s/^((DEBUG|WARNING|ERROR)\d+:)/$1$script:/g}
	  }

	if($type eq 'verbose')
	  {print STDERR ($message) if(!defined($verbose) || $level == 0 ||
				      ($level < 0 && $verbose <= $level) ||
				      ($level > 0 && $verbose >= $level))}
	elsif($type eq 'debug')
	  {
	    my $tmp_msg = $message;
	    if(defined($DEBUG) && abs($DEBUG) < 2)
	      {
		if(defined($smpl_msg) && defined($smpl_ldr))
		  {$tmp_msg = $smpl_msg}
	      }

	    if(!defined($DEBUG) || $level == 0  ||
	       ($level < 0 && $DEBUG <= $level) ||
	       ($level > 0 && $DEBUG >= $level))
	      {
		if($replace_debug_num)
		  {$tmp_msg =~ s/^DEBUG\d+/DEBUG$debug_num/}
		if($debug_num == 0 && $tmp_msg =~ /^DEBUG(\d+)/)
		  {$debug_num = $1}
		print STDERR ($tmp_msg);
		$debug_num++;
	      }
	    elsif($debug_num == 0 && $tmp_msg =~ /^DEBUG(\d+)/)
	      {
		my $tnum = $1;
		if($tnum == 1)
		  {$debug_num = 1}
		$replace_debug_num = 1;
	      }
	    else
	      {$replace_debug_num = 1}
	  }
	elsif($type eq 'error' || $type eq 'warning')
	  {
	    if(scalar(@$message_array) < 4)
	      {
		#Print the error without using the error function so as to
		#avoid a potential infinite loop.
		print STDERR ("ERROR: Parameter array too small.  Must ",
			      "contain at least 4 elements, but it has [",
			      scalar(@$message_array),"].\n");
		$leader = '';
	      }

	    #Skip this one if it is above the error_limit
	    next if(defined($error_limit) && $error_limit != 0 &&
		    $level > $error_limit);

	    my $tmp_msg = $message;
	    my $tmp_ldr = $leader;
	    if(defined($DEBUG) && !$DEBUG)
	      {
		if(defined($smpl_msg) && defined($smpl_ldr))
		  {
		    $tmp_msg = $smpl_msg;
		    $tmp_ldr = $smpl_ldr;
		  }
	      }

	    #Notify when going above the error limit
	    $message .=
	      join('',($tmp_ldr,"NOTE: Further ",
		       ($type eq 'error' ? 'error': "warning"),"s of this ",
		       "type will be suppressed.\n$tmp_ldr",
		       "Set --error-limit to 0 to turn off error ",
		       "suppression\n"))
		if(defined($error_limit) && $level == $error_limit);

	    print STDERR ($tmp_msg) if(!defined($quiet) || !$quiet);
	  }
	else
	  {
	    #Print the error without using the error function so as to avoid a
	    #potential infinite loop if error() ever sends an invalid type.
	    print STDERR ("ERROR: Invalid type found in standard error ",
			  "buffer: [$type].\n");
	  }
      }

    if($replace_debug_num)
      {$debug_number = $debug_num - 1}

    if(defined($DEBUG) && $DEBUG < 0)
      {print STDERR ("\nDONE-DEBUG-FLUSH-TRACE:",getTrace(),"\n\n")}

    undef($stderr_buffer);
  }

#This method creates a single-line trace.  It skips the call to this method and
#to the warning, error, or debug methods at the start of the trace.  Each
#element in the trace shows the subroutine and the line number inside the
#subroutine where the call was made.  The first element in the trace is the
#most recent call.  The last element in the trace is the oldest call (e.g. from
#main).  If the most recent call is from the main script, the script name is
#omitted, otherwise the file name where the call is is prepended.  When
#multiple sequential methods are called from the same file, the file name is
#skipped.  The format of the trace is:
#[file if not main/]calling_method(LINEline_number):[file if not the same as
#the last element and not in main of parent script/]calling_method(LINE
#line_number):...
#Example: CommandLineInterface.pm/openOut(LINE7479):MAIN(LINE53):
#Does not include script name for pipeline mode - call trace only.
sub getTrace
  {
    my @caller_info = caller(0);

    my $trace = '';

    #If any of these subs are the first in the trace, skip them
    my $skip_hash = {error => 1, warning => 1, debug => 1, __ANON__ => 1};
    my $skip_end_hash = {'(eval)' => 1, MAIN => 1};

    #Do not include the script name in the trace if the trace starts out from
    #the programmer's script.  They don't need a reminder of where their own
    #errors, warnings, and debugs, called directly from their script, are
    #coming from (unless in pipeline mode).
    my $script = $0;
    $script =~ s/^.*\/([^\/]+)$/$1/;
    my $last_filename = $script;

    #For each sub, report the line inside the sub where the call originated
    my $filename = $caller_info[1] || '';
    my $line_num = $caller_info[2] || '';

    my $end_called = 0;

    my $stack_level = 1;
    while(@caller_info = caller($stack_level))
      {
	my $calling_sub = $caller_info[3] || '';

	$filename =~ s%.*/%%;

	if(defined($calling_sub))
	  {$calling_sub =~ s/^.*::(.+)$/$1/}
	else
	  {$calling_sub = 'MAIN'}

	if($calling_sub eq 'END')
	  {$end_called = 1}

	#Only add to the trace if the line number is defined and the first
	#trace element is not one of the ones we're skipping
	if(defined($line_num) &&
	   ($trace ne '' || !exists($skip_hash->{$calling_sub})) &&
	   (!$end_called || ($end_called && $line_num ne '' &&
			     !exists($skip_end_hash->{$calling_sub}))))
	  {
	    if($trace ne '')
	      {$trace .= ':'}

	    if($filename eq $script && $trace eq '')
	      {$trace .= "$calling_sub(LINE$line_num)"}
	    elsif($filename ne $last_filename)
	      {$trace .= "$filename/$calling_sub(LINE$line_num)"}
	    else
	      {$trace .= "$calling_sub(LINE$line_num)"}
	  }

	$stack_level++;
	$last_filename = $filename unless($trace eq '');

	$filename = $caller_info[1] || '';
	$line_num = $caller_info[2] || '';
      }

    $trace .= ':' if($trace ne '');

    if(!$end_called || ($end_called && $line_num ne '' &&
			!exists($skip_end_hash->{MAIN})))
      {$trace .= "MAIN(LINE$line_num):"}

    return($trace);
  }

#This method guesses whether this script is running with concurrent or
#serially run siblings (i.e. in a script).  It uses pgrep and (indirectly) lsof.
#Cases where the script is intended to return true: 1. when the script is being
#piped to or from another command (i.e. not a file). 2. when the script is being
#run from inside another script.  In both cases, it is useful to know so that
#messages on STDERR can be prepended with the script name so that the user
#knows the source of any message
sub inPipeline
  {
    my $ppid = getppid();
    my $siblings = `pgrep -P $ppid`;

    #Return true if any sibling processes were detected
    return(1) if($siblings =~ /\d/);

    #Return true if the parent is a script
    return(calledInsideAScript($ppid));
  }

sub amIPipedTo
  {
    my $forced = defined($_[0]) ? $_[0] : 0;
    my $pipes  = getMyPipeData($forced);
    return($pipes->[0]);
  }

sub amIPipedFrom
  {
    my $forced = defined($_[0]) ? $_[0] : 0;
    my $pipes  = getMyPipeData($forced);
    return($pipes->[1]);
  }

sub amIRedirectedTo
  {
    my $forced = defined($_[0]) ? $_[0] : 0;

    my $handle_data = getMyLsofData($forced);

    #Get the file descriptors
    my $fdin = fileno(STDIN);

    if(defined($fdin) && $fdin =~ /\d/ && $fdin > -1 &&
       $handle_data =~ /\s${fdin}r\s+REG\s+\S+\s+\S+\s+\S+\s+(\S+)/)
      {
	my $infile = $1;

	#Ignore lsof read lines that are this script
	my $script = $0;
	$script =~ s/^.*\/([^\/]+)$/$1/;
	my $scriptpat = quotemeta($script);

	if($infile !~ m%/$scriptpat$%)
	  {return(1)}
      }


    return(0);
  }

#Calls lsof
#Globals used: $pipe_cache
sub getMyPipeData
  {
    my $forced = defined($_[0]) ? $_[0] : 0;

    #Return what was previously determined
    if(!$forced && defined($pipe_cache))
      {return(wantarray ? @$pipe_cache : $pipe_cache)}

    #Initialize the pipe boolean values
    $pipe_cache = [0,0,0];

    #Get the data necessary to determine piping of standard file handles
    my $handle_data = getMyLsofData($forced);

    #Get the file descriptors
    my $fdin = fileno(STDIN);
    my $fdot = fileno(STDOUT);
    my $fder = fileno(STDERR);

    if(defined($fdin) && $fdin =~ /\d/ && $fdin > -1 &&
       $handle_data =~ /\s$fdin\s+PIPE\s+/)
      {$pipe_cache->[0] = 1}
    if(defined($fdot) && $fdot =~ /\d/ && $fdot > -1 &&
       $handle_data =~ /\s$fdot\s+PIPE\s+/)
      {$pipe_cache->[1] = 1}
    if(defined($fder) && $fder =~ /\d/ && $fder > -1 &&
       $handle_data =~ /\s$fder\s+PIPE\s+/)
      {$pipe_cache->[2] = 1}

    return(wantarray ? @$pipe_cache : $pipe_cache);
  }

sub getMyLsofData
  {
    my $forced = defined($_[0]) ? $_[0] : 0;

    #Return what was previously determined
    if(!$forced && defined($lsof_cache) && $lsof_cache ne '')
      {return($lsof_cache)}

    $lsof_cache = `lsof -w -b -p $$`;

    return($lsof_cache);
  }

#This method guesses whether this script is running with serially run siblings
#(i.e. in a script).  It uses lsof.  Cases where the script is intended to
#return true: 1. 2. when the script is being run from inside a script being read
#by an interpreter.  It is useful to know so that messages on STDERR can be
#prepended with the script name so that the user knows the source of any message
#and in determining the source of STDIN (e.g. not connected to a tty and
#(possibly) not a pipe, but rather: inherited from the parent
sub calledInsideAScript
  {
    my $ppid = $_[0];

    #Find out what file handles the parent process has open
    my $parent_data = `lsof -w -b -p $ppid`;

    #Return true if the parent has a read-only handle open on a regular file
    #(implying it's reading a script - the terminal/shell does a read/write
    #(mode 'u'))
    return(1) if($parent_data =~ /\s+\d+r\s+REG\s+/);

    return(0);
  }

#Do not call this method internally, as it could cause an infinite loop with
#processCommandLine.  Instead, check $force
#Globals used: $force
sub isForced
  {
    unless($processCommandLine_called)
      {processCommandLine()}
    return($force);
  }

#Do not call this method internally, as it could cause an infinite loop with
#processCommandLine.  Instead, check $verbose
#Globals used: $verbose
sub isVerbose
  {
    unless($processCommandLine_called)
      {processCommandLine()}
    return($verbose);
  }

#Do not call this method internally, as it could cause an infinite loop with
#processCommandLine.  Instead, check $DEBUG
#Globals used: $DEBUG
sub isDebug
  {
    unless($processCommandLine_called)
      {processCommandLine()}
    return($DEBUG);
  }

#Do not call this method internally, as it could cause an infinite loop with
#processCommandLine.  Instead, check $header
#Globals used: $header
sub headerRequested
  {
    unless($processCommandLine_called)
      {processCommandLine()}
    return($header);
  }

#Do not call this method internally, as it could cause an infinite loop with
#processCommandLine.  Instead, check $dry_run
#Globals used: $dry_run
sub isDryRun
  {
    unless($processCommandLine_called)
      {processCommandLine()}
    return($dry_run);
  }

sub setDefaults
  {
    my @in = getSubParams([qw(HEADER ERRLIMIT COLLISIONMODE RUNMODE|DEFRUNMODE
			      DEFSDIR UNPROCFILEWARN)],
			  [],[@_]);
    my $header_def     = $in[0];
    my $errlimit_def   = $in[1];
    my $colmode_def    = $in[2];
    my $runmode_def    = $in[3];
    my $defs_dir       = $in[4];
    my $unprocwarn_def = $in[5];

    my $errors = 0;

    if(defined($header_def) && ($header_def == 0 || $header_def == 1))
      {$header = $header_def}
    elsif(defined($header_def))
      {
	error("Invalid HEADER value: [$header_def].  Must be 0 or 1.");
	$errors++;
      }

    if(defined($errlimit_def) && $errlimit_def =~ /^\d+$/)
      {$error_limit = $errlimit_def}
    elsif(defined($errlimit_def))
      {
	error("Invalid ERRLIMIT value: [$errlimit_def].  Must be an unsigned ",
	      "integer.");
	$errors++;
      }

    if(defined($colmode_def) &&
       ($colmode_def eq 'error' || $colmode_def eq 'merge' ||
	$colmode_def eq 'rename'))
      {$def_collide_mode = $colmode_def}
    elsif(defined($colmode_def))
      {
	error("Invalid COLLISIONMODE value: [$colmode_def].  Must be one of ",
	      "['error','merge','rename'].");
	$errors++;
      }

    if(defined($runmode_def) &&
       ($runmode_def eq 'run'  || $runmode_def eq 'dry-run' ||
	$runmode_def eq 'help' || $runmode_def eq 'usage'))
      {$default_run_mode = $runmode_def}
    elsif(defined($runmode_def))
      {
	error("Invalid DEFRUNMODE value: [$runmode_def].  Must be one of ",
	      "['run','dry-run','usage','help'].");
	$errors++;
      }

    if(defined($defs_dir) && (!-e $defs_dir || (-w $defs_dir && -x $defs_dir)))
      {$defaults_dir = $defs_dir}
    elsif(defined($defs_dir))
      {
	error("Invalid DEFSDIR (user defaults directory): [$defs_dir].  Must ",
	      "either not already exist or be writable/executable.");
	$errors++;
      }

    if(defined($unprocwarn_def) && $unprocwarn_def =~ /^\d+$/)
      {$unproc_file_warn = $unprocwarn_def}
    elsif(defined($unprocwarn_def))
      {
	error("Invalid UNPROCFILEWARN: [$unprocwarn_def].  Must be 0 or 1.");
	$errors++;
      }

    if($errors > 0)
      {
	quit(-66);
	return(1);
      }

    return(0);
  }

##
## This method prints a description of the script and it's input and output
## files.
##
#Globals used: $script_version_number, $created_on_date
sub help
  {
    ##TODO: Give the programmer a way to set IGNORE_UNSUPPLIED in all
    ##      instances.  See requirement 185
    my @in       = getSubParams([qw(ADVANCED IGNORE_UNSUPPLIED)],[],[@_]);
    my $script   = $0;
    my $advanced = $in[0];
    my $ignore   = $in[1];
    my @stat     = stat($script);
    my $ctime    = @stat && defined($stat[9]) ? $stat[9] : scalar(time);
    my $lmd      = localtime($ctime);

    unless($processCommandLine_called)
      {processCommandLine()}

    $script =~ s/^.*\/([^\/]+)$/$1/;

    $script_version_number = 'UNKNOWN'
      if(!defined($script_version_number));

    $created_on_date = 'UNKNOWN' if(!defined($created_on_date) ||
				    $created_on_date eq 'DATE HERE');

    my $custom_help = customHelp($ignore,$advanced);

    if(getRunModeStatus() != 1 || $default_run_mode ne 'usage')
      {
	$custom_help .= "\n\n";
	$custom_help .= "Supply --usage to see usage output.";
      }

    #Print a description of this program
    print << "end_print";

$script version $script_version_number
Created: $created_on_date
Last Modified: $lmd

$custom_help

end_print

    if($advanced)
      {
	my $legend = "USAGE LEGEND\n\n";
	$legend .=
	  alignCols(['*','=','Required option.'],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['~','=',
		     join('',('Required option, but has a default value, thus ',
			      'effectively optional.'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['^','=',
		     join('',("Conditionally required option.  E.g. When 1 of ",
			      "2 mutually exclusive options must be ",
			      "supplied.  Note, if one of the 2 options has a ",
			      "default value, '~' will be preferentially ",
			      "displayed."))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['...','=',
		     join('',('Multiple flags or flag arguments may be ',
			      'supplied.  E.g.:'))],
		    [11,1],[0,1,1],[0,0,0]) . "\n";
	$legend .=
	  alignCols(['','','-f...','=',
		     'Multiple instances of "-f" can be supplied.'],
		    [11,1,14,1],[0,1,1,1,1],[0,0,0,0,0]);
	$legend .=
	  alignCols(['','','-f <arg...>','=',
		     join('',('Multiple arguments can be supplied to "-f".'))],
		    [11,1,14,1],[0,1,1,1,1],[0,0,0,0,0]);
	$legend .=
	  alignCols(['','','-f <arg...>...','=',
		     join('',('Multiple instances of "-f" can be supplied, ',
			      'each with multiple arguments.'))],
		    [11,1,14,1],[0,1,1,1,1],[0,0,0,0,0]) . "\n";
	$legend .=
	  alignCols(['','',
		     join('',("Argument delimiters may be displayed between ",
			      "the argument and the ellipsis (e.g. comma ",
			      "delimited would be displayed as: ",
			      "'<arg,...>').   If the the delimiter is a ",
			      "space, the arguments must all be grouped ",
			      "inside a single pair of quotes or be escaped.  ",
			      "Multiple sequential delimiters are all ",
			      "condensed to 1 (e.g. '1,,,2' = '1,2').  A ",
			      "special delimiting character of '*' indicates ",
			      "that the argument will be (bsd) globbed (glob ",
			      "patterns recognized: *,?,[],{}).  Only <file> ",
			      "and <dir> types are globbed.  Glob patterns ",
			      "must be inside quotes to associate all files ",
			      "with the preceding flag.  If multi-character ",
			      "delimiters are used, they will be detailed in ",
			      "the description."))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['[<arg>]','=',
		     join('',('Flags with optional arguments (e.g. <cnt>) are ',
			      'displayed inside square brackets.'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['[default]','=',
		     join('',("An option's description starts with a ",
			      "description of its default value, if it has a ",
			      "default.  Note, default values are not ",
			      "displayed if they are not defined.  ",
			      "Additionally default values for flags that do ",
			      "not take arguments are always false and are ",
			      "not shown.  If negatable options (options that ",
			      'have flags starting with or without "no" - ',
			      'e.g. --flag or --noflag) have a default, only ',
			      'the flag that is the opposite of the default ',
			      'will be shown in the flag column.'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(["<enum>\n<a,b,c>",'=',
		     join('',("A flag that takes only one of a set of ",
			      "specific strings is an 'enumeration' and is ",
			      "indicated by the argument being represetned as ",
			      "a list of acceptable values inside angle ",
			      "brackets and delimited by '|'.  Long lists ",
			      "will be truncated and appended to the ",
			      "description."))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['<cnt>','=',
		     join('',('Count ("cnt") arguments are integer arguments ',
			      'whose flags can be supplied multiple times ',
			      'with or without the count argument argument ',
			      "(i.e. they're always optional and shown inside ",
			      'square brackets (see "[<arg>]" above)).  Each ',
			      'occurrence of the flag without an argument ',
			      'increments the count (from left to right) or ',
			      'can be statically set by providing the integer ',
			      'argument (negative values allowed).  Mixing ',
			      'flags with and without the count argument can ',
			      'produce unexpected results, so only use one ',
			      'style or the other.  If the flag has a default ',
			      'value, the count starts at that value.'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['<dir>','=',
		     join('',('Directory.  Any dir type argument can be ',
			      'supplied a BSD glob pattern (though they must ',
			      'be inside quotes to associate them with the ',
			      'accompanying flag).'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['<file>','=',
		     join('',('Any file type argument can be given a single ',
			      "dash character ('-') as an argument, which ",
			      'stands for either "read from STDIN" or "write ',
			      'to STDOUT", depending on the file flag type.  ',
			      (!defined($primary_infile_type) ? '' :
			       "Infile option " .
			       getInfileFlag($primary_infile_type) . " will " .
			       "recognize input on standard in automatically " .
			       "and thus does not require a dash to be " .
			       "supplied" .
			       (getNumInfileTypes() < 2 ? '.  ' :
				' (unless a dash is supplied to one of the ' .
				'other infile options).  ')),
			      'Only one infile option can read from STDIN in ',
			      'one run.  Any file type argument can be ',
			      'supplied a BSD glob pattern (inside quotes).'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['<flt>','=',
		     join('',('Float.  E.g. a number with a decimal value.  ',
			      'Signed or unsigned.  Scientific notation is ',
			      'allowed.'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['<int>','=',
		     join('',('Integer argument.  Signed or unsigned.  ',
			      'Scientific notation (without a decimal) is ',
			      'allowed.'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['<sfx>','=',
		     join('',('Suffix appended to input file names.  Note, a ',
			      'dot is not added by default.  Providing an ',
			      'empty string essentially creates an output ',
			      'file name that is the same as the input file ',
			      'name, but you will get an error unless ',
			      '--overwrite is also provided.'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['<stub>','=',
		     join('',('A stub argument must always be accompanied by ',
			      'input on standard in.  A stub is used as a ',
			      'file name prefix for input on standard in.  ',
			      'Stubs get <sfx> appended to them, defined by ',
			      'suffix options, to create an output file ',
			      'name.  If no stub is provided, the default ',
			      'stub used for input on standard in is ',
			      '"STDIN".'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['< <file>','=',
		     join('',('If a redirect (i.e. "<") is shown among an ',
			      "option's flags, it means that it can read from ",
			      'standard in (but if no input is detected, the ',
			      'script will not wait for input).  Only 1 ',
			      'input file option can read from STDIN.'))],
		    [11,1],[0,1,1],[0,0,0]) . "\n";
	$legend .=
	  alignCols(['','','-f <stub> < <file>','=',
		     join('',('-f has the built-in ability to read from STDIN ',
			      '(without the need to supply "-") & a stub can ',
			      'optionally be supplied to name the input ',
			      'file.'))],
		    [11,1,18,1],[0,1,1,1,1],[0,0,0,0,0]);
	$legend .=
	  alignCols(['','','-f - < <file>','=',
		     join('',('Any file option has the ability to read from ',
			      'standard input if a dash is supplied to the ',
			      'flag as an argument, but note no stub can ',
			      '(yet) be set for the input file name when a ',
			      'dash is required.'))],
		    [11,1,18,1],[0,1,1,1,1],[0,0,0,0,0]) . "\n";
	$legend .=
	  alignCols(['STDIN','=',
		     join('',('"STDIN" may be mentioned in numerous places.  ',
			      'Only one input file type can take standard in ',
			      'at a time.  If an input file type has the ',
			      'built-in ability to read from standard input, ',
			      'a flag option will be presented as `< ',
			      '<file>`.  You can choose to send standard in ',
			      'to other input file types by supplying a dash ',
			      'as the file argument.  Note there is a ',
			      'difference between the built-in ability to ',
			      'read standard input and reading from STDIN ',
			      'being a default.  If the default value is ',
			      '"STDIN", the script will wait for user input ',
			      'if no file was provided.  The built-in ability ',
			      'to read from STDIN however will not wait for ',
			      'user input if no file is provided and no input ',
			      'is detected on standard in (i.e. no redirected ',
			      'input).  See "<file>" for more details.'))],
		    [11,1],[0,1,1],[0,0,0]);
	$legend .=
	  alignCols(['STDOUT','=',
		     join('',('If "STDOUT" is listed as a default for an ',
			      'output file or outfile suffix, it means that ',
			      'output will go to standard out by default ',
			      '(when no file name or suffix is defined).'))],
		    [11,1],[0,1,1],[0,0,0]);

	print($legend,"\n\n");
      }

    if($advanced > 1 ||
       ($advanced == 1 && (!defined($advanced_help) || $advanced_help eq '')))
      {
	my $header = '                 ' .
	  join("\n                 ",split(/\n/,getHeader()));

	my $odf = getOutdirFlag(2);

	print("ADVANCED\n========\n\n",
	      alignCols(['* HEADER FORMAT:',
			 join('',('Unless --noheader is supplied or STANDARD ',
				  'output is going to the terminal (and not ',
				  'redirected into a file), every output ',
				  'file, including output to standard out, ',
				  'will get a header that is commented using ',
				  "the '#' character (i.e. each line of the ",
				  "header will begin with '#').  The format ",
				  'of the standard header looks like this:'))],
			[16],[0,1],[0,0]),"\n",
	      $header,"\n\n",
	      "                 The header is important for 2 reasons:\n\n",
	      alignCols(['1.',
			 join('',('It records information about how the file ',
				  'was created: user name, time, script ',
				  'version information, and the command line ',
				  'that was used to create it.'))],
			[2],[17,1],[0,0]),"\n",
	      alignCols(['2.',
			 join('',('The header is used to confirm that a file ',
				  'inside a directory that is to be output to ',
				  '(using $odf) was created by this script ',
				  'before deleting it when in overwrite ',
				  'mode.  See OVERWRITE PROTECTION below.'))],
			[2],[17,1],[0,0]),"\n",
	      alignCols(['* OVERWRITE PROTECTION:',
			 join('',('This script prevents the over-writing of ',
				  'files (unless --overwrite is provided).  A ',
				  'check is performed for pre-existing files ',
				  'before any output is generated.  It will ',
				  'even check if future output files will be ',
				  'over-written in case two input files from ',
				  'different directories have the same name ',
				  'and a common $odf.  Furthermore, before ',
				  'output starts to a given file, a last-',
				  'second check is performed in case another ',
				  'program or script instance is competing ',
				  'for the same output file.  If such a case ',
				  'is encountered, an error will be generated ',
				  "and the file will always be skipped.\n\n",
				  'Directories: When $odf is supplied with ',
				  '--overwrite, the directory and its ',
				  'contents will not be deleted.  If you ',
				  'would like an output directory to be ',
				  'automatically removed, supply --overwrite ',
				  'twice on the command line.  The directory ',
				  'will be removed, but only if all of the ',
				  'files inside it can be confirmed to have ',
				  'been created by a previous run of this ',
				  'script.  For this, headers are required to ',
				  'be in the files (i.e. the previous run ',
				  'must not have included the --noheader ',
				  'flag.  This requirement ensures that it is ',
				  'very unlikely to accidentally delete ',
				  'anything that is not intended to have been ',
				  'deleted.  If a directory cannot be ',
				  'emptied, the script will proceed with a ',
				  'warning about any files in the output ',
				  "directory it could not clean out.\n\nNote ",
				  'that individual files bearing the same ',
				  'name as a current output file will be ',
				  'overwritten regardless of a header.'))],
			[23],[0,1],[0,0]),"\n",
	     );

	print << "end_print";
* ADVANCED USER DEFAULTS:

If you find you are always supplying the same option over and over, you can save it as a default using the --save-args flag.  Run the script with --save-args along with the options and their values that you want to save and they will be included every time the script runs.  To clear the defaults, run the script with --save-args as the only parameter.

Saving *one* of the following flags changes the "default run mode":

    --usage
    --help
    --run
    --dry-run

Note: These options are not always visible in the usage output because they may be irrelevant given the defaults saved, however they are always recognized options.

The default run mode, put simply, determines what the script does when no options are provided on the command line.  Although note, the script will not run if any required options do not have values, so if the default run mode is --run, a usage (along with an error) will be printed.

Only one mode may be saved as a default run mode.

* ADVANCED FILE I/O FEATURES:

Sets of input files, each with different output directories can be supplied.  Supply each file set with an additional (e.g.) -i flag.  Wrap each set of files in quotes and separate them with spaces.

Output directories (e.g.) --outdir can be supplied multiple times in the same order so that each input file set can be output into a different directory.  If the number of files in each set is the same, you can supply all output directories as a single set instead of each having a separate --outdir flag.

Examples:

  $0 -i 'a b c' --outdir '1' -i 'd e f' --outdir '2'

    Resulting file sets: 1/a,b,c  2/d,e,f

  $0 -i 'a b c' -i 'd e f' --outdir '1 2 3'

    Resulting file sets: 1/a,d  2/b,e  3/c,f

If the number of files per set is the same as the number of directories in 1 set are the same, this is what will happen:

  $0 -i 'a b' -i 'd e' --outdir '1 2'

    Resulting file sets: 1/a,d  2/b,e

NOT this: 1/a,b 2/d,e  To do this, you must supply the --outdir flag for each set, like this:

  $0 -i 'a b' -i 'd e' --outdir '1' --outdir '2'

Other examples:

  $0 -i 'a b c' -i 'd e f' --outdir '1 2'

    Result: 1/a,b,c  2/d,e,f

  $0 -i 'a b c' --outdir '1 2 3' -i 'd e f' --outdir '4 5 6'

    Result: 1/a  2/b  3/c  4/d  5/e  6/f

If this script has multiple types of file options (which are processed together), the files which are associated with one another will be associated in the same manner as the output directories above.  Basically, if the number of files or sets of files match, they will be automatically associated in the order in which they were provided on the command line.

end_print
      }
    elsif($advanced)
      {print("Supply `--help --extended 2` for details on advanced interface ",
	     "options.\n\n")}
    else
      {print("Supply `--help --extended` for advanced help.\n\n")}

    return(0);
  }

sub customUsage
  {
    my $local_extended = defined($_[0]) ? $_[0] :
      (defined($extended) ? $extended : 0);

    my $short = '';
    my $long  = '';

    my($short_flag_col_width,$long_flag_col_width) =
      getUsageFlagColWidths();

    #We want to keep the order the programmer added the options, except to
    #require that required options be first and that the combo variable option
    #'run|dry-run' (see addRunModeOptions) be the very first (if it was
    #added), so we'll save the order the user added the options.
    my $pos_hash = {};
    my $opt_cnt = 0;
    foreach my $usage_hash (@$usage_array)
      {$pos_hash->{$usage_hash} = $opt_cnt++}

    my $combo_flag = 'run|dry-run';

    my $advanced_header = 0;
    my($flags_remainder,$short_desc_remainder,$long_desc_remainder);
    foreach my $usage_hash (grep {(!$_->{HIDDEN} && !$_->{ADVANCED}) ||
				    ($_->{HIDDEN} && $extended > 2) ||
				       ($_->{ADVANCED} && !$_->{HIDDEN} &&
					$extended > 1)}
			    sort {#Put --extended last
			      ($a->{GETOPTKEY} eq 'extended:+') <=>
				($b->{GETOPTKEY} eq 'extended:+') ||
				  (defined($a->{ADVANCED}) && $a->{ADVANCED})
				    <=> (defined($b->{ADVANCED}) &&
					 $b->{ADVANCED}) ||
					   ($b->{REQUIRED} || $b->{TTREQD}) <=>
					     ($a->{REQUIRED} || $a->{TTREQD}) ||
					       (join('|',@{$b->{OPTFLAG}}) eq
						$combo_flag) <=>
						  (join('|',@{$a->{OPTFLAG}}) eq
						   $combo_flag) ||
						     $pos_hash->{$a} <=>
						       $pos_hash->{$b}}
			    @$usage_array)
      {
	my $short_flags = getUsageFlags($usage_hash,1);
	my $long_flags  = getUsageFlags($usage_hash);
	my $short_desc  = $usage_hash->{SUMMARY};
	my $long_desc   = $usage_hash->{DETAILS};
	#If the enum values are too long to be displayed in the flags column &
	#were truncated (i.e. replaced with an ellipsis)
	if($usage_hash->{OPTTYPE} =~ /enum/ && $long_flags =~ /\.{3}>/)
	  {
	    my $enumvals = join(',',@{$usage_hash->{ACCEPTS}});
	    $long_desc .= "\n\nFull list of acceptable values: [$enumvals].";
	  }
	#If the array value delimiter is multi-character or otherwise does not
	#match a display value and the description doesn't mention 'delim',
	#append the delimiter pattern
	if($usage_hash->{OPTTYPE} =~ /_array/ && $long_desc !~ /delim/i)
	  {
	    my $disp_delim = getDisplayDelimiter($usage_hash->{DELIMITER},
						 $usage_hash->{OPTTYPE},
						 $usage_hash->{ACCEPTS});

	    if(defined($disp_delim) && length($disp_delim) > 1)
	      {
		my $qm = quotemeta($disp_delim);
		#This assumes the presence of any regular expression character
		#means it's a regular expression
		$long_desc .= "\n\nDelimiting " .
		  ($qm ne $disp_delim ? 'pattern' : 'string') .
		    ": [$disp_delim].";
	      }
	  }

	my $required = '';
	if((exists($usage_hash->{REQUIRED}) &&
	    defined($usage_hash->{REQUIRED}) && $usage_hash->{REQUIRED}) ||
	   #Indiv. opts are made optional when in a tagteam, so we must check:
	   $usage_hash->{TTREQD})
	  {
	    if(hasDefinedDefault($usage_hash))
	      {$required = '~'}
	    #1 of 2 tagteam options is required and 1 is hidden
	    elsif($usage_hash->{TTREQD} && $usage_hash->{TTHIDN})
	      {$required = '*'}
	    #1 of 2 tagteam options is required and 0 or 2 are hidden
	    elsif($usage_hash->{TTREQD} && !$usage_hash->{TTHIDN})
	      {$required = '^'}
	    else
	      {$required = '*'}
	  }

	#Add the default string if it's defined and not already manually added
	#to the short description
	my $default  = displayDefault($usage_hash);
	if($default ne '' && defined($short_desc) && $short_desc ne '' &&
	   $short_desc !~ /^\[/)
	  {
	    $short_desc = $default . $short_desc;

	    if($short_desc =~ /^\[[^\]\}]*\]\s*\{[^\}]*\}/ &&
	       $short_desc !~ /^\[[^\]\}]*\]\s*\{[^\}]*\}\s/)
	      {$short_desc =~ s/\}\s*/\} /}
	    elsif($short_desc =~ /^\[[^\]]*\]\s*[^\{]/ &&
	       $short_desc !~ /^\[[^\]]*\]\s/)
	      {$short_desc =~ s/\]\s*/\] /}
	  }

	#Add the default string if it's defined and not already manually added
	#to the long description
	if($default ne '' && $long_desc !~ /^\[/)
	  {
	    $long_desc = $default . $long_desc;

	    if($long_desc =~ /^\[[^\]\}]*\]\s*\{[^\}]*\}/ &&
	       $long_desc !~ /^\[[^\]\}]*\]\s*\{[^\}]*\}\s/)
	      {$long_desc =~ s/\}\s*/\} /}
	    elsif($long_desc =~ /^\[[^\]]*\]\s*[^\{]/ &&
	       $long_desc !~ /^\[[^\]]*\]\s/)
	      {$long_desc =~ s/\]\s*/\] /}
	  }

	if(!$advanced_header && $usage_hash->{ADVANCED} &&
	   ((defined($long_desc) && $long_desc ne '') ||
	    (defined($short_desc) && $short_desc ne '')))
	  {
	    $advanced_header = 1;
	    $long .= "ADVANCED\n\n";
	  }

	if($advanced_header && $usage_hash->{GETOPTKEY} eq 'extended:+')
	  {$long .= "\n"}

	if(defined($short_desc) && $short_desc ne '')
	  {$short .= alignCols([$required,$short_flags,$short_desc],
			       [1,$short_flag_col_width],
			       [0,1,2],
			       [0,2,0])}
	if(defined($long_desc) && $long_desc ne '')
	  {$long .= alignCols([$required,$long_flags,$long_desc],
			      [1,$long_flag_col_width],
			      [0,1,2],
			      [0,2,0]) . "\n"}
	elsif(defined($short_desc) && $short_desc ne '')
	  {$long .= alignCols([$required,$long_flags,$short_desc],
			      [1,$long_flag_col_width],
			      [0,1,2],
			      [0,2,0]) . "\n"}
      }

    $short .= "\n";

    return($short,$long);
  }

##TODO: Add support for setting multiple times. (Currently only called by usage/
##      help.)
sub getWindowWidth
  {
    if(!defined($window_width))
      {
	$window_width = $window_width_def;
	#If the output is piped, or to a file, return the default
	if(isStandardOutputToTerminal())
	  {
	    eval('use Term::ReadKey;1') || return($window_width);
	    $window_width = (GetTerminalSize())[0];
	  }
	return($window_width);
      }
    return($window_width);
  }

sub getUsageFlagColWidths
  {
    my $max_flag_col_width   = 24;
    my $short_flag_col_width = 0;
    my $long_flag_col_width  = 0;

    foreach my $usage_hash (grep {(!$_->{HIDDEN} && !$_->{ADVANCED}) ||
				    ($_->{HIDDEN} && $extended > 2) ||
				       ($_->{ADVANCED} && !$_->{HIDDEN} &&
					$extended > 1)} @$usage_array)
      {
	my $short_flags = getUsageFlags($usage_hash,1);
	my $long_flags  = getUsageFlags($usage_hash);

	if(defined($usage_hash->{SUMMARY}) && $usage_hash->{SUMMARY} ne '' &&
	   length($short_flags) > $short_flag_col_width)
	  {$short_flag_col_width = length($short_flags)}

	if($long_flag_col_width < $max_flag_col_width)
	  {
	    foreach my $long_flag (split(/\n/,$long_flags))
	      {
		if(length($long_flag) > $long_flag_col_width)
		  {
		    $long_flag_col_width = length($long_flag);
		    last if($long_flag_col_width >= $max_flag_col_width);
		  }
	      }
	  }

	last if($long_flag_col_width  >= $max_flag_col_width &&
	        $short_flag_col_width >= $max_flag_col_width);
      }

    if($long_flag_col_width >= $max_flag_col_width)
      {$long_flag_col_width = $max_flag_col_width}
    if($short_flag_col_width >= $max_flag_col_width)
      {$short_flag_col_width = $max_flag_col_width}

    return($short_flag_col_width,$long_flag_col_width);
  }

#Takes the usage hash of 1 option and returns the flags with arguments as they
#are to be displayed in the detailed usage output.
#Globals used: $extended,$GetOptHash
sub getUsageFlags
  {
    my $usghash = $_[0];
    my $minmode = $_[1];

    #Prepare the list of flags
    my @flaglist = @{$usghash->{OPTFLAG}};
    if($usghash->{FLAGLESS})
      {unshift(@flaglist,'')}

    my $flagstr =
      join("\n",
	   map {
	     #append a space unless it's an empty string.  This allows us to
	     #process the flagless options the same as the flagged options
	     $_ .= ($_ eq '' ? '' : ' ');

	     #Prepare the enumeration string
	     my $en = '';
	     if($usghash->{OPTTYPE} =~ /enum/)
	       {
		 $en = join(',',@{$usghash->{ACCEPTS}});
		 if(length($en) > 60)
		   {$en =~ s/(.{57})/$1.../}
	       }

	     my $dl = '';
	     if($usghash->{OPTTYPE} =~ /_array/)
	       {
		 $dl = getDisplayDelimiter($usghash->{DELIMITER},
					   $usghash->{OPTTYPE},
					   $usghash->{ACCEPTS});
		 if(defined($dl))
		   {
		     if(length($dl) > 1)
		       {$dl = '...'}
		     else
		       {$dl = "$dl..."}
		   }
		 else
		   {$dl = ''}
	       }

	     if($usghash->{OPTTYPE} eq 'bool')
	       {
		 s/ $//;
		 $_;
	       }
	     elsif($usghash->{OPTTYPE} eq 'negbool')
	       {
		 s/ $//;
		 my $f  = $_;
		 my $nf = $_;
		 $nf =~ s/^-+//;
		 #If flag is 1 character or already has dashes, prepend w/ dash
		 if($nf =~ /-/ || length($nf) == 1)
		   {$nf = "--no-$nf"}
		 else
		   {$nf = "--no$nf"}
		 my $def = ${$GetOptHash->{$usghash->{GETOPTKEY}}};
		 if(!defined($def))
		   {($f,$nf)}
		 elsif($def)
		   {$nf}
		 else
		   {$f}
	       }
	     elsif($usghash->{OPTTYPE} eq 'count')
	       {$_ . "[<cnt>]"}
	     elsif($usghash->{OPTTYPE} eq 'string')
	       {"$_<str>"}
	     elsif($usghash->{OPTTYPE} eq 'integer')
	       {"$_<int>"}
	     elsif($usghash->{OPTTYPE} eq 'float')
	       {"$_<flt>"}
	     elsif($usghash->{OPTTYPE} eq 'enum')
	       {"$_<$en>"}

	     elsif($usghash->{OPTTYPE} eq 'string_array' ||
		   $usghash->{OPTTYPE} eq 'string_array2d')
	       {"$_<str$dl>..."}
	     elsif($usghash->{OPTTYPE} eq 'integer_array' ||
		   $usghash->{OPTTYPE} eq 'integer_array2d')
	       {"$_<int$dl>..."}
	     elsif($usghash->{OPTTYPE} eq 'float_array' ||
		   $usghash->{OPTTYPE} eq 'float_array2d')
	       {"$_<flt$dl>..."}
	     elsif($usghash->{OPTTYPE} eq 'enum_array' ||
		   $usghash->{OPTTYPE} eq 'enum_array2d')
	       {"$_<{$en}$dl>..."}

	     elsif($usghash->{OPTTYPE} eq 'infile' ||
		   $usghash->{OPTTYPE} eq 'outfile')
	       {"$_<file*...>..."}
	     elsif($usghash->{OPTTYPE} eq 'outdir')
	       {"$_<dir*...>..."}
	     elsif($usghash->{OPTTYPE} eq 'suffix')
	       {"$_<sfx>"}
	     else
	       {"$_ ?ERROR?"}
	   } @flaglist) .

	     #Append stdin & stub/dash for primary/non-primary input files
	     ($usghash->{OPTTYPE} eq 'infile' ?
	      ($usghash->{PRIMARY} ? "\n< <file>\n" .
	       getDefaultFlag($usghash->{OPTFLAG}) . ' <stub> < <file>' :
	       "\n" . getDefaultFlag($usghash->{OPTFLAG}) .
	       ' - < <file>') : '') .

		 ($usghash->{HIDDEN} ? "\n[HIDDEN-OPTION]" : '');

    if($minmode)
      {$flagstr =~ s/\n.*//s}

    debug({LEVEL => -1},"Returning flagstr: [$flagstr].");

    return($flagstr);
  }

sub showDefault
  {
    my $type    = $_[0];
    my $ref     = $_[1];
    my $default = $_[2];

    if($type ne 'bool' && $type ne 'negbool' && $type ne 'count')
      {return(1)}
    elsif($type eq 'bool')
      {return(defined($default) && $default ne '' && $default ne '0')}
    elsif($type eq 'negbool') #Only show a negatable boolean's def if the
                              #default is defined and the value is undefined
      {return(defined($default) && (!defined($ref) || !defined($$ref)))}
    elsif($type eq 'count')   #Only show a count's def if it's non-0
      {return(defined($default) && $default != 0)}

    return(1);
  }

#Globals used: $GetOptHash
sub displayDefault
  {
    my $usage_hash = $_[0];
    my $disp = '';
    if(showDefault($usage_hash->{OPTTYPE},
                   $GetOptHash->{$usage_hash->{GETOPTKEY}},
                   $usage_hash->{DEFAULT}))
      {
        my $undef    = '';
        my $emptystr = '[]';

        #Empty string defaults for these types make no sense and imply the
        #default is undefined, so don't display square brackets
        if($usage_hash->{OPTTYPE} =~ /file/ ||
           $usage_hash->{OPTTYPE} =~ /suffix/ ||
           $usage_hash->{OPTTYPE} =~ /integer/ ||
           $usage_hash->{OPTTYPE} =~ /float/ ||
           $usage_hash->{OPTTYPE} =~ /enum/ ||
           $usage_hash->{OPTTYPE} eq 'outdir')
          {$emptystr = ''}

        if(defined($usage_hash->{DEFAULT}))
          {
            if($usage_hash->{DEFAULT} eq '')
              {
                if(defined($GetOptHash->{$usage_hash->{GETOPTKEY}}))
                  {$disp = $emptystr}
                else
                  {$disp = $undef}
              }
            else
              {$disp = "[$usage_hash->{DEFAULT}]"}
          }
        else
          {$disp = $undef}
      }

    return($disp);
  }

#$usage_hash->{DEFAULT} is only for display purposes. This sub checks the actual
#default value either in the reference variable or the default saved elsewhere
sub hasDefinedDefault
  {
    my $usage_hash = $_[0];

    #For now, we will assume that the display default having a defined value
    #that's not an empty string means that there really is a default set (which
    #may not be true)
    ##TODO: Check the actual default, which includes checking things like the
    #default_infiles_array, etc.
    if(defined($usage_hash->{DEFAULT}) && $usage_hash->{DEFAULT} ne '')
      {return(1)}

    return(0);
  }

#Globals used: $help_summary, $advanced_help, $extended
sub customHelp
  {
    my $ignore = defined($_[0]) ? $_[0] : 0;  #Ignore unset FORMAT descriptions
    my $local_extended = (defined($_[1]) ? $_[1] :               #Advanced help
			  (defined($extended) ? $extended : 0));

    my $out = '';

    my $summary_flag = 'WHAT IS THIS:';
    my $summary = (defined($help_summary) ? $help_summary :
		   join('','No script description available.'));

    $out .= alignCols(['*',$summary_flag,$summary],
		      [1,14],
		      [0,1,2],
		      [0,0,0]) . "\n" if(defined($help_summary) || !$ignore);

    #Now let's construct the custom advanced help string.
    if($local_extended && defined($advanced_help) && $advanced_help ne '')
      {
	$out .= alignCols(['*','DETAILS:',$advanced_help],
			  [1,14],
			  [0,1,2],
			  [0,0,0]) . "\n";
      }

    #For each input file type that is not hidden or is primary (of which there
    #can be only 1, BTW)
    foreach my $usage_hash (grep {$_->{OPTTYPE} eq 'infile' &&
				    ($local_extended > 1 || !$_->{HIDDEN} ||
				     $_->{PRIMARY})}
			    @$usage_array)
      {
	my $flag = "INPUT FORMAT:\n" . join(',',@{$usage_hash->{OPTFLAG}});
	if($usage_hash->{HIDDEN} && $usage_hash->{PRIMARY})
	  {
	    $flag = "STDIN FORMAT:";
	    #Include the hidden flags if extended > 1
	    if($local_extended > 1)
	      {$flag .= "\n" . join(',',@{$usage_hash->{OPTFLAG}})}
	    if($usage_hash->{HIDDEN})
	      {$flag .= ($usage_hash->{FLAGLESS} || $local_extended <= 1 ?
			 "\n" : ',') . '[HIDDEN-OPTION]'}
	  }
	elsif($usage_hash->{HIDDEN})
	  {$flag .= ($usage_hash->{FLAGLESS} ? '' : ',') . '[HIDDEN-OPTION]'}

	my $desc = $usage_hash->{FORMAT};
	if(!defined($desc) || $desc eq '')
	  {
	    next if($ignore);
	    $desc = join('','No format description available.');
	  }

	$out .= alignCols(['*',$flag,$desc],
			  [1,14],
			  [0,1,2],
			  [0,0,0]) . "\n";
      }

    #Keep track of the tagteam output options that have been processed
    my $seen_ttids = {};

    #For each output file type that is either part of a tagteam, is not hidden,
    #or is primary.  (We'll worry about hidden tagteams inside the loop.)
    foreach my $usage_hash (grep {($_->{OPTTYPE} eq 'outfile' ||
				   $_->{OPTTYPE} eq 'suffix') &&
				     ($_->{TAGTEAM} || !$_->{HIDDEN} ||
				      $_->{PRIMARY} || $local_extended > 1)}
			    @$usage_array)
      {
	#If this is a suffix linked to an outfile type, skip it completely -
	#This is just an internal way of code re-use
	if($usage_hash->{HIDDEN} && $usage_hash->{OPTTYPE} eq 'suffix')
	  {
	    my $file_type_id = $suffix_id_lookup->[$usage_hash->{FILEID}]->[0];
	    if(exists($outfile_types_hash->{$file_type_id}))
	      {next}
	  }

	#If this option is a part of a tagteam
	if($usage_hash->{TAGTEAM})
	  {
	    my $ttid = $usage_hash->{TAGTEAMID};

	    #If this tagteam has already been done, skip it
	    next if(exists($seen_ttids->{$ttid}));
	    $seen_ttids->{$ttid}++;

	    #Obtain the usage information from the tagteam hash
	    $usage_hash = $outfile_tagteams->{$ttid};

	    #The tagteam usage hash has its own hidden value (if both of its
	    #options are hidden), so we need to check HIDDEN again
	    next if($usage_hash->{HIDDEN} && !$usage_hash->{PRIMARY});
	  }

	my $flag = '';

	#Create the section title in the header
	if($usage_hash->{HIDDEN} && $usage_hash->{PRIMARY})
	  {$flag .= "STDOUT FORMAT:"}
	else
	  {$flag .= "OUTPUT FORMAT:"}

	#Append the flags to the header as a sub-title if not hidden
	if(!$usage_hash->{HIDDEN} || $local_extended > 1)
	  {$flag .= "\n" . join(',',@{$usage_hash->{OPTFLAG}})}
	if($usage_hash->{HIDDEN})
	  {$flag .= "\n[HIDDEN-OPTION]"}

	my $desc = $usage_hash->{FORMAT};

	if(!defined($desc) || $desc eq '')
	  {
	    next if($ignore);
	    $desc = join('',('The author of this script has not provided ',
			     'a format description for this output file ',
			     'type.  Please add a description using one of ',
			     'the addOutfileOption or addOutfileSuffixOption ',
			     'methods.'));
	  }

	$out .= alignCols(['*',$flag,$desc],
			  [1,14],
			  [0,1,2],
			  [0,0,0]) . "\n";
      }

    return($out);
  }

sub sum
  {
    my $sum = 0;
    $sum += $_ foreach(@_);
    return($sum);
  }

sub alignCols
  {
    my $column_vals  = $_[0]; #array - 1 row, but cells may have hard returns
    my $col_widths   = $_[1]; #array - may leave off last col or all but 1
    my $gap_widths   = $_[2]; #array - starts with the indent size
    my $wrap_indents = $_[3]; #array - soft-wrap indent sizes

    my $term_width = getWindowWidth();

    #Validate the gap widths
    if(!defined($gap_widths))
      {$gap_widths = [0,map {1} 1..$#{$column_vals}]}
    elsif(scalar(@$gap_widths) == 1)
      {
	if(scalar(@$column_vals) > 1)
	  {
	    my $tmp = $gap_widths->[0];
	    $gap_widths = [0,map {$tmp} 1..$#{$column_vals}];
	  }
      }
    elsif(scalar(@$gap_widths) == $#{$column_vals})
      {unshift(@$gap_widths,0)}
    elsif(scalar(@$gap_widths) != scalar(@$column_vals))
      {
	error("Invalid number of gap widths [",scalar(@$gap_widths),
	      "] versus number of column values: [",scalar(@$column_vals),"].");
	return('');
      }

    #Validate the column widths
    if(scalar(@$column_vals) != scalar(@$col_widths))
      {
	if($#{$column_vals} == scalar(@$col_widths))
	  {push(@$col_widths,$term_width - sum(@$col_widths,@$gap_widths))}
	elsif(scalar(@$col_widths) == 1)
	  {
	    my $tmp = $col_widths->[0];
	    $col_widths = [(map {$tmp} 1..$#{$column_vals}),
			   $term_width - sum(@$col_widths,@$gap_widths)];
	  }
	else
	  {
	    error("Invalid number of column widths [",scalar(@$col_widths),"] ",
		  "versus number of column values [",scalar(@$column_vals),
		  "].");
	    return('');
	  }

	if($col_widths->[-1] < 1)
	  {
	    warning("Window width [$term_width] too small for specified ",
		    "column widths [",
		    join(',',(@$col_widths)[0..($#{$col_widths}-1)]),"].",
		    {DETAIL => 'No room is left for the last column'});
	    return('');
	  }
      }

    #Validate the soft-wrap indents
    if(!defined($wrap_indents))
      {$wrap_indents = [map {0} 0..$#{$column_vals}]}
    elsif(scalar(@$wrap_indents) < scalar(@$column_vals))
      {
	while(scalar(@$wrap_indents) < scalar(@$column_vals))
	  {push(@$wrap_indents,0)}
      }
    elsif(scalar(@$wrap_indents) > scalar(@$column_vals))
      {
	error("Invalid number of soft-wrap indents [",scalar(@$wrap_indents),
	      "] versus number of column values: [",scalar(@$column_vals),"].");
	return('');
      }

    my($line,$out);
    my @remainders = @$column_vals;
    while(scalar(grep {$_ ne ''} @remainders))
      {
	$line = '';

	foreach my $index (0..$#{$column_vals})
	  {
	    my $remainder   = $remainders[$index];
	    my $gap_width   = $gap_widths->[$index];
	    my $col_width   = $col_widths->[$index];
	    my $wrap_indent = $wrap_indents->[$index];

	    if($index > 0)
	      {
		#Append spaces to fill up to the current column
		$line .= ' ' x (sum((@$col_widths)[0..($index - 1)],
				    (@$gap_widths)[0..($index - 1)]) -
				length($line));
	      }

	    #Add the gap
	    $line .= ' ' x $gap_width;

	    if(length($remainder) > $col_width ||
	       $remainder !~ /^[^\n]{$col_width}\n./s)
	      {
		my $soft_wrap = 1;
		my $current = substr($remainder,0,$col_width);
		my $next_char =
		  length($remainder) > $col_width ?
		    substr($remainder,$col_width,1) : '';
		my $added_hyphen = 0;
		if($current =~ /^[^\n]*\n\n/)
		  {
		    $current =~ s/(?<=\n)\n.*//s;
		    $soft_wrap = 0;
		  }
		elsif($current =~ /\n/)
		  {
		    $current =~ s/(?<=\n).*//s;
		    $soft_wrap = 0;
		  }
		elsif(#The random chop didn't just happened to be a valid spot
		      $next_char ne "\n" && $next_char ne '' &&
		      $next_char ne ' ' &&
		      !($current =~ /(?<!-)-$/ && $next_char =~ /[a-zA-Z]/))
		  {
		    #$current =~ s/(.*)\b\{lb}\s*\S+/$1/;
		    if(length($current) == $col_width)
		      {
			my($dashwrap,$commawrap,$spacewrap);
			$dashwrap = $commawrap = $spacewrap = $current;

			#Try to break up the current cell value at the last
			#dash, if one exists that's between letters of a
			#reasonable-long word (don't break on really-long words,
			#which might be aligned DNA or some other block of
			#characters)
			$dashwrap =~ s/(.*[a-zA-Z]-)(?=[a-zA-Z])\S{1,20}$/$1/;

			#Try to break up the current cell value at the last
			#comma, if one exists and is not followed by any of the
			#following: close-bracket, comma, quote, colon, dot, or
			#semicolon
			my $nowrapcomma = '[\.,\'";:\)\]\}\>]';
			$commawrap =~ s/(.*[^,],)(?!$nowrapcomma)\S.*/$1/;

			#Unless the string ends with spaces
			unless($spacewrap =~ s/\s+$//)
			  {
			    #Try to break up the current cell value at the last
			    #space, if one exists that's not followed by
			    #something that looks longer than a real word or a
			    #line- or thought-ending character, like a period,
			    #close-bracket, colon, comma, semicolon, exclamation
			    #point - or event what may be considered a footnote,
			    #like asterisk, up-arrow, or tilde.
			    my $nowrapspc = '[\.,;:\)\]\}\>\!\*\^\~]';
			    $spacewrap =~
			      s/(.*\S)\s+((?!$nowrapspc)\S.{0,20})$/$1/;
			  }

			#If both were trimmed
			if(length($dashwrap) < length($current) &&
			   length($commawrap) < length($current))
			  {
			    #Keep the longer one
			    $current = (length($dashwrap) > length($commawrap) ?
					$dashwrap : $commawrap);
			  }
			elsif(length($dashwrap) < length($current))
			  {$current = $dashwrap}
			else
			  {$current = $commawrap}

			if(length($spacewrap) < $col_width &&
			   (length($current) == $col_width ||
			    length($spacewrap) > length($current)))
			  {$current = $spacewrap}
		      }
		    if(length($current) == $col_width && $col_width > 1 &&
		       $current !~ /\s$/ && $current !~ /^\s/)
		      {
			#Force a dash if valid
			if($current =~ s/[A-Za-z]$/-/)
			  {$added_hyphen = 1}
		      }
		  }

		if(length($current) == $col_width && $next_char eq "\n")
		  {$soft_wrap = 0}

		$current =~ s/[ \t]+$//;
		#If the line was empty (i.e. the only character was \n)
		if($current eq '')
		  {
		    if($remainder =~ /^\n(.*)/s)
		      {$remainder = $1}
		  }
		else
		  {
		    my $pattern = $current;
		    chop($pattern) if($added_hyphen);
		    if($remainder =~ /\Q$pattern\E *(.*)/s)
		      {
			$remainder = $1;
			$remainder =~ s/^ *// unless($current =~ /\n/);
			if($soft_wrap && $wrap_indent && length($remainder) &&
			   $remainder ne "\n")
			  {$remainder = (' ' x $wrap_indent) . $remainder}
			chomp($current);
		      }
		  }

		if(length($current) == $col_width && $next_char eq "\n")
		  {$remainder =~ s/^\n//}

		debug("Next portion colidx [$index]: [$current]\n",
		      "Remainder: [$remainder].",{LEVEL => -1});

		$line .= $current;
	      }
	    else
	      {
		debug("Next portion colidx [$index]: [$remainder]\n",
		      "Remainder: [].",{LEVEL => -1});

		$line .= $remainder;
		$remainder = '';
	      }

	    if($index == $#{$column_vals})
	      {$line =~ s/\s*$/\n/s}

	    $remainders[$index] = $remainder;
	  }

	$out .= $line;
      }

    $out =~ s/\s*$/\n/;

    debug({LEVEL => -1},"Returning: [$out]");

    return($out);
  }

sub getSummaryUsageOptStr
  {
    my $local_extended = scalar(@_) > 0 && defined($_[0]) ? $_[0] :
      (defined($extended) ? $extended : 0);

    my $script = $0;
    $script =~ s/^.*\/([^\/]+)$/$1/;

    my $optionals          = 'OPTIONS';
    my $optionals_wo_prim  = 'OPTIONS';
    my $requireds          = '';
    my $requireds_wo_prim  = '';
    my $primary_inf_exists = 0;
    my $primary_hidden     = 0;
    my $first_reqd         = 1;

    #Add visible options
    foreach my $usage_hash (grep {!defined($_->{HIDDEN}) ||
				    !$_->{HIDDEN} ||
				      ($_->{HIDDEN} &&
				       $_->{OPTTYPE} eq 'infile' &&
				       $_->{PRIMARY})}
			    @$usage_array)
      {
	my $prim = 0;
	#If this is an input file type and it is primary
	if($usage_hash->{OPTTYPE} eq 'infile' &&
	   exists($usage_hash->{PRIMARY}) &&
	   defined($usage_hash->{PRIMARY}) && $usage_hash->{PRIMARY})
	  {
	    $primary_inf_exists = 1;
	    $prim               = 1;
	    $primary_hidden     = $usage_hash->{HIDDEN};
	  }

	next if(exists($usage_hash->{HIDDEN}) &&
		defined($usage_hash->{HIDDEN}) && $usage_hash->{HIDDEN});

	my $flag = getDefaultFlag($usage_hash->{OPTFLAG});
	if($usage_hash->{OPTTYPE} eq 'negbool')
	  {
	    my $def = ${$GetOptHash->{$usage_hash->{GETOPTKEY}}};
	    if(!defined($def))
	      {$flag =~ s/^-+/--[no]/}
	    elsif($def)
	      {
		my $nf = $flag;
		$nf =~ s/^-+//;
		$nf = "--no$nf";
		$flag = $nf;
	      }
	  }

	#Add to the required options string
	if(defined($usage_hash->{REQUIRED}) && $usage_hash->{REQUIRED})
	  {
	    $requireds .= ($first_reqd ? '' : ' ') . $flag;
	    if(!$prim)
	      {$requireds_wo_prim .= ($first_reqd ? '' : ' ') . $flag}

	    #Add a required input file's example argument
	    if($usage_hash->{OPTTYPE} eq 'infile')
	      {
		$requireds .= " <file*...>...";
		$requireds_wo_prim .= " <file*...>..." unless($prim);
	      }
	    #Add a required output file's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'outfile')
	      {
		$requireds .= " <file*...>...";
		$requireds_wo_prim .= " <file*...>...";
	      }
	    #Add a required output file's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'suffix')
	      {
		$requireds .= " <sfx>";
		$requireds_wo_prim .= " <sfx>";
	      }
	    #Add a required output directory's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'outdir')
	      {
		$requireds .= " <dir*...>";
		$requireds_wo_prim .= " <dir*...>";
	      }
	    #Add a required integer array option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'integer_array')
	      {
		$requireds .= " <int...>";
		$requireds_wo_prim .= " <int...>";
	      }
	    #Add a required float array option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'float_array')
	      {
		$requireds .= " <flt...>";
		$requireds_wo_prim .= " <flt...>";
	      }
	    #Add a required string array option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'string_array')
	      {
		$requireds .= " <str...>";
		$requireds_wo_prim .= " <str...>";
	      }
	    #Add a required enum array option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'enum_array')
	      {
		my $acc = $usage_hash->{ACCEPTS};
		if(defined($acc) && ref($acc) eq 'ARRAY' && scalar(@$acc))
		  {
		    $acc = join('|',@$acc);
		    if(length($acc) > 20)
		      {$acc =~ s/(.{17}).*/$1.../}
		  }
		else
		  {$acc = 'str'}
		$requireds .= " <$acc...>";
		$requireds_wo_prim .= " <$acc...>";
	      }
	    #Add a required integer array option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'integer_array2d')
	      {
		$requireds .= " <int...>...";
		$requireds_wo_prim .= " <int...>...";
	      }
	    #Add a required float array option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'float_array2d')
	      {
		$requireds .= " <flt...>...";
		$requireds_wo_prim .= " <flt...>...";
	      }
	    #Add a required string array option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'string_array2d')
	      {
		$requireds .= " <str...>...";
		$requireds_wo_prim .= " <str...>...";
	      }
	    #Add a required enum array option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'enum_array2d')
	      {
		my $acc = $usage_hash->{ACCEPTS};
		if(defined($acc) && ref($acc) eq 'ARRAY' && scalar(@$acc))
		  {
		    $acc = join('|',@$acc);
		    if(length($acc) > 20)
		      {$acc =~ s/(.{17}).*/$1.../}
		  }
		else
		  {$acc = 'str'}
		$requireds .= " <$acc...>...";
		$requireds_wo_prim .= " <$acc...>...";
	      }
	    #Add a required negatable boolean option's negation
	    elsif($usage_hash->{OPTTYPE} eq 'negbool')
	      {
		my $neg = $flag;
		$neg =~ s/^-+/--no/;
		my $od = ${$GetOptHash->{$usage_hash->{GETOPTKEY}}};
		my($of);
		if(!defined($od))
		  {$of = $flag}
		elsif($od)
		  {$of = $neg}
		else
		  {$of = $flag}
		$requireds .= $of;
		$requireds_wo_prim .= $of;
	      }
	    #Add a required count option's example optional argument
	    elsif($usage_hash->{OPTTYPE} eq 'count')
	      {
		$requireds .= " [<cnt>]";
		$requireds_wo_prim .= " [<cnt>]";
	      }
	    #Add a required integer option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'integer')
	      {
		$requireds .= " <int>";
		$requireds_wo_prim .= " <int>";
	      }
	    #Add a required float option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'float')
	      {
		$requireds .= " <flt>";
		$requireds_wo_prim .= " <flt>";
	      }
	    #Add a required string option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'enum')
	      {
		my $acc = $usage_hash->{ACCEPTS};
		if(defined($acc) && ref($acc) eq 'ARRAY' && scalar(@$acc))
		  {
		    $acc = join('|',@$acc);
		    if(length($acc) > 20)
		      {$acc =~ s/(.{17}).*/$1.../}
		    $acc = "<$acc>";
		  }
		else
		  {$acc = 'str'}
		$requireds .= " $acc";
		$requireds_wo_prim .= " $acc";
	      }
	    #Add a required string option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'string')
	      {
		$requireds .= " <str>";
		$requireds_wo_prim .= " <str>";
	      }
	    #Add a required unknown option's example argument
	    elsif($usage_hash->{OPTTYPE} eq 'unk')
	      {
		$requireds .= " <val>";
		$requireds_wo_prim .= " <val>";
	      }
	    $first_reqd = 0;
	  }
      }

    #Hidden only refers to the flags and thus the usage entries.  If a primary
    #infile option is hidden, this summary string is the only indication that
    #the script can take anything on STDIN.
    my $summary_str = (!$primary_inf_exists ||
		       ($primary_inf_exists && !$primary_hidden) ?
		       "$script " . ($requireds ne '' ? "$requireds " : '') .
		       "[$optionals]\n" : '');
    if(($local_extended && $primary_inf_exists) ||
       ($primary_inf_exists && $primary_hidden))
      {$summary_str .= "$script " . ($requireds_wo_prim ne '' ?
				     "$requireds_wo_prim " : '') .
				       "[$optionals_wo_prim] < input_file\n"}
    $summary_str .= "\n";

    return($summary_str);
  }

##
## This method prints a usage statement in long or short form depending on
## whether "no descriptions" is true.
##
#Globals used: $extended, $GetOptHash, $explicit_quit
sub usage
  {
    my @in = getSubParams([qw(ERROR_MODE EXTENDED)],[],[@_]);
    my $error_mode     = $in[0]; #Don't print full usage in error mode
    my $local_extended = scalar(@in) > 1 && defined($in[1]) ? $in[1] :
      (defined($extended) ? $extended : 0);

    unless($processCommandLine_called)
      {processCommandLine()}

    debug({LEVEL => -1},"Value of usage: [$usage].");

    #Don't print a usage after quit has been called unless $usage == 1
    if($explicit_quit && $usage != 1)
      {return(0)}

    print(($error_mode ? "\n" : ''),getSummaryUsageOptStr($local_extended));

    #Obtain the custom user options
    my($short,$long) = customUsage();

    if($error_mode)
      {print("Run with ",($default_run_mode eq 'usage' ?
			  "no options" : '--usage'),
	     " for usage.\n")}
    else
      {
	if(!$local_extended)
	  {print($short)}
	else #Advanced options/extended usage output
	  {print($long)}

	if($short =~ /^\*/ || $long =~ /^\*/)
	  {print("* Required.\n")}
	if($short =~ /^~/ || $long =~ /^~/)
	  {print("~ Required (but has default).\n")}
	if($short =~ /^\^/ || $long =~ /^\^/)
	  {print("^ 1 of 2 mutually exclusive options required.\n")}
      }

    return(0);
  }

BEGIN
  {
    #Enable export of subs & vars
    require Exporter;
    our @ISA       = qw(Exporter);
    our @EXPORT    = qw(openIn                       openOut
			closeIn                      closeOut
			getLine                      verbose
			verboseOverMe                quit
			error                        warning
			debug                        nextFileCombo
			getInfile                    getOutfile
			addInfileOption              addOutfileSuffixOption
			addOutdirOption              addOutfileOption
			addOption                    addOutfileTagteamOption
			addOptions                   addArrayOption
			add2DArrayOption             getOutHandleFileName
			getNextFileGroup             getAllFileGroups
			getNumFileGroups             getFileGroupSizes
                        setScriptInfo                getInHandleFileName
                        processCommandLine           resetFileGroupIterator
                        isForced                     headerRequested
                        isDryRun                     setDefaults
                        isDebug                      isVerbose);
    our @EXPORT_OK = qw(markTime                     getCommand
			sglob                        getVersion
			isThereInputOnSTDIN          isStandardOutputToTerminal
			printRunReport               getHeader
			flushStderrBuffer            inPipeline
                        usage                        help);

    _init();

    #This allows us to track runtime warnings about undefined variables, etc.
    $SIG{__WARN__} = sub {warning("Runtime warning: [",@_,"].")};
    $SIG{__DIE__}  = sub {@$compile_err = @_};
  }

END
  {
    #If the user did not call quit explicitly or force is defined and true
    if(!$explicit_quit || (defined($force) && $force))
      {
	#We're definitely quitting, so if force is undefined or true, set false
	$force = 0 if(!defined($force) || $force);

	#Unless there was a compilation error, quit cleanly.
	#Note that the error is already printed and the error() method has
	#likely not been compiled yet
	if(defined($compile_err) && scalar(@$compile_err) &&
	   (!defined($command_line_processed) || $command_line_processed < 2))
	  {print STDERR ("CommandLineInterface: Unable to complete set up.\n")}
	elsif(!defined($cleanup_mode) || !$cleanup_mode)
	  {quit(0)}
      }
  }

=head1 NAME

CommandLineInterface - Give your script the behaviors of a unix builtin tool.

=head1 SYNOPSIS

CommandLineInterface allows you to instantly give any script a unix-like command-line interface.

=head2 EXAMPLE 1 - SIMPLE USAGE

    #cat.pl
    use CommandLineInterface;
    while(my $inputFile = getInfile())
      {
        my $outputFile = getOutfile();
        openOut(*OUT,$outputFile);
        openIn(*IN,$inputFile) || next;
        while(getLine(*IN))
          {print}
        closeIn(*IN);
        closeOut(*OUT);
      }

    #USAGE
    #>cat.pl --verbose -i in.txt -o .out -- plus usage, redirect, adv opts, etc

=head2 EXAMPLE 2 - COMMON USAGE

    #catpairs.pl
    use CommandLineInterface;
    setScriptInfo(VERSION => '1.0',
                  CREATED => '9/25/2016',
                  AUTHOR  => 'Robert Leach',
                  CONTACT => 'rleach@princeton.edu',
                  COMPANY => 'Princeton University',
                  LICENSE => 'Copyright 2018',
                  HELP    => 'Concatenates pairs of files.');

    my $filetype1 = addInfileOption(FLAG       => 'i',
                                    REQUIRED   => 1,
                                    DEFAULT    => undef,
                                    PRIMARY    => 1,
                                    SHORT_DESC => 'First input file type.',
                                    LONG_DESC  => 'First input file type.  ' .
                                    'Put at the begining of the output file.',
                                    FORMAT     => 'Ascii text.');

    my $filetype2 = addInfileOption(FLAG       => 'j',
                                    REQUIRED   => 1,
                                    SHORT_DESC => 'Second input file type.',
                                    LONG_DESC  => 'Second input file type.' .
                                    '  Put at the end of the output file.',
                                    FORMAT     => 'Ascii text.',
                                    PAIR_WITH  => $filetype1,
                                    PAIR_RELAT => 'ONETOONE');

    my $outftype1 = addOutfileOption(FLAG          => 'o',
                                     COLLISIONMODE => 'merge',
                                     SHORT_DESC    => 'Output file name.',
                                     LONG_DESC     => 'Provide a name for ' .
                                     'the output file.  An output file name ' .
                                     'for each pair of input files may be ' .
                                     'provided (see -i and -j).',
                                     FORMAT        => 'Same as the input file',
                                     PAIR_WITH     => $filetype1,
                                     PAIR_RELAT    => 'ONETOONE');

    while(nextFileCombo())
      {
        my $inputFile1 = getInfile($filetype1);
        my $inputFile2 = getInfile($filetype2);
        my $outputFile = getOutfile($outftype1);

        openOut(*OUT,$outputFile) || next; #'merge' mode set above
                                           #automatically opens 1st in write,
                                           #then in append

        openIn(*IN1,$inputFile1)  || next;
        while(getLine(*IN1))
          {print}
        closeIn(*IN1);

        openIn(*IN2,$inputFile2)  || next;
        while(getLine(*IN2))
          {print}
        closeIn(*IN2);

        closeOut(*OUT);
      }

    #USAGE
    #>catpairs.pl -i '1.txt 2.txt 3.txt' -j '4.txt 5.txt 6.txt' -o '14.txt 25.txt 36.txt'

=head1 DESCRIPTION

CommandLineInterface (henceforth, 'CLI') basically gives any file processing script an instant command line interface with all the standard bells and whistles.

I<File Processing Features>

CLI makes processing of ordered pairs or groups of files a breeze with 2-dimensional file parameters, enforced relationships between file types (e.g. 1:1, 1:M, or 1:1orM), over-write protection, automatic construction of output file names and stubs (including output directories, compounded file names, outfile suffixes, or appended numbers), the ability to skip pairs/groups of files when their output file already exists, automatic outfile headers containing dated run, version, user, etc. information.  Since the package generates the outfile names ahead of time, it gives it the ability to check for pre-existing output files, even predicted outfile name conflicts that don't yet exist, right at the beginning of the script, without having to wait through any file processing and with no to little coding effort on your part.

The ability to handle 2-dimensional file parameters is probably the most useful feature of CLI.  Each file flag can be supplied multiple times and each instance can take multiple input files.  It can do this because it bsd_globs each file string, supporting any glob character supported by bsd (e.g. {}, [], *, ?).  It even has the ability to overcome some limitations on command line length.  CLI takes the 2-dimensional file parameters and can mix & match them in multiple ways, enforcing the file type relationships along the way.  For example, these commands are equivalent:

    example.pl -i '1.txt 2.txt' -i '3.txt 4.txt' -i '5.txt 6.txt' -j a.txt -j b.txt -j c.txt

    example.pl -i '1.txt 2.txt' -i '3.txt 4.txt' -i '5.txt 6.txt' -j 'a.txt b.txt c.txt'

CLI sees that there are 3 groups of type -i, 3 files of type -j, and whether you provide those files each with a separate instance of -j or all in one, it will process the pairs in the same way:

    1.txt a.txt
    3.txt b.txt
    5.txt c.txt
    2.txt a.txt
    4.txt b.txt
    6.txt c.txt

Through some design examples in the discussion, you can see ways in which processing of the repeated files can be handled (e.g. 'a.txt').

CLI comes with a suite of standard command-line flags (and accompanying methods):

=over 4

=item B<Simple Flags>

Basic flags for verbosity, help, info, headers, and script control.


=over 4

=item --verbose           Use verbose(), verboseOverMe()

=item --quiet             quiets verbose(), warning(), error()

=item --help              automatic or use help()

=item --version           automatic or use getVersion()

=item --force             automatic; errors state when applicable

=item --header            automatic or use openOut(), getHeader()

=item --extended          more/advanced usage/help/version/header

=item --save-as-default   save command line options as defaults

=back

=item B<Overwrite Protection Flags>

Flags to help deal with pre-existing output files, all of which apply to all files opened by openOut() and pre-checked during processCommandLine().  Using perl's open() function circumvents overwrite protection:


=over 4

=item --overwrite         automatically handled

=item --skip              automatically handled

=item --append            automatically handled

=back


=item B<Debug Flags>

These flags help to figure out bugs.


=over 4

=item --debug             Use debug(). <0 = package debugging

=item --error-limit       suppress repeated error/warning types

=item --dry-run           prevents openIn & openOut operations

=item --pipeline          automatic; prepend script name to msgs

=back

=back

Simply by using CommandLineInterface, your script will have these options available on the command line.  Some of them require your input or the usage of certain methods to be useful.  E.g. Call error() instead of printing to STDERR, add options using the add*Option methods, call openIn() and openOut() instead of open(), etc.

=head2 Methods

=over 12

=item C<add2DArrayOption> FLAG, VARREF [, TYPE, REQUIRED, DEFAULT, HIDDEN, SHORT_DESC, LONG_DESC, ACCEPTS, DELIMITER]

Add an option/flag to the command line interface that a user can supply on the command line either multiple times, once with multiple values, or both.  Each instance of the FLAG on the command line defines a sub-array and the space-delimited values (wrapped in quotes) will be pushed onto the inner array.  E.g. -a '1 2 3' -a 'a b c' creates the following 2D array: [['1','2','3'],['a','b','c']].

FLAG is the name or names of the flag the user supplies on the command line (with or without an argument as defined by TYPE).  You can supply a single FLAG or a reference to an array of FLAGs.  Only alpha-numeric characters, dashes, and underscores are permitted.  Single character flags will be prepended with a single dash '-' and multi-character flags will get a double dash '--'.

VARREF takes a reference to an array onto which values supplied on the command line will be pushed.  The reference must be defined before passing it to add2DArrayOption.

TYPE can be any of:

    integer - signed or unsigned integer (exponents like 10e10 allowed)
    float   - float (exponents like 10.0e10 allowed)
    string  - string
    enum    - enumeration (values defined using the ACCEPTS array)

If not supplied, the default TYPE is str if ACCEPTS is also not supplied, or enum if ACCEPTS is supplied.

If REQUIRED is a non-zero value (e.g. '1'), the script will quit with an error and a usage message if at least 1 value is not supplied by the user on the command line.  If required is not supplied or set to 0, the flag will be treated as optional.

The DEFAULT parameter is not used to initialize the VARREF value, but rather is a string simply describing/defining the default in the usage message for this parameter.  Optionally, a reference to an array of references to arrays of scalars may be supplied.  The 2D array will be converted into a string using delimiting paranthases and commas, e.g.: "((1,2),(3,4)),((5),(6,7,8))", when displayed in the usage output's default for the given option.

If HIDDEN is a non-zero value (e.g. '1'), the flag/option created by this method will not be a part of the usage output.  Note that if HIDDEN is non-zero, a DEFAULT must be supplied.

SHORT_DESC is the short version of the usage message for this output file type.  An empty string will cause this option to not be in the short version of the usage message.

LONG_DESC is the long version of the usage message for this output file type.  If LONG_DESC is not defined/supplied and SHORT_DESC has a non-empty string, SHORT_DESC is copied to LONG_DESC.

Note, both SHORT_DESC and LONG_DESC have auto-generated formatting which includes whether or not the option is REQUIRED.

ACCEPTS takes a reference to an array of scalar values.  If defined/supplied, the list of acceptable values will be shown in the usage message for this option after the default value and before the description.  This parameter is intended for short lists of discrete values (i.e. enumerations) only.  Descriptions of acceptable value ranges should instead be incorporated into the LONG_DESC.

DELIMITER is the character between multiple values supplied to a single FLAG.  Note, if you use a space as your DELIMITER, the arguments must be wrapped in quotes.  Multiple character DELIMITERs are allowed.  Empty values (between multiple instances of contiguous delimiters) are skipped.  A perl regular expression is allowed (e.g. '\s+').  The default is based on TYPE.  Defaults of DELIMITER for each TYPE are:

    integer - Non-number characters (i.e. not 0-9, '+', '-', or 'e' (exponent).
    float   - Same as int, but decimals are included.
    string  - No delimiting is done.
    enum    - Any character not in the ACCEPTS values.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -a '1 2 three four' -a "5 6"

I<Code>

    my $array2d = [];
    add2DArrayOption(FLAG       => 'a',
                     VARREF     => $array2d,
                     TYPE       => 'string',
                     REQUIRED   => 1,
                     DEFAULT    => '',
                     HIDDEN     => 0,
                     SHORT_DESC => 'A series of numbers.',
                     LONG_DESC  => 'A space-delimited series of numbers.');
    processCommandLine();
    foreach my $sub_array (@$array2d)
    print(join(' ',@$sub_array),"\n");

I<Output>

    1 2 three four
    5 6

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.

Default file options that are added if none defined (which also affect the behavior of this method):

    None

I<LIMITATIONS>

There's currently no way to require a minimum, maximum, or exact number of required values - only at least 1.

There is not yet a way to pair a 2D array option with input or output files.

The reference supplied to VARREF must be an array reference.  There is no accommodation for method references, however addOption() can be used to supply a method reference instead.

I<ADVANCED>

FLAG strings are used as a key in the hash passed to Getopt::Long's GetOptions method.  As such, a type could be specified in the FLAG string, however since this is an array option with a delimiter, appending a type string in the flag string, such as 'a=i', cannot be used due to the parsing of delimited values.  So using the TYPE parameter is preferable.

VARREF is the value that is supplied as a value in the hash passed to Getopt::Long's GetOptions method.  Note that the VARREF array variable supplied is not populated until processCommandLine() has been called.  Once processCommandLine() has been called, no further calls to add2DArrayOption() are allowed.

If an array is pre-populated with default values, the default is not replaced, but rather is added to.  In order to set a default value, the prgrammer must set the default after the command line has been processed, if the user did not set a value.

If REQUIRED is true, but the array reference provided is populated with default values, the option is essentially optional.  Setting REQUIRED to true only forces the user to supply a value if the array reference refers to an empty array.  Note also that if the user provides no options on the command line, a general usage is printed, but if other options are supplied, and error about missing required options is generated.

=item C<addArrayOption> FLAG, VARREF [, TYPE, REQUIRED, DEFAULT, HIDDEN, SHORT_DESC, LONG_DESC, DELIMITER, ACCEPTS]

Add an option/flag to the command line interface that a user can supply on the command line either multiple times, once with multiple values (if DELIMITER is defined), or both, and each value will be pushed onto the VARREF array reference.

FLAG is the name or names of the flag the user supplies on the command line (with or without an argument as defined by TYPE).  You can supply a single FLAG or a reference to an array of FLAGs.  Only alpha-numeric characters, dashes, and underscores are permitted.  Single character flags will be prepended with a single dash '-' and multi-character flags will get a double dash '--'.

VARREF takes a reference to an array onto which values supplied on the command line will be pushed.  The reference must be defined before passing it to addArrayOption.

TYPE can be any of:

    integer - signed or unsigned integer (exponents like 10e10 allowed)
    float   - signed or unsigned decimal value (exponents like 10.0e10 allowed)
    string  - string
    enum    - enumeration (values defined using the ACCEPTS array)

If not supplied, the default TYPE is str if ACCEPTS is also not supplied, or enum if ACCEPTS is supplied.

If REQUIRED is a non-zero value (e.g. '1'), the script will quit with an error and a usage message if at least 1 value is not supplied by the user on the command line.  If required is not supplied or set to 0, the flag will be treated as optional.

The DEFAULT parameter is not used to initialize the VARREF value, but rather is a scalar (or reference to an array of scalars) simply describing/defining the default in the usage message for this parameter.  Setting the default value if no value is supplied by the user, is a job for the programmer.

If HIDDEN is a non-zero value (e.g. '1'), the flag/option created by this method will not be a part of the usage output.  Note that if HIDDEN is non-zero, a DEFAULT must be supplied.

SHORT_DESC is the short version of the usage message for this output file type.  An empty string will cause this option to not be in the short version of the usage message.

LONG_DESC is the long version of the usage message for this output file type.  If LONG_DESC is not defined/supplied and SHORT_DESC has a non-empty string, SHORT_DESC is copied to LONG_DESC.

Note, both SHORT_DESC and LONG_DESC have auto-generated formatting which includes whether or not the option is REQUIRED.

DELIMITER is the character between multiple values supplied to a single FLAG.  Note, if you use a space as your DELIMITER, the arguments must be wrapped in quotes.  Multiple character DELIMITERs are allowed.  Empty values (between multiple instances of contiguous delimiters) are skipped.  A perl regular expression is allowed (e.g. '\s+').  The default is based on TYPE.  There is no default delimiter for addArrayOption() (though there is for add2DArrayOption()).  Without supplying a delimiter, each value must be submitted with a flag.  If you do provide a delimiter, multiple flags are still allowed, but all values are pushed onto the same array from left to right, as they appear in order on the command line.

ACCEPTS takes a reference to an array of scalar values.  If defined/supplied, the list of acceptable values will be shown in the usage message for this option after the default value and before the description.  This parameter is intended for short lists of discrete values (i.e. enumerations) only.  Descriptions of acceptable value ranges should instead be incorporated into the LONG_DESC.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -a '1 2 three four' -a "5 6"

I<Code>

    my $array = [];
    addArrayOption(FLAG       => 'a',
                   VARREF     => $array,
                   REQUIRED   => 1,
                   DEFAULT    => '',
                   HIDDEN     => 0,
                   SHORT_DESC => 'A series of numbers.',
                   LONG_DESC  => '   space-delimited series of numbers.',
                   DELIMITER  => ' ');
    processCommandLine();
    print(join("\n",@$array),"\n");

I<Output>

    1
    2
    three
    four
    5
    6

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.

Default file options that are added if none defined (which also affect the behavior of this method):

    None

I<LIMITATIONS>

There's currently no way to require a minimum, maximum, or exact number of required values - only at least 1.  This will be addressed when requirement 172 is implemented.

There is not yet a way to pair an array option with input or output files.  This will be addressed when requirement 15 is implemented.

The reference supplied to VARREF must be an array reference.  There is no accommodation for method references, however addOption() can be used to supply a method reference instead.

If an array is pre-populated with default values, the default is not replaced, but rather is added to.  In order to set a default value, the prgrammer must set the default after the command line has been processed, if the user did not set a value.

I<ADVANCED>

VARREF is the value that is supplied as a value in the hash that is passed to Getopt::Long's GetOptions method.  Note that the VARREF array variable supplied is not populated until processCommandLine() has been called.  Once processCommandLine() has been called, no further calls to addArrayOption() are allowed.

The DELIMITER will be shown in the script's usage in the flags column, inside the argument, between the argument type and an ellipsis, e.g. "--flag <int ...>".  In this case, the delimiter is a space.  If a multi-character delimiter is provided, the flag column will appear as "--flag <int...>" and an addendum will be appended to the LONG_DESC.  If a perl regular expression is used, a representative DELIMITER will be shown in the flags column, if an arbitrary example will be used and an addendum placed in the description.

If REQUIRED is true, but the array reference provided is populated with default values, the option is essentially optional.  Setting REQUIRED to true only forces the user to supply a value if the array reference refers to an empty array.  Note also that if the user provides no options on the command line, a general usage is printed, but if other options are supplied, and error about missing required options is generated.

=item C<addInfileOption> FLAG [, REQUIRED, DEFAULT, PRIMARY, HIDDEN, SHORT_DESC, LONG_DESC, FORMAT, PAIR_WITH, PAIR_RELAT]

Adds an input file option to the command line interface.

FLAG is the name or names of the flag the user supplies on the command line with file, space-delimited list of files inside quotes, or a glob pattern inside quotes.  You can supply a single FLAG or a reference to an array of FLAGs.  Only alpha-numeric characters, dashes, and underscores are permitted.  Single character flags will be prepended with a single dash '-' and multi-character flags will get a double dash '--'.

The return value is an input file type ID that is later used to obtain the files that the user has supplied on the command line (see getInfile(), getNextFileGroup(), getAllFileGroups()).  Files for each input file type are kept in a 2D array where the outer array is indexed by the number of occurrences of the flag on the command line (e.g. '-i') and the inner array is all the files supplied to that flag instance.  Note, CommandLineInterface globs input files, so to supply multiple files to a single instance of -i, you have to wrap the file names/glob pattern(s) in quotes.

REQUIRED indicates whether CommandLineInterface should fail with an error if the user does not supply a required file type.  The value can be either 0 (false) or non-zero (e.g. "1") (true).

A DEFAULT file name or glob pattern can be provided.  The value supplied to DEFAULT may be a glob/string (interpreted as a series of files supplied to the first instance of the associated flag on the command line), a reference to an array of globs/strings (also interpreted as a series of files), or a 2D array of globs/strings (where each inner array is considered as a series of globs/strings supplied via a different instance of the associated flag on the command line).  If the user explicitly supplies any number of files on the command line, all default files will be ignored (not added).

There can be only one PRIMARY input file type.  Making an input file type 'PRIMARY' (0 (false) or non-zero (e.g. "1") (true)) does 2 things: 1. PRIMARY files can be submitted without the indicated flag.  (Note, they are still grouped by wrapping in quotes and they are still globbed.)  2. The PRIMARY file type can be supplied on STDIN (standard in, via a pipe or redirect).  Note, if there is a single value supplied to a PRIMARY file type's flag and STDIN is present, the value supplied to the flag is treated as a stub for creating output files with the outfile suffix option(s).

If HIDDEN is a non-zero value (e.g. '1'), the flag/option created by this method will not be a part of the usage output.  Note that if HIDDEN is non-zero, a DEFAULT must be supplied.  If HIDDEN is unsupplied, the default will be 0 if the file type is not linked to another file type that is itself HIDDEN.  If the linked file is HIDDEN, the default will be HIDDEN for this option as well.

SHORT_DESC is the short version of the usage message for this file type.  An empty string will cause this option to not be in the short version of the usage message.

LONG_DESC is the long version of the usage message for this file type.  If LONG_DESC is not defined/supplied and SHORT_DESC has a non-empty string, SHORT_DESC is copied to LONG_DESC.

Note, both SHORT_DESC and LONG_DESC have auto-generated formatting which includes details on the REQUIRED and PRIMARY states as well as the flag(s) parsed from FLAG.

FORMAT is the description of the input file format that is printed when --help is provided by the user.  The auto-generated details for input format descriptions includes the applicable flag(s) and whether or not the flag is necessary.

PAIR_WITH and PAIR_RELAT allow the programmer to require a certain relative relationship with other input (or output) file parameters (already added).  PAIR_WITH takes the input (or output) file type ID (returned by the previous call to addInfileOption() or addOutfileOption()) and PAIR_RELAT takes one of 'ONETOONE', 'ONETOMANY', or 'ONETOONEORMANY'.  For example, if there should be one output file for every group of input files of type $intype1, then PAIR_WITH and PAIR_RELAT should be $intype1 and 'ONETOMANY', respectively.

All calls to addInfileOption() must occur before any/all calls to processCommandLine(), nextFileCombo(), getInfile, getNextFileGroup(), openOut(), openIn(), and getAllFileGroups().  If you wish to put calls to the add*Option methods at the bottom of the script, you must put them in a BEGIN block.

The returned input file type ID must also be used when calling addOutfileSuffixOption() so that the interface can automatically construct output file names for you and perform overwrite checks.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt' -j 'file.tab'

I<Code>

    my $id1 = addInfileOption(FLAG       => 'i',
                              REQUIRED   => 1,
                              DEFAULT    => undef,
                              PRIMARY    => 1,
                              HIDDEN     => 0,
                              SHORT_DESC => 'Input file(s).',
                              LONG_DESC  => '1 or more text input files.',
                              FORMAT     => 'ASCII text.');
    my $id2 = addInfileOption(FLAG       => 'j',
                              REQUIRED    => 0,
                              DEFAULT     => undef,
                              PRIMARY     => 0,
                              HIDDEN      => 0,
                              SHORT_DESC  => 'Input file(s).',
                              LONG_DESC   => '1 or more tabbed input files.',
                              FORMAT      => 'Tab delimited ASCII text, 1 ' .
                                             'tab per line.  First column ' .
                                             'is a unique ID and the second ' .
                                             'column is a value.',
                              PAIR_WITH   => $id1,
                              PAIR_RELAT  => 'ONETOMANY');

I<Output>

    n/a

=back

I<ASSOCIATED FLAGS>

A default file option is added if addInfileOption is never called:

    -i                  Input file.

I<LIMITATIONS>

A 'MANYTOMANY' PAIR_RELAT is not supported yet.  This will be addressed when requirement 140 is implemented.  See the DISCUSSION for hints on getting MANYTOMANY behavior.

The only supported static number of files for PAIR_RELAT is 'ONE'.  While strings like '1:1', '1:M', and '1:1orM' are supported, '1' and 'M' cannot be replaced by some other static integer, e.g. to require one file type to be supplied 1 file for every 4 of another file.  This may be implemented in the future.

I<ADVANCED>

addInfileOption() is called automatically with a default input file flag (-i, and other alternate flags) at runtime if no input file option was explicitly added.  If a flag (e.g. '-i') was already used for another option, it is removed and an alternate flag is used.

Multiple values supplied to a PRIMARY file type's flag when STDIN is present causes STDIN to be treated as an additional file parameter to the flag, mixed in with the named input files (i.e. there is no stub).  In these instances, the STDIN input will be named 'STDIN' when used to create output file names with the outfile suffix option(s).

PAIR_RELAT can be instructed to only allow 1 instance of an input file type (by supplying the string 'ONE') without needing PAIR_WITH to be defined.

=item C<addOption> FLAG, VARREF [, TYPE, REQUIRED, DEFAULT, HIDDEN, SHORT_DESC, LONG_DESC, ACCEPTS]

This method allows the programmer to create simple options on the command line.  The values of user-supplied options are available after processCommandLine() is called.

FLAG is the name or names of the flag the user supplies on the command line (with or without an argument as defined by TYPE).  You can supply a single FLAG or a reference to an array of FLAGs.  Only alpha-numeric characters, dashes, and underscores are permitted.  Single character flags will be prepended with a single dash '-' and multi-character flags will get a double dash '--'.

VARREF is a reference to the perl variable where the user's supplied value will be stored (e.g. $variable).

TYPE can be any of the following:

    bool    - FLAG does not take an argument and sets VARREF to 1 if supplied.
    negbool - A 'negatable' FLAG that does not take an argument.  The user can supply the flag as-is, which sets VARREF to 1, or they can supply --no<FLAG> to set VARREF to 0.  Usage will show the flag which is the opposite of the value referred to in VARREF.  If the value referred to by VARREF is undefined, the usage will show both flags.
    integer - signed or unsigned integer (exponents like 10e10 allowed)
    float   - signed or unsigned decimal value (exponents like 10.0e10 allowed)
    string  - string
    enum    - enumeration where the argument can be one of a set of acceptable values defined by ACCEPTS.
    count   - A 'count' FLAG that can either be set with an integer argument or incremented by multiple instances of FLAG without an argument.  Do not mix FLAGs with and without arguments.

REQUIRED indicates whether the option is required on the command line when the user runs the script.  If it is not supplied, the user will either get an error (if other options were supplied) to indicate the missing required options, or the usage message if no options were supplied at all.

Supply a DEFAULT value for automatic inclusion in the usage message for this option.  This only affects the usage message.  The value referenced by VARREF is not altered to get this value.  The value referenced by VARREF should already be set to its default value before processCommandLine is called.  Though it may seem redundant, the programmer may have long or complex defaults that depend on other parameters, thus the displayed default string might be more succinctly described as 'auto' or described in the option description.

If HIDDEN is set to a non-zero value, the option will not be included in the usage message.

SHORT_DESC is the short version of the description of this option.  If set to undefined or an empty string, this option will not appear in the short usage message.  The short usage message is what the user will see if they run the script with no options.

LONG_DESC is the long version of the description of this option.  If set to undefined or an empty string, this option will be set to a warning that the programmer has not provided a description of this option.  The long usage message is what the user will see if they run the script with only the --extended flag.

ACCEPTS takes a reference to an array of scalar values.  If defined/supplied, the list of acceptable values will be shown in the usage message for this option after the default value and before the description.  This parameter is intended for short lists of discrete values (i.e. enumerations) only.  Descriptions of acceptable value ranges should instead be incorporated into the LONG_DESC.

I<EXAMPLE>

=over 4

I<Command>

    example.pl --exhaustive yes

I<Code>

    my $answer = 'no';
    addOption(FLAG       => 'exhaustive',
              VARREF     => \$answer,
              REQUIRED   => 1,
              DEFAULT    => 'no',
              HIDDEN     => 0,
              SHORT_DESC => 'Whether or not to calculate exhaustively.',
              LONG_DESC  => 'Whether or not to calculate exhaustively.  ' .
                            'maybe=flip a coin.',
              ACCEPTS    => ['yes','no','maybe']);
    processCommandLine();
    print("$answer\n");

I<Output>

    yes

=back

I<ASSOCIATED FLAGS>

n/a

I<LIMITATIONS>

None.

I<ADVANCED>

VARREF may be a reference to a method.  See `perldoc Getopt::Long` for more information and details.

If REQUIRED is true, but the reference provided is populated with a default value, the option is essentially optional.  Setting REQUIRED to true only forces the user to supply a value if the reference refers to an undefined or empty variable.  Note also that if the user provides no options on the command line, a general usage is printed, but if other options are supplied, and error about missing required options is generated.

=item C<addOptions> GETOPTHASH [, REQUIRED, OVERWRITE, RENAME]

Add an existing Getopt::Long hash.  This method mainly serves to help facilitate quick conversion of existing scripts which already use Getopt::Long.

GETOPTHASH is a reference to the hash that is supplied to Getopt::Long's GetOptions() method.  See `perldoc Getopt::Long` for details on the structure of the hash.

addOptions can be called multiple times to add to the hash that will be eventually supplied to Getopt::Long's GetOptions() method.

REQUIRED is the value indicating whether all of the options provided in the hash are required on the command line or not.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -e 2 -k test

I<Code>

    my $e_int = 3;
    my $k_str = 'default';
    addOptions(GETOPTHASH => {'e=i' => \$e_int,
                              'k=s' => \$k_str});
    processCommandLine();
    print("$k_str : $e_int\n");

I<Output>

    test : 2

=back

I<ASSOCIATED FLAGS>

n/a

I<LIMITATIONS>

This method does not convert input and output file options of existing scripts to utilize this module, nor does it convert output directory or output file suffix options.  It does not provide a means of setting the usage message.  It is only intended to provide a quick means to get an existing script that uses Getopt::Long already to quickly be able to use this module.

I<ADVANCED>

2 advanced/hidden parameters to this method exist:

OVERWRITE deactivates a default option that you wish to handle yourself.  The key must be an exact match and thus is intended for advanced users only, as it requires looking at the source code of this module.

RENAME: [in development/experimental] If a reference to a value in the GetOptions hash already exists, delete and remake the key-value pair using the associated key.

If REQUIRED is true, but the reference provided is populated with a default value, the option is essentially optional.  Setting REQUIRED to true only forces the user to supply a value if the reference refers to an undefined or empty variable.  Note also that if the user provides no options on the command line, a general usage is printed, but if other options are supplied, and error about missing required options is generated.

=item C<addOutdirOption> FLAG [, REQUIRED, DEFAULT, HIDDEN, SHORT_DESC, LONG_DESC]

Adds an output directory option to the command line interface.  All output files generated through the addOutfileSuffixOption() and addOutfileOption() methods will be put in the output directory if it is supplied.  The entire path (if any) is replaced with a path to the supplied output directory.  If an outdir is not provided by the user, the supplied path of the outfile or the input file (to which a suffix is added) is where the output file will go.

FLAG is the name or names of the flag the user supplies on the command line with a directory argument.  FLAG can be a single scalar value or a reference to an array of FLAGs.  Only alpha-numeric characters, dashes, and underscores are permitted.  Single character flags will be prepended with a single dash '-' and multi-character flags will get a double dash '--'.

No return value.

The output directory(/ies) that the user supplies are stored in a 2 dimensional array and are paired with the other file options in a 1:1 or 1:M relationship.  The file names/paths returned by getOutfile() will include the output directory that was supplied by the user via this option.

CLI requires that the user supply either a named output file or both an outfile suffix and input file(s) if they supply an output directory.

CLI creates directories supplied by the user automatically, before any file processing occurs and will issue an error if creation fails.  Creation happens when the command line options are processed, as a last step, after all other options are processed and outfile conflicts evaluated.

REQUIRED indicates whether CommandLineInterface should fail with an error if the user does not supply an output directory.  The REQUIRED value can be either 0 (false) or non-zero (e.g. "1") (true).

A DEFAULT output directory can be provided.  If the user does not supply an output directory, the default will be used.  If there is no default desired, do not include the DEFAULT key or supply it as undef (the builtin perl function).

To create an output directory with an immutable, always-present value (e.g. 'output') that the user should not see as an option in the usage or help output, set HIDDEN to a non-zero value.

SHORT_DESC is the short version of the usage message for this output directory option.  An empty string will cause this option to not be in the short version of the usage message.

LONG_DESC is the long version of the usage message for this output directory option.  If LONG_DESC is not defined/supplied and SHORT_DESC has a non-empty string, SHORT_DESC is copied to LONG_DESC.

Note, both SHORT_DESC and LONG_DESC have auto-generated formatting which includes details on the REQUIRED state as well as the flag(s) parsed from FLAG.

All calls to addOutdirOption() must occur before any/all calls to processCommandLine(), nextFileCombo(), getInfile, getNextFileGroup(), openOut(), openIn(), and getAllFileGroups().  If you wish to put calls to the add*Option methods at the bottom of the script, you must put them in a BEGIN block.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt' -o .out --outdir myoutput
    #or...
    example.pl --outfile test.out --outdir myoutput

I<Code>

    addOutdirOption(FLAG       => 'outdir',
                    REQUIRED   => 0,
                    DEFAULT    => undef,
                    HIDDEN     => 0,
                    SHORT_DESC => 'Output directory.',
                    LONG_DESC  => 'Output directory.  Will be created if ' .
                                  'it does not already exist.');

I<Output>

    myoutput/*.out

=back

I<ASSOCIATED FLAGS>

Default file options that are added if none defined (which also affect the behavior of this method):

    --outdir            Output directory. see addOutdirOption()

I<LIMITATIONS>

The programmer cannot require a 1:1, 1:M, or 1:1orM relationship between supplied directories and other file options (yet).  Requirement number 149, once implemented, will provide this capability.  Refer to the PAIR_WITH and PAIR_RELAT options in addInfileOption() to get an idea of how this eventual feature will be implemented.

Currently, there is no way to force the deletion of a directory.  Requirement 69, once implemented will always delete a pre-existing directory if 3 --overwrite flags are provided.

There is currently no way to obtain the output directory(/ies) that the user supplied on the command line alone, unless you parse them from the getOutfile() return string.  Requirement 150 will add this method.

There's no current hook for the programmer to obtain the status of directory creation (yet).  The only way to determine such a failure is by the return status of openOut().  Requirement 151 will add this hook.

Automatic creation of nested directories is not supported.  Requirement 152, once implemented will allow the programmer to specify that automatic creation of nested directories is allowed.

I<ADVANCED>

The relationship between the number of outdir flags and outdirs supplied to each outdir flag with the input files and named output files is enforced to be either ONETOMANY (1:M) or ONETOONE (1:1).  Typical usage is to either supply a single output directory or to supply as many directories as there are instances of input file flags.

An alternative usage is to supply as many directories as match the number of files supplied to a single input file flag (as long as all occurrences of the same input file flag and other types of input file flags have either the same number of files or 1 file.

One could also supply an output directory for each and every input file.

=item C<addOutfileOption> FLAG [, COLLISIONMODE, REQUIRED, PRIMARY, DEFAULT, SHORT_DESC, LONG_DESC, FORMAT, HIDDEN, PAIR_WITH, PAIR_RELAT]

FLAG is the name or names of the flag the user supplies on the command line with a file argument.  FLAG can be a single scalar value or a reference to an array of FLAGs.  Only alpha-numeric characters, dashes, and underscores are permitted.  Single character flags will be prepended with a single dash '-' and multi-character flags will get a double dash '--'.

The return value is an output file type ID that is later used to obtain the output file names constructed from the output file names and output directory name(s) that the user has supplied on the command line (see getOutfile() and getNextFileGroup()).

COLLISIONMODE is an advanced feature that determines how to handle situations where 2 or more combinations of input files end up generating output into the same output file.

For example, if a pair of files has a ONETOMANY relationship, and the 'one' file is what has been assigned an outfile suffix, multiple combinations of that file with different input files of the 'many' type will have the same output file.  Or, if 2 input files in different source directories are being appended a suffix and an output directory has been supplied, those output file names will collide.  COLLISIONMODE is what determines what will happen in that situation.

COLLISIONMODE can be set to 1 of 3 modes/strategies, each represented by a string: 'error', 'merge', or 'rename' to handle these situations.  The default for addOutfileOption() is 'merge', which notably differs from the default for addOutfileSuffixOption() because it assumes that the user uses a suffix when each input file has an output file and uses an outfile option when multiple input files have a single output file (even though each mode supports both strategies).  A COLLISIONMODE of 'error' indicates that an error should be printed and the script should quit (if caught before file processing starts - if caught after file processing starts, only an error is issued and its up to the programmer to decide what to do with the failure status returned by openOut()).  A COLLISIONMODE of 'merge' means that pre-existing output files or output file names generated with the same name/path should be appended-to or concatenated together.  A COLLISIONMODE of 'rename' indicates that if 2 or more output file names have the same path/name, their file names will be manipulated to not conflict.  See the ADVANCED section for more details.

The COLLISIONMODE set here is over-ridden by the COLLISIONMODE set by setDefaults().  This is because the user is intended to use --collision-mode on the command line to change the behavior of the script and setDefaults is supplying a default value for that flag.  This behavior will change when requirement 114 is implemented.

REQUIRED indicates whether CommandLineInterface should fail with an error if the user does not supply a required output file type.  The value can be either 0 (false) or non-zero (e.g. "1") (true).

There may be any number of PRIMARY output file types.  Setting PRIMARY to a non-zero value indicates that if no output file suffix is supplied by the user and there is no default set, output to this output file type should be printed to STDOUT.

A DEFAULT output file can be provided.  If there is no DEFAULT, output will go to STDOUT.  If there is no default desired, do not include the DEFAULT key or supply it as undef (the builtin perl function).  Note, setting a DEFAULT suffix will cause output for this output file type to never be printed to STDOUT.

To construct output file names with an immutable, always-present output file name (e.g. 'output.log') that the user should not see as an option in the usage or help output, set HIDDEN to a non-zero value.  If HIDDEN is unsupplied, the default will be 0 if the file type is not linked to another file type that is itself HIDDEN.  If the linked file is HIDDEN, the default will be HIDDEN for this option as well.

SHORT_DESC is the short version of the usage message for this output file type.  An empty string will cause this option to not be in the short version of the usage message.

LONG_DESC is the long version of the usage message for this output file type.  If LONG_DESC is not defined/supplied and SHORT_DESC has a non-empty string, SHORT_DESC is copied to LONG_DESC.

Note, both SHORT_DESC and LONG_DESC have auto-generated formatting which includes details on the REQUIRED state as well as the flag(s) parsed from FLAG.

FORMAT is the description of the output file format that is printed when --help is provided by the user.  The auto-generated details for output format descriptions includes the applicable flag(s).

PAIR_WITH and PAIR_RELAT allow the programmer to require a certain relative relationship with other input (or output) file parameters (already added).  PAIR_WITH takes the input (or output) file type ID (returned by the previous call to addInfileOption() or addOutfileOption()) and PAIR_RELAT takes one of 'ONETOONE', 'ONETOMANY', or 'ONETOONEORMANY'.  For example, if there should be one output file for every group of input files of type $intype1, then PAIR_WITH and PAIR_RELAT should be $intype1 and 'ONETOMANY', respectively.

All calls to addOutfileOption() must occur before any/all calls to processCommandLine(), nextFileCombo(), getInfile, getNextFileGroup(), openOut(), openIn(), and getAllFileGroups().  If you wish to put calls to the add*Option methods at the bottom of the script, you must put them in a BEGIN block.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt' -j output.out

I<Code>

    my $id1 = addInfileOption(FLAG       => 'i',
                              REQUIRED   => 1,
                              DEFAULT    => undef,
                              PRIMARY    => 1,
                              SHORT_DESC => 'Input file(s).',
                              LONG_DESC  => '1 or more text input files.',
                              FORMAT     => 'ASCII text.');
    my $oid = addOutfileOption(FLAG       => 'j',
                               REQUIRED   => 0,
                               PRIMARY    => 1,
                               DEFAULT    => undef,
                               HIDDEN     => 0,
                               SHORT_DESC => 'Output file.',
                               LONG_DESC  => 'ASCII Text output file.',
                               FORMAT     => 'Tab delimited ASCII text.',
                               PAIR_WITH  => $id1,
                               PAIR_RELAT => 'ONETOMANY');

I<Output>

    output.out

=back

I<ASSOCIATED FLAGS>

Default file options that are added if none defined (which also affect the behavior of this method):

    --outfile           Output file.
    --outdir            Output directory. see addOutdirOption()

I<LIMITATIONS>

None.

I<ADVANCED>

A COLLISIONMODE of 'rename' handles conflicting output file names by appending the input file names they are associated with.  All of the files in the file set returned by the nextFileCombo() iterator are evaluated, and the fewest number of input file names are concatenated together with the output file name as is needed to make the output file names unique.

=item C<addOutfileSuffixOption> FLAG, FILETYPEID [, VARREF, COLLISIONMODE, REQUIRED, PRIMARY, DEFAULT, HIDDEN, SHORT_DESC, LONG_DESC, FORMAT]

Adds an output file suffix option to the command line interface.

FLAG is the name or names of the flag the user supplies on the command line with a suffix argument.  FLAG can be a single scalar value or a reference to an array of FLAGs.  Only alpha-numeric characters, dashes, and underscores are permitted.  Single character flags will be prepended with a single dash '-' and multi-character flags will get a double dash '--'.

The return value is an output file suffix type ID that is later used to obtain the output file names constructed from the input file names and output directory name(s) that the user has supplied on the command line (see getOutfile() and getNextFileGroup()).  Only one suffix is allowed per flag on the command line.  Note, CommandLineInterface appends only.

FILETYPEID is the ID of the input file type returned by addInfileOption() indicating the files to which the suffix provided by the user on the command line will be appended.

Since output file names are constructed automatically and retrieved by getOutfile(), the VARREF option is not required (and is in fact discouraged).  But if you want to be able to obtain the suffix to construct custom file names (which note, will not have the full overwrite protection provided by CommandLineInterface), you can provide a reference to a scalar so that after the command line is processed, you will have the suffix provided by the user.  Note also that DEFAULT is what is used as the suffix when the user does not provide one.  The pre-existing value of VARREF is ignored.

COLLISIONMODE is an advanced feature that determines how to handle situations where 2 or more combinations of input files end up generating output into the same output file.

For example, if a pair of files has a ONETOMANY relationship, and the 'one' file is what has been assigned an outfile suffix, multiple combinations of that file with different input files of the 'many' type will have the same output file.  Or, if 2 input files in different source directories are being appended a suffix and an output directory has been supplied, those output file names will collide.  COLLISIONMODE is what determines what will happen in that situation.

COLLISIONMODE can be set to 1 of 3 modes/strategies, each represented by a string: 'error', 'merge', or 'rename' to handle these situations.  The default for addOutfileOption() is 'merge', which notably differs from the default for addOutfileSuffixOption() because it assumes that the user uses a suffix when each input file has an output file and uses an outfile option when multiple input files have a single output file (even though each mode supports both strategies).  A COLLISIONMODE of 'error' indicates that an error should be printed and the script should quit (if caught before file processing starts - if caught after file processing starts, only an error is issued and its up to the programmer to decide what to do with the failure status returned by openOut()).  A COLLISIONMODE of 'merge' means that pre-existing output files or output file names generated with the same name/path should be appended-to or concatenated together.  A COLLISIONMODE of 'rename' indicates that if 2 or more output file names have the same path/name, their file names will be manipulated to not conflict.  See the ADVANCED section for more details.

The COLLISIONMODE set here is over-ridden by the COLLISIONMODE set by setDefaults().  This is because the user is intended to use --collision-mode on the command line to change the behavior of the script and setDefaults is supplying a default value for that flag.  This behavior will change when requirement 114 is implemented.

REQUIRED indicates whether CommandLineInterface should fail with an error if the user does not supply a required suffix type.  The value can be either 0 (false) or non-zero (e.g. "1") (true).

There may be any number of PRIMARY output file types.  Setting PRIMARY to a non-zero value indicates that if no output file suffix is supplied by the user and there is no default set, output to this output file type should be printed to STDOUT.

A DEFAULT output file suffix can be provided.  If the user does not supply a suffix, the default will be used to construct output file names.  If there is no default desired, do not include the DEFAULT key or supply it as undef (the builtin perl function).  Note, setting a DEFAULT suffix will cause output for this output file type to never be printed to STDOUT.

To construct output file names with an immutable, always-present suffix (e.g. '.log') that the user should not see as an option in the usage or help output, set HIDDEN to a non-zero value.  If HIDDEN is unsupplied, the default will be 0 if the file type is not linked to another file type that is itself HIDDEN.  If the linked file is HIDDEN, the default will be HIDDEN for this option as well.

SHORT_DESC is the short version of the usage message for this output file type.  An empty string will cause this option to not be in the short version of the usage message.

LONG_DESC is the long version of the usage message for this output file type.  If LONG_DESC is not defined/supplied and SHORT_DESC has a non-empty string, SHORT_DESC is copied to LONG_DESC.

Note, both SHORT_DESC and LONG_DESC have auto-generated formatting which includes details on the REQUIRED and PRIMARY states as well as the flag(s) parsed from FLAG.

FORMAT is the description of the output file format that is printed when --help is provided by the user.  The auto-generated details for output format descriptions includes the applicable flag(s).

All calls to addOutfileSuffixOption() must occur before any/all calls to processCommandLine(), nextFileCombo(), getOutfile, getNextFileGroup(), openIn(), openOut(), and getAllFileGroups().  If you wish to put calls to the add*Option methods at the bottom of the script, you must put them in a BEGIN block.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt' -o .out

I<Code>

    my $id1 = addInfileOption(FLAG       => 'i',
                              REQUIRED   => 1,
                              DEFAULT    => undef,
                              PRIMARY    => 1,
                              SHORT_DESC => 'Input file(s).',
                              LONG_DESC  => '1 or more text input files.',
                              FORMAT     => 'ASCII text.');
    my $oid = addOutfileSuffixOption(FLAG       => 'o',
                                     FILETYPEID => $id1,
                                     VARREF     => undef,
                                     REQUIRED   => 0,
                                     PRIMARY    => 1,
                                     DEFAULT    => undef,
                                     HIDDEN     => 0,
                                     SHORT_DESC => 'Outfile suffix.',
                                     LONG_DESC  => ('Suffix appended to file '.
                                                    'submitted via -i.'),
                                     FORMAT     => ('Tab delimited ASCII ' .
                                                    'text, 1 tab per line.  ' .
                                                    'First column is a ' .
                                                    'unique ID and the  ' .
                                                    'secondcolumn is a ' .
                                                    'value.');

I<Output>

    *.txt.out

=back

I<ASSOCIATED FLAGS>

Default file options that are added if none defined (which also affect the behavior of this method):

    -o                  Output file suffix. See addOutfileSuffixOption()
    -i                  Input file. See addInfileOption()


I<LIMITATIONS>

Does not replace existing extensions at the end of input file names (yet).  This will be addressed when requirement 171 is implemented.  Nor does it insert a dot between the input file and the supplied suffix.  If the user wants the suffix to be appended with a dot, the dot must be supplied as a part of the suffix.

I<ADVANCED>

The user can supply an empty string ('') as an output file suffix which would cause an over-write situation (unless an output directory was specified (see addOutdirOption())), however this would trigger an overwrite error and the script would quit before processing any files.  The user could supply --overwrite to allow the input file to be overwritten, but note that the code would have to be written in a way such that the input is fully read in and the output buffered, in order for this to work properly.  To prevent a user from creating overwrite situations like this, you must validate the output file name returned by getOutfile() is different from the file name returned by getInfile().

Note that addOutfileOption() is a wrapper for a hidden and specially treated call to addInfileOption() containing the output file name as what is read in with the supplied flag, followed by a call to addOutfileSuffixOption() with a default set as an empty string.  The return value of addOutfileOption() is what is returned by the internal call to addOutfileSuffixOption().  In this way, getOutfile works for both output file suffix IDs and output file IDs.

A COLLISIONMODE of 'rename' handles conflicting output file names by compounding input file names.  This requires multiple types of input files.  All of the files in the file set advanced to by the nextFileCombo() iterator are evaluated and the fewest number of input file names are concatenated together as is needed to make the output file names unique.

=item C<addOutfileTagteamOption> FLAG_SUFF, FLAG_FILE, FILETYPEID (or PAIR_WITH) [, PAIR_RELAT, VARREF, REQUIRED, PRIMARY, FORMAT, DEFAULT, DEFAULT_IS_FILE, HIDDEN_SUFF, HIDDEN_FILE, SHORT_DESC_SUFF, SHORT_DESC_FILE, LONG_DESC_SUFF, LONG_DESC_FILE, COLLISIONMODE_SUFF, COLLISIONMODE_FILE]

Adds an output file suffix option and an output file option to the command line interface.  The resulting 2 options are mutually exclusive and allow the user to either specify a full output file name or an output file suffix (appended to an input file name) for the same generated output.

The return value is an output type ID that behaves exactly the same way as the returned ID from either addOutfileOption() or addOutfileSuffixOption(), and is later used to obtain the output file names that were either fully supplied or constructed from the input file names, both of which are put into any output directory name(s) that the user has supplied on the command line (see getOutfile() and getNextFileGroup()).  The programmer does not have to be concerned with how the user supplied the output file names.

Note, the interface will create a default outfile tagteam by if addOutfileOption() or addOutfileSuffixOption() (or both) are never called.

Note, this method is essentially a wrapper to both of the addOutfileOption() and addOutfileSuffixOption() methods, thus for each parameter below, please refer to that method's parameter description..

FLAG_SUFF & FLAG_FILE - See addOutfileSuffixOption's & addOutfileOption's FLAG parameter (respectively).

FILETYPEID - See addOutfileSuffixOption's FILETYPEID & addOutfileOption's PAIR_WITH parameters.

PAIR_RELAT - See addOutfileOption's PAIR_RELAT parameter.

VARREF - See addOutfileSuffixOption's VARREF parameter.

REQUIRED - See addOutfileSuffixOption's & addOutfileOption's REQUIRED parameter.

PRIMARY - See addOutfileSuffixOption's & addOutfileOption's PRIMARY parameter.

FORMAT - See addOutfileSuffixOption's & addOutfileOption's FORMAT parameter.

DEFAULT - See addOutfileSuffixOption's DEFAULT parameter.

DEFAULT_IS_FILE - If this is a non-zero value, the DEFAULT parameter (above) is supplied to addOutfileOption's DEFAULT parameter and addOutfileSuffixOption's DEFAULT parameter is supplied as undefined.  Only one or the other can have a default value, not both.

HIDDEN_SUFF & HIDDEN_FILE - See addOutfileSuffixOption's & addOutfileOption's HIDDEN parameter (respectively).  Briefly - whether or not the option is hidden in the usage output.

SHORT_DESC_SUFF & SHORT_DESC_FILE - See addOutfileSuffixOption's & addOutfileOption's SHORT_DESC parameter (respectively).

LONG_DESC_SUFF & LONG_DESC_FILE - See addOutfileSuffixOption's & addOutfileOption's LONG_DESC parameter (respectively).

COLLISIONMODE_SUFF & COLLISIONMODE_FILE - See addOutfileSuffixOption's & addOutfileOption's COLLISIONMODE parameter (respectively).

All calls to addOutfileTagteamOption() must occur before any/all calls to processCommandLine(), nextFileCombo(), getOutfile, getNextFileGroup(), openIn(), openOut(), and getAllFileGroups().  If you wish to put calls to the add*Option methods at the bottom of the script, you must put them in a BEGIN block.

I<EXAMPLE>

=over 4

I<Command>

    #EXAMPLE1:
    example.pl -i '*.txt' -o .out

    #EXAMPLE2:
    example.pl -i '*.txt' --outfile combined.out

    #EXAMPLE3:
    example.pl -i '*.txt'

I<Code>

    my $id1 = addInfileOption(FLAG       => 'i',
                              REQUIRED   => 1,
                              DEFAULT    => undef,
                              PRIMARY    => 1,
                              SHORT_DESC => 'Input file(s).',
                              LONG_DESC  => '1 or more text input files.',
                              FORMAT     => 'ASCII text.');
    my $oid = addOutfileTagteamOption(FLAG_SUFF       => 'o',
                                      FLAG_FILE       => 'outfile',
                                      FILETYPEID      => $id1,
                                      PRIMARY         => 1,
                                      FORMAT          => 'Tab delimited.',
                                      SHORT_DESC_SUFF => 'Outfile suffix.',
                                      SHORT_DESC_FILE => 'Outfile.',
                                      LONG_DESC_SUFF  => ('Suffix appended ' .
                                                          'to file submitted '.
                                                          'via -i'),
                                      LONG_DESC_FILE => 'Outfile.  See ' .
                                                        '--help for format.');

I<Output>

    #EXAMPLE1:
    *.txt.out

    #EXAMPLE2:
    combined.out

    #EXAMPLE3:
    All output goes to STDOUT

=back

I<ASSOCIATED FLAGS>

Default file options that are added if none defined (which also affect the behavior of this method):

    -o                  Output file suffix. See addOutfileSuffixOption()
    --outfile           Output file. See addOutfileOption()
    -i                  Input file. See addInfileOption()


I<LIMITATIONS>

See LIMITATIONS for each of the wrapped methods: addOutfileOption() and addOutfileSuffixOption().

I<ADVANCED>

The output file ID that is returned is actually a tagteam ID.  When getOutfile() is called with the ID, it checks the ID to see if it is a tagteam ID.  If it is, it checks to see which of the two options in the tagteam were supplied by the user and returns the corresponding output file name (whether it was created using an input file name, or supplied as a full output file name by the user.

The default COLLISIONMODE_* is different for the 2 types of options.  The default mode for the suffix option is 'error'.  I.e. If 2 file names are constructed with the same name/path, a fatal error occurs, preventing the script from processing any files.  The default mode for the create outfile option is 'merge', meaning if an output file name is supplied multiple times, the output is aggregated in that file (not overwritten).

You can actually call addOutfileTagteamOption() once with no parameters to create the default output file options as long as addOutfileOption() and addOutfileSuffixOption() have not been called without any parameters.  If either addOutfileOption() or addOutfileSuffixOption() have not been called before processCommandLine() is called, they are called without any options and made into a tagteam with the first outfile option of the opposing type.  For example, if you call addOutfileSuffixOption() and never call addOutfileOption(), it is automatically called with no parameters and made into a tagteam with the -o option you explicitly created.  There is currently no way to prevent this automatic option creation, but if you do not want to allow a user to supply output files by one or the other method, you can create a hidden version of that option.

FILETYPEID can actually be an optional parameter is there has only been 1 call to addInfileOption().  If there have been multiple input file options created, the FILETYPEID is required.

=item C<closeIn> HANDLE

Closes and untracks the file connected to HANDLE.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    closeIn(HANLDE => *INP);

    #or

    closeIn(*INP);

I<Output>

    n/a

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all errors, warnings, & debugs.  See quiet()
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --debug             Prints debug messages.  See debug()

I<LIMITATIONS>

None.

I<ADVANCED>

Generates verbose messages if --verbose is supplied on the command line and QUIET was not supplied to openIn (or was 0).

=item C<closeOut> HANDLE

Closes, de-selects, and untracks the file connected to HANDLE.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    closeIn(*OUTP);

    #or

    openOut(HANLDE => *OUTP);

I<Output>

    n/a

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all errors, warnings, & debugs.  See quiet()
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --debug             Prints debug messages.  See debug()

I<LIMITATIONS>

None.

I<ADVANCED>

Generates verbose messages if --verbose is supplied on the command line and QUIET was not supplied to openOut (or was 0).

Will not close STDOUT.

=item C<debug> EXPRs [, {LEVEL}]

Print messages along with line numbers.  Messages are prepended with 'DEBUG#: ' where # indicated the order in which the debug calls were made.

Multiple instances of --debug (or a value supplied to --debug) increases the debug level.

A debug level greater than 1 also inserts a call trace in front of the debug message (and after the debug number).

I<EXAMPLE>

=over 4

I<Command>

    example.pl '*.txt'

I<Code>

    debug({LEVEL=>1},"This is a debug message.");

I<Output>

    DEBUG1: This is a debug message.

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --debug             Prints debug messages.
    --quiet             Suppress all error, warning, verbose, & debug messages.
    --pipeline          Prepends script name to errors, warnings, & debugs.

I<LIMITATIONS>

The call trace currently indicates method name and line number, but does not yet indicate file name.  This will be addresses requirement 170 is implemented.

I<ADVANCED>

Supplying a negative level to --debug on the command line debugs the CommandLineInterface inner-workings.  The debug level of CommandLineInterface that produces the most debug output is -99.

=item C<error> EXPRs

See C<warning>.

=item C<flushStderrBuffer> [FORCE]

This method flushes any debug, error, warning, or verbose messages that might be in the buffer, if the flags linked to those messages (e.g. --verbose, --debug, --error-limit) have been rpocessed and their associated class variables defined.  This method is called automatically, thus it you never need to call it.  It's only useful when debugging fatal errors that occur before processCommandLine() is called.

Standard error messages only get buffered if they are generated before the command line arguments have been processed.  The reason for this is to wait until flags such as --quiet have been processed so that CommandLineInterface knows whether it should print its buffer or suppress it.  processCommandLine() calls flushStderrBuffer().

By default, flushStderrBuffer() does not print messages if the associated flag's variable (e.g. $verbose) is defined and true.  To force the flushing of messages awaiting the definition of such variables, use the FORCE parameter, set to a non-zero value.

flushStderrBuffer() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... flushStderrBuffer);` statement or call it using the package name: `CommandLineInterface::flushStderrBuffer();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    error("Something went wrong in pre-processing");
    CommandLineInterface::flushStderrBuffer(1);
    processCommandLine();

I<Output>

    ERROR: Something went wrong in pre-processing.

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.
    --error-limit       Suppress some errors & warnings.  See error()/warning()
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --debug             Prints debug messages.  See debug()

I<LIMITATIONS>

None.

I<ADVANCED>

Upon successful exit, flushStderrBuffer(1) is called via the quit() method (which is called in the END block).  If not previously called elsewhere, processCommandLine() is called just before the flush, meaning that if there was not a problem processing the command line arguments, the buffer should be empty.  If you see messages on STDERR even though you supplied the --quiet flag, something has gone wrong with command line argument processing.

=item C<getAllFileGroups> [FILETYPEID*]

getAllFileGroups returns a 2D array of input files provided by all instances of the flag defined by addInfileOption.  The inner arrays each hold all files specified by a single instance of a flag on the command line, provided space-delimited or globbed file names.  In scalar context, it returns a reference to an array of arrays of file names.  In list context, it returns an array of arrays of file names.

FILETYPEID is the ID returned by addInfileOption().  Supply it to specify the type of input files supplied by the flag defined by addInfileOption().

* FILETYPEID is optional when there is only 1 input file type, in which case, it defaults to the single input file type.  It is required otherwise.

I<EXAMPLE>

=over 4

I<Command>

    #>ls
    #1.txt 2.txt 3.txt a.text b.text c.text

    example.pl -i '*.txt' -i '*.text'

I<Code>

    my $fid = addInfileOption(FLAG => 'i');
    processCommandLine();
    foreach my $inf_group (getAllFileGroups())
      {print(join(' ',@$inf_group),"\n")}

I<Output>

    1.txt 2.txt 3.txt
    a.text b.text c.text

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

This method can only be used to retrieve input files, not output files, nor is there yet a way to retrieve outfile stubs or suffixes.  Until these functions have been implemented, it is highly recommended to use the nextFileCombo() iterator in combination with getInfile() and getOutfile() instead of this method.

This method does not skip any input files that may be associated with existing output files when --skip is provided.

I<ADVANCED>

n/a

=item C<getCommand> [INCLUDE_PERL_PATH, NO_DEFAULTS, INC_DEFMODE]

Returns a string containing the command that was issued on the command line (without input or output redirects).  It (by default) incorporates command line parameters that were previously saved using the --save-as-default flag.  Added defaults are commented at the end of the command to denote that they were added by the script.  This method is called automatically to generate output file headers containing the command that generated them and when --verbose is supplied.

The command returned by getCommand() is what the shell gives it, thus unless glob characters such as '*', '?', etc. are wrapped in quotes, the command returned will be post-shell expansion/interpolation.  You do not have to call processCommandLine() before calling getCommand().

If INCLUDE_PERL_PATH has a non-zero value, the path to the perl executable is placed in front of the script call.  This allows the user to know which of possibly multiple perl installations ran the script.

If NO_DEFAULTS has a non-zero value, the user saved defaults, previously saved using --save-as-default, will be omitted from the returned command.  Note, in string context, the returned command separates user defaults from manually supplied options with '--' and a comment and encapsulates the defaults in square brackets.  To run the command in the same way, the defaults must either be saved and the command omit the defaults or the defaults must be cleared and manually supplied.

Any options such as --run, --dry-run, --usage, and --help that were supplied via saved defaults (see --save-as-default) are not actually used in runs of the script, but they are stored with default options and affect the DEFRUNMODE (see setDefaults()).  One of these 4 options will change the default run mode.

INC_DEFMODE

getCommand() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... getCommand);` statement or call it using the package name: `CommandLineInterface::getCommand();`.

I<EXAMPLE>

=over 4

I<Command>

    #Previous command to save default arguments:
    example.pl --verbose 3 --save-as-default
    #Command related to output below:
    example.pl -i '*.txt' file{1,2}.tab

I<Code>

    print("My command: ",CommandLineInterface::getCommand());

I<Output>

    My command: example.pl -i '*.txt' file1.tab file2.tab -- [USER DEFAULTS ADDED: --verbose 3]

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --save-as-default   Save current options for inclusion in every run.

I<LIMITATIONS>

getCommand() has no way to know what glob string was provided to the shell before shell expansion (unless the glob was wrapped in quotes).

getCommand() does not know about pipes, shell variables, or input and output redirects.

Multiple spaces between arguments are not preserved.

Currently, if the user has set any default parameters, the command output will not run the same via simple copy and paste if you include the commented default parameters.  Also, if defaults have changed, that will affect the way the pasted command behaves, so check your defaults (at the bottom of the usage output) before rerunning a command.  The ability to ignore defaults for a script run will be addressed when requirement 66 is implemented.

I<ADVANCED>

n/a

=item C<getFileGroupSizes> [FILETYPEID*]

This method returns the numbers of files supplied to each instance of the flag defined by addInfileOption that were provided by the user on the command line.  In scalar context, it returns a reference to an array of sizes.  In list context, it returns an array of sizes.

FILETYPEID is the ID returned by addInfileOption().  Supply it to specify the type of input files supplied by the flag defined by addInfileOption().

* FILETYPEID is optional when there is only 1 input file type, in which case, it defaults to the single input file type.  It is required otherwise.

I<EXAMPLE>

=over 4

I<Command>

    #>ls
    #1.txt 2.txt 3.txt a.text b.text c.text

    example.pl -i '*.txt' -i '*.text'

I<Code>

    my $fid = addInfileOption(FLAG => 'i');
    processCommandLine();
    print(join("\n",getFileGroupSizes()),"\n");

I<Output>

    3
    3

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

This method can only be used to retrieve a number of input files per flag for a single input file type, not for output files.

This method does not skip any input files that may be associated with existing output files when --skip is provided.

I<ADVANCED>

n/a

=item C<getHeader>

Returns a multi-line string with leading comment characters containing various info about the run.  The purpose of such a header is to be able to know how a file was generated.

getHeader() is called by default in openOut (unless --no-header is supplied on the command line), so you should never need to call this method.

getHeader() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... getHeader);` statement or call it using the package name: `CommandLineInterface::getHeader();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt

I<Code>

    print("The outfile header:\n",CommandLineInterface::getHeader());

I<Output>

    The outfile header:
    #your_version_number
    #User: your_username
    #Time: Thu Feb  9 15:43:36 2017
    #Host: your_hostname
    #PID: your_process_id
    #Directory: /where/you/ran/the/script
    #Command: /usr/bin/perl example.pl -i in.txt

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --header            Print commented header to outfiles.  See getHeader()

I<LIMITATIONS>

getHeader fills in some information using environment variables like USER, HOST, and PWD.  If those variables are not defined in the user's environment, those fields in the header will be empty.

There is no way to select specific output files to get headers and others to not get headers.

Reading of input files does not skip automatically generated headers by default.

See the LIMITATIONS section of processCommandLine() for information on headers output to STDOUT.

I<ADVANCED>

Note that CommandLineInterface knows if you are redirecting output via a pipe or out to a file, in which case the header is printed.  Every output file gets a header.  When output is going to a terminal session (i.e. a tty), header output is withheld.

To skip headers when reading in a file generated by a script using CommandLineInterface, you must skip the header during file processing, e.g. `next if(/^#/)`.

=item C<getInHandleFileName> HANDLE

Returns the file name (and path as supplied) associated with the input file handle.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i ../in.txt

I<Code>

    openIn(*INPUT,getInfile());
    print("Input file: ",getInHandleFileName(*INPUT));

I<Output>

    Input file: ../in.txt

=back

I<ASSOCIATED FLAGS>

Default file options that are added if none defined (which affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

None.

I<ADVANCED>

n/a

=item C<getInfile> [FILETYPEID*, ITERATE]

Returns the file of type FILETYPEID (the ID returned by addInfileOption) that is among the current combination of files that are being processed together (see nextFileCombo()).

If ITERATE supplied and non-zero, multiple calls with the same FILETYPEID will advance the nextFileCombo() iterator.  The entire combination is advanced.

If ITERATE is not supplied, iteration is set to automatic and the behavior depends on whether the nextFileCombo() iterator has been called or not.  Calling nextFileCombo puts automatic iteration control under it's control.  Without calling nextFileCombo(), iteration is controlled by getInfile() and/or getOutfile().  A warning will be issued about possible skipped file combinations if getInfile() and the nextFileCombo() is called.  See the ADVANCED section below for notes on how this relates to files that have a ONETOMANY relationship with other files.

* FILETYPEID is optional when there is only 1 input file type, in which case, it defaults to the single input file type.  It is required otherwise.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '1.txt 2.txt'

I<Code>

    while(my $f = getInfile($fid,1))
      {print($f,"\n")}

I<Output>

    1.txt
    2.txt

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --skip              Skip file set w/ existing outfiles. See nextFileCombo()

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

None.

I<ADVANCED>

If there is only one input file type, the FILETYPEID is optional.  Without ITERATE, or with ITERATE => 0, the same file will be returned each time and the file set iterator will not advance.

getInfile() must always be called inside a loop controlled by nextFileCombo() (if you use nextFileCombo() at all.  This is because every file type is included in the nextFileCombo() iterator, even those which have a ONETOMANY relationship.  What this means is that the same ONETOMANY file will be returned with every one of the other files.  The reasons for this are 1. to support the novel feature of a ONETOONEORMANY relationship and 2. to allow any number of sets of ONETOMANY pairs of file types to be processed.

What this means is that you cannot as of yet process the ONETOMANY 'one' file outside of the loop that returns that file repeatedly.  Requirement 132 will address this limitation.  Until then, the 'one' file in a ONETOMANY relationship must be tracked so that it is processed only once.  For example:

=over 4

    my($onedata);
    while(nextFileCombo())
      {
        my $manyfile = getInfile($id1);
        my $onefile  = getInfile($id2);

        unless(exists($seen->{$onefile}))
          {$onedata = processOneFile($onefile)}
        $seen->{$onefile}++;

        processManyFile($manyfile,$onedata);
      }

=back

=item C<getLine> HANDLE VERBOSELEVEL VERBOSEFREQ

In SCALAR context, returns the next line of the file connected to HANDLE (see openIn()).

In LIST context, returns all lines (or all remaining lines).

The advantage of using getLine over <INP> is that it recognizes carriage returns (\r) and off combinations of them with newlines (\n).

VERBOSELEVEL determines how many verbose flags the user must supply before a verbose message about the current line number being read will be printed to STDERR.  Default value is 2.

VERBOSEFREQ is a number that indicates how many lines to read between verbose message printings.  E.g. The value '100' will print a verbose messages every 100th line read.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    getLine(HANLDE => *INP);

    #or

    getLine(*INP);

I<Output>

    n/a

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all errors, warnings, & debugs.  See quiet()
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --debug             Prints debug messages.  See debug()

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

None.

I<ADVANCED>

This method handles files containing carriage returns, newlines, or both.  It does this by reading lines into a buffer and shifting lines off as they are requested.

=item C<getNextFileGroup> [FILETYPEID*]

getNextFileGroup is an iterator that retrieves an array of input files all provided by a single instance of a flag defined by addInfileOption.  In scalar context, it returns a reference to an array of file names.  In list context, it returns an array of file names.

FILETYPEID is the ID returned by addInfileOption().  Supply it to specify the type of input files supplied by the flag defined by addInfileOption().

* FILETYPEID is optional when there is only 1 input file type, in which case, it defaults to the single input file type.  It is required otherwise.

Note that it is highly recommended to use the nextFileCombo() iterator instead of the getNextFileGroup iterator, because it associates input files with their corresponding output files and when there are multiple types of input files, it associates them in order.  It's a much more robust iterator.

I<EXAMPLE>

=over 4

I<Command>

    #>ls
    #1.txt 2.txt 3.txt a.text b.text c.text

    example.pl -i '*.txt' -i '*.text'

I<Code>

    my $fid = addInfileOption(FLAG => 'i');
    processCommandLine();
    while(my $inf_group = getNextFileGroup())
      {print(join(' ',@$inf_group),"\n")}

I<Output>

    1.txt 2.txt 3.txt
    a.text b.text c.text

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

This method can only be used to retrieve input files, not output files, thus it is highly recommended to use the nextFileCombo() iterator in combination with getInfile() and getOutfile() instead of this method.

There is currently no way as of yet to reset this iterator explicitly, though it automatically resets after having returned an undefined value indicating that no more file groups are present.  A reset method will be provided when requirement 173 is implemented.

This method does not skip any input files that may be associated with existing output files when --skip is provided.  --skip functionality is implemented in the openOut() method.

I<ADVANCED>

Note, when the iterator has nothing more to return, it returns an undefined value, however it automatically resets, so if it is called again after having returned an undefined value, it starts back over from the beginning.

=item C<getNumFileGroups> [FILETYPEID*]

This method returns the number of times a flag defined by addInfileOption was provided by the user on the command line.  If the input file type is PRIMARY and input is detected on standard in, the number returned accounts for it as if there was a flag supplied.

FILETYPEID is the ID returned by addInfileOption().  Supply it to specify the type of input files supplied by the flag defined by addInfileOption().

* FILETYPEID is optional when there is only 1 input file type, in which case, it defaults to the single input file type.  It is required otherwise.

I<EXAMPLE>

=over 4

I<Command>

    #>ls
    #1.txt 2.txt 3.txt a.text b.text c.text

    example.pl -i '*.txt' -i '*.text'

I<Code>

    my $fid = addInfileOption(FLAG => 'i');
    processCommandLine();
    print(getNumFileGroups(),"\n");

I<Output>

    2

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

This method can only be used to retrieve a number of input file flags for a single input file type, not for output files.

This method does not skip any input file groups that may be associated with existing output files when --skip is provided.

I<ADVANCED>

n/a

=item C<getOutfile> SUFFIXID [, ITERATE]

Returns a file name for the output file type specified by SUFFIXID (the ID returned by addOutfileSuffixOption()) that is in the current file set (see nextFileCombo()).

If ITERATE supplied and non-zero, multiple calls with the same SUFFIXID will advance the nextFileCombo() iterator.  The entire combination is advanced.

If ITERATE is not supplied, iteration is set to automatic and the behavior depends on whether the nextFileCombo() iterator has been called or not.  Calling nextFileCombo puts automatic iteration control under it's control.  Without calling nextFileCombo(), iteration is controlled by getInfile() and/or getOutfile().  A warning will be issued about possible skipped file combinations if getOutfile() and the nextFileCombo() is called.  See the ADVANCED section below for notes on how this relates to files that have a ONETOMANY relationship with other files.

I<EXAMPLE>

=over 4

I<Command>

     example.pl -i '1.txt 2.txt' -o .out

I<Code>

    while(my $f = getInfile($fid,1))
      {
        my $o = getOutfile($oid);
        print($o,"\n");
      }

I<Output>

    1.txt.out
    2.txt.out

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --skip              Skip file set w/ existing outfiles. See nextFileCombo()

Default file options that are added if none defined (which also affect the behavior of this method):

    -o                  Output file suffix. see addOutfileSuffixOption()
    --outfile           Output file. see addOutfileOption()
    --outdir            Output directory. see addOutdirOption()

I<LIMITATIONS>

The returned file name has the suffix appended to the full input file name it was connected to when addOutfileSuffixOption() was called.  It does not replace an existing extension (yet).  This will be addressed when requirement 171 is implemented.

While the file will have been checked for pre-existing files by the same name or even checked for predicted future output file name conflicts, the check is performed at the beginning of the script, so the file could have been already created by another process or by code that doesn't use openOut by the time the file is opened.  Thus an output file must be opened by openOut to guarantee overwrite protection.

I<ADVANCED>

addOutFileSuffixOption() and addOutfileOption() both return an ID that is accepted by getOutfile using its SUFFIXID parameter (even though it refers to it as a suffix and addOutfileOption ostensibly returns an output file ID).  This is actually because of code re-use.  addOutfileOption is really a wrapper for the creation of a hidden input file type (which is presented in the usage as an output file) and a call to addOutfileSuffixOption(), where the default value for the suffix is set to an empty string.  The input file types that are actually output files are tracked so that they are not processed as input files.

getOutfile() must always be called inside a loop controlled by nextFileCombo() (if you use nextFileCombo() at all.  This is because every file type is included in the nextFileCombo() iterator, even those which have a ONETOMANY relationship.  What this means is that the same ONETOMANY file will be returned with every one of the other files.  The reasons for this are 1. to support the novel feature of a ONETOONEORMANY relationship and 2. to allow any number of sets of ONETOMANY pairs of file types to be processed.

What this means is that you cannot as of yet process the ONETOMANY 'one' file outside of the loop that returns that file repeatedly.  Requirement 132 will address this limitation.  Until then, the 'one' file in a ONETOMANY relationship must be tracked so that it is processed only once.  For example:

=over 4

    while(nextFileCombo())
      {
        my $manyfile = getInfile($id1);
        my $onefile  = getOutfile($id2);

        unless(exists($seen->{$onefile}))
          {openOut(*OUT,$onefile)}
        $seen->{$onefile}++;

        processManyFile($manyfile,$onedata);
      }

=back

Note that if you set the COLLISIONMODE to 'merge' in the call to addOutfileOption() earlier during the command line interface definition section of code, then the output file check (as above) is unnecessary.  openOut() and closeOut() will allow output to concatenate in the file, but without --append specified by the user, it will not append to a file that existed before the script started.  For example:

=over 4

    while(nextFileCombo())
      {
        my $manyfile = getInfile($id1);
        my $onefile  = getOutfile($id2);

        openOut(*OUT,$onefile);

        processManyFile($manyfile,$onedata);

        closeOut(*OUT);
      }

=back

=item C<getOutHandleFileName> HANDLE

Returns the file name (and path as supplied) associated with the output file handle.

I<EXAMPLE>

=over 4

I<Command>

    example.pl --outfile out.txt

I<Code>

    openIn(*OUT,getOutfile());
    print("Output file: ",getInHandleFileName(*OUT));

I<Output>

    Output file: out.txt

=back

I<ASSOCIATED FLAGS>

Default file options that are added if none defined (which affect the behavior of this method):

    -o                  Output file suffix. see addOutfileSuffixOption()
    --outfile           Output file. see addOutfileOption()

I<LIMITATIONS>

None.

I<ADVANCED>

n/a

=item C<getVersion> [COMMENT, EXTENDED]

Returns the version number of the script (set by setScriptInfo()) in which CommandLineInterface is being used.  If the script author did not seet a version number, the string 'UNKNOWN' will be returned.

If --extended is supplied on the command line, multi-line output is generated including script name, creation date, last modified date, author, company, license, and similar information about the version of CommandLineInterface.

If COMMENT is supplied and non-zero, the returned string will be commented.

If EXTENDED is 1 or greater, the script name is included, e.g. "example.pl Version 1.0".  If EXTENDED is 2 or larger, a multi-line string is returned that includes information such as autheor, last modified date, etc..  If EXTENDED is 3 or larger, version information about CommandLineInterface is also included.  Supplying EXTENDED over-rides the user's setting of --extended on the command line (even if set to 0).  The number of times --extended is supplied (or if a single instance is given a value (e.g. --extended 2) and EXTENDED is not supplied, the value supplied by the user on the command line is used.

getVersion() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... getVersion);` statement or call it using the package name: `CommandLineInterface::getVersion();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt

I<Code>

    setScriptInfo(VERSION => '1.2');
    print(getVersion());

I<Output>

    1.2

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --extended          Print extended usage/help/version/header.

I<LIMITATIONS>

None

I<ADVANCED>

n/a

=item C<headerRequested>

This method returns the value of the --header (or --no-header) flag.  The value will be 1 if --header was provided on the command line, 0 if --no-header was supplied once, or 1 if neither was supplied nor saved as a default (see --save-as-default).

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt --no-header

I<Code>

    print("Value of --header: ",headerRequested());

I<Output>

    Value of --header: 1

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --header            Print commented header to outfiles.  See getHeader()

I<LIMITATIONS>

headerRequested() calls processCommandLine() to get the value of the flag if the command line has not yet been processed, thus you cannot call headerRequested() before you have finished all calls to the add*Options methods.

I<ADVANCED>

n/a

=item C<help> [ADVANCED, IGNORE_UNSUPPLIED]

The help() method prints information about the script that is set by setScriptInfo() and the input and output file formats (whose information is set by calls to addInfileOption(), addOutfileOption(), and addOutfileSuffixOption().

ADVANCED mode (supplied & non-zero) prints detailed information about overwrite protection and advanced file IO features.  CommandLineInterface calls the help() method automatically when --help is supplied and ADVANCED is set to non-zero if --extended is also supplied.

If IGNORE_UNSUPPLIED is supplied & non-zero and the author of the script has not provided information on input and output file formats, or a description of what the script does, those sections of the help output will be skipped.  Otherwise, a message that the author has not yet supplied the information is printed.

help() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... help);` statement or call it using the package name: `CommandLineInterface::help();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    setScriptInfo(VERSION => "1.0a",
                  CREATED => "11/28/2016",
                  HELP    => "This script does x and y.");
    processCommandLine();
    CommandLineInterface::help();

I<Output>


    example.pl version 1.0a
    Created: 11/28/2016
    Last Modified: Fri Feb 10 09:55:47 2017

    * WHAT IS THIS: This script does x and y.
    * INPUT FORMAT:   The author of this script has not provided a format
      -i,--infile,    description for this input file type.  Please add a
      --stub          description using the addInfileOption method.
    * OUTPUT FORMAT:  The author of this script has not provided a format
      -o,             description for this input file type.  Please add a
      --suffix        description using one of the addOutfileOption or
                      addOutfileSuffixOption methods.



=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --help              Print help message and quit.  See help()
    --extended          Print extended usage/help/version/header.

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()
    -o                  Output file suffix. see addOutfileSuffixOption()
    --outfile           Output file. see addOutfileOption()

I<LIMITATIONS>

It is not possible to set the input & output format help messages of the default -i and -o/--outfile options.  In order to provide these messages, you must create the options using addInfileOption(), addOutfileOption(), and addOutfileSuffixOption().  When these options are provided, they replace the default options.

I<ADVANCED>

n/a

=item C<inPipeline>

This method guesses whether the script is running from within another script or whether it is being piped to or from another command (i.e. not a file).  It is used internally to know whether its STDERR messages might be mixed with those from other commands.  It uses this awareness to prepence warnings, errors, and debug messages with the script name so that the user knows the source of any message.

It returns 1 if it thinks it is not being run as part of a pipeline.  It returns 0 if it thinks it is being run manually & by itself.

Pipeline mode modifications to messages can be explicitly set by the user by supplying --pipeline or --no-pipeline.

inPipeline() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... inPipeline);` statement or call it using the package name: `CommandLineInterface::inPipeline();`.

I<EXAMPLE 1>

=over 4

I<Command>

    example.pl -i in.txt

I<Code>

    print("In pipeline?: ",CommandLineInterface::inPipeline());

I<Output>

    In pipeline?: 0

=back

I<EXAMPLE 2>

=over 4

I<Command>

    cat in.txt | example.pl

I<Code>

    print("In pipeline?: ",CommandLineInterface::inPipeline());

I<Output>

    In pipeline?: 1

=back

I<ASSOCIATED FLAGS>

The following default option does not affect the behavior of this method, but rather affects whether the method is called automatically:

    --pipeline          Prepends script name to errors, warnings, & debugs.

I<LIMITATIONS>

This method is experimental and should not be relied upon for serious logic decisions.  For example, processes running in the background may result in pipeline mode being enabled.  It is only used in CommandLineInterface to prepend the script name to various STDERR messages and may not behave as expected on some systems.

I<ADVANCED>

This method is used to set a class variable which a user can set explicitly by supplying either --pipeline or --no-pipeline.  If the user does not supply either of those flags, inPipeline is called only once to set the class variable.  It is called the first time a debug, warning, or error message is printed.  It uses pgrep and lsof and parses the output to determine whether there exist any sibling processes with the same parent process or if the parent process is reading a script input file.

=item C<isDebug>

This method returns the value of the --debug flag.  The value will be 0 if --debug was not provided on the command line, 1 if --debug was supplied once, 2 if supplied twice, etc..  The --debug flag can also take a value (e.g. --debug 3) in which case, that is the value that is returned.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt --debug

I<Code>

    print("Value of --debug: ",isDebug());

I<Output>

    Value of --debug: 1

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --debug             Prints debug messages.  See debug()

I<LIMITATIONS>

isDebug() calls processCommandLine() to get the value of the flag if the command line has not yet been processed, thus you cannot call isDebug() before you have finished all calls to the add*Options methods.

I<ADVANCED>

n/a

=item C<isDryRun>

This method returns the value of the --dry-run flag.  The value will be 0 if --dry-run was not provided on the command line or 1 if it was supplied.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt --dry-run

I<Code>

    print("Value of --dry-run: ",isDryRun());

I<Output>

    Value of --dry-run: 1

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --dry-run           Skip all directory and outfile creation steps.

I<LIMITATIONS>

isDryRun() calls processCommandLine() to get the value of the flag if the command line has not yet been processed, thus you cannot call isDryRun() before you have finished all calls to the add*Options methods.

I<ADVANCED>

n/a

=item C<isForced>

This method returns the value of the --force flag.  The value will be 0 if --force was not provided on the command line, 1 if --force was supplied once, 2 if supplied twice, etc..  The --force flag can also take a value (e.g. --force 3) in which case, that is the value that is returned.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt --force

I<Code>

    print("Value of --force: ",isForced());

I<Output>

    Value of --force: 1

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --force             Prevent quit upon critical errors.

I<LIMITATIONS>

isForced() calls processCommandLine() to get the value of the flag if the command line has not yet been processed, thus you cannot call isForced() before you have finished all calls to the add*Options methods.

I<ADVANCED>

n/a

=item C<isThereInputOnSTDIN>

This method returns true (/non-zero) if input has been piped or redirected into the script.  If input is not present on STDIN, it returns false (/0).

isThereInputOnSTDIN() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(:DEFAULT isThereInputOnSTDIN);` statement or call it using the package name: `CommandLineInterface::isThereInputOnSTDIN();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt

I<Code>

    print("Input coming in on standard in?: ",
          CommandLineInterface::isThereInputOnSTDIN());

I<Output>

    Input coming in on standard in?: 0

=back

I<ASSOCIATED FLAGS>

n/a

I<LIMITATIONS>

None.

I<ADVANCED>

n/a

=item C<isStandardOutputToTerminal>

This method returns true (/non-zero) if output has not been piped or redirected out from the script.  If output has been redirected to a file or piped into another command, it returns false (/0).

isStandardOutputToTerminal() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... isStandardOutputToTerminal);` statement or call it using the package name: `CommandLineInterface::isStandardOutputToTerminal();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt > out.txt

I<Code>

    print("Output going to TTY?: ",
          CommandLineInterface::isStandardOutputToTerminal());

I<Output>

    Output going to TTY?: 0

=back

I<ASSOCIATED FLAGS>

n/a

I<LIMITATIONS>

None

I<ADVANCED>

n/a

=item C<isVerbose>

This method returns the value of the --verbose flag.  The value will be 0 if --verbose was not provided on the command line, 1 if --verbose was supplied once, 2 if supplied twice, etc..  The --verbose flag can also take a value (e.g. --verbose 3) in which case, that is the value that is returned.  This method is useful if for example, you are making a system call and need to know whether to provide a verbose or quiet flag.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt --verbose

I<Code>

    print("Value of --verbose: ",isVerbose());

I<Output>

    Value of --verbose: 1

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --verbose           Prints verbose messages.  See verbose()

I<LIMITATIONS>

isVerbose() calls processCommandLine() to get the value of the flag if the command line has not yet been processed, thus you cannot call isVerbose() before you have finished all calls to the add*Options methods.

I<ADVANCED>

n/a

=item C<markTime> [MARKINDEX]

If not provided a MARKINDEX, this method marks the time, adding it to an array.  In scalar context, it returns the time (in seconds) since the last mark.  If a MARKINDEX is supplied, (starting from 0) no mark is added to the marks array and it returns the time since the supplied mark.

The first mark is always the start time of the script.

markTime() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... markTime);` statement or call it using the package name: `CommandLineInterface::markTime();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt

I<Code>

    sleep(2);
    print("Elapsed time (s): ",CommandLineInterface::markTime());

I<Output>

    Elapsed time (s): 2

=back

I<ASSOCIATED FLAGS>

n/a

I<LIMITATIONS>

Only whole seconds are reported.

There is currently no way to obtain the MARKINDEX that was created when markTime() is called.  One must keep a cound if specific marks are desired.  Note, you can also use negative indexes.

I<ADVANCED>

n/a

=item C<nextFileCombo>

CommandLineInterface processes files in pairs, or more generally, in sets of files of different types which we will refer to here as a file set.  The nextFileCombo() iterator advances through a 2 dimensional array of files that as a set are processed together.  There is one file of each type (both input and output) in a set/combination.  If multiple files are supplied to a flag "-i" and multiple files are supplied to flag "-j" (as long as they each are supplied with the same number of files), the first file of each group of files supplied to each flag, put together, is the first file set.  nextFileCombo() is an iterator that advances through all of those "pairs", so it is usually called within a while loop.

Returns true until there are no more input file sets to advance to.

File names can be retrieved using getInfile() and getOutfile() by simply supplying the file type as the only argument.  Hint: if you're unsure of the order the files will come out in, you can use --verbose --dry-run with your file options to see the order in which the files are returned.

getInfile() and getOutfile(), if nextFileCombo() has not been called, will call it implicitly each time one of them is prompted to return the same member of a combination twice.  If nextFileCombo() has been called before either of these methods has, getInfile() and getOutfile() will not auto-iterate.  See getInfile() and getOutfile() for more information.

Input files can be added with relationships to other input files, such as is described above (1:1 or "one-to-one") or in one of any of these relationships: 1:M (one-to-many) or 1:1orM (one-to-one-or-many).  The 1:M relationship affects the file sets in the following manner, best seen by example:

I<EXAMPLE 1> One-to-many

=over 4

I<Command>

    example.pl -i '1.txt 2.txt' -j a.txt

I<Code>

    while(nextFileCombo())
      {print(getInfile($fid1)," ",getInfile($fid2),"\n")}

I<Output>

    1.txt a.txt
    2.txt a.txt

=back

For tips on how to avoid processing the same file multiple times, refer to the DISCUSSION section below, under 1:1orM, or take a look at the ADVANCED section of each of the getInfile() and getOutfile() methods.

I<EXAMPLE 2> One-to-one

=over 4

I<Command>

    example.pl -i '1.txt 2.txt' -j 'a.txt b.txt'

I<Code>

    while(nextFileCombo())
      {print(getInfile($fid1)," ",getInfile($fid2),"\n")}

I<Output>

    1.txt a.txt
    2.txt b.txt

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --skip              Skips file sets if 1 or more output files exists.

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()
    -o                  Output file suffix. see addOutfileSuffixOption()
    --outfile           Output file. see addOutfileOption()
    --outdir            Output directory. see addOutdirOption()

These and any other options added using the indicated add*Option methods define the files that nextFileCombo() uses for iterating.  Note, --outdir only changes the strings returned when retrieving the output files.

I<LIMITATIONS>

M:M "many-to-many" is not currently fully supported.  Refer to the DISCUSSION section, under the heading M:M for more information.  This will be addressed when requirement 140 is implemented.

There is currently no means of sub-iterating based on file relationships (e.g. files that have a ONETOMANY relationship with other files.  This will be addressed once requirement 132 has been implemented.  Requirement 264 will also address this limitation.

I<ADVANCED>

Calling nextFileCombo() triggers the processing of the command line options (if they have not been processed already).

The iterator will start over the next time it is called after having returned undef.

=item C<openIn> HANDLE, FILE [, QUIET]

Opens FILE for input to be read on HANDLE unless --dry-run was supplied.

Returns non-zero if successful (or if --force was supplied).  0 otherwise.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    my $myfile = getInfile();

    openIn(HANLDE => *INP,
           FILE   => $myfile,
           QUIET  => 1);

    #or

    openIn(*INP,$myfile,1);

I<Output>

    n/a

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all errors, warnings, & debugs.  See quiet()
    --error-limit       Suppress some errors & warnings.  See error()/warning()
    --verbose           Prints open message.  See verbose()
    --debug             Prints debug messages.  See debug()

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

Only designed to handle files and STDIN.  Piping and/or system call behavior not supported.

I<ADVANCED>

Tracks open file handles.  Generates verbose messages if --verbose is supplied on the command line and QUIET is not supplied (or 0).  Supplying QUIET => 1 will also cause closeIn to be quiet as well.

If --dry-run was supplied, the file is opened, but immediately closed (in order to catch potential errors with a real run).

Opens STDIN if FILE is '-'.

=item C<openOut> HANDLE [, FILE, SELECT, QUIET, HEADER, APPEND, MERGE]

Opens FILE for writing through HANDLE unless --dry-run was supplied.  Opens STDOUT if FILE is not supplied.

Returns non-zero if successful (or if --force was supplied).  0 otherwise.

If SELECT is non-zero, the handle is selected.  Generates verbose messages if --verbose is supplied on the command line and QUIET is not supplied (or 0).

If --header is supplied (or --noheader is not supplied, depending on the default), the first time a file is opened for writing, a header will be printed to the output file.  See getHeader().

If APPEND is non-zero, a file will be opened in append mode.  0 = open for writing from the beginning of the file.  0 is subject to over-write protection.  APPEND differs from MERGE in that it only applies to the first time it is opened.  The number of times a file is opened is tracked in order to support output files that have a ONETOONEORMANY relationship with input files.  Different input files which generate output to the same file is what MERGE is for, which is distinct from APPENDing to pre-existing files before the script was run.

If MERGE has a non-zero value, subsequent times a file is opened (after the first open), it is opened in append mode.  Note that an error will be generated in if the file being written to already exists the first time it is opened unless APPEND is non-zero.

I<EXAMPLE 1>

I<Command>

    example.pl -i '*.txt' -o .out

I<Code>

=over 4

    while(nextFileCombo())
      {
        my $infile = getInfile();
        my $myfile = getOutfile();

        openOut(HANLDE => *OUTP,
                FILE   => $myfile,
                SELECT => 1,
                QUIET  => 1,
                HEADER => 1,
                APPEND => 0,
                MERGE  => 0);

        ...

        closeOut(*OUTP);
      }

I<Output>

    *.txt.out

=back

I<EXAMPLE 2>

I<Command>

    example.pl -i '*.txt' --outfile merged_output.out

I<Code>

=over 4

    while(nextFileCombo())
      {
        my $infile = getInfile();
        my $myfile = getOutfile();

        openOut(*OUTP,$myfile,1,1,1,0,1);

        ...

        closeOut(*OUTP);
      }


I<Output>

    merged_output.out

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all errors, warnings, & debugs.  See quiet()
    --verbose           Print close message.  See verbose() and verboseOverMe()
    --debug             Prints debug messages.  See debug()
    --overwrite         Overwrites existing output files.
    --skip              Skip file set w/ existing outfiles. See nextFileCombo()
    --append            Append to existing outfiles.
    --dry-run           Skip all directory and outfile creation steps.
    --force             Prevent quit upon critical errors.
    --header            Print commented header to outfiles.  See getHeader()

Default file options that are added if none defined (which also affect the behavior of this method):

    -o                  Output file suffix. see addOutfileSuffixOption()
    --outfile           Output file. see addOutfileOption()
    --outdir            Output directory. see addOutdirOption()

I<LIMITATIONS>

Only designed to handle files and STDOUT.  Piping and/or system call behavior not supported.

I<ADVANCED>

Tracks open file handles.  Generates verbose messages if --verbose is supplied on the command line and --quiet is not supplied.  Supplying QUIET => 1 will also cause closeOut to be quiet as well.

If --dry-run was supplied, the file is not opened, but a successful open status is returned.

Overwrite protection is implemented in this method.  If --overwrite is not supplied, this method will not open a pre-existing file and will return a status of 0 with an error.

Opens STDOUT if FILE is '-'.  See the PRIMARY parameter to the addOutfileOption() and addOutfileSuffixOption() methods for information on how '-' can be automatically set when no method of generating output files is supplied on the command line by the user.

Quits with a critical error if FILE is undefined.

=item C<printRunReport> [ERRNO]

Deceptively named, this method will print a run report only if it is deemed that a run report is desireable.  A run report is deemed desireable if --quiet was not supplied and either --verbose was supplied, --debug was supplied, there was at least 1 warning or error, or ERRNO is non-zero.

ERRNO is assumed to be the exit code that will be used upon exit of the script.

If an error or warning occurred during execution, a summary of each error/warning type that occurred is also printed, containing the number of errors of the specified type and an example snippet of one of the errors.

Output goes to standard error and is never buffered.  An empty line preceeds the run report.

This method is called automatically in the quit() method (which is called in the END block.

printRunReport() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... printRunReport);` statement or call it using the package name: `CommandLineInterface::printRunReport();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i in.txt

I<Code>

    error("Something bad happened");
    CommandLineInterface::printRunReport(4);

I<Output>

    ERROR1: Something bad happened

    Done.  STATUS: [EXIT-CODE: 4 ERRORS: 1 WARNINGS: 0 TIME: 0s] SUMMARY:
    	1 ERROR LIKE: [ERROR1: Something bad happened]
    	Scroll up to inspect full errors/warnings in-place.

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --debug             Prints debug messages.  See debug()

I<LIMITATIONS>

Exit code must be supplied.  There's no way to not print the message about the exit code.

Output is not buffered (in case the class variables are not defined for --verbose, --debug, etc.).

If --error-limit is set to 0, the format and content of the output will be sub-optimal.  Use --quiet instead.

I<ADVANCED>

Error types are tracked by the line on which error() or warning() is called.

The example of errors/warnings given in the summary is the first occurrence of that type of error.

Long errors and warnings in the summary are truncated.

=item C<processCommandLine>

processCommandLine() triggers the arguments on the command line to be processed.  All options are handled automatically.  For example, if --help was supplied, the help message is printed and the script exits.

CommandLineInterface was designed primarily for file processing scripts, thus if no input files or options are provided, a usage is printed and the script exits.

If your script does processing of input files, it is not necessary to call this method.  It will be called implicitly the first time you access an input file.  If your script does not actually process any input files, you must call this method to trigger the processing of the command line.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -j "Hello World"

I<Code>

    my $string = '';
    addOption(FLAG   => 'j',
              VARREF => \$string,
              TYPE   => 'string');
    processCommandLine();
    print($string);

I<Output>

    Hello World

=back

I<ASSOCIATED FLAGS>

processCommandLine uses/sets every default option provided by CommandLineInterface.  If --verbose is supplied, all option settings are reported on STDERR.

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.
    --error-limit       Suppress some errors & warnings.  See error()/warning()
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --pipeline          Prepends script name to errors, warnings, & debugs.
    --debug             Prints debug messages.  See debug()
    --overwrite         Overwrites existing output files.
    --skip              Skip file set w/ existing outfiles. See nextFileCombo()
    --append            Append to existing outfiles.
    --dry-run           Skip all directory and outfile creation steps.
    --force             Prevent quit upon critical errors.
    --help              Print help message and quit.  See help()
    --extended          Print extended usage/help/version/header.
    --version           Print version message and quit.  See getVersion()
    --header            Print commented header to outfiles.  See getHeader()
    --save-as-default   Save current options for inclusion in every run.

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()
    -o                  Output file suffix. see addOutfileSuffixOption()
    --outfile           Output file. see addOutfileOption()
    --outdir            Output directory. see addOutdirOption()

I<LIMITATIONS>

There is currently no way to use CommandLineInterface in a script in a mode where it operates when nothing is supplied on the command line because when processCommandLine() is called, it will automatically print a usage and exit.  This will be addressed when requirement 157 is implemented.

Likewise, there is no way to remove the default input or output file/directory options without adding your own version of those options.  This will be addressed when requirement 174 is implemented.

If the --header (or --noheader) flag is not provided on the command line, processCommandLine() tries to predict if script output is being redirected into a file and if so, it prints the header to STDOUT, but it is only a guess and sometimes gets it wrong.  The logic used is whether the output is going to a TTY or not and whether a suffix has been provided.

I<ADVANCED>

processCommandLine triggers most of the default functionality, such as overwrite protection.  All anticipated output files are checked up-front for possible overwrite and collision situations.

=item C<quit> ERRNO

The quit() method, aside from exiting the script with the given ERRNO exit code, does 3 things:

    1. Flushes the standard error buffer (if called before the command line parameters have been processed).
    2. Prints a run report summarizing errors, warnings, etc..
    3. Skips the exit if --force was supplied and ERRNO is non-zero

The run report will print (at a minimum) a summary of the exit status if the conditions upon quitting include a non-zero (or undefined) exit code, any errors or warnings were printed, --verbose was supplied, or if any debug statements were printed.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    quit(1);

I<Output>


    Done.  STATUS: [EXIT-CODE: 1 ERRORS: 0 WARNINGS: 0 TIME: 0s]

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --debug             Prints debug messages.  See debug()
    --force             Prevent quit upon critical errors.

I<LIMITATIONS>

None.

I<ADVANCED>

quit(0) is called inside the END block in order to clean up the STDERR buffer, any remaining unclosed file handles, print the run report (if necessary), etc.

=item C<resetFileGroupIterator> [FILETYPEID*]

getNextFileGroup() is an iterator that cycles through groups of files provided by a number of instances of the same input file flag (e.g. -i).  Each flag can take a group of input files, which is what getNextFileGroup() returns.  Each call to getNextFileGroup() returns the next group in the order they occur on the command line.  resetFileGroupIterator() allows you to reset that iterator so that the next call to getNextFileGroup() will return the first group of files.

Note that the iterator resets on its own after having returned undef after the last groupd was returned.

FILETYPEID indicates the input file type (it's what's returned by addInfileOption()).

Note that it is highly recommended to use the nextFileCombo() iterator instead of the getNextFileGroup iterator, because it associates input files with their corresponding output files and when there are multiple types of input files, it associates them in order.  It's a much more robust iterator.

* FILETYPEID is optional when there is only 1 input file type, in which case, it defaults to the single input file type.  It is required otherwise.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '{1,2}.txt' -i '{a,b}.txt' -i 'alpha.txt'

I<Code>

    @files1 = getNextFileGroup();
    @files2 = getNextFileGroup();
    resetFileGroupIterator();
    @files3 = getNextFileGroup();
    print(@files1,"\n",@files2,"\n",@files3);

I<Output>

    1.txt 2.txt
    a.txt b.txt
    1.txt 2.txt

=back

I<ASSOCIATED FLAGS>

Default file options that are added if none defined (which affect the behavior of this method):

    -i                  Input file. see addInfileOption()

I<LIMITATIONS>

This iterator does not associate input files with corresponding output files, such as those defined by addOutfileOption() and addOutfileSuffixOption(), thus getOutfile() will not return files in an order associated with the files returned by the file group iterators.  Output files must be handled manually if you use this iterator.

I<ADVANCED>

n/a

=item C<setDefaults> [HEADER, ERRLIMIT, COLLISIONMODE, DEFRUNMODE, DEFSDIR, UNPROCFILEWARN]

Use this method to set default values for some command line flags that CommandLineInterface provides (or doesn't provide).

HEADER sets --header.  Can be 0 or 1.  See headerRequested().  Default is 0.

ERRLIMIT sets --error-limit.  Unsigned integer.  See error() and warning().  Default is 5.  0 is unlimited.

COLLISIONMODE is an advanced feature that determines what the script does when outfile names conflict/collide.  Possible values are:

    error  = an error will be generated
    merge  = output is merged/concatenated together in processing order
    rename = composite output filenames are constructed by combining input file names (joined with a '.')

COLLISIONMODE sets the default behavior for all output file types that do not specify a COLLISIONMODE explicitly.  This differs from supplying --collision-mode on the command line (see `--usage --extended --extended`), which over-rides the modes set by all of the addOutfile*Option methods.

The default value for each output file type depends on how the outfile option was defined.  Output file types defined by the addOutfileOption method, default to a collision mode of 'merge' and output file types defined by addOutfileSuffixOption default to a collision mode of 'error'.  Setting this value changes the default for both types.  This will change when requirement 114 is implemented.

For functionality related to COLLISIONMODE for files not controlled by the user on the command line, see the APPEND parameter to the openOut method.  Setting COLLISIONMODE to 'merge' is the same as setting openOut's APPEND parameter explicitly to -1.  In fact, explicitly setting openOut's APPEND parameter to anything else over-rides all COLLISIONMODE settings, regardless of how they are specified.

DEFRUNMODE (i.e. 'Default Run Mode') in short, determines how the script behaves either when no arguments are supplied on the command-line and all the conditions required to run are met.

For example, running a script without any arguments provided on the command line can have a couple desireable outcomes (and what is desireable depends on the script):

    1. Generate a usage message
    2. Generate a help message
    3. Run the script (e.g. if required options have values*)
    4. Run the script in dry-run mode (e.g. if required options have values*)

* A required option can have either a hard-coded default value (see the various add*Option methods) or a user-saved default value (see --save-as-default).  The above behaviors apply only when no options are supplied on the command line.

Possible values of DEFRUNMODE and the resultant script behavior when no arguments are supplied are:

    usage   = Prints usage & exits [DEFAULT]
    run     = Runs script
    dry-run = Runs script without writing to output files
    help    = Prints help & exits

Each mode adds flags for the other modes to the command line interface (e.g. --run, --dry-run, --usage, or --help).  Note that if required options without defaults exist, --run is omitted as an option because the default behavior of all modes is to run when all required options have values and an argument is explicitly supplied on the command line.  --extended and --debug options are the exception - they will not trigger a script to run by themselves unless DEFRUNMODE is 'run'.

A main goal of DEFRUNMODE is to not get in the way.  In any mode, if there are required options, and they all have values defined by any means, execution will not be halted by a usage or help message.

See notes in ADVANCED about how required options with default values or how required options set via --save-as-default can affect script running.

DEFSDIR is the user defaults directory (used by all scripts that use CommandLineInterface).  If the user saves some parameters as defaults (e.g. `--verbose --save-as-default`), a file containing the defaults for the specific script is saved in this directory.

Set UNPROCFILEWARN to 0 to turn off warnings about unprocessed input/output file sets when your script exits (successfully).  A file set is a group of input files that are processed together (see PAIR_WITH parameter of addInfileOption and addOutfileOption).  A file set is considered processed when the set is iterated (either explicitly by calling nextFileCombo() or implicitly by calling getInfile(), getOutfile(), or getOutdir() (on the same file type ID)).  Warnings about unprocessed file sets can usually be avoided by either looping, like `while(nextFileCombo())` or by calling quit(ERRNO => 1).  The only time you should need to set UNPROCFILEWARN to 0 is when a valid/successful outcome of a script involves not retrieving all files supplied on the command line.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    setDefaults(HEADER => 0);
    print("Header?: ",headerRequested());

I<Output>

    Header?: 0

=back

I<ASSOCIATED FLAGS>

The following default options are affected by the behavior of this method:

    --error-limit       Suppress some errors & warnings.  See error()/warning()
    --header            Print commented header to outfiles.  See getHeader()
    --save-as-default   Save current options for inclusion in every run.

Setting the DEFRUNMODE in this method also affects the visibility and values of these flags:

    --run
    --dry-run
    --usage
    --help

I<LIMITATIONS>

The ERRLIMIT set here is over-ridden by the user supplying --error-limit, but only for errors occurring after the command line has been processed.  Repeated errors or warnings which occur after setDefaults() and before processCommandLine is called will be suppressed based on the value supplied to this method.  repeated errors or warnings occurring outside of that window will be subject to the hard-coded default or the user's --error-limit value.  This is because until the command line is processed, all STDERR output is buffered, but only if the limit is undefined.  This will be fixed when requirement 257 is implemented.

I<ADVANCED>

With regard to DEFRUNMODE, note that a required option with a default value is essentially optional because a value has already been supplied.  This can be true if the call to one of the add*Option() methods included a hard-coded default value (there are some exceptions: see documentation for each method) or if the user has used --save-as-default to save a value for a required option.

If all required options have default values (either hard-coded or user-saved), then CommandLineInterface will treat the script as if there are no required options.  For example, if DEFRUNMODE is set to 'usage', the --run flag will be added to the interface.  This means that if a required option without a hard-coded default exists, the user will not see --run in the usage output, but after they add their own saved defaults to the required options, --run will be added to the usage as a required option (alternatively --dry-run in this case will run the script too, albeit without creating output files).

The user will not be allowed to save the --run flag, thus if you want the script to be able to run without the user supplying any options, you must set DEFRUNMODE to 'run'.

=item C<setScriptInfo> [VERSION, CREATED, HELP, AUTHOR, CONTACT, COMPANY, LICENSE, DETAILED_HELP]

This is the first method that should be called and is where you set information that a user can retrieve using the --help and --version flags.  This information is also used when the --header flag is supplied to create a header that includes the script version and creation date.

VERSION is a free-form string you can use to set a version number that will be printed when --version or --help is supplied or included in file headers when --header is supplied.

CREATED is a free-form string you can use to set a creation date that will be printed when --help or --version --extended is supplied.  It is also included in file headers when --header is supplied.

HELP is the text that is included in the --help output after the "WHAT IS THIS" bullet at the top of the help output.

AUTHOR is the name or names of the author of the script.

CONTACT is the contact information (e.g. email address) of the point(s) of contact or author(s) of the script.

COMPANY is where the script was developed.

LICENSE is a string indicating the license type.

DETAILED_HELP is what is printed if the user runs the script with the --help and --extended flags together.

I<EXAMPLE>

=over 4

I<Command>

    example.pl --version

I<Code>

    setScriptInfo(VERSION => "1.0a",
                  CREATED => "11/28/2016",
                  HELP    => "This script does x and y.");
    processCommandLine();

I<Output>

    1.0a

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --help              Print help message and quit.  See help()
    --extended          Print extended usage/help/version/header.
    --version           Print version message and quit.  See getVersion()
    --header            Print commented header to outfiles.  See getHeader()

I<LIMITATIONS>

None

I<ADVANCED>

n/a

=item C<sglob> EXPR

sglob(), standing for "safe glob", performs a bsd_glob using the GLOB_CSH argument.  It's more reliable than perl's built-in glob method, which fails for files with spaces in the name (even if they are escaped).  The purpose of this method is to allow the user to enter input files using double quotes and un-escaped spaces, as is expected to work with many programs which accept individual files as opposed to sets of files.  This version works with a mix of unescaped and escaped spaces, as well as glob characters [*, ?, [], {,,,}].  It will also split non-files on unescaped spaces and uses a helper sub (globCurlyBraces) to mitigate truncations from long strings that is an issue on some systems.

sglob() takes (EXPR) a single string (the command line argument(s)) and returns a list of the parsed/separated arguments.

sglob() is used by CommandLineInterface to parse arguments given to the various file options, such as those added by addInfileOption(), addOutfileOption(), addOutfileSuffixOption(), and addOutdirOption().

sglob() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... sglob);` statement or call it using the package name: `CommandLineInterface::sglob();`.

I<EXAMPLE>

=over 4

I<Command>

    #Given files: 1.txt, 2.txt, a.tab, and b.tab
    example.pl -j '*.txt' -j '*.tab'

I<Code>

    my $custom_handled_files = [];
    addOption(FLAG   => 'j',
              VARREF => sub {push(@$custom_handled_files,[sglob($_[1])])});
    processCommandLine();
    print(join("\n",map {join(' ',@$_)} @$custom_handled_files));

I<Output>

    1.txt 2.txt
    a.tab b.tab

=back

I<ASSOCIATED FLAGS>

n/a

I<LIMITATIONS>

While sglob peforms better than perl's built-in glob and bsd_glob, it is still limited by the allowed number of characters in a shell command.  Behavior can be unexpected if the shell truncates a long series of arguments.  The limit on the command line length imposed by the shell is inversely affected by the size of the environment.

I<ADVANCED>

n/a

=item C<usage> [ERROR_MODE, EXTENDED]

usage() is called automatically when the command line arguments are processed (see processCommandLine(), whose initial call is triggered by numerous methods).  usage() prints a formatted message about available options in the script.

Descriptions of options printed by usage() are set by the various add*Option methods, such as addOption(), addArrayOption(), add2DArrayOption(), addInfileOption(), addOutfileOption(), addOutfileSuffixOption(), and addOutdirOption().  addOptions() is excluded from this list since it is supplied only as a quick conversion method for existing scripts that already use the Getopt::Long module.  Each of these methods has a FLAG, REQUIRED, DEFAULT, SHORT_DESC, and LONG_DESC argument, along with other case-specific arguments (such as TYPE, PRIMARY, HIDDEN, ACCEPTS, FORMAT, and DELIMITER) that affect the content of the usage message.

usage() outputs a usage message in 3 modes: an error mode, a short summary mode, and an extended/detailed mode.  The default mode is the short summary mode.  Error mode only prints a sample command with a list of acceptable short flags.  The detailed mode is triggered by supplying --extended as the only option supplied on the command line.

--extended (from the command line) can be explicitly overridden using the EXTENDED argument.

ERROR_MODE is specified by a non-zero value and over-rides the EXTENDED mode.

The default short summary mode uses the SHORT_DESC values specified in the add*Option methods.  If the value is undefined or an empty string, the option is not included in the short usage summary.  The first shortest flag specified in the FLAG values supplied to the add*Option methods is what is reported in both the ERROR_MODE and in the short usage summary mode.  The EXTENDED mode reports all flag values specified in the FLAG string supplied to the add*Option methods as well as the LONG_DESC.

There are 3 columns in the short summary and extended modes: flags, required/optional, and the description.  These modes also include a sample command and a reporting of whatever user defaults have been set using the --save-as-default option.  The first part of the description contains the default value enclosed in square brackets '[]'.  If an option has an ACCEPTS value set, those values will appear after the default, surrounded by curly braces.  Note, descriptions for input and output files should refer to the --help output for file formats.

The EXTENDED usage includes all the default options supplied by CommandLineInterface, but the short summary includes only the default options (if present): -i, -o, --help, and --extended.

If PRIMARY is a non-zero value for one of the addInfileOption calls, the flag column in the usage output will contain an asterist and a default message in the description indicating that the flag is not required and that input on STDIN will be assumed the be this type of file as is provided to the indicated flag for this option.

usage() is not exported by default, thus you must either supply it in your `use CommandLineInterface qw(... usage);` statement or call it using the package name: `CommandLineInterface::usage();`.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    CommandLineInterface::usage();

I<Output>


    example.pl -i "input file(s)" [...]

         -i                   OPTIONAL [stdin] Input file(s).
         -o                   OPTIONAL [none] Outfile suffix (appended to -i).
         --help               OPTIONAL Print general info and file formats.
         --extended           OPTIONAL Print extended usage.

    No user defaults set.

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --extended          Print extended usage/help/version/header.
    --save-as-default   Save current options for inclusion in every run.

Default file options that are added if none defined (which also affect the behavior of this method):

    -i                  Input file. see addInfileOption()
    -o                  Output file suffix. see addOutfileSuffixOption()
    --outfile           Output file. see addOutfileOption()
    --outdir            Output directory. see addOutdirOption()

I<LIMITATIONS>

The DEFAULTS and ACCEPTS displayed by usage() are only used in the usage output and not for setting or validating user input.  Validation of values using the ACCEPTS hash will be implemented when requirement 94 is addressed.

usage() is called (and the script exits) when no options are (or only --extended is) provided and by default, when a critical error is ecountered during command line processing.  There is currently no way to not print the usage, but the exit can be skipped in the event of an error by providing --force.  Running without arguments instead of generating a usage message will be addressed when requirement 157 is implemented.

The width of the usage output is static, set at 80 characters.  There is currently no way to change this.  A way to print to the terminal window width will be addressed when requirement 175 is implemented.

I<ADVANCED>

n/a

=item C<verbose> EXPRs [, {LEVEL, FREQUENCY, OVERME}]

Prints EXPR to STDERR.  Multiple EXPRs are all printed (similar to print()).

A newline character is added to the end of the message if none was supplied.

A hash reference can be supplied anywhere in the argument list, containing the keys LEVEL and/or FREQUENCY.

A verbose message's LEVEL refers to when a it should be printed and depends on the verbose level (i.e. how many times --verbose was supplied on the command line (or what number was supplied to it)).  A message will be printed if the verbose level is greater than or equal to the message LEVEL.  For example, `verbose({LEVEL=>2},"Hello world.");` will print if --verbose is supplied at least 2 times on the command line, but not when supplied only once.

A verbose message's FREQUENCY refers to when a repeated call to verbose (e.g. in a loop) should be printed.  The message will be printed on every FREQUENCY'th call from the same line of code.  E.g. `

For the effect of OVERME, see verboseOverMe().

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt' --verbose --verbose

    #or

    example.pl -i '*.txt' --verbose 2

I<Code>

    verbose({LEVEL => 1},"Currently on line:");
    my $cnt = 0;
    while($cnt < 30)
      {verbose({LEVEL => 2,FREQUENCY=>10},++$cnt)}
    verbose({LEVEL => 3},"Done"); #Will not print, bec. LEVEL = 3 & verbose = 2

I<Output>

    Currently on line:
    10
    20
    30

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --pipeline          Prepends script name to errors, warnings, & debugs.

I<LIMITATIONS>

There is currently no way to prevent the automatic appending of a newline character.  Requirement 169 will address this.

Verbose messages do not cleanly write over previous verboseOverMe messages (or any other output ending in a carriage return) which contain tab characters.

I<ADVANCED>

verbose() removes the last newline character at the end of every verbose message (e.g. verbose("...\n")) before appending its default newline character.  Therefore, if you append multiple newline characters at the end of your message, the output will effectively contain all newline characters.

=item C<verboseOverMe> EXPRs [, {LEVEL, FREQUENCY}]

Same functionality as verbose().  Prints EXPR to STDERR, but tells the next call of verbose(), verboseOverMe(), debug(), warning(), or error() to print over top of the message printed here.

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt' --verbose --verbose

    #or

    example.pl -i '*.txt' --verbose 2

I<Code>

    verboseOverMe({LEVEL => 1},"Currently on line: 0");
    my $cnt = 0;
    while($cnt < 30)
      {verboseOverMe({LEVEL => 2,FREQUENCY=>10},"Currently on line: ",++$cnt)}
    verbose("Done");

I<Output>

#It's hard to represent real-time appearance, but when the script completes,
#the final output will look like this:

    Done

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.
    --verbose           Prints status.  See verbose() and verboseOverMe()
    --pipeline          Prepends script name to errors, warnings, & debugs.

I<LIMITATIONS>

Verbose messages do not cleanly write over previous verboseOverMe messages (or any other output ending in a carriage return) which contain tab characters.

CommandLineInterface currently knows nothing about your terminal's window width.  If a verboseOverMe message is printed which is longer than the window width, the next message (depending on the behavior of your terminal app, may only overwrite the last portion of the previous message that was soft-wrapped from the previous line.  This can cause unsightly mass output if large messages are printed to a norrow terminal window.  This will be addressed when requirement 176 is implemented.

If EXPR contains newline characters (\n), only the last line will be printed over on the next call.

I<ADVANCED>

All STDERR messages printed by verbose(), verboseOverMe(), debug(), warning(), or error() keep track of the length of the last line so that if the next message printed is shorter, spaces will be printed to clear the prior line.

This method simply passes its parameters to verbose(), but adds {OVERME=>1} to the parameters.

Messages printed via verboseOverMe simply append a carriage return at the end.  Any last newline character in the message is replaced with a carriage return.

Hint: To not print over the last verboseOverMe message printed, call verbose with a message that starts with a newline character (\n).

=item C<warning> EXPRs

=item C<error> EXPRs

Prints EXPR(s) to STDERR.  Multiple EXPRs are all printed (similar to print()).  Messages are prepended by 'ERROR#: ' or 'WARNING#: ' where '#' is the sequential error/warning number (indicating the order in which the errors/warnings occurred).

I<EXAMPLE>

=over 4

I<Command>

    example.pl -i '*.txt'

I<Code>

    error("An error occurred.");
    warning("A warning occurred.");

I<Output>

    ERROR1: An error occurred.
    WARNING1: A warning occurred.

=back

I<ASSOCIATED FLAGS>

The following default options affect the behavior of this method:

    --quiet             Suppress all error, warning, verbose, & debug messages.
    --error-limit       Suppress some errors & warnings.
    --pipeline          Prepends script name to errors, warnings, & debugs.
    --debug             Prepends call trace.  See debug()

I<LIMITATIONS>

The call trace currently indicates method name and line number, but does not yet indicate file name.  This will be addresses requirement 170 is implemented.

I<ADVANCED>

The number supplied to --error-limit indicates how many times each instance of a call to error() may be called before its output is suppressed.  The first time its output is suppressed a suppression warning message is printed to STDERR.  `--error-limit 0` turns off error suppression.

--pipeline is detected automatically by detection of sibling processes (assumed to be involved in a pipe of input or output) or by the fact that the parent prcess is not a shell/tty.  Explicitly setting --pipeline or --no-pipeline turns off automatic detection.

If --debug is supplied on the command line once, error messages will contain the calling block name (i.e. method name) and the originating line number of where the error/warning was called.  If --debug is supplied more than once, a full call trace after the error number and before the error message is included.  Call traces from left to right proceed from child/last call to parent/first caller methods.

=back

=head1 DISCUSSION

=head2 Combining single character flags not allowed

Many unix tools allow a series of options to be abbreviated in such a way that instead of supplying -x -y -z, a user could supply -xyz or even just xyz (without the dash).  However CommandLineInterface prohibits this because the combination of long option flags with bundled options (e.g. -xyz) can lead to unexpected result.  Refer to the bundling and bundling_override sections of Getopt::Long's perldoc for further details.

=head2 1:1orM (Processing repeated input files)

nextFileCombo() is an iterator that allows you to process pairs of files together (abstracted to "sets" of files for more than 2 types of input file).  It supports the ability for users to run (serially) many batches of files in a single command by supplying the same flags multiple times.  For example:

example.pl -i '1*.txt' -j a.txt -i '2*.txt' -j b.txt).

The sets (or pairs) of input files are pre-organized, processed, validated, checked to see that their output files have overwrites/collisions, etc..  Each pair/set of input files that go together (or rather, are processed together) are kept in a 2D array, and it's the index of the outer array that nextFileCombo() advances.  Using the example above, that array might look something like this:

[['1_1.txt', 'a.txt'],
 ['1_2.txt', 'a.txt'],
 ['1_3.txt', 'a.txt'],
 ['2_1.txt', 'b.txt'],
 ['2_2.txt', 'b.txt'],
 ['2_3.txt', 'b.txt'],
 ['2_4.txt', 'b.txt']]

If you have an input file type that has a 1:M or 1:1orM relationship with another type of input file (as in the example above), nextFileCombo() will end up returning the 1 file repeatedly because it's a part of multiple sets.  Thus, code that processes that file, if no special steps are taken to only process such a file once, will process the same file multiple times.  For example:

BAD EXAMPLE:

my $fidi = addInfileOption('i');
my $fidj = addInfileOption(FLAG       => 'j',
                           PAIR_WITH  => $fidj,
                           PAIR_RELAT => 'ONETOMANY');
while(nextFileCombo())
  {
    my $ifile = getInfile($fidi);
    my $jfile = getInfile($fidj);

    my $jdata  = processFileTypeJ($jfile);
    my $result = processFileTypeI($ifile,$jdata);
  }

The above example is poorly written because it processes the same -j file for each file provided to -i in cases like this:

example.pl -i '1.txt 2.txt 3.txt' -j lookup.txt

The file 'lookup.txt' ends up getting processed 3 times, one time for each of the 3 -i files.

On the other hand, you can write your code in a way that processes single files paired with multiple files once:

GOOD EXAMPLE:

my $fidi = addInfileOption('i');
my $fidj = addInfileOption(FLAG       => 'j',
                           PAIR_WITH  => $fidj,
                           PAIR_RELAT => 'ONETOONEORMANY');
my $jprocessed = {};
my $jdata;
while(nextFileCombo())
  {
    my $ifile = getInfile($fidi);
    my $jfile = getInfile($fidj);

    if(exists($jprocessed->{$jfile}))
      {$jdata = $jprocessed->{$jfile}}
    else
      {
        $jdata = processFileTypeJ($jfile);
        $jprocessed->{$jfile} = $jdata;
      }

    my $result = processFileTypeI($ifile,$jdata);
  }

This code would work both in the case of 'ONETOMANY' or 'ONETOONEORMANY'.  The purpose of 'ONETOONEORMANY' is to support cases where a user can decide that they want to use the same data provided to -j for all files provided to -i or if they want a different -j file for each file provided to -i.

There is a new feature on the way that will make the ONETOMANY case a lot easier and allow you to create nested loops, using iterators that account for 1:M relationships.  Until then, checking files to see if they've been processed before, as demonstrated above, is a simple way to make your file processing more efficient.  There are of course, more ways to do it.  This is just one example.

=head2 M:M

If you want to process all combinations of 2 (or more) types of input files, the code actually can do it, but currently it is caught and prohibited because there are cases that are not supported, and it's because of the built-in flexibility that allows users to do things like this:

example.pl -i '1.txt 2.txt 3.txt' -i 'a.txt b.txt' -j 'nums.txt letters.txt'

example.pl -i '1.txt 2.txt 3.txt' -i 'a.txt b.txt' -j nums.txt -j letters.txt

Each of the above commands results in the same pairings of files of type -i and -j.  CommandLineInterface searches for and finds the "matching dimensions".  By dimensions, I mean the number of instances of a type of flag versus the number of files supplied to that flag.  The processing of the parameters creates a 2D array of files for each flag type and it transposes any types when there is not a matching dimension.

The code, as it's currently written, would (without the catching of the case where there are no matching dimensions) output all combinations of input files.  However, it's not an explicit behavior, and that's the code that needs to be added.  Because as it stands right now, it cannot output all possible combinations whenever there is a matching dimension between the 2, 2D arrays of types of input files.

=head1 LICENSE

This is released under the GNU Public License 3.0.

=head1 AUTHOR

Robert W. Leach - L<http://http://lsi.princeton.edu/directory/robert-w.-leach/>

=head1 SEE ALSO

L<GetOpt::Long>

=cut

1;
