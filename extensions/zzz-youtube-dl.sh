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

## zdl-extension types: programs
## zdl-extension name: youtube-dl (comando per elenco delle estensioni: youtube-dl --list-extractors), Aria2 (anche torrent), Axel, Wget, RTMPDump, cURL


if command -v youtube-dl &>/dev/null &&
       [ -z "$url_in_file" ] &&
       [ -z "$break_loop" ] &&
       ! dler_type "no-resume" "$url_in" &&
       ! dler_type "wget" "$url_in" &&
       ! dler_type "rtmp" "$url_in"
then
    youtube-dl -R 1 --get-url --get-filename "$url_in" &>"$path_tmp"/youtube-dl.data &
    pid_yt_dl=$!

    for i in {20..0}
    do
	print_c 4 "$i  \r\c"
	sleep 1
	! check_pid $pid_yt_dl && break
    done

    kill -9 $pid_yt_dl
    data=$(grep -Pv '(WARNING|xml$|html$|xhtml$)' "$path_tmp"/youtube-dl.data)
	
    items=( "$path_tmp"/filename_* )

    if (( ${#items[@]}>0 ))
    then
	for item in ${items[@]}
	do
	    url=$(cat "$item" 2>/dev/null)
	    if [ "${url%% }" == "$url_in" ]
	    then
		item="${item// /_}"
		file_in="${item#*filename_}"
		file_in="${file_in%.txt}"
		break
	    fi
	done
    fi

    if [ -z "$file_in" ]
    then
	file_in="$(tail -n1 <<< "$data")"
	file_in="${file_in% _ *}"

	ext0=$(grep -o '^\.'"${file_in##*.}" $path_usr/mimetypes.txt | head -n1)
	file_in="${file_in%$ext0}"

	## elimina doppione nel nome del file
	if (( $(( ${#file_in}%2 ))==1 ))
	then
	    length=$(( (${#file_in}-1)/2 ))
	    [ "${file_in:0:$length}" == "${file_in:$(( $length+1 )):$length}" ] &&
		file_in="${file_in:0:$length}"
	fi
    fi

    url_in_file="$(tail -n2 <<< "$data" | head -n1)"

    if ! url "$url_in_file"
    then
	unset file_in url_in_file
    else
	[ "$url_in" != "$url_in_file" ] &&
	    print_c 1 "youtube-dl: $url_in_file"
	unset break_loop
    fi
fi

