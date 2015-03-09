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
## zdl-extension name: Videopremium

if [[ "$url_in" =~ (videopremium.) ]]; then
    print_c 1 "Estrazione dati: attendi..."
    file_in=$(wget -O- -q "$url_in" | grep title| sed -r 's|.+>([^<]+)<.+|\1|g')
    html=$(wget "http://zoninoz.hol.es/api.php?uri=$url_in" -O- -q)
    echo "$html" |grep rtmpdump\ \-V > $path_tmp/extract_rtmp
    chmod +x $path_tmp/extract_rtmp
    streamer=$(./$path_tmp/extract_rtmp |grep -P redirect.+STRING |sed -r 's|.+rtmp(.+)>$|rtmp\1|g')
    echo "$html" |grep rtmpdump\ \-q | sed -r "s,rtmpdump\ \-q\ \-r \"\"(.+)\|.+$,rtmpdump\ \-r\ \"$streamer\"\ \1,g"> $path_tmp/extract_rtmp

    swfUrl=$(sed -r 's|.+\-W\ \"([^"]+)\".+|\1|g' $path_tmp/extract_rtmp)
    pageUrl=$(sed -r 's|.+\-p\ \"([^"]+)\".+|\1|g' $path_tmp/extract_rtmp)
    playpath=$(sed -r 's|.+\-y\ \"([^"]+)\".+|\1|g' $path_tmp/extract_rtmp)
    conn=$(sed -r 's|.+\-C\ \"([^"]+)\".+|\1|g' $path_tmp/extract_rtmp)

    downloader_cmd=$(cat $path_tmp/extract_rtmp)
    if [ "$downloader_in" == cURL ]; then
	downloader_cmd="curl \"$streamer swfUrl=${swfUrl} pageUrl=$pageUrl playpath=$playpath conn=$conn\""
    fi
fi
