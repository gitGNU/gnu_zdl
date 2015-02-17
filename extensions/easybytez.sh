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
## zdl-extension name: Easybytez


if [ "$url_in" != "${url_in//easybytez}" ]; then
    if [ "$login" == "1" ]; then
	wget -q -t 1 -T $max_waiting --user-agent="$user_agent" --retry-connrefused --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -O "$path_tmp/login.tmp" "http://www.easybytez.com/login.html" &>/dev/null

	input_hidden "$path_tmp/login.tmp"
	
	host="easybytez"
	host_login
	wget -q -t 1 -T $max_waiting --retry-connrefused -q --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl.tmp" --post-data="${post_data}&login=${user}&password=${pass}" "http://www.easybytez.com" &>/dev/null
	unset post_data
    fi	    
    file_in=`wget -t 1 -T $max_waiting --retry-connrefused -q --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies -O - "$url_in" 2>/dev/null |grep '<span class="name">'`
    file_in="${file_in#*>}"
    file_in="${file_in%%<*}"
    url_in_file="${url_in}"
    not_available=`wget -t 1 -T $max_waiting --retry-connrefused -q --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies -O - "$url_in" |grep "File not available"`
    if [ ! -z "$not_available" ]; then
	_log 3
	break
    fi
    check_in_file
    if [ ! -z "${file_in}" ] && [ ! -f "${file_in}" ] && [ -z "$not_available" ]; then
	if [ ! -z "$exceeded_login" ]; then
	    check_ip easybytez
	fi
	if [ "$login" == "1" ]; then
	    wget -q -t 1 -T $max_waiting --retry-connrefused -q --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl.tmp" $url_in &>/dev/null
	    echo -e "...\c"
	    countdown=40
	    redirected=true
	else
	    check_ip easybytez

	    wget -q -t 1 -T $max_waiting --retry-connrefused --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl.tmp" $url_in &>/dev/null
	    countdown=60
	fi
	
	input_hidden "$path_tmp/zdl.tmp"
	wget -t 1 -T $max_waiting -q --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl --post-data="${post_data}&method_free=Free Download" $url_in -O "$path_tmp"/zdl2.tmp &>/dev/null

	exceeded=`cat "$path_tmp"/zdl2.tmp |grep "Upgrade your account to download bigger files"`

	if [ -z "$exceeded_login" ]; then
	    exceeded_login=`cat "$path_tmp"/zdl2.tmp |grep 'You have reached the download-limit:'`
	fi
	unset post_data
	check_in_file
	if [ $? != 1 ] && [ -z "$not_available" ] && [ -z "$exceeded" ]; then
	    input_hidden "$path_tmp/zdl2.tmp"
	    
	    wget -t 1 -T $max_waiting -q --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl --post-data="${post_data}&btn_download=Download File" $url_in -O "$path_tmp"/zdl3.tmp &>/dev/null
	    echo -e "...\c"
	    unset post_data
	    
	    print_c 2 "Attendi $countdown secondi:"
	    for s in `seq 0 $countdown`; do
		echo -e $s"\r\c"
		sleeping 1
	    done
	    echo -e "  \r\c"

	    input_hidden "$path_tmp/zdl3.tmp"
	    length_in=`cat .zdl_tmp/zdl3.tmp |grep Size`
	    length_in="${length_in#*\(}"
	    length_in="${length_in%% *}"
	    post_data="${post_data}&btn_download=Download File"

	    url_in_file="$url_in"
	else
	    break_loop=true
	fi
    fi
fi
