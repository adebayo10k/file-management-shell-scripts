#!/bin/bash
#: Title			:utils.ffmpeg_multi_in_multi_out.sh
#: Date				:2020-06-03
#: Author			:"Damola Adebayo" <adebay10k>
#: Version			:1.0
#: Description		:call the ffmpeg program
#: Description		:many input files to many output files
#: Description		:
#: Options			:None
#: Usage			:

##################################################################
##################################################################
# THIS STUFF IS HAPPENING BEFORE MAIN FUNCTION CALL:
#===================================

# 1. MAKE SHARED LIBRARY FUNCTIONS AVAILABLE HERE

# make all the shared library functions available to this script
shared_bash_functions_fullpath="${SHARED_LIBRARIES_DIR}/shared-bash-functions.inc.sh"
shared_bash_constants_fullpath="${SHARED_LIBRARIES_DIR}/shared-bash-constants.inc.sh"

for resource in "$shared_bash_functions_fullpath" "$shared_bash_constants_fullpath"
do
	if [ -f "$resource" ]
	then
		echo "Required library resource FOUND OK at:"
		echo "$resource"
		source "$resource"
	else
		echo "Could not find the required resource at:"
		echo "$resource"
		echo "Check that location. Nothing to do now, except exit."
		exit 1
	fi
done


# 2. MAKE SCRIPT-SPECIFIC FUNCTIONS AVAILABLE HERE

# must resolve canonical_fullpath here, in order to be able to include sourced function files BEFORE we call main, and  outside of any other functions defined here, of course.

# at runtime, command_fullpath may be either a symlink file or actual target source file
command_fullpath="$0"
command_dirname="$(dirname $0)"
command_basename="$(basename $0)"

# if a symlink file, then we need a reference to the canonical file name, as that's the location where all our required source files will be.
# we'll test whether a symlink, then use readlink -f or realpath -e although those commands return canonical file whether symlink or not.
# 
canonical_fullpath="$(readlink -f $command_fullpath)"
canonical_dirname="$(dirname $canonical_fullpath)"

# this is just development debug information
if [ -h "$command_fullpath" ]
then
	echo "is symlink"
	echo "canonical_fullpath : $canonical_fullpath"
else
	echo "is canonical"
	echo "canonical_fullpath : $canonical_fullpath"
fi

# included source files for json profile import functions
#source "${canonical_dirname}/preset-profile-builder.inc.sh"


# THAT STUFF JUST HAPPENED (EXECUTED) BEFORE MAIN FUNCTION CALL!
##################################################################
##################################################################


input_file_extension=".VOB"
output_file_extension=".mp4"

for input_file in $HOME/INSANITY_fullscreen/*${input_file_extension}
do
    output_file="${input_file%${input_file_extension}}""${output_file_extension}"
    echo "input file:  $input_file"
    echo "output file:  $output_file"
    echo "... encoding ..." && echo

    ffmpeg -i "${input_file}" -qscale 0 "${output_file}"

done

