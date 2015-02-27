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
## zdl-extension name: Tusfiles

if [ "$url_in" != "${url_in//'tusfiles.net'}" ]; then
    wget -q -t 1 -T $max_waiting --no-check-certificate --retry-connrefused --keep-session-cookies --save-cookies="$cookies" -O "$path_tmp/zdl.tmp" "$url_in" &>/dev/null

    unset post_data
    input_hidden "$path_tmp/zdl.tmp"
    post_data="${post_data#*&}"

    file_in=`cat "$path_tmp/zdl.tmp" |grep '?q='`
    file_in="${file_in#*'?q='}"
    file_in="${file_in%%\"*}"

    if [ ! -f "$path_tmp"/cookies.zdl ]; then touch "$path_tmp"/cookies.zdl ; fi
    url_in_file="${url_in}"
    redirected="true"
fi
