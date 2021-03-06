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

## zdl-extension types: shortlinks
## zdl-extension name: Adf.ly, Adfoc.us, linkbucks.com, Bit.ly, Goo.gl, Bc.vc, Ref.so


if [[ "$url_in" =~ (bc.vc|adf.ly|adfoc.us|linkbucks.com|bit.ly|goo.gl|ref.so) ]]
then
    if command -v curl &>/dev/null
    then
	new_url=$(curl -d "url=$url_in" "http://www.bypassshorturl.com/get.php")
    fi

    if [ -z "$new_url" ]
    then
	new_url=$(wget -qO- --post-data="url=$url_in" "http://www.bypassshorturl.com/get.php")
    fi

    new_url="$(sanitize_url "$new_url")"
    
    if url "$new_url"
    then
	replace_url_in "$url_in"

    else
	break_loop=true
    fi
fi
