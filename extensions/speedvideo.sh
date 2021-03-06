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

## zdl-extension types: streaming
## zdl-extension name: Speedvideo (HD)


if [[ "$url_in" =~ (speedvideo.) ]]
then
    ## url_embed=$(grep -oP 'http://[^"]+embed-[^"]+' <<< "$html")
    
    if [[ ! "$url_in" =~ embed ]]
    then
	htm=$(wget -qO- "$url_in"                        \
		    --user-agent="$user_agent"            \
		    --keep-session-cookies                \
		    --save-cookies="$path_tmp"/cookies.zdl)

	input_hidden "$htm"
    fi

    html=$(wget -qO- "$url_in"                          \
		--user-agent="$user_agent"              \
		--load-cookies="$path_tmp"/cookies.zdl  \
		--post-data="$post_data")

    unset post_data
    
    if [[ "${htm}${html}" =~ 'File Not Found' ]] 
    then
	_log 3

    else
	linkfile=$(grep 'file: base64_decode' <<< "$html"   |
			  head -n1                          |
			  sed -r 's|.+\"([^"]+)\".+|\1|g')

	if [ -z "$linkfile" ]
	then
	    linkfile=$(grep 'var linkfile ="' <<< "$html" |
			      sed -r 's|.+\"([^"]+)\".+|\1|g')
	fi

	var2=$(grep base64_decode <<< "$html" |
		      sed -r 's|.+ ([^ ]+)\)\;$|\1|g' | head -n1)
	

	url_in_file=$(base64_decode "$linkfile"     \
				    $(grep "$var2" <<< "$html"                |
				    	     head -n1                         |
				    	     sed -r 's|.+ ([^ ]+)\;$|\1|g') )

	url_in_file="http://${url_in_file#*'///'}"
	url_in_file="${url_in_file%'/'*}"
	
	end_extension
    fi
fi
