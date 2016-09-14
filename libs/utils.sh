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

function get_mime {
    file -b --mime-type "$1"
}

function size_file {
    stat -c '%s' "$1" 2>/dev/null
}

function trim {
    echo $1
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
    char=( '+' '/' '=' ' ' )
    encoded=( '%2B' '%2F' '%3D' '%20' )

    text="$1"
    for i in $(seq 0 $(( ${#char[*]}-1 )) )
    do
	text="${text//${char[$i]}/${encoded[$i]}}"
    done
    echo -n "$text"
}

function add_container {
    local new
    unset new
    container=$(urlencode "$1")
    URLlist=$(wget "http://dcrypt.it/decrypt/paste"     \
		   --post-data="content=${container}"   \
		   -qO- |
		     egrep -e "http" -e "://")

    while read line
    do
	new=$(sed -r "s|.*\"(.+)\".*|\\1|g" <<< "$line")
	new=$(sanitize_url "$new")
	
	(( i == 1 )) && url_in="$new"

	echo "$new" >> "$path_tmp"/links_loop.txt &&
	    print_c 1 "Aggiunto URL: $new"

    done <<< "$URLlist"
}

function base36 {
    b36arr=( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z )
    for i in $(echo "obase=36; $1"| bc)
    do
        echo -n "${b36arr[${i#0}]}"
    done
}

function split {
    if [[ "$2" ]]
    then
	IFS="$2"
	splitted=($1)
	for i in ${splitted[*]}
	do echo $i
	done
	unset IFS

    else
	sed -r "s|(.{1})|\1\n|g" <<< "$1" 2>/dev/null
    fi
}

function obfuscate {
    local obfs
    for i in $(split "$1")
    do
	 obfs+=$(char2code "$i")
    done
    obfs=$(( obfs + obfs - RANDOM * RANDOM + $(date +%s) ))

    for i in $(split "$obfs")
    do
	code2char "10$i"
    done
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
    sed -e s,[^a-zA-Z0-9],,g <<< "$string" 2>/dev/null
}




function nodejs_eval {
    if [ -f "$1" ]
    then
	jscode="$(cat "$1")"

    else
	jscode="$1"
    fi

    result=$($nodejs $evaljs "($jscode)")

    if [ -z "$result" ]
    then
	result=$($nodejs $evaljs "$jscode")
    fi
       
    if [ -d /cygdrive ] &&
	   [ -z "$result" ]
    then
	result=$($nodejs -e "console.log($jscode)")
    fi

    echo "$result"
}

function scrape_url {
    url_page="$1"
    if url "$url_page"
    then
	print_c 1 "[--scrape-url] connessione in corso: $url_page"

	baseURL="${url_page%'/'*}"

	html=$(wget -qO-                         \
		    --user-agent="$user_agent"   \
		    "$url_page"                    |
		      tr "\t\r\n'" '   "'                             | 
		      grep -i -o '<a[^>]\+href[ ]*=[ \t]*"[^"]\+"'    | 
		      sed -e 's/^.*"\([^"]\+\)".*$/\1/g' 2>/dev/null)

	while read line
	do
	    [[ ! "$line" =~ ^(ht|f)tp\:\/\/ ]] &&
		line="${baseURL}/$line"

	    if [[ "$line" =~ "$url_regex" ]]
	    then
		echo "$line"
		if [ -z "$links" ]
		then
		    links="$line"
		else
		    links="${links}\n$line"
		fi
		start_file="$path_tmp/links_loop.txt"
		set_link + "$line"
	    fi
	done <<< "$html" 

	print_c 1 "Estrazione URL dalla pagina web $url_page completata"
    fi
}


function set_ext {
    local filename="$1"
    local exts ext item

    for item in "$filename" "$url_in_file"
    do
	url "$item" &&
	    item="${item%?*}"
	
	test_ext=".${item##*.}"
    
	if [ -n "$test_ext" ] &&
	       grep -P "^$test_ext\s" $path_usr/mimetypes.txt &>/dev/null
	then
	    echo $test_ext 
	    return 0
	fi
    done

    rm -f "$path_tmp/test_mime"
    
    if [ ! -f "$filename" ] &&
	   url "$url_in_file" &&
	   ! dler_type "rtmp" "$url_in" &&
	   ! dler_type "youtube-dl" "$url_in"
    then
	if [ -f "$path_tmp"/cookies.zdl ]
	then
	    COOKIES="--load-cookies=$path_tmp/cookies.zdl"

	elif [ -f "$path_tmp"/flashgot_cfile.zdl ]
	then
	    COOKIES="--load-cookies=$path_tmp/flashgot_cfile.zdl"
	fi

	if [ -n "${post_data}" ]
	then
	    method_post="--post-data=${post_data}"
	fi
	

	wget --user-agent=Firefox                  \
	     -t 3 -T 40                            \
	     $COOKIES                              \
	     $method_post                          \
	     -qO "$path_tmp/test_mime" "$url_in_file" &
	mime_pid=$!

	counter=0
	while ( [ ! -f "$path_tmp/test_mime" ] &&
		    (( counter<10 )) ||
			[[ "$(file --mime-type "$path_tmp/test_mime")" =~ empty ]] ) &&
		  check_pid $mime_pid
	do
	    sleep 0.5
	    ((counter++))
	done
	
	kill -9 $mime_pid
	mime_type=$(file -b --mime-type "$path_tmp/test_mime")
	rm -f "$path_tmp/test_mime"

    elif [ -f "$filename" ]
    then
	mime_type=$(file -b --mime-type "$filename")
    fi

    if [ -n "$mime_type" ]
    then
	exts=$(grep "$mime_type" $path_usr/mimetypes.txt | awk '{print $1}')
	head -n1 <<< "$exts"
	return 0
	
    else
	return 1
    fi
}

function replace_url_in {
    if url "$1"
    then
	set_link - "$url_in"
	url_in="$1"
	set_link + "$url_in"
	return 0
	
    else
	return 1
    fi
}

function sanitize_url {
    data=$(anydownload "$1")
    
    data="${data%%'?'}"
    data="${data## }"
    data="${data%% }"
    data="${data%'#20%'}"
    data="${data%'#'}"
    data="${data// /%20}"
    data="${data//'('/%28}"
    data="${data//')'/%29}"
    data="${data//'['/%5B}"
    data="${data//']'/%5D}"
    
    echo "$data"
}

function sanitize_file_in {
    local ext ext0
    
    file_in="${file_in## }"
    file_in="${file_in%% }"
    file_in="${file_in// /_}"
    file_in="${file_in//\'/_}"
    file_in="${file_in//\"/_}"
    file_in="${file_in//[\[\]\(\)]/-}"
    file_in="${file_in//\/}"
    file_in="${file_in##-}"
    file_in="$(htmldecode "$file_in")"
    file_in="${file_in//'&'/and}"
    file_in="${file_in//'#'}"
    file_in="${file_in//';'}"
    file_in="${file_in//'?'}"
    file_in="${file_in//'!'}"
    file_in="${file_in//'$'}"
    file_in="${file_in//'%20'/_}"
    file_in="$(urldecode "$file_in")"
    file_in="${file_in//'%'}"
    file_in="${file_in//\|}"
    file_in="${file_in//'`'}"
    file_in="${file_in//[<>]}"
    file_in="${file_in::180}"
    file_in=$(sed -r 's|^[^0-9a-zA-Z\[\]()]*([0-9a-zA-Z\[\]()]+)[^0-9a-zA-Z\[\]()]*$|\1|g' <<< "$file_in" 2>/dev/null)

    if ! dler_type "no-check-ext" "$url_in"
    then
	ext=$(set_ext "$file_in")
	file_in="${file_in%$ext}$ext"
    fi
}

function link_parser {
    local _domain userpass ext item param
    param="$1"

    # extract the protocol
    parser_proto=$(echo "$param" | grep '://' | sed -r 's,^([^:\/]+\:\/\/).+,\1,g' 2>/dev/null)

    # remove the protocol
    parser_url="${param#$parser_proto}"

    # extract domain
    _domain="${parser_url#*'@'}"
    _domain="${_domain%%\/*}"
    [ "${_domain}" != "${_domain#*:}" ] && parser_port="${_domain#*:}"
    _domain="${_domain%:*}"

    if [ -n "${_domain//[0-9.]}" ]
    then
	[ "${_domain}" != "${_domain%'.'*}" ] && parser_domain="${_domain}"
    else 
	parser_ip="${_domain}"
    fi

    # extract the user and password (if any)
    userpass=`echo "$parser_url" | grep @ | cut -d@ -f1`
    parser_pass=`echo "$userpass" | grep : | cut -d: -f2`
    if [ -n "$pass" ]
    then
	parser_user=`echo $userpass | grep : | cut -d: -f1 `
    else
	parser_user="$userpass"
    fi

    # extract the path (if any)
    parser_path="$(echo $parser_url | grep / | cut -d/ -f2-)"

    if [[ "${parser_proto}" =~ ^(ftp|http) ]]
    then
	if ( [ -n "$parser_domain" ] || [ -n "$parser_ip" ] ) &&
	       [ -n "$parser_path" ]
	then
	    return 0
	fi
    fi
    return 1
}

function url {
    if grep_urls "$1" &>/dev/null
    then
	return 0
    else
	return 1
    fi
}

function grep_urls {
    local input result
    result=1
    
    if [ -f "$1" ] &&
	   [ "$(file -b --mime-type "$1")" == 'text/plain' ]
    then
	input=$(cat "$1")

    else
	input="$1"
    fi

    while read line
    do
        if [ -f "$line" ] &&
	       [[ "$line" =~ \.torrent$ ]]
	then
	    echo "$line" 
	    result=0
	fi

    done <<< "$input"
    
    grep -P '(^xdcc://.+|^irc://.+|^magnet:.+|^\b(((http|https|ftp)://?|www[.]*)[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))[-_]*)$' <<< "$input" &&
	result=0

    return $result
    
}

function file_filter {
    ## opzioni filtro
    filtered=true
    if [ -n "$no_file_regex" ] &&
	   [[ "$1" =~ $no_file_regex ]]
    then
	_log 13
	return 1
    fi
    if [ -n "$file_regex" ] &&
	   [[ ! "$1" =~ $file_regex ]]
    then
	_log 14
	return 1
    fi
}

function join {
    tr " " "$2" <<< "$1"
}

function dotless2ip {
    local k
    local dotless=$1
    local i=$2
    [ -z "$i" ] && i=3
    
    if ((i == 0))
    then
	ip+=( $dotless )
	join "${ip[*]}" '.'
	return

    else
	k=$((256**i))
	
	ip+=( $((dotless / k)) )
	((i--))
	dotless2ip $((dotless - ip[-1] * k )) $i
    fi
}
