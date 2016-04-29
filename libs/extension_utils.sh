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

#### hacking web pages

function get_tmps {
    wget -t 3 -T $max_waiting                    \
	 --no-check-certificate                  \
	 --retry-connrefused                     \
	 --save-cookies="$path_tmp"/cookies.zdl  \
	 --user-agent="$user_agent"              \
	 -qO "$path_tmp/zdl.tmp"                 \
	 "$url_in"  
}

function input_hidden {
    if [ -n "$1" ]
    then
	unset post_data datatmp data value name post
	if [ -f "$1" ]
	then
	    datatmp=$(grep -P "input.+type\=.+hidden" < "$1")
	else
	    datatmp=$(grep -P "input.+type\=.+hidden" <<< "$1")
	fi

	for ((i=1; i<=$(wc -l <<< "$datatmp"); i++))
	do
	    data=$(sed -n "${i}p" <<< "$datatmp" |grep name)
	    name=${data#*name=\"}
	    name=${name%%\"*}

	    value=${data#*value=\"}
	    value=${value%%\"*}

	    [ -n "$name" ] && eval postdata_$name=\"${value}\"
	    
	    if [ "$name" == "realname" ] || [ "$name" == "fname" ] ## <--easybytez , sharpfile , uload , glumbouploads
	    then 
		file_in="$value"
	    fi
	    
	    if [ -z "$post_data" ]
	    then
		post_data="${name}=${value}"
	    else
		post_data="${post_data}&${name}=${value}"
	    fi
	done
    fi
}

function pseudo_captcha { ## modello d'uso in ../extensions/rockfile.sh
    	while read line
	do
	    i=$(sed -r 's|.*POSITION:([0-9]+)px.+|\1|g' <<< "$line")
	    captcha[$i]=$(htmldecode_regular "$(sed -r 's|[^>]+>&#([^;]+);.+|\1|' <<< "$line")")
	done <<< "$(grep '&#' <<< "$1" |
	    sed -r 's|padding-left|\nPOSITION|g' |
	    grep POSITION)"

	echo "${captcha[*]}" | tr -d ' '
}

function urldecode {
    printf '%b' "${1//%/\\x}" 2>/dev/null
}

function htmldecode {
    entity=( '&quot;' '&amp;' '&lt;' '&gt;' '&OElig;' '&oelig;' '&Scaron;' '&scaron;' '&Yuml;' '&circ;' '&tilde;' '&ensp;' '&emsp;' '&thinsp;' '&zwnj;' '&zwj;' '&lrm;' '&rlm;' '&ndash;' '&mdash;' '&lsquo;' '&rsquo;' '&sbquo;' '&ldquo;' '&rdquo;' '&bdquo;' '&dagger;' '&Dagger;' '&permil;' '&lsaquo;' '&rsaquo;' '&euro;' )

    entity_decoded=( '"' '&' '<' '>' 'Œ' 'œ' 'Š' 'š' 'Ÿ' '^' '~' ' ' '  ' '' '' '' '' '' '–' '—' '‘' '’' '‚' '“' '”' '„' '†' '‡' '‰' '‹' '›' '€' )

    decoded_expr="$1"
    for i in $(seq 0 $(( ${#entity[*]}-1 )) )
    do
	decoded_expr="${decoded_expr//${entity[$i]}/${entity_decoded[$i]}}"
    done
    echo "$decoded_expr"
}

function htmldecode_regular {
    for cod in $@
    do 
    	printf "\x$(printf %x $cod)"
    done
}

function urlencode {
    char=( '+' '/' '=' )
    encoded=( '%2B' '%2F' '%3D' )

    text="$1"
    for i in $(seq 0 $(( ${#char[*]}-1 )) )
    do
	text="${text//${char[$i]}/${encoded[$i]}}"
    done
    echo -n "$text"
}

function add_container {
    container=$(urlencode "$1")
    URLlist=$(wget -q "http://dcrypt.it/decrypt/paste" --post-data="content=${container}" -O- |egrep -e "http" -e "://")
    unset new
    for ((i=1; i<=$(wc -l <<< "$URLlist"); i++))
    do
	new=$(sed -n ${i}p  <<< "$URLlist" |sed -r "s|.*\"(.+)\".*|\\1|g")
	[ "$i" == 1 ] && url_in="$new"
	#links_loop + "$new"
	echo -e "${new// /%20}" >> "$path_tmp"/links_loop.txt && print_c 1 "Aggiunto URL: $new"
    done
    unset new
}

function base36 {
    b36arr=( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z )
    for i in $(echo "obase=36; $1"| bc)
    do
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

    while [ "$c" != 0 ]
    do
	 (( c-- ))
	 int=$(base36 $c)
	 if [ -n "${k[$c]}" ] &&
		[ "${k[$c]}" != 0 ]
	 then
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
    while (( $s<$max ))
    do
	if ! check_pid $pid_prog
	then
	    exit
	fi
	sleeping 1
	s=`date +"%s"`
	s=$(( $s-$k ))
	print_c 0 "$s\r\c"
    done 
}

function countdown- {
    max=$1
    start=`date +"%s"`
    stop=$(( $start+$max ))
    diff=$max
    while (( $diff>0 ))
    do
	if ! check_pid $pid_prog
	then
	    exit
	fi
	this=`date +"%s"`
	diff=$(( $stop-$this ))
	print_c 0 "           \r\c"
	print_c 0 "$diff\r\c"
	sleeping 1
    done 
}

function clean_countdown {
    rm -f "$path_tmp"/.wise-code
}

function tags2vars {
    if [[ -n $1 ]]
    then
	 eval $(sed -r 's|<([^/<>]+)>([^/<>]+)</([^<>]+)>|\1=\2; |g' <<< "$1")
    fi
}

function char2code {
    printf "%d" "'$1"
}

function code2char {
    printf \\$(printf "%03o" "$1" )
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

function base64_decode {
    arg1=$1
    arg2=$2
    var_4=${arg1:0:$arg2}
    var_5=${arg1:$(( $arg2+10 ))} 
    arg1="$var_4$var_5"
    var_6='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
    var_f=0
    var_10=0
    while true
    do
	var_a=$(( $(expr index "$var_6" ${arg1:$var_f:1} )-1 ))
	(( var_f++ ))
	var_b=$(( $(expr index "$var_6" ${arg1:$var_f:1} )-1 )) 
	(( var_f++ ))
	var_c=$(( $(expr index "$var_6" ${arg1:$var_f:1} )-1 )) 
	(( var_f++ ))
	var_d=$(( $(expr index "$var_6" ${arg1:$var_f:1} )-1 )) 
	(( var_f++ ))
	var_e=$(( $var_a << 18 | $var_b << 12 | $var_c << 6 | $var_d ))
	var_7=$(( $var_e >> 16 & 0xff ))
	var_8=$(( $var_e >> 8 & 0xff ))
	var_9=$(( $var_e & 0xff ))
	if (( $var_c == 64 ))
	then
	    var_12[$(( var_10++ ))]=$(code2char $var_7)
	else
	    if (( $var_d == 64 ))
	    then
		var_12[$(( var_10++ ))]=$(code2char $var_7)$(code2char $var_8)
	    else
		var_12[$(( var_10++ ))]=$(code2char $var_7)$(code2char $var_8)$(code2char $var_9)
	    fi
	fi
	(( $var_f>=${#arg1} )) && break
    done
    sed -r 's| ||g' <<< "${var_12[*]}"
}


function redirect {
    url_input="$1"
    sleeping 1

    if ! url "$url_in" 
    then
	return 1
    fi
    
    k=$(date +"%s")
    s=0
    while true
    do
    	if ! check_pid "$wpid" ||
		[ "$s" == 0 ] ||
		[ "$s" == "$max_waiting" ] ||
		[ "$s" == $(( $max_waiting*2 )) ]
    	then 
    	    kill -9 "$wpid" &>/dev/null
    	    rm -f "$path_tmp/redirect"
    	    wget -t 1 -T $max_waiting                       \
    		 --user-agent="$user_agent"                 \
    		 --no-check-certificate                     \
    		 --load-cookies="$path_tmp"/cookies.zdl     \
    		 --post-data="${post_data}"                 \
    		 "$url_input"                               \
    		 -SO /dev/null -o "$path_tmp/redirect" &
    	    wpid=$!
	    echo "$wpid" >> "$path_tmp"/pid_redirects
    	fi
	
    	if [ -f "$path_tmp/redirect" ]
	then
	    url_redirect="$(grep 'Location:' "$path_tmp/redirect" 2>/dev/null |head -n1)"
	    url_redirect="${url_redirect#*'Location: '}"
	    #url_redirect="$(sanitize_url "$url_redirect")"
	fi

	if url "$url_redirect" &&
		[ "$url_redirect" != "https://tusfiles.net" ] # || ! check_pid "$wpid"
    	then 
    	    kill -9 $(cat "$path_tmp"/pid_redirects) &>/dev/null
    	    break
    	elif (( $s>90 ))
    	then
    	    kill -9 $(cat "$path_tmp"/pid_redirects) &>/dev/null
    	    return
    	else
    	    [ "$s" == 0 ] &&
		print_c 2 "Redirezione (attendi massimo 90 secondi):"

	    sleeping 1
    	    s=`date +"%s"`
    	    s=$(( $s-$k ))
    	    print_c 0 "$s\r\c"
    	fi
    done

    url_in_file="${url_redirect}"

    rm -f "$path_tmp/redirect"
    unset url_redirect post_data
    return 0
}

function simply_debrid {
    html_url=$(wget --keep-session-cookies                                 \
		    --save-cookies="$path_tmp/cookies.zdl"                 \
		    --post-data="link=$1&submit=GENERATE TEXT LINKS"       \
		    "https://simply-debrid.com/generate#show"              \
		    -qO-                                              |
		      grep -Po "inc/generate/name.php[^']+")
    
    json_data=$(wget --load-cookies="$path_tmp/cookies.zdl"      \
		     "https://simply-debrid.com/$html_url"       \
		     -qO-                                     |
		       sed -r 's|\\\/|/|g')
    
    if [[ "$json_data" =~ '"error":0' ]]
    then
	print_c 2 "Estrazione dell'URL del file attraverso https://simply-debrid.com ..."
	file_in=$(sed -r 's|.+\"name\":\"([^"]+)\".+|\1|' <<< "$json_data")
	url_in_file=$(sed -r 's|.+\"generated\":\"([^"]+)\".+|\1|' <<< "$json_data")
	url_in_file=$(sanitize_url "$url_in_file")

    elif [[ "$url_in" =~ (nowdownload) ]]
    then
	_log 2
	breakloop=true
    
    else
	_log 11
	print_c 3 "Riprova cambiando indirizzo IP (verrà estratto da https://simply-debrid.com)\nPuoi usare le opzioni --reconnect oppure --proxy" |
	    tee -a $file_log
	breakloop=true
    fi		    
}

function set_ext {
    local filename="$1"
    local exts ext

    [[ "$filename" =~ MEGAenc$ ]] &&
	echo .MEGAenc &&
	return 0

    rm -f "$path_tmp/test_mime"
    
    if [ ! -f "$filename" ] &&
	   url "$url_in_file" &&
	   ! dler_type "rtmp" "$url_in" &&
	   ! dler_type "youtube-dl" "$url_in"
    then
	wget --user-agent=Firefox -qO "$path_tmp/test_mime" "$url_in_file" &
	mime_pid=$!

	counter=0
	while [ ! -f "$path_tmp/test_mime" ] &&
		  (( counter<10 )) &&
		  [ ! -f "$path_tmp/test_mime" ] ||
		      [[ "$(file --mime-type "$path_tmp/test_mime")" =~ empty ]]
	do
	    sleep 0.5
	    ((counter++))
	done
	
	kill -9 $mime_pid
	mime_type=$(file --mime-type "$path_tmp/test_mime" | cut -d' ' -f2)
	rm -f "$path_tmp/test_mime"

    elif [ -f "$filename" ]
    then
	mime_type=$(file --mime-type "$filename" | cut -d' ' -f2)
    fi

    if [ -n "$mime_type" ]
    then
	exts=$(grep "$mime_type" $path_usr/mimetypes.txt | awk '{print $1}')
	for ext in $exts
	do
	    [[ "$filename" =~ $ext$ ]] &&
		return 0
	done
	head -n1 <<< "$exts"
	
    else
	return 1
    fi
}

function replace_url_in {
    if url "$1"
    then
	links_loop - "$url_in"
	url_in="$1"
	links_loop + "$url_in"
	return 0
	
    else
	return 1
    fi
}
