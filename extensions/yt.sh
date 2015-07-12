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
## zdl-extension name: Youtube

shopt -u nullglob

if [ "$url_in" != "${url_in//'youtube.com/watch'}" ]
then
    links_loop - "$url_in"
    url_in=$(urldecode "$url_in")
    links_loop + "$url_in"
    #videoType="mp4"

    html=$(wget -Ncq -e convert-links=off                    \
    		--keep-session-cookies                       \
    		--save-cookies="$path_tmp"/cookies.zdl       \
    		--no-check-certificate                       \
    		--user-agent="$user_agent"                   \
    		"$url_in" -O- )
    
    if [ -z "$html" ]
    then
    	_log 8 

    elif [[ "$html" =~ \<title\>(.+)\<\/title\> ]]
    then
    	title=$(sed -r 's/([^0-9a-z])+/_/ig' <<< "${BASH_REMATCH[1]}" |
    		       sed -r 's/_youtube//ig'                        |
    		       sed -r 's/^_//ig'                              |
    		       tr '[A-Z]' '[a-z]'                             |
    		       sed -r 's/_amp//ig')


	url_in_file=$(wget -qO- "http://zoninoz.hol.es/api.php?uri=$url_in" |tail -n1)

	if [ -n "$(axel -o /dev/null "$url_in_file" | grep '403 Forbidden')" ]
	then
	    dler=$downloader_in
	    downloader_in=Wget
	    ch_dler=1
	    print_c 3 "Il server non permette l'uso di $dler: il download verrà effettuato con $downloader_in"
	fi
	
	videoType=$(wget --spider -S "$url_in_file" 2>&1| grep 'Content-Type:')
	videoType="${videoType##*\/}"

	[ -n "$videoType" ] && file_in="$title.$videoType" && echo "$title.$videoType" 

	
	# 	html=$(grep 'url_encoded_fmt_stream_map' <<< "$html")
	# 	if [ -n "$html" ]
	# 	then 
	# 	    html="${html#*url_encoded_fmt_stream_map}"

	#         ## quality: large -> medium -> small (qualità più alta disponibile è nella prima riga)
	# 	    url_in_file=$(urldecode "$html" | sed -r 's|codecs|\ncodecs|g')
	# 	    url_in_file=$(grep "$videoType" <<< "$url_in_file" |grep 'url=')

	# 	    if [[ "$url_in_file" =~ quality\=hd ]]
	# 	    then
	# 		url_in_file="$(grep 'quality=hd' <<< "$url_in_file" | head -n1)"
	
	# 	    elif [[ "$url_in_file" =~ quality\=medium ]]
	# 	    then
	# 		url_in_file="$(grep 'quality=medium' <<< "$url_in_file" | head -n1)"

	# 	    elif [[ "$url_in_file" =~ quality\=small ]]
	# 	    then
	# 		url_in_file="$(grep 'quality=small' <<< "$url_in_file" | head -n1)"
	# 	    else
	# 		url_in_file="$(grep 'quality' <<< "$url_in_file" | head -n1)"
	# 	    fi

	# 	    url_in_file=$(sed -r 's|.+url=([^,;\\]+)[,;\\]+.+|\1|g' <<< "$url_in_file")
	# 	    url_in_file=$(urldecode "$url_in_file")


	
	# 	    if [ -z "$url_in_file" ]
	# 	    then
	# 		_log 2
	# 	    # else
	# 		## DEBUG:
	# 	    # 	wget -S --spider "$url_in_file" -a zdl.log
	# 	    fi
	# 	else
	# 	    _log 2
	# 	fi

	
    else
    	_log 9
    	not_available=true
    fi
    axel_parts=4
fi

shopt -s nullglob
