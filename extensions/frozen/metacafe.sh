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

## zdl-extension types: streaming
## zdl-extension name: Metacafe

if [ "$url_in" != "${url_in//metacafe.com\/watch}" ]; then
    wget "$url_in" -q -O "$path_tmp/zdl.tmp"
    if [ -z $(grep isFamilyFilterOn\:true < "$path_tmp"/zdl.tmp) ]; then
	cat $path_tmp/zdl.tmp | grep flashVars |grep mediaURL> $path_tmp/zdl2.tmp
	urldecode "$(cat $path_tmp/zdl2.tmp )" > $path_tmp/zdl3.tmp
	urldecode "$(cat $path_tmp/zdl3.tmp )" > $path_tmp/zdl2.tmp
	code="$(cat $path_tmp/zdl2.tmp )"
	code="${code##*mediaURL\":\"}"
	code="${code%%\"*}"
	code="${code//'\'}"
	code="${code//'[From www.metacafe.com] '}"
	url_in_file="$code"
	ext="${url_in_file##*'.'}"
	file_in=$(cat $path_tmp/zdl.tmp | grep "title>")
	file_in="${file_in#*'<title>'}"
	file_in="${file_in%'</title>'*}.$ext"
    else
	not_available=true
	print_c 3 "Filmato non ancora estraibile da $url_in: filtro \"famiglia\" di Metacafe" | tee -a $file_log

	### sistema per disattivare il filtro-famiglia via cookie (funziona), ma poi c'è il problema dell'estrazione di url_in_file, che è diversa e "misteriosa"
	#
	# rm -f "$path_tmp/cookies.zdl"
	# wget --keep-session-cookies --save-cookies="$path_tmp/cookies.zdl" "http://www.metacafe.com/f/index.php?inputType=filter&controllerGroup=user" --post-data="filters=0" -q -O out.html

	# wget --load-cookies="$path_tmp/cookies.zdl" "$url_in" -q -O "$path_tmp/zdl.tmp"
    fi
fi