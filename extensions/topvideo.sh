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

# function packed {
#     p=$1
#     a=$2
#     c=$3

#     IFS="|"
#     k=( $4 )
#     unset IFS

#     e=$5 #non esiste
#     d=$6 #non esiste

#     while [ $c != 0 ]; do
# 	 (( c-- ))
# 	 base36 "$c"
# 	 if [ ! -z "${k[$c]}" ] && [ "${k[$c]}" != 0 ]; then
# 	     p=$(echo "$p" |sed s/\\b$int\\b/${k[$c]}/g)
# 	     unset int
# 	 fi
#     done
#     echo "$p"
# }

# function packed_args {
#     code="${1#*\}\(\'}"
#     code="${code%%\'.split*}"
#     code_p="${code//\}\'*}}"
#     code_a1="${code#*\}\',}"
#     code_a="${code_a1%%,*}"
#     code_c="${code_a1#$code_a,}"
#     code_c="${code_c%%,*}"
#     code_k="${code_a1#*$code_c,\'}"
# }


if [ "$url_in" != "${url_in//'topvideo.'}" ]; then
    wget -q -t 1 -T $max_waiting --retry-connrefused --keep-session-cookies --save-cookies="$cookies" -O "$path_tmp/zdl.tmp" "$url_in" &>/dev/null
    echo -e "...\c"
    unset post_data
    tmp="$path_tmp/zdl.tmp"
    input_hidden
    post_data="${post_data#*&}"
    url=$(cat "$path_tmp/zdl.tmp" |grep Form| grep action)
    url="${url%\'*}"
    url="${url##*\'}"
    wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl --post-data="${post_data}" "$url" -O "$path_tmp/zdl2.tmp" &>/dev/null
    echo -e "...\c"

    packed_args "$(cat $path_tmp/zdl2.tmp|grep eval)"
    packed_code=$( packed "$code_p" "$code_a" "$code_c" "$code_k" )
    
    url_in_file="${packed_code%%.mp4*}.mp4"
    url_in_file="${url_in_file##*\"}"
    
    file_in=$(cat "$path_tmp/zdl.tmp" |grep 'Title>')
    file_in="${file_in#*'<Title>'}"
    file_in="${file_in%%'</Title>'*}.mp4"
    file_in="${file_in// /_}"
    if [ ! -f "$path_tmp"/cookies.zdl ]; then touch "$path_tmp"/cookies.zdl ; fi
fi
