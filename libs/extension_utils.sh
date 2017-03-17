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
    wget -t 1 -T $max_waiting                    \
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


function tags2vars {
    if [[ -n $1 ]]
    then
	 eval $(sed -r 's|<([^/<>]+)>([^/<>]+)</([^<>]+)>|\1=\2; |g' <<< "$1")
    fi
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

function simply_debrid {
    local url="$1"

    print_c 2 "Estrazione dell'URL del file attraverso https://simply-debrid.com ..."
    
    local html=$(wget --keep-session-cookies                                 \
    		      --save-cookies="$path_tmp/cookies.zdl"                 \
    		      --post-data="link=$url&submit=GENERATE TEXT LINKS"     \
    		      "https://simply-debrid.com/generate#show"              \
    		      -qO-)

    local html_url='https://simply-debrid.com/'$(grep -Po 'inc/generate/name.php[^"]+' <<< "$html")

    url "$html_url" &&
	print_c 4 "... $html_url ..."

    wget -qO /dev/null 'https://simply-debrid.com/inc/generate/adb.php?nok=1' \
    	 --keep-session-cookies --save-cookies="$path_tmp/cookies.zdl"

	json_data=$(wget --load-cookies="$path_tmp/cookies.zdl"                 \
			 "$html_url" -qO- |
			   sed -r 's|\\\/|/|g')
    
    if [[ "$json_data" =~ '"error":0' ]]
    then
	file_in=$(sed -r 's|.+\"name\":\"([^"]+)\".+|\1|' <<< "$json_data")
	url_in_file=$(sed -r 's|.+\"generated\":\"([^"]+)\".+|\1|' <<< "$json_data")
	url_in_file=$(sanitize_url "$url_in_file")

	if url "$url_in_file" &&
		[ -n "$file_in" ]
	then
	    (( axel_parts>4 )) && axel_parts=4
	    debrided=true
	fi

    elif [[ "$url_in" =~ (nowdownload) ]]
    then
	print_c 3 "$PROG non è riuscito ad acquisire l'URL del file da simply-debrid: prova manualmente dalla pagina https://simply-debrid.com/generate#show\n"
	set_link - "$url_in"
	break_loop=true
	breakloop=true
    
    else
	_log 11
	print_c 3 "Riprova cambiando indirizzo IP (verrà estratto da https://simply-debrid.com)\nPuoi usare le opzioni --reconnect oppure --proxy" |
	    tee -a $file_log
	breakloop=true
    fi		    
}


function php_aadecode {
    php $path_usr/libs/aadecoder.php "$1"
}

function aaextract {
    ## codificato con php-aaencoder, ma non lo usiamo per decodificarlo

    encoded="window = this;"
    encoded+=$(grep '\^' <<< "$1" |
		      sed -r 's|<\/script>||g') 

    encoded+='for(var index in window){window[index];}'

    if [ -d /cygdrive ]
    then
	$nodejs -e "console.log($encoded)"

    else
	$nodejs $evaljs "$encoded"
    fi
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

function unpack {
    jscode=$(grep -P 'eval.+p,a,c,k,e,d' <<< "$1" | 
		    sed -r 's|.*eval||g')

    nodejs_eval "$jscode"    
}

function packed {
    if [ "$#" == 1 ]
    then
	## accetta come parametro il pezzo di codice "eval...packed..."
	packed_args "$1"
	p=$(sed -r 's@(.+)@\U\1@g' <<< "$code_p") ## <-- va convertito con base36, quindi servono le lettere maiuscole
	a="$code_a"
	c="$code_c"

	IFS="|"
	k=( "$code_k" )
	unset IFS

    else
	p=$(sed -r 's@(.+)@\U\1@g' <<< "$1") ## <-- va convertito con base36, quindi servono le lettere maiuscole
	a=$2
	c=$3

	IFS="|"
	k=( $4 )
	unset IFS

	e=$5 #non esiste
	d=$6 #non esiste
    fi

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

function get_title {
    html="$1"
    if [ -f "$html" ]
    then
	html=$(cat "$html")
    fi

    grep -P '<[Tt]{1}itle[^>]*>' <<< "$html" |
	sed -r 's|.*<[Tt]{1}itle[^>]*>([^<]+)<.+|\1|g'
}

function end_extension {
    local count

    url_in_file=$(sanitize_url "$url_in_file")
    
    if ( ! url "$url_in_file" || [ -z "$file_in" ] ) &&
	   ( [ -z "$streamer" ] || [ -z "$playpath" ] )
    then
	count=$(get_try_counter "$url_in")

	if ((count < try_end))
	then
	    set_try_counter "$url_in"
	    _log 2

	elif check_connection
	then
	    _log 30

	else
	    _log 31
	    set_exit
	    break_loop=true
	fi
	return 1

    else
	set_try_counter "$url_in" reset
	return 0
    fi
}

function anydownload {
    ## http://anydownload.altervista.org
    local url_in="$1"
    local URL_IN
    local irc_host irc_chan irc_msg
    
    if [[ "$url_in" =~ xweaseldownload\.php ]]
    then
	url_in=$(urldecode "${url_in#*url=}")
	url_in=$(sed -r 's|\s{1}|%20|g' <<< "$url_in")

	URL_IN=$(wget -qO- "$url_in"               |
			grep 'xdcc' 2>/dev/null    |
			head -n1                   |
			sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

    elif [[ "$url_in" =~ IRCdownload\.php ]] &&
	 [[ ! "$url_in" =~ adfly ]]
    then
	html=$(wget -qO- "$url_in")
	echo "$html" >OUT
	
	irc_host=$(grep server0 <<< "$html" |
			     sed -r 's|.+\"([^"]+)\"[^"]+|\1|g')

	irc_chan=$(grep canale0 <<< "$html" |
			  sed -r 's|.+\"\#([^"]+)\"[^"]+|\1|g')

	irc_msg="msg "$(grep 'nome_bot0' <<< "$html" | sed -r 's,.+value=\"([^"]+)\"[^"]+,\1,g')" xdcc send "$(grep numero_pack0 <<< "$html" | sed -r 's,.+\"([^"]+)\"[^"]+$,\1,g')
	
        URL_IN="irc://${irc_host}/${irc_chan}/${irc_msg}"
    fi

    if url "$URL_IN"
    then
	echo "$URL_IN"
	return 0

    else
	echo "$url_in"
	return 1	
    fi    
}

function extension_clicknupload {
    local url_in="$1"
    local html post_data

    if [ "$url_in" != "${url_in//clicknupload.}" ]
    then
	html=$(wget -t1 -T$max_waiting                               \
		    "$url_in"                                        \
		    --user-agent="Firefox"                           \
		    --keep-session-cookies="$path_tmp/cookies.zdl"   \
		    -qO-)
	
	[ -z "$html" ] &&
	    command -v curl >/dev/null && 
	    html=$(curl "$url_in") 

	if [[ "$html" =~ (File Not Found) ]]
	then
	    _log 3

	else
	    input_hidden "$html"
	    post_data+="&method_free=Free Download >>"

	    html=$(wget "$url_in"                       \
			--post-data="$post_data"        \
			-qO-)

	    input_hidden "$html"

	    html=$(wget "$url_in"                       \
			--post-data="$post_data"        \
			-qO-)

	    url_in_file=$(grep downloadbtn <<< "$html" |
				 sed -r "s|.+open\('([^']+)'\).+|\1|g")

	    url "$url_in_file" &&
		return 0
	fi
    fi
    return 1
}

function extension_mega {
    local url_in="$1"
    
    
    if [[ "$url_in" =~ (^https\:\/\/mega\.co\.nz\/|^https\:\/\/mega\.nz\/) ]]
    then
	url_in="${url_in//mega.co.nz/mega.nz}"
	
	id=$(awk -F '!' '{print $2}' <<< "$url_in")

	key=$(awk -F '!' '{print $3}' <<< "$url_in" | sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g')
	b64_hex_key=$(echo -n $key | base64 --decode --ignore-garbage 2> /dev/null | xxd -p | tr -d '\n')
	key[0]=$(( 0x${b64_hex_key:00:16} ^ 0x${b64_hex_key:32:16} ))
	key[1]=$(( 0x${b64_hex_key:16:16} ^ 0x${b64_hex_key:48:16} ))
	key=$(printf "%016x" ${key[*]})

	iv="${b64_hex_key:32:16}0000000000000000"

	json_data=$(wget -qO- --post-data='[{"a":"g","g":1,"p":"'$id'"}]' https://eu.api.mega.co.nz/cs)

	url_in_file="${json_data%\"*}"
	url_in_file="${url_in_file##*\"}"
	
	##    file_in="$key".MEGAenc
	awk -F '"' '{print $6}' <<< "$json_data"             |
	    sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g'       |
	    base64 --decode --ignore-garbage 2> /dev/null    |
	    xxd -p                                           |
	    tr -d '\n' > "$path_tmp"/enc_attr.mdtmp
	
	xxd -p -r "$path_tmp"/enc_attr.mdtmp > "$path_tmp"/enc_attr2.mdtmp
	openssl enc -d -aes-128-cbc -K $key -iv 0 -nopad -in "$path_tmp"/enc_attr2.mdtmp -out "$path_tmp"/dec_attr.mdtmp
	file_in=$(awk -F '"' '{print $4}' "$path_tmp"/dec_attr.mdtmp).MEGAenc
	sanitize_file_in
	
	if [ -z "$url_in_file" ] ||
	       [ -z "$file_in" ]
	then
	    _log 2
	    
	elif ! url "$url_in_file"
	then
	    _log 3
	    
	else
	    #### for POST-PROCESSING:
	    ## openssl enc -d -aes-128-ctr -K $key -iv $iv -in $enc_file -out $out_file
	    echo -e "$key\n$iv" > "$path_tmp"/"$file_in".tmp

	    axel_parts=1
	fi
    fi
}
