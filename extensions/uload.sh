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
## zdl-extension name: Uload

if [ "$url_in" != "${url_in//uload.}" ]; then
    check_ip uload
    wget -q -t 1 -T $max_waiting --retry-connrefused --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl.tmp" $url_in &>/dev/null
    echo -e "...\c"

    test_exceeded=`cat "$path_tmp/zdl.tmp" | grep "h2"`
    if [ ! -z "$test_exceeded" ]; then
	test_exceeded="${test_exceeded#*- }"
	test_exceeded="${test_exceeded%% *}"
	test_exceeded="${test_exceeded%.*}"
	if (( $test_exceeded>400 )); then
	    exceeded=true
	fi
    fi
    
    if [ -z "$exceeded" ]; then
	unset post_data
	input_hidden "$path_tmp/zdl.tmp"
	post_data="${post_data//'op=catalogue&'}"
	
	wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl --save-cookies=$path_tmp/cookies2.zdl --post-data="$post_data&method_free=Free Download / Stream" $url_in -O "$path_tmp"/zdl2.tmp &>/dev/null
	
	unset post_data
	input_hidden "$path_tmp/zdl2.tmp"
	post_data="${post_data//'op=catalogue&'}&btn_download=Create Download Link"
	
	wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies --save-cookies=$path_tmp/cookies2.zdl --post-data="$post_data&method_free=Free Download / Stream" $url_in -O "$path_tmp"/zdl3.tmp &>/dev/null
	
	if [ -f "$path_tmp"/zdl3.tmp ];then
	    url_in_file=`cat "$path_tmp"/zdl3.tmp | grep "http://uload.to/images/download.png"`
	    url_in_file="${url_in_file#<a href=\"}"
	    url_in_file="${url_in_file%%\"*}"
	fi
    fi
fi
