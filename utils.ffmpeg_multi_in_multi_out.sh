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

input_file_extension=".m4v"
output_file_extension=".mp4"

for input_file in $HOME/INSANITY/*${input_file_extension}
do
    output_file="${input_file%${input_file_extension}}""${output_file_extension}"
    echo "input file:  $input_file"
    echo "output file:  $output_file"
done

