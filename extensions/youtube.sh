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

shopt -u nullglob

if [ "$url_in" != "${url_in//'youtube.com/watch'}" ]; then
    videoType="mp4"

    ## (Wget) Scarica il codice HTML della pagina YouTube del video
    html="`wget -Ncq -e convert-links=off --keep-session-cookies --save-cookies /dev/null --no-check-certificate "$url_in" -O-`" || _log 8 

    ## Impostazione del nome del file come il titolo della pagina YouTube
    if [[ $html =~ \<title\>(.+)\<\/title\> ]]; then
	title=${BASH_REMATCH[1]}
	title=$(echo $title | sed -r 's/([^0-9a-z])+/_/ig')
	title=$(echo $title | sed -r 's/_youtube//ig')
	title=$(echo $title | sed -r 's/^_//ig')
	title=$(echo $title | tr '[A-Z]' '[a-z]')
	title=$(echo $title | sed -r 's/_amp//ig')
    else
	_log 9 
    fi

                    ## Selezione del blocco di codice contenente gli URLs ai vari formati video
    while IFS= read -r line
    do
	if [[ $line =~ \"url_encoded_fmt_stream_map\"(.*) ]]; then
	    download=${BASH_REMATCH[1]}
	    break
	fi
    done <<< "$html"

                    ## Selezione della stringa contenente l'URL per scaricare in formato mp4
    IFS=',' read -ra URLs <<< "$download"
    for val in "${URLs[@]}"; do
	if [[ $val =~ $videoType ]]; then
	    download=$val
	    break
	fi
    done

                    ## Conversione caratteri unicode e rimozione parti della stringa non necessarie 
    download=$(echo $download | sed -r 's/\:\ \"//')
    download=$(echo $download | sed -r 's/%3A/:/g')
    download=$(echo $download | sed -r 's/%2F/\//g')
    download=$(echo $download | sed -r 's/%3F/\?/g')
    download=$(echo $download | sed -r 's/%3D/\=/g')
    download=$(echo $download | sed -r 's/%252C/%2C/g')
    download=$(echo $download | sed -r 's/%26/\&/g')
    download=$(echo $download | sed -r 's/sig=/signature=/g')
    download=$(echo $download | sed -r 's/\\u0026/\&/g')
    download=$(echo $download | sed -r 's/(type=[^&]+)//g')
    download=$(echo $download | sed -r 's/(fallback_host=[^&]+)//g')
    download=$(echo $download | sed -r 's/(quality=[^&]+)//g')

                    ## Selezione del parametro firma (generato ed unserito in modo casuale ad ogni visita della pagina)
    if [[ $download =~ (signature=[^&]+) ]]; then
	signature=${BASH_REMATCH[1]}
    else
	_log 10 #die "\nERRORE: firma del video non trovata!\n\n"
    fi

                    ## Selezione dell'URL
    if [[ $download =~ (http?:.+) ]]; then
	youtubeurl=${BASH_REMATCH[1]}
    else
	_log 3 #die "\nERRORE: URL del video non trovato!\n\n"
    fi

                    ## Rimozione del parametro firma dall'URL (se presente)
    youtubeurl=$(echo $youtubeurl | sed -r 's/\&signature.+$//')

                    ## Posizionamento corretto del parametro firma
    download="$youtubeurl&$signature"

                    ## Rimozione duplicati
    download=$(echo $download | sed -r 's/\&+/\&/g')
    url_in_file=$(echo $download | sed -r 's/\&itag=[0-9]+\&signature=/\&signature=/g')

                    ## Nome del file da scaricare
    file_in="$title.$videoType"

fi

shopt -s nullglob
