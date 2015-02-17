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

## zdl-extension types: download
## zdl-extension name: Nowdownload

# Nowdownload /Nowvideo
function wise {
    w="$1"
    i="$2"
    s="$3"
    e="$4"
    lIll=0;
    ll1I=0;
    Il1l=0;
    ll1l=();
    l1lI=();
    while true; do
	if (( $lIll<5 )); then
	    l1lI+=( "${w:$lIll:1}" )
	elif (( $lIll<${#w} )); then
	    ll1l+=( "${w:$lIll:1}" )
	fi
	(( lIll++ ))
	

	if (( $ll1I<5 )); then
	    l1lI+=( "${i:$ll1I:1}" )
	elif (( $ll1I<${#i} )); then
	    ll1l+=( "${i:$ll1I:1}" )
	fi
	(( ll1I++ ))
		
	if (( $Il1l<5 )); then
	    l1lI+=( "${s:$Il1l:1}" )
	elif (( $Il1l<${#s} )); then
	    ll1l+=( "${s:$Il1l:1}" )
	fi
	(( Il1l++ ))
	test1=$(( ${#w}+${#i}+${#s}+${#e} ))
	test2=$(( ${#ll1l[*]}+${#l1lI[*]}+${#e} ))
	if (( $test1 == $test2 )); then
	    break
	fi
    done

    lI1l="${ll1l[*]}"
    lI1l="${lI1l//' '}"
    I1lI="${l1lI[*]}"
    I1lI="${I1lI//' '}"
    ll1I=0
    unset l1ll
    l1ll=()
    max=$(( ${#ll1l[*]}-1 ))

    for lIll in $(seq 0 2 $max); do
	ll11=-1;

	char_code=$(char2code ${I1lI:$ll1I:1})
	if (( $char_code%2 )); then 
	    ll11=1
	fi
	
	int=$(parse_int "${lI1l:$lIll:2}" 36)
	code_char=$(code2char $(( $int-$ll11 )))
	l1ll+=( "$code_char" )

	(( ll1I++ ))
	if (( $ll1I>=${#l1lI[*]} )); then
	    ll1I=0
	fi
    done
    join="${l1ll[*]}"
    echo "${join//' '}"

}

function wise_2 {
    lI1l=$1
    I1lI=$2
    ll1I=0
    unset l1ll
    l1ll=()
    max=${#lI1l}
    for lIll in $(seq 0 2 $max); do
	ll11=-1;

	char_code=$(char2code ${I1lI:$ll1I:1})
	if (( $char_code%2 )); then 
	    ll11=1
	fi
	
	int=$(parse_int "${lI1l:$lIll:2}" 36)
	code_char=$(code2char $(( $int-$ll11 )))
	l1ll+=( "$code_char" )

	(( ll1I++ ))
	if (( $ll1I>=${#l1lI[*]} )); then
	    ll1I=0
	fi
    done
    join="${l1ll[*]}"
    echo "${join//' '}"
}


function wise_args {
    code="${1##*'('}"
    code="${code%%')'*}"
    code="${code//\'}"
    echo ${code//','/' '}
}


if [ "$url_in" != "${url_in//'nowdownload'}" ]; then
    if [ "$url_in" != "${url_in//'down.php?id='}" ]; then
	url_in_old="$url_in"
	url_in="${url_in_old//'down.php?id='/dl/}"
	links_loop - "$url_in_old"
	links_loop + "$url_in"
    elif [ "$url_in" != "${url_in//'download.php?id='}" ]; then
	url_in_old="$url_in"
	url_in="${url_in_old//'download.php?id='/dl/}"
	links_loop - "$url_in_old"
	links_loop + "$url_in"
    fi
fi

if [ "$url_in" != "${url_in//nowdownload.}" ] && [ "$url_in" == "${url_in//\/nowdownload\/}" ]; then
    get_tmps
    test_file=`cat "$path_tmp"/zdl.tmp | grep "This file does not exist"`
    if [ ! -z "$test_file" ]; then
	_log 3
	break_loop=true
	break
    fi
    now=`cat "$path_tmp"/zdl.tmp | grep "Download Now"`
    if [ ! -z "$now" ]; then
	url_in_file="${now#*\"}"
	url_in_file="${url_in_file%%\"*}"
	unset now
	
    else
	wise_code=$(cat "$path_tmp"/zdl.tmp | grep ";eval")
	if [ ! -e "$path_usr/extensions/zdl-wise" ]; then
	    print_c 2 "Attendi: potrebbe impiegare qualche minuto"
	    wise_code=$( wise $( wise_args "$wise_code" ) )
	    wise_code=$( wise $( wise_args "$wise_code" ) )
	    wise_code=$( wise $( wise_args "$wise_code" ) )

	    unset url_in_file
	    preurl_in_file="${wise_code##*href=\"}"
	    preurl_in_file="${preurl_in_file%%\"*}"
	    preurl_in_file="${url_in%'/dl/'*}$preurl_in_file"
	    wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl2.tmp" "$preurl_in_file" &>/dev/null 
	    url_in_file=$(cat "$path_tmp/zdl2.tmp" |grep nowdownloader)
	    url_in_file="${url_in_file#*href=\"}"
	    url_in_file="${url_in_file%%\"*}"
	    
	else
	    print_c 2 "Attendi circa 30 secondi:"
	    k=`date +"%s"`
	    s=0
	    while true; do
		sleep 1
		s=`date +"%s"`
		s=$(( $s-$k ))
		echo -e $s"\r\c"
	    done &
	    pid_counter=$!
	    trap "kill $pid_counter; trap SIGINT; exit" SIGINT
	    wise_code=$( "$path_usr"/extensions/zdl-wise $( wise_args "$wise_code" ) )
	    wise_code=$( "$path_usr"/extensions/zdl-wise $( wise_args "$wise_code" ) )
	    wise_code=$( "$path_usr"/extensions/zdl-wise $( wise_args "$wise_code" ) )
	    kill $pid_counter 2>/dev/null
	    trap SIGINT
	    unset url_in_file
	    preurl_in_file="${wise_code##*href=\"}"
	    preurl_in_file="${preurl_in_file%%\"*}"
	    preurl_in_file="${url_in%'/dl/'*}$preurl_in_file"
	    while true; do
		if (( $s>30 )); then
		    wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl -O "$path_tmp/zdl2.tmp" "$preurl_in_file" &>/dev/null 
		fi
		sleeping 1
		s=`date +"%s"`
		s=$(( $s-$k ))
		echo -e $s"\r\c"
		url_in_file=$(cat "$path_tmp/zdl2.tmp" |grep nowdownloader)
		url_in_file="${url_in_file#*href=\"}"
		url_in_file="${url_in_file%%\"*}"
		premium=$(cat "$path_tmp/zdl2.tmp" |grep "You need Premium")
		sleeping 0.1
		if [ ! -z "$url_in_file" ] || [ ! -z "$premium" ] || (( $s > 60 )); then
		    break
		fi
	    done
	fi
    fi
    if [ ! -z "$premium" ]; then
	_log 11
	break_loop=true
    else
	file_in="${url_in_file##*'/'}"
	file_in="${file_in%'?'*}"
    fi

    if [ -z "$file_in" ]; then
	break_loop=true
    fi
    unset preurl_in_file 
fi

