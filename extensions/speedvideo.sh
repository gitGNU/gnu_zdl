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
	html=$(wget -qO- "$url_in"                        \
		    --user-agent="$user_agent"            \
		    --keep-session-cookies                \
		    --save-cookies=$path_tmp/cookies.zdl)

	input_hidden "$html"
    fi

    html=$(wget -qO- "$url_in"                        \
		--user-agent="$user_agent"            \
		--load-cookies=$path_tmp/cookies.zdl  \
		--post-data="$post_data")

    unset post_data
    
    if [[ ! "$html" =~ 'File Not Found' ]]
    then
	linkfile=$(grep 'file: base64_decode' <<< "$html"   |
			  head -n1                          |
			  sed -r 's|.+\"([^"]+)\".+|\1|g')
	
	if [ -z "$linkfile" ]
	then
	    linkfile=$(grep 'var linkfile ="' <<< "$html" |
			      sed -r 's|.+\"([^"]+)\".+|\1|g')
	fi
	

	var2=$(grep base64_decode <<< "$html" |
		      sed -r 's|.+ ([^ ]+)\)\;$|\1|g')
	

	url_in_file=$(base64_decode "$linkfile"                      \
				    $(grep "$var2" <<< "$html"                |
					     head -n1                         |
					     sed -r 's|.+ ([^ ]+)\;$|\1|g') )

	## FFMpeg
	if [[ "$url_in_file" =~ .m3u8$ ]]
	then
	    # downloader_in="FFMpeg"
	    # noresume_links+=( speedvideo\. )

	    ##wget -qO- "$url_in_file" |sed -n 5p ##<-- quinta riga: risoluzione più bassa della terza
	    #url_in_file="${url_in_file%\/*}/$(wget -qO- "$url_in_file" |sed -n 3p)"

	    ## senza ffmpeg
	    url_m3u8="${url_in_file%\/*}/$(wget -qO- "$url_in_file" |sed -n 3p)"
	    unset url_in_file

	    links_loop - "$url_in"
	    url_in="$url_m3u8"
	    links_loop + "$url_in"
	    #ext=".ts"
	fi

	file_in="${file_in}$ext"
	unset url_in_files
    	# axel_parts=4
	
    	# if ! url "$url_in_file" ||
    	# 	[ "$file_in" == ".${url_in_file##*.}" ]
    	# then
    	#     _log 2
    	# fi
    else
    	_log 3
    fi

    url "${url_in_file}" ||
	url "$url_m3u8" ||
	_log 2
fi
