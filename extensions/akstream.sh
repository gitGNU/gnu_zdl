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
## zdl-extension name: Akstream

if [[ "$url_in" =~ akstream[^/]+\/(play|v)\/ ]]; then
    url=$(sed -r "s|${BASH_REMATCH[1]}\/|embed.php?v=|g" <<< "$url_in")
    html=$(wget -q -O- "$url")
    url_in_file=$(grep source <<< "$html" | tail -n1 |sed -r 's|[^"]+\"([^"]+)\".+|\1|g')
    file_in=$(grep '<title>' <<< "$html" | sed -r 's|[^>]+>([^<]+)<.+|\1|g').${url_in_file##*.}
fi
