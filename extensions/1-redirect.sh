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

urls_redir="italiafilms.tv/engine nowupload.net/nowdownload"

for url_redir in $urls_redir; do
    if [ "$url_in" != "${url_in//$url_redir}" ]; then
	export LANG="$prog_lang"
	export LANGUAGE="$prog_lang"
	new_url_in=`wget -O /dev/null -S "$url_in" 2>&1 |grep Location |sed -n 1p`
	export LANG="$user_lang"
	export LANGUAGE="$user_language"
	new_url_in="${new_url_in#*: }"
	new_url_in="${new_url_in%% *}"
	if [ "$new_url_in" == "${new_url_in//$url_redir}" ] && [ "$new_url_in" != "${new_url_in//'http://'}" ]; then
	    links_loop - "$url_in"
	    url_in="$new_url_in"
	    links_loop + "$url_in"
	else
	    _log 2
	    unset url_in
	fi
    fi
done

