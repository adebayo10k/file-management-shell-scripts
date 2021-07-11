#!/bin/bash
#: Title			:utils.file_extension_match_mover
#: Date				:2019-
#: Author			:"Damola Adebayo" <adebay10k>
#: Version			:1.0
#: Description		:move regular files with matching file extensions from
#: Description		:whatever depth they are under a source directory, directly
#: Description		:into a destination directory at depth 1
#: Options			:None
#: Usage			:

##################################################################
##################################################################
# THIS STUFF IS HAPPENING BEFORE MAIN FUNCTION CALL:
#===================================

# 1. MAKE SHARED LIBRARY FUNCTIONS AVAILABLE HERE

# make all those library function available to this script
shared_bash_functions_fullpath="${SHARED_LIBRARIES_DIR}/shared-bash-functions.sh"
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


# THAT STUFF JUST HAPPENED BEFORE MAIN FUNCTION CALL!
##################################################################
##################################################################


# ALSO, need to SIMPLIFY current iterations! get rid of clever but overcomplicated code.

function main()
{
    echo "OUR CURRENT SHELL LEVEL IS: $SHLVL"

	echo "USAGE: $(basename $0)"

    # Display a program header and give user option to leave if here in error:
    echo
    echo -e "       \033[33m============================================================================\033[0m";
    echo -e "       \033[33m||   Welcome to the FILE EXTENSION MATCHING, REGULAR FILE MOVING UTILITY  ||  author: Damola Adebayo\033[0m";  
    echo -e "       \033[33m============================================================================\033[0m";
    echo
    echo " Type q to quit NOW, or press ENTER to continue."
    echo && sleep 1
    read last_chance

    case $last_chance in 
	[qQ])	echo
			echo "Goodbye!" && sleep 1
			exit 0
				;;
	*) 		echo "You're IN..." && echo && sleep 1
		 		;;
    esac 

    ##########################################

    # GLOBAL VARIABLE DECLARATIONS:
	test_line="" # global...
    line_type="" # global...

    source_dir_fullpath="" # OR #test_line=""
    destination_dir_fullpath="" # OR #test_line=""
    file_extension=""
    config_file_fullpath="/etc/file-extension-match-mover.config"
    #declare -a directories_to_exclude=() # ...


    # totals for each subset of files:
    all_reg_files_count=0
    all_dir_files_count=0
    matched_reg_files_count=0
    matched_dir_files_count=0


    ##########################################
    # call problem domain functions
    # 
    match_and_move_files


} ## end main

###########################################################
# the while loop that encapsulates pretty much the whole of this program
function match_and_move_files()
{
    more_files_to_move="yes"

    while [ "$more_files_to_move" == 'yes' ]
    do
               
        echo "Opening your editor now..." && echo && sleep 2
        nano "$config_file_fullpath" # /etc exists, so no need to test access etc.
        # no need to validate config file path here, since we've just edited the config file!

        check_config_file_content

        # read file match configuration
        import_file_match_configuration
        
        exit 0

        move_matching_files #



    done
}

###########################################################
# test whether the configuration files' format is valid,
# and that each line contains something we're expecting
function check_config_file_content()
{
	while read lineIn
	do
		# any content problems handled in the following function:
        test_and_set_line_type "$lineIn"
        return_code="$?"
        echo "exit code for tests of that line was: $return_code"
        if [ $return_code -eq 0 ]
        then
            # if tested line contained expected content
            # :
            echo "That line was expected!" && echo
        else
            echo "That line was NOT expected!"
            echo "Exiting from function \"${FUNCNAME[0]}\" in script \"$(basename $0)\""
            exit 0
        fi

	done < "$config_file_fullpath" 

}
###########################################################
# 
function import_file_match_configuration()
{
    
	echo
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "STARTING THE 'IMPORT CONFIGURATION INTO VARIABLES' PHASE in script $(basename $0)"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo

    get_dirs_fullpath_config
	get_file_extension_config
	
	# NOW DO ALL THE DIRECTORY ACCESS TESTS FOR IMPORTED PATH VALUES HERE.
	# REMEMBER THAT ORDER IS IMPORTANT, AS RELATIVE PATHS DEPEND ON ABSOLUTE.

	for dir in "$destination_dir_fullpath" "$source_dir_fullpath"
	do

		# this valid form test works for sanitised directory paths
		test_file_path_valid_form "$dir"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "HOLDING (PARENT) DIRECTORY PATH IS OF VALID FORM"
		else
			echo "The valid form test FAILED and returned: $return_code"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_UNEXPECTED_ARG_VALUE
		fi	

		# if the above test returns ok, ...
		test_dir_path_access "$dir"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "The full path to the HOLDING (PARENT) DIRECTORY is: $dir"
		else
			echo "The HOLDING (PARENT) DIRECTORY path access test FAILED and returned: $return_code"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_REQUIRED_FILE_NOT_FOUND
		fi

	done

	# NOW TEST THE VALUE WE'VE IMPORTED FOR THE SINGLE (FOR NOW) FILE EXTENSION:
    # although we already tested these to id them in the first place, just making sure
    # nothing's changed

    echo "before imported variable test, file extension was set to: "$file_extension"   "
    
    if [[ "$file_extension" =~ $FILE_EXTENSION_REGEX ]]
    then
        echo "The valid file extension is: $file_extension"
    else
        echo "File extension regex match test FAILED"
		echo "Nothing to do now, but to exit..." && echo
		exit $E_REQUIRED_FILE_NOT_FOUND
	fi


}

###########################################################
function move_matching_files()
{
    OIFS=$IFS # store pre-existing IFS to be reset at end
    count=1
    # quote directory:
    find "$src_dir_path" -type f -name "*$file_extension" |
    while IFS=$'\n' read file_path
    do
        echo -e "\e[33m$count:\e[0m";
        #echo "$count:"

        echo "original filename:    $file_path"

        # make destination parent directory with spaces removed:
        #dir_path=${file_path%/*}
        #dir_path="${dir_path//' '/'_'}"
        #dst_dir_path="${dir_path//"$src_dir_path"/"$dst_dir_path"}"

        echo "destination parent directory:    $dst_dir_path"
        
        #mkdir -p "$dst_dir_path" # build parent directory structure if needed

        # rename file and move to destination parent directory:

        filename=${file_path##*/}
        filename="${filename//' '/'_'}"

        echo "new base filename:    $filename"

        dst_file_path="${dst_dir_path}/${filename}"

        echo "destination filepath:    $dst_file_path"

        mv -i "$file_path" "$dst_file_path" # prompt before overwriting  

        count=$((count+1))

        #if [ $count -gt 10 ]
        #then
        #    break
        #fi 

    done
    IFS=$OIFS

#    matching_files=`find $src_dir_path -name "*$file_extension"`
#
#    echo && echo "matching files:"
#    echo "===================="
#    echo "$matching_files"
#
#    echo "Press enter if ok..."
#    read
#
#    for filename in $matching_files
#    do
#        #variable expansion to replace all instances of pattern with string:
#        mv "$filename" "${filename//' '/'_'}"
#        
#        #mv "$filename" "${filename//"$src_dir_path"/"$dst_dir"}"
#    done	
#
    echo && echo "new file names found:"
    echo "===================="
    ls -R "$dst_dir_path"

} # end function
###########################################################
##########################################################################################################
##########################################################################################################
# A DUAL PURPOSE FUNCTION - CALLED TO EITHER TEST OR TO SET LINE TYPES:
# TESTS WHETHER THE LINE IS OF EITHER VALID comment, empty/blank OR string (variable or value) TYPE,
# SETS THE GLOBAL line_type AND test_line variableS.
function test_and_set_line_type
{

#echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# TODO:
    # ADD ANOTHER CONFIG FILE VALIDATION TEST:
	# TEST THAT THE LINE FOLLOWING A VARIABLE= ALPHANUM STRING MUST BE A VALUE/ ALPHANUM STRING, ELSE FAIL
    # IF LINE END WITH THE CONTINUATION CHARACTER (\) ... NEXT LINE NOT ACTUALLY A TESTED LINE
	test_line="${1}"
	line_type=""

	if [[ "$test_line" == "#"* ]] # line is a comment
	then
		line_type="comment"
		echo "line_type set to: $line_type"
	elif [[ "$test_line" =~ [[:blank:]] || "$test_line" == "" ]] # line empty or contains only spaces or tab characters
	then
		line_type="empty"
		echo "line_type set to: $line_type"
	elif [[ "$test_line" =~ [[:alnum:]] ]] # line is a string (not commented)
	then
		echo -n "Alphanumeric string  :  "
		if [[ "$test_line" == *"=" ]]
		then
			line_type="variable_string"
			echo "line_type set to: "$line_type" for "$test_line""
		elif [[ "$test_line" =~ $abs_filepath_regex ]]	#
		then
			line_type="value_string"
			echo "line_type set to: "$line_type" for "$test_line""
        elif [[ "$test_line" =~ $FILE_EXTENSION_REGEX ]]	#
		then
			line_type="value_string"
			echo "line_type set to: "$line_type" for "$test_line""
		else
            echo "line_type set to: \"UNKNOWN\" for "$test_line""
			echo "Failsafe : Couldn't match the Alphanum string"
			return $E_UNEXPECTED_BRANCH_ENTERED
		fi
	else
        echo "line_type set to: \"UNKNOWN\" for "$test_line""
		echo "Failsafe : Couldn't match this line with ANY line type!"
		return $E_UNEXPECTED_BRANCH_ENTERED
	fi

#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}
##########################################################################################################
# for any absolute file path value to be imported...
function get_dirs_fullpath_config
{

	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	for keyword in "destination_dir_fullpath=" "source_dir_fullpath="
	do

		line_type=""
		value_collection="OFF"

		while read lineIn
		do

			test_and_set_line_type "$lineIn" # interesting for the line FOLLOWING that keyword find

			if [[ $value_collection == "ON" && $line_type == "value_string" ]]
			then
				sanitise_absolute_path_value "$lineIn"
				echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
				echo "test_line has the value: $test_line"
				echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
				set -- $test_line # using 'set' to get test_line out of this subprocess into a positional parameter ($1)

			elif [[ $value_collection == "ON" && $line_type != "value_string" ]]
			# last value has been collected for this directory
			then
				value_collection="OFF" # just because..
				break # end this while loop, as last value has been collected for this holding directory
			else
				# value collection must be OFF
				:
			fi
			
			
			# switch value collection ON for the NEXT line read
			# THEREFORE WE'RE ASSUMING THAT A KEYWORD CANNOT EXIST ON THE 1ST LINE OF THE FILE
			if [[ "$lineIn" == "$keyword" ]]
			then
				value_collection="ON"
			fi

		done < "$config_file_fullpath"

		# ASSIGN
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "test_line has the value: $1"
		echo "the keyword on this for-loop is set to: $keyword"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

		if [ "$keyword" == "destination_dir_fullpath=" ]
		then
			destination_dir_fullpath="$1"
			# test_line just set globally in sanitise_absolute_path_value function
		elif [ "$keyword" == "source_dir_fullpath=" ]
		then
			source_dir_fullpath="$1"
			# test_line just set globally in sanitise_absolute_path_value function
		else
			echo "Failsafe branch entered"
			exit $E_UNEXPECTED_BRANCH_ENTERED
		fi

		set -- # unset that positional parameter we used to get test_line out of that while read subprocess
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "test_line (AFTER set --) has the value: $1"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

	done

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
## VARIABLE 3:
function get_file_extension_config
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	keyword="file_extension="
	line_type=""
	value_collection="OFF"

	while read lineIn
	do

		test_and_set_line_type "$lineIn" # interesting for the line FOLLOWING that keyword find

		if [[ $value_collection == "ON" && $line_type == "value_string" ]]
		then
			# lineIn must be the extension value we're looking for
            # but do we santise it? and if so how? 
            sanitise_file_extension_value "$lineIn"
			set -- $test_line # 

		elif [[ $value_collection == "ON" && $line_type != "value_string" ]]
        # last value has been collected for file_extension
		then 
			value_collection="OFF" # just because..
			break # end this while loop, as last value has been collected for file_extension
		else
			# value collection must be OFF
			:
		fi
		
		
		# switch value collection ON for the NEXT line read
		# THEREFORE WE'RE ASSUMING THAT A KEYWORD CANNOT EXIST ON THE 1ST LINE OF THE FILE
		if [[ "$lineIn" == "$keyword" ]]
		then
			value_collection="ON"
		fi

	done < "$config_file_fullpath"


	# ASSIGN 
	file_extension=$1 # test_line was just set globally in sanitise_file_extension_value function
	set -- # unset that positional parameter we used to get test_line out of that while read subprocess

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
# keep sanitise functions separate and specialised, as we may add more to specific value types in future
# FINAL OPERATION ON VALUE, SO GLOBAL test_line SET HERE. RENAME CONCEPTUALLY DIFFERENT test_line NAMESAKES
function sanitise_absolute_path_value ##
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

    # sanitise values
	# - trim leading and trailing space characters
	# - trim trailing / for all paths
	test_line="${1}"
	echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo

	while [[ "$test_line" == *'/' ]] ||\
	 [[ "$test_line" == *[[:blank:]] ]] ||\
	 [[ "$test_line" == [[:blank:]]* ]]
	do 
		# TRIM TRAILING AND LEADING SPACES AND TABS
		# backstop code, as with leading spaces, config file line wouldn't even have been
		# recognised as a value!
		test_line=${test_line%%[[:blank:]]}
		test_line=${test_line##[[:blank:]]}

		# TRIM TRAILING / FOR ABSOLUTE PATHS:
		test_line=${test_line%'/'}
	done

	echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

	## sanitise values
	## - trim leading and trailing space characters
	## - trim trailing / for all paths
	#test_line="${1}"
	#echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo
#
	## TRIM TRAILING AND LEADING SPACES AND TABS
	#test_line=${test_line%%[[:blank:]]}
	#test_line=${test_line##[[:blank:]]}
#
	## TRIM TRAILING / FOR ABSOLUTE PATHS:
    #while [[ "$test_line" == *'/' ]]
    #do
    #    echo "FOUND TRAILING SLASH"
    #    test_line=${test_line%'/'}
    #done 
#
	#echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}
##########################################################################################################
# keep sanitise functions separate and specialised, as we may add more to specific value types in future 
function sanitise_file_extension_value ##
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# sanitise values
	# - trim leading and trailing space characters
	test_line="${1}"
	echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo

	# TRIM TRAILING AND LEADING SPACES AND TABS
	test_line=${test_line%%[[:blank:]]}
	test_line=${test_line##[[:blank:]]}

	echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}
##########################################################################################################

# firstly, we test that the parameter we got is of the correct form for an absolute file | sanitised directory path 
# if this test fails, there's no point doing anything further
# 
function test_file_path_valid_form
{
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_file_fullpath=$1
	
	echo "test_file_fullpath is set to: $test_file_fullpath"
	#echo "test_dir_fullpath is set to: $test_dir_fullpath"

	if [[ $test_file_fullpath =~ $abs_filepath_regex ]]
	then
		echo "THE FORM OF THE INCOMING PARAMETER IS OF A VALID ABSOLUTE FILE PATH"
		test_result=0
	else
		echo "AN INCOMING PARAMETER WAS SET, BUT WAS NOT A MATCH FOR OUR KNOWN PATH FORM REGEX "$abs_filepath_regex"" && sleep 1 && echo
		echo "Returning with a non-zero test result..."
		test_result=1
		return $E_UNEXPECTED_ARG_VALUE
	fi 


	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}

###############################################################################################
# need to test for read access to file 
# 
function test_file_path_access
{
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_file_fullpath=$1

	echo "test_file_fullpath is set to: $test_file_fullpath"

	# test for expected file type (regular) and read permission
	if [ -f "$test_file_fullpath" ] && [ -r "$test_file_fullpath" ]
	then
		# test file found and accessible
		echo "Test file found to be readable" && echo
		test_result=0
	else
		# -> return due to failure of any of the above tests:
		test_result=1 # just because...
		echo "Returning from function \"${FUNCNAME[0]}\" with test result code: $E_REQUIRED_FILE_NOT_FOUND"
		return $E_REQUIRED_FILE_NOT_FOUND
	fi

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}
###############################################################################################
# need to test for access to the file holding directory
# 
function test_dir_path_access
{
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_dir_fullpath=$1

	echo "test_dir_fullpath is set to: $test_dir_fullpath"

    if ! [ -d "$test_dir_fullpath" ]
    then
        mkdir -p "$dst_dir_path" # build parent directory structure if needed
    fi

    if [ -d "$test_dir_fullpath" ] && cd "$test_dir_fullpath" 2>/dev/null
	then
		# directory file found and accessible
		echo "directory "$test_dir_fullpath" found and accessed ok" && echo
		test_result=0
	else
		# -> return due to failure of any of the above tests:
		test_result=1
		echo "Returning from function \"${FUNCNAME[0]}\" with test result code: $E_REQUIRED_FILE_NOT_FOUND"
		return $E_REQUIRED_FILE_NOT_FOUND
	fi

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}
###############################################################################################

main "$@"; exit
