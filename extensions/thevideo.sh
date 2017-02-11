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

## zdl-extension types: streaming download
## zdl-extension name: Thevideo

if [ "$url_in" != "${url_in//'//thevideo.'}" ]
then
    id_thevideo="${url_in##*\/}"
    url_qualities="https://thevideo.me/download/getqualities/${id_thevideo}"

    code_mode_hash=( $(wget -t 1 -T $max_waiting "$url_qualities" -qO- |
			    grep download_video | tail -n1 |
			    sed -r "s|.+\('(.+)','(.+)','(.+)'\).+|\1 \2 \3|g") )

    html_2_file=$(curl -s "https://thevideo.me/download/${code_mode_hash[0]}/${code_mode_hash[1]}/${code_mode_hash[2]}")

    vt_url=$(grep dljsv <<< "$html_2_file" | sed -r 's|.+\"([^"]+)\".+|\1|g')
    vt_code=$(curl -s "$vt_url")
    vt_code="${vt_code#*each\|}"
    vt_code="${vt_code%%\|*}"
    
    url_in_file=$(grep downloadlink <<< "$html_2_file")
    url_in_file="${url_in_file#*\"}"
    url_in_file="${url_in_file%%\"*}?download=true&vt=${vt_code}"

    file_in="${url_in_file##*\/}"
    file_in="${file_in%\?*}"
    file_in="${file_in%%.mp4}"

    end_extension
fi
