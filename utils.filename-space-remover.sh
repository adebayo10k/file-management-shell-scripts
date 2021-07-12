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


# program allows user to review file listings before renaming them.
# full, unchecked, uncontrolled, non-interactive renaming of what\
# + could be 100s of found files now seems a bit risky.

function main()
{
	echo "OUR CURRENT SHELL LEVEL IS: $SHLVL"

	echo "USAGE: $(basename $0)"  
	
	# Display a program header and give user option to leave if here in error:
    echo
    echo -e "		\033[33m===================================================================\033[0m";
    echo -e "		\033[33m||          Welcome to the INTRA-FILENAME SPACE REMOVER          ||  author: adebayo10k\033[0m";  
    echo -e "		\033[33m===================================================================\033[0m";
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

    
    # GLOBAL VARIABLE DECLARATIONS:
	test_line="" # global...
    
    source_dir_fullpath="" # OR #test_line=""
    excluded_dir_config_file_fullpath="/etc/filename_space_remover.excluded_dir_config"
	declare -a directories_to_exclude=() # ...

    # totals for each subset of files:
    all_reg_files_count=0
    all_dir_files_count=0
    spaced_reg_files_count=0
    spaced_dir_files_count=0
    
    # >>>>>>>>>> SHOULD WE JUST START HERE BY OPENING A CONFIG FILE USING nano? <<<<<<<<<<

    get_dir_to_check # including validation of this user input

    generate_updated_file_listings 

    exit 0

    rename_files #


} ## end main


##########################################################################################################
##########################################################################################################
##########################################################################################################

# loop over this block of code until whole of the output listing is ready to be renamed
function generate_updated_file_listings()
{    
    while : #1
    do

        # import directories to exclude from updated excludes config file
        # this is the first thing to happen after editing the config file
        import_excludes_config

        get_file_totals

        #reset_file_totals

        #all_reg_files_count=$(get_file_totals2 "$all_reg_files_count" "f" "*")
        #all_dir_files_count=$(get_file_totals2 "$all_dir_files_count" "d" "*")
        #spaced_reg_files_count=$(get_file_totals2 "$spaced_reg_files_count" "f" "* *")
        #spaced_dir_files_count=$(get_file_totals2 "$spaced_dir_files_count" "d" "* *")

        # negative response terminates program, affirmative just allows continuation
        get_continue_response "numbers look credible? continue with these numers? [y/n] (or q to quit program)"
        if [ $? -eq 0 ]
        then
            echo "Your answer was AFFIRMATIVE" && echo && sleep 1
            echo "Continuing program execution..." && sleep 1
        else
            echo "Your answer was NEGATIVE" && echo && sleep 1
            echo "Aborting program execution..." && sleep 1 
            exit 0 ## perhaps in future branch we'll continue loop?
        fi

        test_for_more_spaced_filenames # program exits if test fails (ie no more found)

        list_spaced_files # output numbered lists of each subset of intra-space character files

        get_continue_response "Based on the above lists, READY FOR RENAME [y] or do you now want to\
 make more filesystem OR directory exclude config file changes[n] ? (or q to quit program)"
        if [ $? -eq 0 ]
        then
            echo "Your answer was AFFIRMATIVE" && echo && sleep 1
            echo "Continuing program execution..." && sleep 1
            break ## and exit function
        else
            echo "Your answer was NEGATIVE" && echo && sleep 1
            echo "Make your filesystem and directory-exclusion-configuration changes now" && echo && sleep 1
            echo "Opening your editor now..." && echo && sleep 3
            while : #2
            do
                nano "$excluded_dir_config_file_fullpath"
                get_continue_response "Changes completed and ready to REFRESH listings? [y] or do you now want to\
 make yet MORE filesystem OR directory exclude config file changes [n] ? (or q to quit program)"
                if [ $? -eq 0 ]
                then
                    echo "Your answer was AFFIRMATIVE" && echo && sleep 1
                    echo "Continuing program execution (refresh listings)..." && sleep 1
                    break ## .. and back into while #1
                else
                    echo "Your answer was NEGATIVE" && echo && sleep 1
                    echo "Make your filesystem and directory-exclusion-configuration changes now" && echo && sleep 1
                    echo "Opening your editor now..." && echo && sleep 3
                    # # .. and repeat #2..
                fi
            done #2        
        fi

    done #1

}
##########################################################################################################
# populate the directories_to_exclude indexed array from the config file
function import_excludes_config()
{
    if [ -f "$excluded_dir_config_file_fullpath" ]; then :; else sudo touch "$excluded_dir_config_file_fullpath"; fi

	echo "exit code after line tests: $?" && echo
    # all lines in file must pass test in order to continue the import

	## TODO: if $? -eq 0 ... ANY POINT IN BRINGING BACK A RETURN CODE?

	# if tests passed, configuration file is accepted and used from here on
	echo "we can use this configuration file" && echo

    # populate the designated array variable
	while read lineIn
	do
		directories_to_exclude+=("$lineIn")  # 

	done < "$excluded_dir_config_file_fullpath"


    for dir in "${directories_to_exclude[@]}"
	do
		#test_and_set_line_type "$lineIn"
        sanitise_absolute_path_value "$dir"
        dir="$test_line"
        echo "back from sanitisation and dir (from excluded config) has value: ${dir}"

        test_file_path_valid_form "$dir"
        if [ $? -eq 0 ]
        then
            echo "EXCLUDED DIRECTORY PATH IS OF VALID FORM"
        else
            echo "The valid form test FAILED and returned: $?"
            echo "Nothing to do now, but to exit..." && echo
            exit 1
            #exit $E_UNEXPECTED_ARG_VALUE
        fi	
    done
}

##########################################################################################################

# gets from user the directory (absolute path) in which to recursively check/
# +for filenames with spaces. 
function get_dir_to_check()
{
    echo "Enter the full path to the directory containing the files of interest" && echo
    read source_dir_fullpath

    sanitise_absolute_path_value "$source_dir_fullpath"
    source_dir_fullpath="$test_line"
    echo "back from sanitisation and source_dir_fullpath has value: ${source_dir_fullpath}"

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
        # if filename (spaced) matches an item in the directories_to_exclude array,
        # then skip, else increment counter
        match_found="false"
        for dir in "${directories_to_exclude[@]}"
	    do
	    	if [ "$dir" == "${spaced_file_name}"* ]
	    	then
                # we're ignoring (not counting) this directory
                match_found="true"
	    		break
	    	fi
        done

        # 
        if [ "$match_found" == "true" ]
        then
            :
        elif [ "$match_found" == "false" ]
        then
            ((spaced_reg_files_count++))
        else
            echo "We should never have entered this branch!"
            exit 1
        fi    
           
    done < <(find "$source_dir_fullpath" -type f -name "* *")

    ######################################

    while IFS=$'\n' read spaced_dir_name
    do
        # if filename (spaced) matches an item in the directories_to_exclude array,
        # then skip, else increment counter
        match_found="false"
        for dir in "${directories_to_exclude[@]}"
	    do
	    	if [ "$dir" == "${spaced_dir_name}"* ]
	    	then
                # we're ignoring (not counting) this directory
                match_found="true"
	    		break
	    	fi
        done

        # 
        if [ "$match_found" == "true" ]
        then
            :
        elif [ "$match_found" == "false" ]
        then
            ((spaced_dir_files_count++))   
        else
            echo "We should never have entered this branch!"
            exit 1
        fi    


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

# get user response y -> 0; n -> 1 
function get_continue_response()
{    
    msg=$1
    echo "$msg"
    read answer

    case $answer in 
	[yY])   return 0
				;;
	[nN])   return 1
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
        # if filename (spaced) matches an item in the directories_to_exclude array,
        # then skip, else increment counter and list 
        match_found="false"
        for dir in "${directories_to_exclude[@]}"
	    do
	    	if [ "$dir" == "${spaced_file_name}"* ]
	    	then
                # we're ignoring (not counting) this directory
                match_found="true"
	    		break
	    	fi
        done

        # 
        if [ "$match_found" == "true" ]
        then
            :
        elif [ "$match_found" == "false" ]
        then
            ((spaced_reg_files_count++))
            echo -e "\e[40m$spaced_reg_files_count:\e[0m";
            echo "$spaced_file_name"
            proposed_filename="${spaced_file_name//' '/'_'}"
            echo "$proposed_filename" && echo  
        else
            echo "We should never have entered this branch!"
            exit 1
        fi    
        
    done < <(find "$source_dir_fullpath" -type f -name "* *")

    #####################################

    echo "DIRECTORY FILES WITH INTRA-FILENAME SPACES:"
    echo "=========================================" && echo

    while IFS=$'\n' read spaced_dir_name
    do
        # if filename (spaced) matches an item in the directories_to_exclude array,
        # then skip, else increment counter
        match_found="false"
        for dir in "${directories_to_exclude[@]}"
	    do
	    	if [ "$dir" == "${spaced_dir_name}"* ]
	    	then
                # we're ignoring (not counting) this directory
                match_found="true"
	    		break
	    	fi
        done

        # 
        if [ "$match_found" == "true" ]
        then
            :
        elif [ "$match_found" == "false" ]
        then
            ((spaced_dir_files_count++))
            echo -e "\e[40m$spaced_dir_files_count:\e[0m";
            echo "$spaced_dir_name"
            proposed_filename="${spaced_dir_name//' '/'_'}"
            echo "$proposed_filename" && echo     
        else
            echo "We should never have entered this branch!"
            exit 1
        fi    
        
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