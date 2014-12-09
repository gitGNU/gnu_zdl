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
	wget -t 3 -T $max_waiting --no-check-certificate --retry-connrefused --save-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl.tmp" $url_in  &>/dev/null
	echo -e "...\c"
    done
}

function input_hidden {
    if [ ! -z "$1" ]; then
	unset post_data datatmp data value name post
	if [ -f "$1" ]; then
	    datatmp=$(grep -P "input.+type\=.+hidden" < "$1")
	else
	    datatmp=$(grep -P "input.+type\=.+hidden" <<< "$1")
	fi

	declare -g -A post
	for ((i=1; i<=$(wc -l <<< "$datatmp"); i++)); do
	    data=$(sed -n "${i}p" <<< "$datatmp")
	    name=${data#*name=\"}
	    name=${name%%\"*}
	    value=${data#*value=\"}
	    value=${value%%\"*}

	    [ ! -z "$name" ] && post[$name]="$value"
	    
	    if [ "$name" == "realname" ] || [ "$name" == "fname" ]; then # <--easybytez , sharpfile , uload , glumbouploads
		file_in="$value"
	    fi
	    
	    if [ -z "$post_data" ]; then
		post_data="${name}=${value}"
	    else
		post_data="${post_data}&${name}=${value}"
	    fi
	done
    fi
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
    echo "$decoded_expr"
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
    URLlist=$(wget -q "http://dcrypt.it/decrypt/paste" --post-data="content=${container}" -O- |egrep -e "http" -e "://")
    unset new
    for ((i=1; i<=$(wc -l <<< "$URLlist"); i++)); do
	new=$(sed -n ${i}p  <<< "$URLlist" |sed -r "s|.*\"(.+)\".*|\\1|g")
	[ "$i" == 1 ] && url_in="$new"
	#links_loop + "$new"
	echo -e "${new// /%20}" >> "$path_tmp"/links_loop.txt && print_c 1 "Aggiunto URL: $new"
    done
    unset new
}

function base36 {
    b36arr=( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z )
    for i in $(echo "obase=36; $1"| bc); do
        echo -n "${b36arr[${i#0}]}"
    done
}

function packed {
    p=$(sed -r 's@(.+)@\U\1@g' <<< "$1") ## <-- va convertito con base36, quindi servono le lettere maiuscole
    a=$2
    c=$3

    IFS="|"
    k=( $4 )
    unset IFS

    e=$5 #non esiste
    d=$6 #non esiste

    while [ "$c" != 0 ]; do
	 (( c-- ))
	 int=$(base36 $c)
	 if [ ! -z "${k[$c]}" ] && [ "${k[$c]}" != 0 ]; then
	     p=$(sed "s@\\b$int\\b@${k[$c]}@g" <<< "$p")
	     unset int
	 fi
    done
    echo "$p"
}

function packed_args {
    code="${1#*\}\(\'}"
    code="${code%%\'.split*}"
    code_p=$(sed -r "s@(.+)'\,([0-9]+)\,([0-9]+)\,'(.+)@\1@g" <<< "$code") 
    code_a=$(sed -r "s@(.+)'\,([0-9]+)\,([0-9]+)\,'(.+)@\2@g" <<< "$code") 
    code_c=$(sed -r "s@(.+)'\,([0-9]+)\,([0-9]+)\,'(.+)@\3@g" <<< "$code") 
    code_k=$(sed -r "s@(.+)'\,([0-9]+)\,([0-9]+)\,'(.+)@\4@g" <<< "$code") 
}

function countdown+ {
    max=$1
    print_c 2 "Attendi $max secondi:"
    k=`date +"%s"`
    s=0
    while (( $s<$max )); do
	sleeping 1
	s=`date +"%s"`
	s=$(( $s-$k ))
	echo -e $s"\r\c"
    done 
}

function tags2vars {
    if [[ ! -z $1 ]]; then
	 eval $(sed -r "s|<([^/<>]+)>([^/<>]+)</([^<>]+)>|\1=\2; |g" <<< "$1")
    fi
}

function char2code {
    char=$1
    printf "%d" "'$char"
}

function code2char {
    code=$1
    printf \\$(printf "%03o" "$code" )
}

function parse_int {
    num_based="${1%% *}"
    base=$2
    echo $(( $base#${num_based##0} )) #conversione di $int da base 36 a base decimale
}

function make_index {
    string="$1"
    sed -e s,[^a-zA-Z0-9],,g <<< "$string"
}
