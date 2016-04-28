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
## zdl-extension name: Vimeo (HD)

if [[ "$url_in" =~ vimeo\.com\/([0-9]+) ]]
then
    html=$(wget https://player.vimeo.com/video/${BASH_REMATCH[1]} -qO-)

    url_in_file=$(grep -P 'token=' <<< "$(echo -e "${html//http/\\nhttp}")")
    url_in_file="${url_in_file%%\"*}"

    ## M3U8: alternativa valida ma incompleta
    #
    # m3u8_url=$(echo -e "${html//http/\\nhttp}"  |
    # 		      grep m3u8                   |
    # 		      tail -n1                    |
    # 		      sed -r 's|([^"]+)\".+|\1|g')
    #
    # m3u8_url=${m3u8_url%%video*}$(wget -qO- "$m3u8_url" | tail -n1 | sed -r "s|\.\.\/\.\.\/(.+)|\1|g")
    #
    # replace_url_in "$m3u8_url"
    
    ext="${url_in_file%'?'*}"
    ext="${ext##*'.'}"
    file_in=$(grep "title>" <<< "$html")
    file_in="${file_in#*'title>'}"
    file_in="${file_in%%'</title'*}"
    file_in="${file_in//\//-}.$ext"
    file_in=$(htmldecode "$file_in")
fi
