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

if [[ "$url_in" =~ ^xdcc://[^/]+/([^/]+)/([^/]+)/([^/]+)/([^/]+) ]]
then
    irc_chan="${BASH_REMATCH[2]##\#}"
    irc_chan="${irc_chan##\%23}"
    replace_url_in "$(sanitize_url "irc://${BASH_REMATCH[1]}/$irc_chan/msg ${BASH_REMATCH[3]} xdcc send ${BASH_REMATCH[4]}")"
fi
									   
if [[ "$url_in" =~ ^irc:\/\/ ]]
then
    file_in="temporaneo-$(date +%s)"
    url_in_file="$url_in"
    downloader_in=DCC_Xfer
fi

