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


if [ "$url_in" != "${url_in//uploaded.}" ]; then
    unset alias
    url_in_file="${url_in%/}"
    
    wget -t 1 -T $max_waiting $url_in_file -q -O "$path_tmp"/test_page.tmp &>/dev/null
    test_exceeded=`cat "$path_tmp"/test_page.tmp |grep 'small style'`
    test_exceeded="${test_exceeded#*'>'}"
    test_exceeded="${test_exceeded%'<'*}"
    test_exceeded=`echo $test_exceeded |grep GB`
    if [ ! -z "$test_exceeded" ]; then
	test_exceeded=${test_exceeded%' '*}
	test_exceeded=${test_exceeded//,/.}
	test_exceeded=`echo "( $test_exceeded>1 )" |bc -l 2>/dev/null`
    fi
    test_available=`wget -q -O - -t 1 -T $max_waiting $url_in_file |grep "</html"`
    
    if [ "$test_exceeded" == "1" ]; then
	exceeded=1
    elif [ -z "$test_available" ]; then
	not_available=true
    else
	if [ "${url_in_file##*/}" != "${url_in_file//*file\/}" ]; then
	    file_in=${url_in_file##*/}
	    url_in_file2=${url_in_file%/*}
	    file_id=${url_in_file2##*/}
	else 
	    wget -t 1 -T $max_waiting "$url_in_file" -O "$path_tmp"/zdl.tmp &>/dev/null
	    file_id=${url_in_file##*/} 
	    file_in=`cat "$path_tmp"/zdl.tmp |grep "id=\"filename\""`
	    file_in="${file_in//<\/a*/}"
	    file_in="${file_in##*>}"
	    if [ "$file_in" != "${file_in//'&alias;'/}" ]; then
		file_in="${file_id}_${file_in//'&alias;'/.}.alias"
	    fi
	    
	fi
	
	if [ ! -f "$file_in" ]; then
	    check_ip uploaded
	    wget -t 1 -T $max_waiting --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl "$url_in_file" -O "$path_tmp"/zdl.tmp &>/dev/null
	    echo -e "...\c"
	    
	    cooking=`cat "$path_tmp"/zdl.tmp |grep ref_user`
	    cooking="${cooking//*\(\'/}"
	    cooking=${cooking//"'"*/}
	    
	    echo "uploaded.to     FALSE   /       FALSE   0       ref     $cooking" >> "$path_tmp"/cookies.zdl
	    
	    wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl "http://uploaded.to/io/ticket/captcha/$file_id" -O "$path_tmp/goal.tmp" &>/dev/null
	    echo -e "...\c"
	    
	    url_in_file=`cat "$path_tmp"/goal.tmp`
	    url_in_file=${url_in_file//*url_in:\'/}
	    url_in_file=${url_in_file//\'*}
	fi
    fi
    
fi
