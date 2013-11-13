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


if [ "$url_in" != "${url_in//shareflare.}" ]; then
    check_ip shareflare
    get_tmps
    tmp="$path_tmp/zdl.tmp"
    input_hidden
    if [ ! -f "${file_in}.st" ] && [ -f "${file_in}" ]; then
	echo
    else
	wget --load-cookies=$path_tmp/cookies.zdl --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl --post-data=$post_data"&submit_ifree=Download file" http://shareflare.net/download4.php -O "$path_tmp"/download4.tmp &>/dev/null
	echo -e "...\c"
	unset post_data
	
	input_hidden
	wget --load-cookies=$path_tmp/cookies.zdl --post-data=$post_data"&frameset=Download file." http://shareflare.net/download3.php -O "$path_tmp"/download3.tmp &>/dev/null
	echo -e "...\c"
	
	wget --load-cookies=$path_tmp/cookies.zdl --post-data=$post_data"&frameset=Download file." "http://shareflare.net/tmpl/tmpl_frame_top.php?link=" -O "$path_tmp"/tmpl_frame_top.php &>/dev/null
	echo -e "...\c"
	
	print_c 2 "Attendi circa 45 secondi:"
	
	k=`date +"%s"`
	while [ "$goal" == "" ]; do
	    sleeping 1
	    s=`date +"%s"`
	    s=$(( $s-$k ))
	    echo -e $s"\r\c"
	    
	    if (( $s>40 )); then
		wget --load-cookies=$path_tmp/cookies.zdl --post-data=$post_data"&frameset=Download file." "http://shareflare.net/tmpl/tmpl_frame_top.php?link=" -O "$path_tmp"/tmpl_frame_top.php &>/dev/null
		
		goal=`less "$path_tmp"/tmpl_frame_top.php |grep direct_link_0` 
		sleeping 1
	    fi
	    if (( $s>90 )); then
		break
	    fi
	done
	
	url_in_file=${goal#*\"}
	url_in_file=${url_in_file//\"*/}
	
	
	n=1
    fi
fi
