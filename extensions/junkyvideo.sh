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

## zdl-extension types: download streaming
## zdl-extension name: Junkyvideo (HD)


if [ "$url_in" != "${url_in//'junkyvideo.com'}" ]
then
    html="$(wget -t 1 -T $max_waiting --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -q -O- $url_in)"

    if [[ "$html" =~ (File Not Found) ]]
    then
	_log 3
    
    elif [ -n "$html" ]
    then
	input_hidden "$html"
	print_c 0 "${BBlue}1/2) "
	countdown+ 6
        #### Per scaricare il file a bassa risoluzione (streaming video), seguire questa pista:
        ## wget -q --post-data="$post_data" "$url_in" -O- |grep file:

	data_html=$(wget -t 1 -T $max_waiting -q "http://junkyvideo.com/dl?op=get_vid_versions&file_code=${postdata_id}" -O- |grep download_video)

	if [ ! -z "$data_html" ]
	then
	    unset data
	    data=( $(sed -r "s|^.+\('(.+)','(.+)','(.+)'\).+$|\1 \2 \3|g" <<< "$data_html") )

	    print_c 0 "${BBlue}2/2) "
	    countdown+ 6
	    html="$(wget -t 1 -T $max_waiting -q                                                            \
		"http://junkyvideo.com/dl?op=download_orig&id=${data[0]}&mode=${data[1]}&hash=${data[2]}"   \
		-O-)"
	    url_in_file=$(grep "$file_in" <<< "$html" |sed -r 's|^[^"]+\"([^"]+).+|\1|g' )
	    file_in="$postdata_fname.${url_in_file##*.}"
	    unset post_data
	    axel_parts=4

	    if [ -z "$url_in_file" ]
	    then
		_log 3
	    fi
	else
	    _log 2
	fi
    else
	_log 2
    fi
fi

