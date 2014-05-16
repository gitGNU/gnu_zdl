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


#### hacking web pages

function get_tmps {
    while [ "`cat "$path_tmp"/zdl.tmp 2>/dev/null |grep \</html`" == "" ]; do
	wget -t 3 -T $max_waiting --retry-connrefused --save-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl.tmp" $url_in  &>/dev/null
	echo -e "...\c"
    done
}

function input_hidden {
    j=1
    cat $tmp | grep input | grep hidden > "$path_tmp"/data.tmp
    max=`wc -l "$path_tmp/data.tmp" | awk '{ print($1) }'`
    max=$(( $max+1 ))
    
    while [ $j != $max ]; do
	data=`cat "$path_tmp"/data.tmp |sed -n "${j}p"`
	name=${data#*name=\"}
	name=${name%%\"*}
	value=${data#*value=\"}
	value=${value%%\"*}
	
	if [ "$name" == "realname" ] || [ "$name" == "fname" ]; then # <--easybytez , sharpfile , uload , glumbouploads
	    file_in="$value"
	fi

	if [ "$post_data" == "" ]; then
	    post_data="${name}=${value}"
	else
	    post_data="${post_data}&${name}=${value}"
	fi
	(( j++ ))
    done
}


function pseudo_captcha { #per implementarla, analizzare ../extensions/frozen/sharpfile.sh
    j=0
    for cod in ${ascii_dec[*]}; do 
	captcha[$j]=`printf "\x$(printf %x $cod)"`
	(( j++ ))
    done
}

function urldecode {
    local data=${1//+/ }
    printf '%b' "${data//%/\x}" 2>/dev/null
}

function htmldecode {
    entity=( '&quot;' '&amp;' '&lt;' '&gt;' '&OElig;' '&oelig;' '&Scaron;' '&scaron;' '&Yuml;' '&circ;' '&tilde;' '&ensp;' '&emsp;' '&thinsp;' '&zwnj;' '&zwj;' '&lrm;' '&rlm;' '&ndash;' '&mdash;' '&lsquo;' '&rsquo;' '&sbquo;' '&ldquo;' '&rdquo;' '&bdquo;' '&dagger;' '&Dagger;' '&permil;' '&lsaquo;' '&rsaquo;' '&euro;' )

    entity_decoded=( '"' '&' '<' '>' 'Œ' 'œ' 'Š' 'š' 'Ÿ' '^' '~' ' ' '  ' '' '' '' '' '' '–' '—' '‘' '’' '‚' '“' '”' '„' '†' '‡' '‰' '‹' '›' '€' )

    decoded_expr="$1"
    for i in $(seq 0 $(( ${#entity[*]}-1 )) ); do
	decoded_expr="${decoded_expr//${entity[$i]}/${entity_decoded[$i]}}"
    done

}

function urlencode {
    char=( '+' '/' '=' )
    encoded=( '%2B' '%2F' '%3D' )

    text="$1"
    for i in $(seq 0 $(( ${#char[*]}-1 )) ); do
	text="${text//${char[$i]}/${encoded[$i]}}"
    done
    
    echo -n "$text"
}

function add_container {
    container=$(urlencode "$1")
    URLlist=$(wget -q "http://dcrypt.it/decrypt/paste" --post-data="content=${container}" -O- |grep "http://")
    unset new
    for ((i=1; i<=$(wc -l <<< "$URLlist"); i++)); do
	new=$(sed -n ${i}p  <<< "$URLlist" |sed -r "s|.*\"(.+)\".*|\\1|g")
	[ "$i" == 1 ] && url_in="$new"
	#links_loop + "$new"
	echo -e "${new// /%20}" >> "$path_tmp"/links_loop.txt && print_c 1 "Aggiunto URL: $new"
    done
    unset new
}
