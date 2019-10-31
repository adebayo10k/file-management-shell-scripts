#!/bin/bash

# fileset_mover.sh
# aka file_matcher_mover.sh

# move media files from wherever they are in the source dir, directly into the destination dir

function main()
{

    move_matching_files #


} ## end main


###########################################################
function move_matching_files()
{
    ################################### EDIT THIS SECTION #############################################
    # specify the file extension to match:
    file_extension=".mp4"  ## REMEMBER TO ESCAPE SPECIAL CHARS WITH \

    # specify source directory:
    #src_dir_path="/media/damola/2TB_ext_hdd/holding_pen_2TB/source"
    src_dir_path="/media/damola/2TB_ext_hdd/holding_pen_2TB/test_source"	

    # specify destination directory:
    #dst_dir_path="/media/damola/2TB_ext_hdd/holding_pen_2TB/scan"
    dst_dir_path="/media/damola/2TB_ext_hdd/holding_pen_2TB/test_scan"	
    ###################################################################################################

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
