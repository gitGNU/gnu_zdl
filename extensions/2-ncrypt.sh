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


if [ "$url_in" != "${url_in//'ncrypt.in/folder'}" ]; then
    links_loop - "$url_in"
    html=$(wget -q -O- "$url_in"|grep ".dlc")
    container_url="${html#*\"}"
    container_url="http://ncrypt.in${container_url%%\"*}"
    
    print_c 1 "Analisi container DLC ..."
    add_container $(wget -q -O- "$container_url")
    break_loop=true
    unset url_in
fi
