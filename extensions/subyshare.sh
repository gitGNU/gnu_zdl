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
## zdl-extension name: Subyshare


if [ "$url_in" != "${url_in//'subyshare.'}" ]
then
    html=$(wget -t 1 -T $max_waiting                       \
		--keep-session-cookies                     \
		--save-cookies="$path_tmp"/cookies.zdl     \
		--user-agent="$user_agent"                 \
		-qO- "${url_in}")
    
    if [[ "$html" =~ (File Deleted|file was deleted|File [nN]{1}ot [fF]{1}ound) ]]
    then
	_log 3

    elif [ -n "$html" ]
    then
	input_hidden "$html"
	file_in="$postdata_fname"

	post_data="${post_data%%referer*}referer=&method_free=Free Download"

	html=$(wget -qO-                                        \
		    --load-cookies="$path_tmp"/cookies.zdl      \
		    --user-agent="$user_agent"                  \
		    --post-data="$post_data"                    \
		    "${url_in}")

	code=$(pseudo_captcha "$html")

	if [[ "$code" =~ ^[0-9]+$ ]]
	then
	    print_c 1 "Pseudo-captcha: $code"
	else
	    print_c 3 "Pseudo-captcha: codice non trovato"
	fi
	
	unset post_data
	input_hidden "$html"
	post_data="${post_data##*'(&'}&code=$code"
	post_data="${post_data//'&down_script=1'}"

	errMsg=$(grep 'Devi attendere' <<< "$html" |
			sed -r 's|[^>]+>([^<]+)<.+|\1|g')
	
	if [[ "$html" =~ (You can download files up to) ]]
	then
	    _log 4

	elif [ -n "$code" ]
	then
	    timer=$(grep timein <<< "$html"          |
			   sed -r 's|.+>([0-9]+)<.+|\1|g')

	    countdown- $timer
	    sleeping 2
	    
	    redirect "$url_in"
	fi
    fi

    try_end=25
    [ -n "$premium" ] &&
	print_c 2 "Subyshare potrebbe aver attivato il captcha: in tal caso, risolvi prima i passaggi richiesti dal sito web" ||
	    end_extension
fi
