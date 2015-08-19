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

## zdl-extension types: download
## zdl-extension name: Nowdownload


if [ "$url_in" != "${url_in//'nowdownload'}" ]
then
    if [ "$url_in" != "${url_in//'down.php?id='}" ]
    then
	url_in_old="$url_in"
	url_in="${url_in_old//'down.php?id='/dl/}"
	links_loop - "$url_in_old"
	links_loop + "$url_in"
    elif [ "$url_in" != "${url_in//'download.php?id='/dl/}" ]
    then
	url_in_old="$url_in"
	url_in="${url_in_old//'download.php?id='/dl/}"
	links_loop - "$url_in_old"
	links_loop + "$url_in"
    fi
fi

if [ "$url_in" != "${url_in//nowdownload.}" ] &&
       [ "$url_in" == "${url_in//\/nowdownload\/}" ]
then
    get_tmps

    if [ -n "$(grep "This file does not exist" "$path_tmp"/zdl.tmp)" ]
    then
	_log 3
	jump=true
    elif [ -n "$(grep "The file is being transfered. Please wait" "$path_tmp"/zdl.tmp)" ]
    then
	_log 17
	jump=true
    fi
    file_in1="$(grep 'Downloading' "$path_tmp"/zdl.tmp)"
    file_in1="${file_in1#*'<br> '}"
    file_in1="${file_in1%%</h4>*}"
    file_in1="${file_in1%' '*}"
    file_in1="${file_in1%' '*}"
    file_in1="${file_in1%' '*}"
    file_in1="${file_in1//'<br>'/}"
    
    while [ "$file_in1" != "${file_in1%.}" ]
    do
	file_in1=${file_in1%'.'}
    done
    
    file_in="${file_in1}"
    if ! file_filter
    then
	jump=true
    fi
    unset file_in
    
    now="$(grep "Download Now" "$path_tmp"/zdl.tmp)"
    if [ -n "$now" ]
    then
	url_in_file="${now#*\"}"
	url_in_file="${url_in_file%%\"*}"
	unset now
    elif [ -z "$jump" ]
    then
	token="$(grep token "$path_tmp"/zdl.tmp)"
	token=${token//*=}
	token=${token//\"*/}
	preurl_in_file=${url_in//\/dl/\/dl2}"/$token"
	print_c 2 "Attendi circa 30 secondi:"
	k=`date +"%s"`
	s=0
	unset url_in_file
	
	while true
	do
	    if (( $s>29 ))
	    then
		wget -t 1 -T $max_waiting                 \
		     --load-cookies=$path_tmp/cookies.zdl \
		     -O "$path_tmp/zdl2.tmp"              \
		     "$preurl_in_file" &>/dev/null 
	    fi
	    
	    sleeping 1
	    s=`date +"%s"`
	    s=$(( $s-$k ))
	    
	    print_c 0 $s"\r\c"

	    if [ -n "$(grep "Click here to become Premium" "$path_tmp"/zdl2.tmp 2>/dev/null)" ]
	    then
		_log 11
		break_loop=true
		break
	    fi
	    
	    url_in_file="$(grep "Click here to download" "$path_tmp"/zdl2.tmp 2>/dev/null)"
	    url_in_file=${url_in_file//*href=\"} 
	    url_in_file=${url_in_file//\"*}
	    sleeping 0.1
	    if url "$url_in_file" ||
		    (( $s > 60 ))
	    then
		break
	    fi
	done
    fi

    # file_in1="$(grep 'Downloading' "$path_tmp"/zdl.tmp)"
    # file_in1="${file_in1#*'<br> '}"
    # file_in1="${file_in1%%</h4>*}"
    # file_in1="${file_in1%' '*}"
    # file_in1="${file_in1%' '*}"
    # file_in1="${file_in1%' '*}"
    # file_in1="${file_in1//'<br>'/}"
    
    # while [ "$file_in1" != "${file_in1%.}" ]
    # do
    # 	file_in1=${file_in1%.}
    # done

    if [ -z "$break_loop" ]
    then
	file_in2="${url_in_file##*\/}"
	file_in2="${file_in2##_}"

	if [ "$file_in2" != "${file_in2//$file_in1}" ] ||
	       [[ "$file_in2" =~ (part[0-9]+|[cC]{1}[dD]{1}[ _-]*[0-9]+) ]] 
	then
    	    file_in="$file_in2"
	    
	elif [ -n "$file_in1" ]
	then
    	    file_ext="${file_in2##*.}"
    	    file_in="${file_in1}.${file_ext}"
	    
	elif [ -z "$jump" ]
	then
    	    _log 2
	fi
	
	file_in="${file_in%'?'*}"

	if ! url "$url_in_file" ||
	       [ "$url_in_file" == "$url_in" ] ||
	       [ -z "$file_in" ]
	then
	    _log 2
	fi
    fi
    unset file_in2 file_in1 file_ext token preurl_in_file jump
fi
