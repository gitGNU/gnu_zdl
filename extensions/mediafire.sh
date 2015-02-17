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
## zdl-extension name: Mediafire


if [ "$url_in" != "${url_in//mediafire.}" ]; then
    check_ip mediafire
    get_tmps
    url_in_file=`cat "$path_tmp"/zdl.tmp |grep 'kNO = '`
    url_in_file=${url_in_file#*'kNO = "'}
#    url_in_file=${url_in_file//\" onclick=\"avh*/}
    url_in_file=${url_in_file%%\"*}
    [ -z "$url_in_file" ] && break_loop=true && newip[${#newip[*]}]=mediafire
    file_in=${url_in_file##*'/'}
    axel_parts=4
fi
