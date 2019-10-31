#!/bin/bash

# linux doesn't like spaces in filenames
# renames files in a directory, with space characters replaced by underscores

function main()
{
    abs_filepath_regex='^(/{1}[A-Za-z0-9\._-~]+)+$' # absolute file path, ASSUMING NOT HIDDEN FILE, ...
    all_filepath_regex='^(/?[A-Za-z0-9\._-~]+)+$' # both relative and absolute file path

    get_dir_to_check
    find_files_and_show_user
    rename_files #


} ## end main



###########################################################
# gets from user the directory (absolute path) in which to recursively check/
# +for filenames with spaces. 
function get_dir_to_check()
{
    echo "Enter the full path to the directory containing the files of interest" && echo
    read source_dir_fullpath 

    # this valid form test works for both sanitised directory paths and absolute file paths
    test_file_path_valid_form "$source_dir_fullpath"
    if [ $? -eq 0 ]
    then
        echo "SYNCHRONISED LOCATION HOLDING (PARENT) DIRECTORY PATH IS OF VALID FORM"
    else
        echo "The valid form test FAILED and returned: $?"
        echo "Nothing to do now, but to exit..." && echo
        exit 1
        #exit $E_UNEXPECTED_ARG_VALUE
    fi	


    #test_dir_path_access...
}

###########################################################
function find_files_and_show_user()
{
    :    
}

###########################################################
function rename_files()
{

    count=1
    OIFS=$IFS # store pre-existing IFS to be reset at end

    find "$source_dir_fullpath" -type f |
    while IFS=$'\n' read file
    do
        echo -e "\e[36m$count:\e[0m";

        echo "$file"
        if echo "$file" | grep -q ' '
        then
            echo "found one WITH spaces"
            filename="${file//' '/'_'}"

            mv -i "$file" "$filename" # prompt before overwriting
            if [ $? -eq 0 ]
            then
                echo "new name: $filename"
            else
                echo "ERROR: THIS FILE WAS NOT RENAMED"
            fi
        else
            echo "found one WITHOUT spaces"
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
	echo && echo "Entered into function ${FUNCNAME[0]}" && echo

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
		return $E_UNEXPECTED_ARG_VALUE
	fi 


	echo && echo "Leaving from function ${FUNCNAME[0]}" && echo

	return "$test_result"
}

###############################################################################################

main "$@"; exit