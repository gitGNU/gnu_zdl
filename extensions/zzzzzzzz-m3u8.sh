#!/bin/bash -i
#
# ZigzagDownLoader (ZDL)
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see http://www.gnu.org/licenses/. 
# 
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

## zdl-extension types: streaming
## zdl-extension name: Tutti i video in streaming di tipo .m3u8

function post_m3u8_genlink {
    ##
    ## for post_m3u8 function
    ##
    
    if [[ "$url_in_file" =~ \.m3u8\?*.* ]]
    then
    	url_m3u8="$url_in_file"
    else
    	url_m3u8="$url_in"
    fi

    files=$(wget -qO- "$url_m3u8" |grep -vP '^#')
    baseurl="${url_m3u8%\/*}"

    set_link - "$url_in"
    
    while read line
    do
    	echo "$baseurl"/"$line" > "${path_tmp}/filename_${file_in}__M3U8__${line}.txt"
    	set_link + "$baseurl"/"$line"
    done <<< "$files"

    file_in="${file_in}_${line}"
    url_in=$(head -n1 <<< "$files")
    url_in_file="$url_in"

    unset files baseurl
}



if [[ "$url_in" =~ \.m3u8\?*.* ]] ||
       [[ "$url_in_file" =~ \.m3u8\?*.* ]]
then    
    downloader_in=FFMpeg

    [[ "$url_in" =~ \.m3u8\?*.* ]] &&
	url_in_file="$url_in"

    [ -z "$file_in" ] &&
	file_in="${url_in_file##*\/}"

    file_in="${file_in}.mp4"

    if url "$url_in_file" &&
	    test -n "$file_in"
    then
	print_c 1 "Rilevato link M3U8: il file verrà scaricato con ffmpeg"
	unset break_loop

    else
	unset file_in url_in_file
    fi

fi

