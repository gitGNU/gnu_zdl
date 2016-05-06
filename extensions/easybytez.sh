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


if [ "$url_in" != "${url_in//easybytez}" ]
then
    proxy_types=( "Transparent" "Anonymous" "Elite" )
    user_agent=Firefox
    
    if [ "$login" == "1" ]
    then
	html=$(wget -qO- -t1 -T$max_waiting                   \
		    --user-agent="$user_agent"                \
		    --retry-connrefused                       \
		    --keep-session-cookies                    \
		    --save-cookies="$path_tmp"/cookies.zdl    \
		    "http://www.easybytez.com/login.html")

	## post_data
	input_hidden "$html"

	## user, pass
	host_login "easybytez"

	wget -q -t1 -T$max_waiting                                        \
     	     --user-agent="$user_agent"                                   \
	     --retry-connrefused                                          \
	     --load-cookies="$path_tmp"/cookies.zdl                       \
	     --keep-session-cookies                                       \
	     --save-cookies="$path_tmp"/cookies.zdl                       \
	     -O /dev/null                                                 \
	     --post-data="${post_data}&login=${user}&password=${pass}"    \
	     "http://www.easybytez.com"
	unset post_data user pass
    fi

    html=$(wget -qO- -t1 -T$max_waiting                    \
		--user-agent="$user_agent"                 \
		--retry-connrefused                        \
		--load-cookies="$path_tmp"/cookies.zdl     \
		--keep-session-cookies                     \
		--save-cookies="$path_tmp"/cookies.zdl     \
		"$url_in") 

    file_in=$(grep '<span class="name">' <<< "$html")
    file_in="${file_in#*>}"
    file_in="${file_in%%<*}"
    url_in_file="${url_in}"

    exceeded_msg="You have reached the download-limit"

    if [[ "$html" =~ (File not available) ]]
    then
	_log 3

    elif check_in_file &&
	    [ -n "${file_in}" ] &&
	    [ ! -f "${file_in}" ] 
    then
	[ "$login" != 1 ] &&
	    check_ip "easybytez"

	input_hidden "$html" # "$path_tmp/zdl.tmp"
	post_data="${post_data}&method_free=Free Download"       
	
	html=$(wget -t 1 -T $max_waiting                             \
		    --user-agent="$user_agent"                       \
		    --load-cookies="$path_tmp"/cookies.zdl           \
		    --keep-session-cookies                           \
		    --save-cookies="$path_tmp"/cookies.zdl           \
		    --post-data="${post_data}"                       \
		    "$url_in" -qO-) 

	countdown=$(grep Wait <<< "$html" |
			   sed -r 's|.+\">(.+)<\/span>.+<\/span.+|\1|')

	exceeded=$(grep "Upgrade your account to download bigger files" <<< "$html")

	if check_in_file                 &&
	       [ -z "$not_available" ]   &&
	       [ -z "$exceeded" ] &&
	       [[ "$countdown" =~ ^([0-9]+)$ ]] &&
	       [[ ! "$html" =~ ($exceeded_msg) ]]
	then
	    input_hidden "$html"
	    post_data="${post_data%op=payments*}btn_download=Download File"
	    
	    html=$(wget -t 1 -T $max_waiting                                    \
			--user-agent="$user_agent" -q                           \
			--load-cookies="$path_tmp"/cookies.zdl                  \
			--keep-session-cookies                                  \
			--save-cookies="$path_tmp"/cookies.zdl                  \
			--post-data="${post_data}"                              \
			"$url_in" -qO-)
	    print_c 2 "\nAttendi:"
	    countdown- "$countdown"
	    redirect "$url_in"

	else
	    _log 25
	fi
    fi
fi
