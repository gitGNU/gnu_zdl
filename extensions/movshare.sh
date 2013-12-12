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
# Copyright (C) 2012
# Free Software Foundation, Inc.
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (project administrator and first inventor)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

## ZDL add-on

if [ "$url_in" != "${url_in//'movshare.'}" ]; then
    wget "$url_in" -O "$path_tmp"/zdl.tmp -q
    flashvars_file=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "flashvars.file=")
    flashvars_file="${flashvars_file#*'flashvars.file='\"}"
    flashvars_file="${flashvars_file%\"*}"

    flashvars_key=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "flashvars.filekey=")
    flashvars_key="${flashvars_key#*'flashvars.filekey='\"}"
    flashvars_key="${flashvars_key%\"*}"
    flashvars_domain=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "flashvars.domain=")
    flashvars_domain="${flashvars_domain#*'flashvars.domain='\"}"
    flashvars_domain="${flashvars_domain%\"*}"

    rm -f "$path_tmp"/zdl2.tmp
    axel "${flashvars_domain}/api/player.api.php?user=undefined&cid=1&file=${flashvars_file}&pass=undefined&key=${flashvars_key}" -o "$path_tmp"/zdl2.tmp &>/dev/null 
    url_in_file=$(cat "$path_tmp"/zdl2.tmp)
    url_in_file="${url_in_file#*'url='}"
    url_in_file="${url_in_file%%'&'*}"
    file_in="${url_in_file##*'/'}"
    ext="${url_in_file##*'.'}"
    file_in=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "share"|grep "title=")
    file_in="${file_in#*'title='}"
    file_in="${file_in%%\"*}.$ext"
fi
