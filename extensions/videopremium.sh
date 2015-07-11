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
## zdl-extension name: Videopremium (RTMP)

## API in php: ricava i dati da remoto (più lento)
#
if [[ "$url_in" =~ (videopremium.) ]]
then
    print_c 1 "Estrazione dati: attendi..."
    
    file_in=$(wget -qO- "$url_in"                  |
		     grep title                    |
		     sed -r 's|.+>([^<]+)<.+|\1|g' |
		     head -n1)
    
    html=$(wget "http://zoninoz.hol.es/api.php?uri=$url_in" -qO-)
    echo "$html" |grep rtmpdump\ \-V > $path_tmp/extract_rtmp
    chmod +x $path_tmp/extract_rtmp
    streamer=$(./$path_tmp/extract_rtmp |grep -P redirect.+STRING |sed -r 's|.+rtmp(.+)>$|rtmp\1|g')
    echo "$html" |grep rtmpdump\ \-q | sed -r "s,rtmpdump\ \-q\ \-r \"\"(.+)\|.+$,rtmpdump\ \-r\ \"$streamer\"\ \1,g"> $path_tmp/extract_rtmp

    swfUrl=$(sed -r 's|.+\-W\ \"([^"]+)\".+|\1|g' $path_tmp/extract_rtmp)
    pageUrl=$(sed -r 's|.+\-p\ \"([^"]+)\".+|\1|g' $path_tmp/extract_rtmp)
    playpath=$(sed -r 's|.+\-y\ \"([^"]+)\".+|\1|g' $path_tmp/extract_rtmp)
    conn=$(sed -r 's|.+\-C\ \"([^"]+)\".+|\1|g' $path_tmp/extract_rtmp)

    downloader_cmd=$(cat $path_tmp/extract_rtmp)
fi

# if [[ "$url_in" =~ (videopremium.) ]]
# then
#     if [[ ! $(command -v rtmpdump 2>/dev/null) ]]
#     then
# 	print_c 3 "Videopremium richiede RTMPDump, che non è installato: il file non verrà scaricato" | tee -a zdl_log.txt
# 	links_loop - "$url_in"
# 	break_loop=true
#     else
# 	print_c 1 "Estrazione dati: attendi..."
# 	if [[ ! "$url_in" =~ embed ]]
# 	then
# 	    link_parser "$url_in"
# 	    parser_path="${parser_path%%\/*}"
# 	    url_embed="${parser_proto}${parser_domain}/embed-${parser_path%.html}-607x360.html"
# 	fi
# 	file_in=$(wget -t 1 -T $max_waiting -O- -q "$url_in" |grep title| sed -r 's|.+>([^<]+)<.+|\1|g' |head -n1)

# 	if [ -n "$file_in" ]
# 	then
# 	    html=$(wget -q -O- "$url_embed" |grep flashvars)

# 	    echo "$url_embed -- $html" 
	    
# 	    streamer=$(head -n1 <<< "$html"| sed -r 's|.+file\"\:\"([^"]+)\".+|\1|g')
# 	    swfUrl="http://videopremium.tv"$(tail -n1 <<< "$html"| sed -r 's|.+embedSWF\(\"([^"]+)\".+|\1|g')
# 	    pageUrl="$url_in"
# 	    playpath="${streamer##*\/}"
# 	    conn="S:$playpath"
# 	    streamer="${streamer%\/*}"

# 	    streamer=$(rtmpdump -r "$streamer" -W "$swfUrl" -p "$pageUrl" -y "$playpath" -C "$conn" -V -C N:3 -B 0.1 2>&1 |grep -P redirect.+STRING |sed -r 's|.+rtmp(.+)>$|rtmp\1|g')
# #	curl "$streamer swfUrl=$swfUrl pageUrl=$pageUrl playpath=$playpath conn=$conn" -v -s 2>&1 #|grep -P redirect.+STRING |sed -r 's|.+rtmp(.+)>$|rtmp\1|g'

# 	    downloader_cmd="rtmpdump -r \"$streamer\" -W \"$swfUrl\" -p \"$pageUrl\" -y \"$playpath\" -C \"$conn\""

# #	if [ "$downloader_in" == cURL ]; then
# #	    downloader_cmd="curl \"$streamer swfUrl=${swfUrl} pageUrl=$pageUrl playpath=$playpath conn=$conn\""
# #	fi
# 	    unset break_loop
# 	else
# 	    _log 2
# 	fi
#     fi
# fi
