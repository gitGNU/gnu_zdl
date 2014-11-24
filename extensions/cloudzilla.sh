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

if [ "$url_in" != "${url_in//'cloudzilla.to/share/file'}" ]; then
    file_in=$(sed -r "s|^.+title=\"([^\"]+)\".+$|\1|" <<< $(wget -O- "$url_in" -q |grep download_hdr))
    link_parser "$url_in"
    file_id=${parser_path##*\/}
    tags2vars $(sed -r "s|<[/]{,1}result>||g" <<< $(wget -q -O - "${parser_proto}$parser_domain/generateticket/" --post-data="file_id=$file_id"))
    if [[ $status == ok ]]; then
	countdown+ $wait
	url_in_file="http://$server/download/$file_id/$ticket_id"
	countdown+ $wait
    fi
fi
