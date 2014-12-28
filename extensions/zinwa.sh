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
## zdl-extension types: streaming
## zdl-extension name: Zinwa (RTMP)

function decodejs_zinwa {
    instr="${1//\'}"
    icount="$2"
    arr=( ${instr//','/ } )
    for ((i=1; i<=$icount; i++)); do
	chars[ $(( $icount-$i+1 )) ]="${arr[$(( ${#arr[*]}-1 ))]}"
	unset arr[$(( ${#arr[*]}-1 ))]
    done
    arr=( ${chars[*]} ${arr[*]} )
    restr=''
    for ((i=0; i<${#arr[*]}; i++)); do
	restr="${restr}$(code2char ${arr[$i]})"
    done
    echo "$restr"
}

if [ "$url_in" != "${url_in//'zinwa.'}" ]; then
    print_c 2 "Attendi...\n"
    html=$(wget -q "$url_in" -O-)
    args=$(grep eval <<< "$html" |sed -r 's|.+\(([^()]+)\).+|\1|g')
    code=$(decodejs_zinwa "${args%,*}" "${args##*,}")
    playpath=$(sed -r "s|.+file: \"([^\"]+)\".+|\1|g" <<< "$code")
    streamer=$(sed -r 's|.+streamer: \"([^"]+)\".+|\1|' <<< "$code")
    file_in=$(grep '<title>' <<< "$html" |sed -r 's|.+>([^<>]+)<.+|\1|g').$(sed -r 's|.+\.([^.]+)\?.*$|\1|g' <<< "$playpath")
fi

