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

# Nowdownload /Nowvideo

function wise_args {
    code="${1##*'('}"
    code="${code%%')'*}"
    code="${code//\'}"
    echo ${code//','/' '}
}


if [ "$url_in" != "${url_in//'nowdownload'}" ]; then
    if [ "$url_in" != "${url_in//'down.php?id='}" ]; then
	url_in_old="$url_in"
	url_in="${url_in_old//'down.php?id='/dl/}"
	links_loop - "$url_in_old"
	links_loop + "$url_in"
    elif [ "$url_in" != "${url_in//'download.php?id='}" ]; then
	url_in_old="$url_in"
	url_in="${url_in_old//'download.php?id='/dl/}"
	links_loop - "$url_in_old"
	links_loop + "$url_in"
    fi
fi

if [ "$url_in" != "${url_in//nowdownload.}" ] && [ "$url_in" == "${url_in//\/nowdownload\/}" ]; then
    get_tmps
    if [[ -z $(cat "$path_tmp"/zdl.tmp) ]]; then
	break_loop=true
	_log 2
	sleeping $sleeping_pause
    else
	test_file=`cat "$path_tmp"/zdl.tmp | grep "This file does not exist"`
	if [ ! -z "$test_file" ]; then
	    _log 3
	    break_loop=true
	    break
	fi
	now=`cat "$path_tmp"/zdl.tmp | grep "Download Now"`
	if [ ! -z "$now" ]; then
	    url_in_file="${now#*\"}"
	    url_in_file="${url_in_file%%\"*}"
	    unset now
	    
	else
	    wise_code=$(cat "$path_tmp"/zdl.tmp | grep ";eval")
	    print_c 2 "Attendi circa 30 secondi:"
	    k=`date +"%s"`
	    s=0
	    while true; do
		touch "$path_tmp"/.wise-code
		sleep 0.9
		s=`date +"%s"`
		s=$(( $s-$k ))
		if [ ! -f "$path_tmp"/.wise-code ]; then
		    break
		fi
		print_c 0 "$s\r\c"
		if ! check_pid $pid_prog
		then
		    exit
		fi
	    done & 
	    wise_code=$( "$path_usr"/extensions/zdl-wise $( wise_args "$wise_code" ) )
	    wise_code=$( "$path_usr"/extensions/zdl-wise $( wise_args "$wise_code" ) )
	    wise_code=$( "$path_usr"/extensions/zdl-wise $( wise_args "$wise_code" ) )
	    clean_countdown

	    unset url_in_file
	    preurl_in_file="${wise_code##*href=\"}"
	    preurl_in_file="${preurl_in_file%%\"*}"
	    preurl_in_file="${url_in%'/dl/'*}$preurl_in_file"
	    while true; do
		if (( $s>30 )); then
		    wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl2.tmp" "$preurl_in_file" &>/dev/null 
		fi
		sleeping 1
		s=`date +"%s"`
		s=$(( $s-$k ))
		print_c 0 "$s\r\c"
		url_in_file=$(cat "$path_tmp/zdl2.tmp" |grep nowdownloader)
		url_in_file="${url_in_file#*href=\"}"
		url_in_file="${url_in_file%%\"*}"
		premium=$(cat "$path_tmp/zdl2.tmp" |grep "You need Premium")
		sleeping 0.1
		if [ ! -z "$url_in_file" ] || [ ! -z "$premium" ] || (( $s > 60 )); then
		    break
		fi
		if ! check_pid $pid_prog
		then
		    exit
		fi
	    done
	fi
	if [ ! -z "$premium" ]; then
	    _log 11
	    break_loop=true
	else
	    file_in="${url_in_file##*'/'}"
	    file_in="${file_in%'?'*}"
	fi

	if [ -z "$file_in" ]; then
	    break_loop=true
	fi
	unset preurl_in_file 
    fi
fi

