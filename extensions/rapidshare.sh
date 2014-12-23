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

## zdl-extension types: download
## zdl-extension name: Rapidshare

if [ "$url_in" != "${url_in//'rapidshare.'}" ]; then
    if [ "$url_in" != "${url_in//'rapidshare.com/files'}" ]; then
	reurl=`wget -t 1 -T $max_waiting "$url_in" -O - -q`
	reurl="${reurl#*location=\"}"
	reurl="${reurl%\"*}"
    elif [ "$url_in" != "${url_in//'rapidshare.com/#!download|'}" ]; then
	reurl="$url_in"
    fi
    
    if [ "$reurl" != "${reurl//public traffic exhausted}" ]; then
	unset url_in_file
    elif [ "$reurl" == "${reurl//File not found}" ] && [ "$reurl" == "${reurl//Download permission denied by uploader}" ]; then

	devrapid="${reurl#*download|}"
	devrapid="${devrapid%%|*}"
	
	fileid="${reurl#*${devrapid}|}"
	fileid="${fileid%%|*}"
	
	file_in="${reurl#*${fileid}|}"
	file_in="${file_in%%|*}"
	
	url_in_file="http://rs${devrapid}.rapidshare.com/cgi-bin/rsapi.cgi?sub=download&fileid=${fileid}&filename=${file_in}&dlauth=0123456789"
	if [ -z "$file_in" ]; then
	    file_in="${url_in#*filename=}"
	    file_in="${file_in%%&*}"
	    url_in_file="$url_in"
	fi
    else
	_log 3
	break
    fi
fi
