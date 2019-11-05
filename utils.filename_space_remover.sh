#!/bin/bash
#: Title		:utils.filename_space_remover.sh
#: Date			:2019-10-26
#: Author		:adebayo10k
#: Version		:1.0
#: Description	:linux doesn't like spaces in filenames.
#: Description	:renames files in a directory, with intra-filename\
#: Description	:+space characters replaced by underscores.
#: Options		:
##

# program allows user to review, then rename up to 100 files at a time.
# full, unchecked, uncontrolled, non-interactive renaming of what\
# + could be 1000s of found files now seems a bit risky.

function main()
{
    source_dir_fullpath="" # OR #test_line=""
    abs_filepath_regex='^(/{1}[A-Za-z0-9\._-~]+)+$' # absolute file path, ASSUMING NOT HIDDEN FILE, ...
    all_filepath_regex='^(/?[A-Za-z0-9\._-~]+)+$' # both relative and absolute file path
    # totals for each subset of files:
    all_reg_files_count=0
    all_dir_files_count=0
    spaced_reg_files_count=0
    spaced_dir_files_count=0
    
    get_dir_to_check # including validation of this user input

    get_file_totals

    #reset_file_totals

    #all_reg_files_count=$(get_file_totals2 "$all_reg_files_count" "f" "*")
    #all_dir_files_count=$(get_file_totals2 "$all_dir_files_count" "d" "*")
    #spaced_reg_files_count=$(get_file_totals2 "$spaced_reg_files_count" "f" "* *")
    #spaced_dir_files_count=$(get_file_totals2 "$spaced_dir_files_count" "d" "* *")
        
    # negative response terminates program, affirmative just allows continuation
    get_continue_response "numbers look credible? continue with these numers? [y/n] (or q to quit program)"
    
    test_for_more_spaced_filenames # program exits if test fails (ie no more found)

    list_spaced_files # output numbered lists of each subset of intra-space character files

    exit 0



    get_continue_response "Based on the above lists, do you now want to make ex-program fs changes? [y/n]\n (or q to quit program)"

    find_files_and_show_user
    

    exit 0

    rename_files #


} ## end main


##########################################################################################################
##########################################################################################################
##########################################################################################################

# gets from user the directory (absolute path) in which to recursively check/
# +for filenames with spaces. 
function get_dir_to_check()
{
    echo "Enter the full path to the directory containing the files of interest" && echo
    read source_dir_fullpath

    sanitise_absolute_path_value "$source_dir_fullpath"

    # this valid form test works for both sanitised directory paths and absolute file paths
    test_file_path_valid_form "$source_dir_fullpath"
    if [ $? -eq 0 ]
    then
        echo "SOURCE DIRECTORY PATH IS OF VALID FORM"
    else
        echo "The valid form test FAILED and returned: $?"
        echo "Nothing to do now, but to exit..." && echo
        exit 1
        #exit $E_UNEXPECTED_ARG_VALUE
    fi	

    # if the above test returns ok, ...
	test_dir_path_access "$source_dir_fullpath"
	if [ $? -eq 0 ]
	then
		echo "The full path to the SOURCE DIRECTORY is: $source_dir_fullpath"
	else
		echo "The SOURCE DIRECTORY path access test FAILED and returned: $?"
		echo "Nothing to do now, but to exit..." && echo
        exit 1
		#exit $E_REQUIRED_FILE_NOT_FOUND
	fi    #...
}

###########################################################
# find the different sets of files and display their totals under source directory
function get_file_totals()
{    
    all_reg_files_count=0
    all_dir_files_count=0
    spaced_reg_files_count=0
    spaced_dir_files_count=0

    OIFS=$IFS # store pre-existing IFS to be reset at end
    
    while IFS=$'\n' read all_file_name
    do
        ((all_reg_files_count++))   
    done < <(find "$source_dir_fullpath" -type f)
    # first < is redirection, second is process substitution

    while IFS=$'\n' read all_dir_name
    do
        ((all_dir_files_count++))   
    done < <(find "$source_dir_fullpath" -type d)    

    while IFS=$'\n' read spaced_file_name
    do
        ((spaced_reg_files_count++))   
    done < <(find "$source_dir_fullpath" -type f -name "* *")

    while IFS=$'\n' read spaced_dir_name
    do
        ((spaced_dir_files_count++))   
    done < <(find "$source_dir_fullpath" -type d -name "* *")

    IFS=$OIFS 

    echo "TOTAL REGULAR FILES: $all_reg_files_count" 
    echo "TOTAL SPACED REGULAR FILES: $spaced_reg_files_count" && echo

    echo "TOTAL DIRECTORY FILES: $all_dir_files_count"
    echo "TOTAL SPACED DIRECTORY FILES: $spaced_dir_files_count" && echo
    
}

###########################################################
# find the different sets of files and display their totals under source directory
function get_file_totals2()
{    
    fileset_counter=$1
    type_arg=$2
    name_arg=$3

    OIFS=$IFS # store pre-existing IFS to be reset at end
    
    while IFS=$'\n' read filename
    do
        fileset_counter=$((fileset_counter+1))   
    done < <(find "$source_dir_fullpath" -type "$type_arg" -name "$name_arg")
   
    IFS=$OIFS

    echo "$fileset_counter" # why is this essential?
    return "$fileset_counter"
    
}

###########################################################

# get user response
function get_continue_response()
{    
    msg=$1
    echo "$msg"
    read answer

    case $answer in 
	[yY])   :
				;;
	[nN])   echo "check fs manually, then run this program again. come back." && sleep 1
            echo "exiting now..." && sleep 1
            exit 0
 				;;
	[qQ])	echo
			echo "Goodbye!" && sleep 1
			exit 0
				;;
	*) 		echo "Just a simple y or n will do..." && echo && sleep 1
		 	get_continue_response "$msg"
		 		;;
    esac 

}

###########################################################
# 
function test_for_more_spaced_filenames()
{
    if [ "$spaced_reg_files_count" -eq 0 ] && [ "$spaced_dir_files_count" -eq 0 ]
    then
        echo "ALL FILENAMES ARE WITHOUT SPACE CHARACTERS" && echo && sleep 1
        echo "Exiting now..." && echo && sleep 1
        exit 0
    else
        echo "AT LEAST ONE FILENAME STILL CONTAINS SPACE CHARACTERS" && echo && sleep 1
        echo "Continuing with program execution..." && echo && sleep 1
    fi

}

###########################################################
# find and show user those spaced files
function list_spaced_files()
{
    spaced_reg_files_count=0
    spaced_dir_files_count=0

    OIFS=$IFS # store pre-existing IFS to be reset at end
    
    echo "REGULAR FILES WITH INTRA-FILENAME SPACES:"
    echo "=========================================" && echo

    # first < is redirection, second is process substitution
    while IFS=$'\n' read spaced_file_name
    do
        ((spaced_reg_files_count++))
        echo -e "\e[40m$spaced_reg_files_count:\e[0m";
        echo "$spaced_file_name"
        proposed_filename="${spaced_file_name//' '/'_'}"
        echo "$proposed_filename" && echo  
    done < <(find "$source_dir_fullpath" -type f -name "* *")

    echo "DIRECTORY FILES WITH INTRA-FILENAME SPACES:"
    echo "=========================================" && echo

    while IFS=$'\n' read spaced_dir_name
    do
        ((spaced_dir_files_count++))
        echo -e "\e[40m$spaced_dir_files_count:\e[0m";
        echo "$spaced_dir_name"
        proposed_filename="${spaced_dir_name//' '/'_'}"
        echo "$proposed_filename" && echo  
    done < <(find "$source_dir_fullpath" -type d -name "* *")

    IFS=$OIFS 

    echo "TOTAL SPACED REGULAR FILES: $spaced_reg_files_count" && echo
    echo "TOTAL SPACED DIRECTORY FILES: $spaced_dir_files_count" && echo

    #NOTE:
    #((all_files_count++))
    #((all_files_count+=1))
    #all_files_count=$(( all_files_count + 1 ))

}

###########################################################

# find and show us those spaced files
function find_files_and_show_user()
{    
    all_files_count=0
    spaced_files_count=0
    OIFS=$IFS # store pre-existing IFS to be reset at end

    echo "Filename with intra-spaces:"
    echo "Proposed file rename:"

    find "$source_dir_fullpath" -type f |
    while IFS=$'\n' read spaced_filename
    do
        #echo -e "\e[40m$all_files_count:\e[0m";

        if echo "$spaced_filename" | grep -q ' '
        then
            ((spaced_files_count++))
            echo -e "\e[40m$spaced_files_count:\e[0m";
            echo "$spaced_filename"
            filename="${spaced_filename//' '/'_'}"
            echo "$filename" && echo
        else
            :
            #echo "found one WITHOUT spaces"
        fi 
        

        
    done
    IFS=$OIFS  

}

###########################################################
function rename_files()
{

    count=1
    OIFS=$IFS # store pre-existing IFS to be reset at end

    find "$source_dir_fullpath" -type f |
    while IFS=$'\n' read spaced_filename
    do
        if echo "$spaced_filename" | grep -q ' '
        then
            filename="${spaced_filename//' '/'_'}"
            mv -i "$spaced_filename" "$filename" # prompt before overwriting
            if [ $? -eq 0 ]
            then
                :
            else
                echo "ERROR: THIS FILE WAS NOT RENAMED"
            fi
        else
            :
            #echo "found one WITHOUT spaces"
        fi 

        count=$(( count + 1 ))

        #if [ $count -gt 20 ]
        #then
        #    break
        #fi

    done
    IFS=$OIFS

} # end function


##########################################################################################################
##########################################################################################################
##########################################################################################################


# we test that the parameter we got is of the correct form for an absolute file | sanitised (trailing / removed)
# +directory path. if this test fails, there's no point doing anything further
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
		echo "PARAMETER WAS NOT A MATCH FOR OUR KNOWN PATH FORM REGEX: "$abs_filepath_regex"" && sleep 1 && echo
		echo "Returning with a non-zero test result..."
		test_result=1
        return 1
		#return $E_UNEXPECTED_ARG_VALUE
	fi 


	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}

###############################################################################################

# FINAL OPERATION ON VALUE, SO GLOBAL test_line SET HERE. RENAME CONCEPTUALLY DIFFERENT test_line NAMESAKES
function sanitise_absolute_path_value ##
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# sanitise values
	# - trim leading and trailing space characters
	# - trim trailing / for all paths
	test_line="${1}"
	echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo

	# TRIM TRAILING AND LEADING SPACES AND TABS
	test_line=${test_line%%[[:blank:]]}
	test_line=${test_line##[[:blank:]]}

	# TRIM TRAILING / FOR ABSOLUTE PATHS:
    while [[ "$test_line" == *'/' ]]
    do
        echo "FOUND ENDING SLASH"
        test_line=${test_line%'/'}
    done    

	echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

    source_dir_fullpath="$test_line"

    echo "source_dir_fullpath after trim cleanups in "${FUNCNAME[0]}" is: $source_dir_fullpath" && echo

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}
###############################################################################################
# need to test for access and write permission to the file holding directory
# 
function test_dir_path_access
{
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_dir_fullpath=$1

	echo "test_dir_fullpath is set to: $test_dir_fullpath"

	if [ -d "$test_dir_fullpath" ] && cd "$test_dir_fullpath" 2>/dev/null && [ -w "$test_dir_fullpath" ]
	then
		# directory file found and accessible
		echo "directory "$test_dir_fullpath" found and accessed ok" && echo
		test_result=0
	else
		# -> return due to failure of any of the above tests:
		test_result=1
		echo "Returning from function \"${FUNCNAME[0]}\" with test result code: xxx-xx" #$E_REQUIRED_FILE_NOT_FOUND"
		return 1 
        #return $E_REQUIRED_FILE_NOT_FOUND
	fi

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}
###############################################################################################

main "$@"; exit