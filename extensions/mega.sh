#!/bin/bash
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
# adapted from: https://gist.github.com/KenMacD/6431823
#

## zdl-extension types: download
## zdl-extension name: Mega

if [[ "$url_in" =~ (^https\:\/\/mega\.co\.nz\/|^https\:\/\/mega\.nz\/) ]]
then
    links_loop - "$url_in"
    url_in="${url_in//mega.co.nz/mega.nz}"
    links_loop + "$url_in"
    
    id=$(awk -F '!' '{print $2}' <<< "$url_in")

    key=$(awk -F '!' '{print $3}' <<< "$url_in" | sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g')
    b64_hex_key=$(echo -n $key | base64 --decode --ignore-garbage 2> /dev/null | xxd -p | tr -d '\n')
    key[0]=$(( 0x${b64_hex_key:00:16} ^ 0x${b64_hex_key:32:16} ))
    key[1]=$(( 0x${b64_hex_key:16:16} ^ 0x${b64_hex_key:48:16} ))
    key=$(printf "%016x" ${key[*]})

    iv="${b64_hex_key:32:16}0000000000000000"

    json_data=$(wget -qO- --post-data='[{"a":"g","g":1,"p":"'$id'"}]' https://eu.api.mega.co.nz/cs)

    url_in_file="${json_data%\"*}"
    url_in_file="${url_in_file##*\"}"
    
    ##    file_in="$key".MEGAenc
    awk -F '"' '{print $6}' <<< "$json_data"             |
	sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g'       |
	base64 --decode --ignore-garbage 2> /dev/null    |
	xxd -p                                           |
	tr -d '\n' > "$path_tmp"/enc_attr.mdtmp
    
    xxd -p -r "$path_tmp"/enc_attr.mdtmp > "$path_tmp"/enc_attr2.mdtmp
    openssl enc -d -aes-128-cbc -K $key -iv 0 -nopad -in "$path_tmp"/enc_attr2.mdtmp -out "$path_tmp"/dec_attr.mdtmp
    file_in=$(awk -F '"' '{print $4}' "$path_tmp"/dec_attr.mdtmp).MEGAenc

    if [ -z "$url_in_file" ] ||
	   [ -z "$file_in" ]
    then
	_log 2
	
    elif ! url "$url_in_file"
    then
	_log 3
	
    else
	#### for POST-PROCESSING:
	## openssl enc -d -aes-128-ctr -K $key -iv $iv -in $enc_file -out $out_file
	echo -e "$key\n$iv" > "$path_tmp"/"$file_in".tmp

	axel_parts=1
    fi
fi
