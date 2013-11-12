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

if [ "$url_in" != "${url_in//dailymotion.com\/video}" ]; then
    get_tmps
    cat $path_tmp/zdl.tmp | grep mp4 > $path_tmp/zdl2.tmp
    urldecode "$(cat $path_tmp/zdl2.tmp )" > $path_tmp/zdl3.tmp
    urldecode "$(cat $path_tmp/zdl3.tmp )" > $path_tmp/zdl2.tmp
    code="$(cat $path_tmp/zdl2.tmp )"
    code="${code##*video_url\":\"}"
    url_in_file="${code%%\"*}"
    file_in=$(cat $path_tmp/zdl.tmp | grep "title>")
    file_in="${file_in#*'<title>'}"
    file_in="${file_in%'</title>'*}.mp4"
fi
