#!/bin/bash

# fileset_mover.sh
# aka file_matcher_mover.sh

# move matching regular files from whatever depth they are under the\
# +source directory, directly into the destination directory (depth 1)...
# just regular files
# just matching file extensions

function main()
{

    # GLOBAL VARIABLE DECLARATIONS:
	test_line="" # global...
    
    src_dir_fullpath="" # OR #test_line=""
    dst_dir_fullpath="" # OR #test_line=""

    config_file_fullpath="/etc/file_matcher_mover.config"	declare -a directories_to_exclude=() # ...

    abs_filepath_regex='^(/{1}[A-Za-z0-9\.\ _-~]+)+$' # absolute file path, ASSUMING NOT HIDDEN FILE, ...
    all_filepath_regex='^(/?[A-Za-z0-9\._-~]+)+$' # both relative and absolute file path
    
    # totals for each subset of files:
    all_reg_files_count=0
    all_dir_files_count=0
    matched_reg_files_count=0
    matched_dir_files_count=0

    # show user program header and purpose of this program
    # give them the option to abort or continue
     
    
    match_and_move_files


} ## end main


###########################################################
# the while loop that encapsulated pretty much the whole of this program
function match_and_move_files()
{
    more_files_to_move="yes"

    while [ "$more_files_to_move" == 'yes']
    do
       
       echo "Opening your editor now..." && echo && sleep 3
       sudo nano "$config_file_fullpath" # /etc exists, so no need to test access etc.

       # read file match configuration
       import_file_match_configuration

       exit 0


       move_matching_files #



    done
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

main "$@"; exit
