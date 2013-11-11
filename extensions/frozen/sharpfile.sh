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


##		SHARPFILE with pseudo-captcha
		
if [ "$url_in" != "${url_in//sharpfile.}" ]; then
    wget $url_in -O "$path_tmp"/zdl.tmp &>/dev/null
    tmp="$path_tmp/zdl.tmp"
    input_hidden
    
    if ( [ ! -f "${file_in}.st" ] && [ -f "${file_in}" ] && [ "$downloader_in" = "Axel" ] ) || ( [ -f "${file_in}" ] && [ "$downloader_in" = "Wget" ] ); then
	echo -n
    else
	check_ip sharpfile
	wget --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl $url_in -O "$path_tmp"/zdl.tmp &>/dev/null
	echo -e "...\c"
	tmp="$path_tmp/zdl.tmp"
	input_hidden
	
	post_data="${post_data//'op=catalogue&'}"
	
	wget --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies --save-cookies=$path_tmp/cookies2.zdl --post-data="$post_data&method_free=Free Download" $url_in -O "$path_tmp"/zdl2.tmp &>/dev/null
	
	captcha_html=`cat "$path_tmp"/zdl2.tmp |grep "position:absolute;padding-left"`
	unset post_data
	unset ascii_dec
	unset i
	while [ ${#ascii_dec[*]} != 4 ];do
	    captcha_html="${captcha_html#*'position:absolute;padding-left:'}"
	    i="${captcha_html%%px*}"
	    captcha_html="${captcha_html#*'&#'}"
	    ascii_dec[$i]="${captcha_html%%';'*}"
	done
	pseudo_captcha
	print_c 2 "Attendi:"
	
	code=${captcha[*]}
	code=${code// /}
	
	s=65
	while [ $s != 0 ]; do
	    echo -e "  \r\c"
	    echo -e $s"\r\c"
	    sleeping 1
	    (( s-- ))
	done
	echo -e "  \r\c"
	tmp="$path_tmp/zdl2.tmp"
	input_hidden
	post_data="${post_data//'op=catalogue&'}"
	post_data="${post_data}&code=${code}"
    fi
    url_in_file="$url_in"
fi
