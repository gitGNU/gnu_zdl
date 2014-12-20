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


is_rtmp "$url_in"
if [ "$?" == 1 ]; then
    if [ ! -z "$(command -v curl 2>/dev/null)" ]; then
	if [ "$downloader_in" != "cURL" ]; then
	    dler=$downloader_in
	    downloader_in=cURL
	    ch_dler=1
	    print_c 3 "Il server non permette l'uso di $dler: il download verrà effettuato con $downloader_in"
	fi
	url_in_file="http://DOMIN.IO/PATH"
    else
	print_c 3 "$url_in --> il download richiede l'uso di cURL, che non è installato" | tee -a $file_log
	links_loop - "$url_in"
	break_loop=true
    fi
fi
