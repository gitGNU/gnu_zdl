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

## zdl-extension types: download, streaming
## zdl-extension name: Neodrive (ex Cloudzilla)


if [[ "$url_in" =~ (cloudzilla.to|neodrive.co)/share/file ]]
then
    file_in=$(wget -t1 -T$max_waiting              \
		   -qO- "$url_in"                 |
		     grep download_hdr -A1        |
		     tail -n1                     |
		     sed -r "s|^.+title=\"([^\"]+)\".+$|\1|")

    if [ -n "$file_in" ]
    then

	##############
	## cloudzilla
	##############
	##
	# url_embed=${url_in%%\/}
	# link_parser "$url_embed"
	# file_id="${url_embed##*\/}"

	# tags=$(sed -r "s|<[/]{,1}result>||g" <<< $(wget -qO- "${parser_proto}www.${parser_domain#www.}/generateticket/" --post-data="file_id=$file_id"))

	# echo -e "tags=$tags"
	
	# if [[ ! "$tags" =~ Invalid  ]]
	# then
	#     tags2vars "$tags"
	#     if [[ $status == ok ]]
	#     then
	# 	countdown+ $wait
	# 	url_in_file="http://$server/download/$file_id/$ticket_id"
	# 	countdown+ $wait
	#     fi
	# else
	#     _log 3
	#     break_loop=true
	# fi

	url_in_file=$(wget -qO- "${url_in//'share/file/'/embed/}" |
			     grep 'var vurl'                      |
			     sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

	[ -z "$url_in_file" ] &&
	    _log 3
    else
	_log 2
    fi
fi
