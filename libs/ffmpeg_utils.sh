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

function ffmpeg_stdout {
    ppid=$2
    cpid=$(children_pids $ppid)
    ##    trap_sigint $cpid $ppid
    echo "$cpid $ppid" >"$path_tmp"/ffmpeg-pids
    
    pattern='frame.+size.+'

    [[ "$format" =~ (mp3|flac) ]] &&
	pattern='size.+kbits/s'
    
    while check_pid $cpid
    do
	tail $1-*.log 2>/dev/null             |
	    grep -oP "$pattern"               |
	    sed -r "s|^(.+)$|\1                                         \n|g" |
	    tr '\n' '\r'
	sleep 1
    done
}

