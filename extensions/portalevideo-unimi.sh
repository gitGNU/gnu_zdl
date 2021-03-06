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
## zdl-extension types: streaming
## zdl-extension name: Portalevideo.unimi.it



if [ "$url_in" != "${url_in//'http://portalevideo.unimi.it'}" ]; then
    url_in_HD="${url_in//def=L/def=H}"
    wget "$url_in_HD" -O "$path_tmp"/zdl.tmp -q
    url_in_file=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "mp4")
    url_in_file="${url_in_file#*source src=\"}"
    url_in_file="${url_in_file%%\"*}"
    file_in=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "Titolo")
    file_in_1="${file_in#*'br>'}"
    file_in_1="${file_in_1%%'</p'*}"
    file_in_2="${file_in#*'Sottotitolo</strong><br>'}"
    file_in_2="${file_in_2%%'</p'*}"
    file_in="${file_in_1} - ${file_in_2}--${url_in_file##*\/}"
fi
