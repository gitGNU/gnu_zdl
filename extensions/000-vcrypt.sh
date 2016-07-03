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
## zdl-extension name: vcrypt.pw

if [ "$url_in" != "${url_in//vcrypt.pw}" ]
then
    url_in_new='http://'$(wget -S --spider "$url_in"    2>&1 |
			      grep -P '[lL]{1}ocation:' | head -n1       |
			      sed -r 's|.+\/http:\/\/(.+)|\1|g')
    if url "$url_in_new"
    then
	url_in_new=$(wget -S --spider "$url_in_new"    2>&1 |
			 grep -P '[lL]{1}ocation:' | head -n1 |
			 sed -r 's|.*[lL]{1}ocation:\s*(.+)|\1|g')
    fi
	
    replace_url_in "$url_in_new" ||
	_log 2
fi

