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
## zdl-extension name: Rockfile


if [ "$url_in" != "${url_in//'rockfile.'}" ]
then
    # real_ip_rockfile=217.23.3.237
    ## real_ip_rockfile=217.23.3.215
    real_ip_rockfile="rockfile.eu"
    
    html=$(wget -t 1 -T $max_waiting                       \
		--keep-session-cookies                     \
		--save-cookies="$path_tmp"/cookies.zdl     \
		--user-agent="$user_agent"                 \
		-qO- ${url_in//rockfile.eu/$real_ip_rockfile})
    
    if [[ "$html" =~ (File Deleted|file was deleted|File not found) ]]
    then
	_log 3

    elif [ -n "$html" ]
    then
	input_hidden "$html"
	file_in="$postdata_fname"

	method_free=$(grep -P 'method_free.+freeDownload' <<< "$html" |
			     sed -r 's|.+(method_free[^"]*)\".+|\1|g' |
			     tr -d '\r')

	post_data="${post_data##*document.write\(\&}&${method_free}=Regular Download"

	html=$(wget -qO-                                        \
		    --load-cookies="$path_tmp"/cookies.zdl      \
		    --user-agent="$user_agent"                  \
		    --post-data="$post_data"                    \
		    "${url_in//rockfile.eu/$real_ip_rockfile}")

	code=$(pseudo_captcha "$html")

	unset post_data
	input_hidden "$html"
	post_data="${post_data##*'(&'}&code=$code" #&btn_download=Download File"  #Scarica File..."
	post_data="${post_data//'&down_script=1'}"

	errMsg=$(grep 'Devi attendere' <<< "$html" |
			sed -r 's|[^>]+>([^<]+)<.+|\1|g')
	
	if [[ "$html" =~ (You can download files up to) ]]
	then
	    _log 4

	elif [ -n "$code" ]
	then
	    timer=$(grep countdown_str <<< "$html"          |
			   head -n1                         |
			   sed -r 's|.+>([0-9]+)<.+|\1|g')

	    countdown- $timer
	    sleeping 2
	    
	    url_in_file=$(wget -qO- "${url_in//rockfile.eu/$real_ip_rockfile}"       \
			       --load-cookies="$path_tmp"/cookies.zdl           \
			       --user-agent="$user_agent"                       \
			       --post-data="$post_data"                   |
				 grep -P '[^\#]+btn_downloadLink'         |
				 sed -r 's|.+href=\"([^"]+)\".+|\1|g')
	    url_in_file=$(sanitize_url "$url_in_file")
	fi
    fi

    try_end=25
    [ -n "$premium" ] &&
	print_c 2 "Rockfile potrebbe aver attivato il captcha: in tal caso, risolvi prima i passaggi richiesti dal sito web" ||
	    end_extension
fi
