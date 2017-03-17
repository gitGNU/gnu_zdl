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
## zdl-extension types: xdcc
## zdl-extension name: Anydownload

if [[ "$url_in" =~ anydownload.+'adflyshrink.php?url='(.+)? ]]
then
    replace_url_in "$(urldecode "${BASH_REMATCH[1]}")"
fi

if [[ "$url_in" =~ anydownload.+(IRCdownload|xweaseldownload)\.php ]]
then
    url_in_anydownload=$(anydownload "$url_in")
    
    if url "$url_in_anydownload"
    then
	replace_url_in "$(sanitize_url "$url_in_anydownload")"

    else
	_log 2
    fi

    unset url_in_anydownload
fi
									   

