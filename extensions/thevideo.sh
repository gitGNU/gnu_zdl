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

if [ "$url_in" != "${url_in//'thevideo.'}" ]; then
    html=$(wget "$url_in" -O- -q)
    unset post_data
    input_hidden "$html"

    url=$(sed -r 's|(.+)\/([^/]+)|\1/download/\2|g' <<< "$url_in")
    html=$(wget -q -O - "$url")

    url=$(sed -r 's|(.+)\/([^/]+)|\1|g' <<< "$url_in")$(grep url: <<< "$html" | sed -r 's|.+\"([^"]+)\".+|\1|g')
    html=$(wget --keep-session-cookies --save-cookies="$path_tmp/cookies.zdl" -q -O - "$url" |grep onclick |head -n1)

    urlcode=$(sed -r "s|^.+'([^']+)','([^']+)','([^']+)'.+$|\1|g" <<< "$html")
    urlmode=$(sed -r "s|^.+'([^']+)','([^']+)','([^']+)'.+$|\2|g" <<< "$html")
    urlhash=$(sed -r "s|^.+'([^']+)','([^']+)','([^']+)'.+$|\3|g" <<< "$html")
    url=$(sed -r 's|(.+)\/([^/]+)|\1/download|g' <<< "$url_in")/$urlcode/$urlmode/$urlhash
    unset url_in_file
    while [ -z "$url_in_file" ]; do
	url_in_file=$(wget "$url" -O- -q |grep "Direct Download Link" | sed -r 's|.+\"([^"]+)\".+|\1|g')
	sleep 1
	check_pid $pid_prog
	[ $? != 1 ] && exit
    done

    file_in=$file_in.${url_in_file##*.}

## per file in streaming (se si riesce a scaricare la pagina con il player [con funzione eval]):
#    packed_args "$(cat $path_tmp/zdl2.tmp|grep eval)"
#    packed_code=$( packed "$code_p" "$code_a" "$code_c" "$code_k" )

    axel_parts=6
fi
