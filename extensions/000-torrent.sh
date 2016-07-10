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

if ( [ -f "$url_in" ] && [[ "$url_in" =~ \.torrent$ ]] ) ||
       [[ "$url_in" =~ ^magnet\: ]]
then
    if [ -f "$url_in" ]
    then
    	bt_data=$(aria2c --show-files "$url_in")

	###### MAGNET URI:
	## url_in_file=$(urldecode "$(grep 'Magnet URI: ' <<< "$bt_data" |
	##			     sed -r 's|Magnet URI: (.+)$|\1|g')")
	url_in_file="$url_in"
	
	file_in=$(grep 'Name: ' <<< "$bt_data" |
			 sed -r 's|.*Name:\s(.+)$|\1|g')

	length_in=$(grep 'Total Length' <<< "$bt_data")
	length_in="${length_in#*\(}"
	length_in="${length_in%\)*}"
	length_in="${length_in//,}"
	
    else
	url_in_file="$url_in"
	file_in=$(sed -r 's|.+&dn=([^\&]+)&.+|\1|' <<< "$(urldecode "$url_in")")
	length_in=$(sed -r 's|.+&xl=([^\&]+)&.+|\1|' <<< "$(urldecode "$url_in")")
    fi
fi
