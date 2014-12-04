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


if [ "$url_in" != "${url_in//exashare.}" ]; then
    html=$(wget -q "$url_in" -O-)
    url_in_file=$(grep file: <<< "$html" | head -n1 | sed -r 's|.+file: \"(.+)\".+|\1|')
    ext=${url_in_file##*.}
    file_in=$(grep 'Title' <<< "$html" |sed -r 's|.+title.{1}(.+)[<].+|\1|').$ext
fi