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

## ZDL add-on
## zdl-extension types: streaming download
## zdl-extension name: WStream (HD)


if [ "$url_in" != "${url_in//wstream.}" ] &&
       [[ ! "$url_in" =~ "black" ]]
then
    html=$(wget -t1 -T$max_waiting                               \
		"$url_in"                                        \
		--user-agent="Firefox"                           \
		--keep-session-cookies                           \
		--save-cookies="$path_tmp/cookies.zdl"           \
		-qO-)
    
    if [[ "$html" =~ (File Not Found) ]]
    then
	_log 3

    else
	download_video=$(grep -P 'download_video.+Original' <<< "$html")

	hash_wstream="${download_video%\'*}"
	hash_wstream="${hash_wstream##*\'}"

	id_wstream="${download_video#*\'}"
	id_wstream="${id_wstream%%\'*}"

	## original
	html2=$(wget -qO- "https://wstream.video/dl?op=download_orig&id=${id_wstream}&mode=o&hash=${hash_wstream}")
	url_in_file=$(grep 'Direct Download Link' <<< "$html2" |
			     sed -r 's|.+\"([^"]+)\".+|\1|g')	     

	if url "$url_in_file"
	then
	    file_in="${url_in_file##*\/}"

	else
	    ## normal
	    url_in_file=$(wget -qO- \
	    		       "https://wstream.video/dl?op=download_orig&id=${id_wstream}&mode=n&hash=${hash_wstream}" |
	    			 grep 'Direct Download Link'                                                            |
	    			 sed -r 's|.+\"([^"]+)\".+|\1|g')

	    file_in=$(get_title "$html" |sed -r 's|Watch\s||')
	    file_in="${file_in%.mp4}.mp4"
	fi
	
	end_extension
    fi
fi
