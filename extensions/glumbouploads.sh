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
# Copyright (C) 2012
# Free Software Foundation, Inc.
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (project administrator and first inventor)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#


if [ "$url_in" != "${url_in//glumbouploads.}" ]; then
    [ "$multi" == "0" ] && [ -f "$file_data" ] && check_ip glumbouploads
    wget -q -t 1 -T $max_waiting --retry-connrefused --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl.tmp" $url_in &>/dev/null
    echo -e "...\c"
    test_exceeded=`cat "$path_tmp/zdl.tmp" | grep "You have requested:"`
    if [ ! -z "$test_exceeded" ]; then
	test_exceeded="${test_exceeded#*'('}"
	test_exceeded="${test_exceeded%')'*}"
	if [ "${test_exceeded}" != "${test_exceeded//MB}" ]; then
	    test_exceeded="${test_exceeded% MB}"
	    test_exceeded="${test_exceeded%.*}"
	    (( test_exceeded++ ))
	    if (( $test_exceeded>1024 )); then
		exceeded=true
	    fi
	elif [ "${test_exceeded}" != "${test_exceeded//GB}" ]; then
	    exceeded=true
	fi
    fi
    
    if [ -z "$exceeded" ]; then
	unset post_data
	tmp="$path_tmp/zdl.tmp"
	input_hidden
	
	post_data="${post_data//'op=login&redirect=&'}"
	if [ -z "$file_in" ]; then
	    file_in=`cat "$path_tmp/zdl.tmp"|grep "fname"|grep "attr"`
	    file_in="${file_in#* \'}"
	    file_in="${file_in%\'*}"
	fi
	
	post_data="$post_data&method_free=Free Download"
	
	wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl --save-cookies=$path_tmp/cookies2.zdl --post-data="$post_data" $url_in -O "$path_tmp"/zdl2.tmp &>/dev/null
	
	unset post_data
	tmp="$path_tmp/zdl2.tmp"
	input_hidden
	post_data="${post_data//'op=login&redirect=&'}"
	print_c 2 "Attendi 100 secondi:"
	for s in `seq 0 100`; do
	    echo -e $s"\r\c"
	    sleeping 1
	done
	wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies --save-cookies=$path_tmp/cookies2.zdl --post-data="$post_data&method_free=Free Download" $url_in -O "$path_tmp"/zdl3.tmp &>/dev/null
	
	if [ -f "$path_tmp"/zdl3.tmp ];then
	    url_in_file=`cat "$path_tmp"/zdl3.tmp | grep "<a href=" |grep "$file_in"`
	    url_in_file="${url_in_file#<a href=\"}"
	    url_in_file="${url_in_file%%\"*}"
	fi
    fi
fi
