#!/bin/bash
#: Title			:utils.file_matcher_mover
#: Date				:2019-
#: Author			:"Damola Adebayo" <adebay10k>
#: Version			:1.0
#: Description		:move regular files with matching file extensions from
#: Description		:whatever depth they are under a source directory, directly
#: Description		:into a destination directory at depth 1
#: Options			:None
#: Usage			:



# ALSO, need to SIMPLIFY current iterations! get rid of clever but overcomplicated code.

function main()
{

    # Display a program header and give user option to leave if here in error:
    echo
    #echo "\033[33m"+$i+"\033[0m";
    echo -e "\033[33m============================================================================\033[0m";
    echo -e "\033[33m||    Welcome to the FILE EXTENSION MATCHING, REGULAR FILE MOVING UTILITY    ||  author: Damola Adebayo\033[0m";  
    echo -e "\033[33m============================================================================\033[0m";
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

    ## EXIT CODES:
	E_UNEXPECTED_BRANCH_ENTERED=10
	E_OUT_OF_BOUNDS_BRANCH_ENTERED=11
	E_INCORRECT_NUMBER_OF_ARGS=12
	E_UNEXPECTED_ARG_VALUE=13
	E_REQUIRED_FILE_NOT_FOUND=20
	E_REQUIRED_PROGRAM_NOT_FOUND=21
	E_UNKNOWN_RUN_MODE=30
	E_UNKNOWN_EXECUTION_MODE=31

    # GLOBAL VARIABLE DECLARATIONS:
	test_line="" # global...
    
    src_dir_fullpath="" # OR #test_line=""
    dst_dir_fullpath="" # OR #test_line=""

    config_file_fullpath="/etc/file_matcher_mover.config"
    #declare -a directories_to_exclude=() # ...

    abs_filepath_regex='^(/{1}[A-Za-z0-9\.\ _-~]+)+$' # absolute file path, ASSUMING NOT HIDDEN FILE, ...
    all_filepath_regex='^(/?[A-Za-z0-9\._-~]+)+$' # both relative and absolute file path. CAREFUL, THIS.
    # MATCHES NEARLY ANY STRING!
    file_extension_regex='^\.{1}[A-Za-z0-9]+$'
    
    # totals for each subset of files:
    all_reg_files_count=0
    all_dir_files_count=0
    matched_reg_files_count=0
    matched_dir_files_count=0

    # show user program header and purpose of this protest_and_set_line_type
    match_and_move_files


} ## end main


###########################################################
# the while loop that encapsulates pretty much the whole of this program
function match_and_move_files()
{
    more_files_to_move="yes"

    while [ "$more_files_to_move" == 'yes' ]
    do
               
        echo "Opening your editor now..." && echo && sleep 3
        sudo nano "$config_file_fullpath" # /etc exists, so no need to test access etc.
        # no need to validate config file path here, since we've just edited the config file!

        check_config_file_content

        exit 0

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

	#echo "exit code for test of that line was: $?" && echo
	#if [ $? -eq 0 ]
    #then
    #    # if tests passed, configuration file is accepted and used from here on
    #    echo "we can use this configuration file" && echo
    #    export config_file_fullpath
    #else
    #    echo "That configuration file was not well formed"
	#	echo "Exiting from function ${FUNCNAME[0]} in script $(basename $0)"
    #    exit 0
    #fi



}
###########################################################
# 
function import_file_match_configuration()
{
    # ignore comment lines, space char lines, empty lines ....
    :
    # for line in read src_dir_path dst_dir_path file_extension

    #    < "$config_file_fullpath" 

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

	#debug printouts:
	#echo "$test_line"

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
        elif [[ "$test_line" =~ $file_extension_regex ]]	#
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

main "$@"; exit
