#!/bin/bash
#: Title		:utils.filename_space_remover.sh
#: Date			:2019-10-26
#: Author		:adebayo10k
#: Version		:1.0
#: Description	:linux doesn't like spaces in filenames
#: Description	:renames files in a directory, with space characters replaced by underscores
#: Description	:
#: Options		:
##

function main()
{
    source_dir_fullpath="" # OR #test_line=""
    abs_filepath_regex='^(/{1}[A-Za-z0-9\._-~]+)+$' # absolute file path, ASSUMING NOT HIDDEN FILE, ...
    all_filepath_regex='^(/?[A-Za-z0-9\._-~]+)+$' # both relative and absolute file path
    spaced_files_count=
    all_files_count= 
    #to_trim_regex='^([A-Za-z0-9\._-~]+[\/])+$'   ##' USE OR DELETE THIS'
    
    get_dir_to_check
    find_files_and_show_user

    exit 0

    rename_files #


} ## end main


#################################################[##########
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
# find and show us those spaced files
function find_files_and_show_user()
{    
    all_files_count=1
    spaced_files_count=1
    OIFS=$IFS # store pre-existing IFS to be reset at end

    echo "filename with intra-spaces:"
    echo "proposed file rename:"

    find "$source_dir_fullpath" -type f |
    while IFS=$'\n' read file
    do
        #echo -e "\e[40m$all_files_count:\e[0m";

        if echo "$file" | grep -q ' '
        then
            ((spaced_files_count++))
            echo -e "\e[40m$spaced_files_count:\e[0m";
            echo "$file"
            filename="${file//' '/'_'}"
            echo "$filename" && echo
        else
            :
            #echo "found one WITHOUT spaces"
        fi 
        
        ((all_files_count++))
        #((all_files_count+=1))
        #all_files_count=$(( all_files_count + 1 ))
        
        #set --
	    #set -- "$spaced_files_count" "$all_files_count" # using 'set' to get test_line out of this subprocess into a positional parameter ($1)


        if [ $all_files_count -gt 100 ]
        then
            set -- "${spaced_files_count}" "$all_files_count"
            #set -- $spaced_files_count
            echo "$@"

            echo "TOTAL SPACED FILES: $spaced_files_count"
            echo "TOTAL FILES: $all_files_count" 

            break
        fi

    done
    IFS=$OIFS  

    echo "$@"
    echo "==========================  $2"


    echo "TOTAL SPACED FILES: $spaced_files_count"
    echo "TOTAL FILES: $all_files_count" 
    echo "$@"
	#set -- # unset that positional parameter we used to get test_line out of that while read subprocess

}

###########################################################
function rename_files()
{

    count=1
    OIFS=$IFS # store pre-existing IFS to be reset at end

    find "$source_dir_fullpath" -type f |
    while IFS=$'\n' read file
    do
        if echo "$file" | grep -q ' '
        then
            filename="${file//' '/'_'}"
            mv -i "$file" "$filename" # prompt before overwriting
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