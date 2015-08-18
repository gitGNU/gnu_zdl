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

#### change IP address

function newip_add_provider {
    if [ -z $no_newip ]
    then
	for provider in ${newip_providers[*]}
	do	
	    [ "$url_in" != "${url_in//$provider.}" ] && newip[${#newip[*]}]=$provider
	done
    fi
}

function check_ip {
    if [ "$reconnect_sh" == true ] &&
	   [ -n "$(command -v $reconnecter 2>/dev/null)" ]
    then
	noproxy
	print_c 4 "\nAvvio programma di riconnessione del modem/router: $reconnecter\n"
	$reconnecter
	
    elif [ "$update_proxy" == true ]
    then
	unset newip update_proxy
	new_ip_proxy
	update_proxy_others="true"
	
    elif [ "${newip[*]}" != "${newip[*]//$1}" ]
    then
	if [ "$reconnect_sh" == true ] &&
	       [ -n "$(command -v $reconnecter 2>/dev/null)" ]
	then
	    noproxy
	    print_c 4 "\nAvvio programma di riconnessione del modem/router: $reconnecter\n"
	    $reconnecter 

	else
	    new_ip_proxy
	fi

    elif [ "$update_defined_proxy" == "true" ]
    then
	export http_proxy=$defined_proxy
    fi
}

function my_ip {
    #myip=`wget -q -O - -t 1 -T 20 checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
    myip=$(wget -q -O - -t 1 -T 20 http://indirizzo-ip.com/ip.php)
    print_c 0 "\n"
    separator-
    if [ -n "$myip" ]
    then
	print_c 1 "Indirizzo IP: $myip"

    else
	print_c 3 "Indirizzo IP non rilevato"
    fi

    separator-
    print_c 0 "\n"
}


function noproxy {
    unset http_proxy
    export http_proxy
}

## servizi che offrono liste di proxy
function ip_adress {
    ## ip-adress.com
    
    for proxy_type in ${proxy_types[*]}
    do
	grep "Proxy_Details" "$path_tmp/proxy.tmp" |
	    grep "${proxy_type}" >> "$path_tmp/proxy2.tmp"
    done

    max=$(wc -l < "$path_tmp/proxy2.tmp")
    string_line=$(sed -n "${line}p" "$path_tmp/proxy2.tmp")
    
    proxy="${string_line#*Proxy_Details\/}"
    [ "$proxy" != "${proxy%:Anonymous*}" ] && proxy_type="Anonymous"
    [ "$proxy" != "${proxy%:Transparent*}" ] && proxy_type="Transparent"
    [ "$proxy" != "${proxy%:Elite*}" ] && proxy_type="Elite"
    proxy="${proxy%:${proxy_type}*}"
}

function proxy_list {
    ## proxy-list.org
    for proxy_type in ${proxy_types[*]}
    do
	html=$(grep -B 4 "${proxy_type}" "$path_tmp/proxy.tmp" |grep class)
    done
    n=$(( $(wc -l <<< "$html")/4 ))
    proxy_type=$(sed -n $(( ${line}*4 ))p <<< "$html")
    proxy_type="${proxy_type%%'</'*}"
    proxy_type="${proxy_type##*>}"

    proxy=$(sed -n $(( ${line}*4-3 ))p <<< "$html")
    proxy="${proxy#*proxy\">}"
    proxy="${proxy%<*}"
}

function proxy_list_old {
    ## proxy-list.org
    unset proxy_ip proxy_type
    
    proxy_ip_list=$( cat "$path_tmp/proxy.tmp" |grep "li class=\"proxy" |grep -v Proxy)

    for ((i=1; i<=$(wc -l <<< "$proxy_ip_list"); i++)); do
	proxy_ip_line=$(sed -n ${i}p <<< "$proxy_ip_list")
	proxy_ip_line="${proxy_ip_line#*>}"
	proxy_ip[ ${#proxy_ip[*]} ]="${proxy_ip_line%<*}"
    done
    
    proxy_type_list=$( cat "$path_tmp/proxy.tmp" |grep "li class=\"type" |grep -v Type)
    for ((i=1; i<=$(wc -l <<< "$proxy_type_list"); i++)); do
	proxy_type_line=$(sed -n ${i}p <<< "$proxy_type_list")
	proxy_type_line="${proxy_type_line//'<strong>'}"
	proxy_type_line="${proxy_type_line#*>}"
	proxy_type[ ${#proxy_type[*]} ]="${proxy_type_line%%<*}"
    done

    for proxytype in ${proxy_types[*]}; do
	for ((i=0; i<${#proxy_ip[*]}; i++)); do
	    if [ "$proxytype" == "${proxy_type[$i]}" ]; then
		echo "${proxy_ip[$i]} ${proxy_type[$i]}" >> "$path_tmp/proxy2.tmp"
	    fi
	done
    done

    if [ -f "$path_tmp/proxy2.tmp" ]
    then
	max=`wc -l "$path_tmp/proxy2.tmp" | awk '{ print($1) }'`
	proxy=`cat "$path_tmp/proxy2.tmp" |sed -n "${line}p"|awk '{print $1}'`
	proxy_type=`cat "$path_tmp/proxy2.tmp" |sed -n "${line}p"|awk '{print $2}'`
    else
	unset proxy proxy_type max
    fi
}			


function new_ip_proxy {
    noproxy
    export LANG="$prog_lang"
    export LANGUAGE="$prog_lang"
    
    maxspeed=0
    minspeed=25
    unset close unreached speed type_speed
    rm -f "$path_tmp/proxy.tmp"
    
    while true
    do
	unset proxy
	## tipi di proxy: Anonymous Transparent Elite
	if [ -z "${proxy_types[*]}" ]
	then 
	    proxy_types=( "Transparent" )
	fi

	#[ "$url_in" != "${url_in//mediafire.}" ] && proxy_types=( "Elite" )
	#[ "$url_in" != "${url_in//uload.}" ] && proxy_types=( "Anonymous" "Elite" )
	#[ "$url_in" != "${url_in//shareflare.}" ] && proxy_types=( "Transparent" )
	[ "$url_in" != "${url_in//uploaded.}" ] && proxy_types=( "Anonymous" "Elite" )
	[ "$url_in" != "${url_in//easybytez.}" ] && proxy_types=( "Transparent" "Anonymous" "Elite" )
	[ "$url_in" != "${url_in//glumbouploads.}" ] && proxy_types=( "Anonymous" "Elite" )

	ptypes="${proxy_types[*]}"
	print_c 1 "\nAggiorna proxy (${ptypes// /, }):"
	old=$http_proxy
	
	noproxy
	line=1
	while [ -z "$proxy" ]
	do		
	    if [ ! -f "$path_tmp/proxy.tmp" ]
	    then
		#wget -q -t 1 -T 20 --post-data="cmd=pr0xylist" --user-agent="Anonimo" ${list_proxy_url[$proxy_server]} -O "$path_tmp/proxy.tmp" &>/dev/null
		wget -q -t 1 -T 20                              \
		     --user-agent="$user_agent"                 \
		     ${list_proxy_url[$proxy_server]}           \
		     -qO "$path_tmp/proxy.tmp"
		
		print_c 4 "Ricerca lista proxy $proxy_server: ${list_proxy_url[$proxy_server]}"
	    fi
	    rm -f "$path_tmp/proxy2.tmp"
	    [ -f "$path_tmp/proxy.tmp" ] && $proxy_server

	    for ((p=0; p<${#proxy_done[*]}; p++))
	    do
		[ "${proxy_done[$p]}" == "$proxy" ] &&
		    unset proxy
	    done
	    
	    if [ -z "$string_line" ]
	    then
		sleeping 3
		(( search_proxy++ ))
		
		[ $search_proxy == 100 ] &&
		    print_c 3 "Finora nessun proxy disponibile: tentativo con proxy disattivato" &&
		    noproxy &&
		    close=true &&
		    break
	    fi

	    if [ "$line" == "$max" ] ||
		   [ -z "$string_line" ]
	    then
		rm -f "$path_tmp/proxy.tmp"
		line=0
	    fi
	    
	    [ -n "$line" ] && (( line++ ))
	    [ -n "$proxy" ] &&
		[ "${proxy_done[*]}" == "${proxy_done[*]//$proxy}" ] &&
		proxy_done[${#proxy_done[*]}]="$proxy"
	done
	
	unset search_proxy num_speed
	[ -n "$close" ] && break
	http_proxy="$proxy"
	export http_proxy
	print_c 0 "Proxy: $http_proxy ($proxy_type)\n"

	unset myip
	print_c 2 "\nTest velocità di download:"

	i=0
	while (( $i<3 ))
	do
	    i=${#speed[*]}
	    #speed[$i]=`wget -t 1 -T $max_waiting -O /dev/null "http://indirizzo-ip.com/ip.php" 2>&1 | grep '\([0-9.]\+ [KM]B/s\)'`
	    #speed[$i]=`wget -t 1 -T $max_waiting -O /dev/null "$url_in" 2>&1 | grep '\([0-9.]\+ [KM]B/s\)'`

	    speed[$i]=$(wget -t 1 -T $max_waiting                \
			     --user-agent="$user_agent"          \
			     -O /dev/null                        \
			     "${list_proxy_url[$proxy_server]}"  \
			     2>&1 | grep '\([0-9.]\+ [KM]B/s\)')
	    

	    if [ -n "${speed[$i]}" ]
	    then
		speed[$i]="${speed[$i]#*'('}"
		speed[$i]="${speed[$i]%%)*}"
		
		type_speed[$i]="${speed[$i]//[0-9. ]}"
		num_speed[$i]="${speed[$i]//${type_speed[$i]}}"
		num_speed[$i]="${num_speed[$i]//[ ]*}"
		num_speed[$i]="${num_speed[$i]//[.,]*}"

		if [ "${type_speed[$i]}" == 'B/s' ]
		then
		    num_speed[$i]="0"

		elif [ "${type_speed[$i]}" == 'MB/s' ]
		then
		    num_speed[$i]=$(( ${num_speed[$i]}*1024 ))
		fi
	    else
		speed[$i]="0 KB/s"
		num_speed[$i]="0"
		type_speed[$i]='KB/s'
	    fi
	    print_c 0 "${speed[$i]}"

	    if [ "${num_speed[0]}" == 0 ]
	    then
		break
	    fi
	done 2>/dev/null
	
	if [ -z "$unreached" ]
	then
	    for k in ${num_speed[*]}
	    do
		(( $maxspeed<$k )) &&  maxspeed=$k 
	    done
	    
	    if (( $maxspeed<$minspeed ))
	    then
		print_c 3 "La massima velocità di download raggiunta usando il proxy è inferiore a quella minima richiesta ($minspeed KB/s)"

	    else
		print_c 1 "Massima velocità di download raggiunta usando il proxy $http_proxy: $maxspeed KB/s"
		break
	    fi 
	fi
	unset unreached speed
    done
    unset maxspeed
    
    rm -f "$path_tmp/proxy.tmp"
    old_proxy="$proxy"
    export LANG="$user_lang"
    export LANGUAGE="$user_language"
    print_c 4 "\nAvvio connessione: $url_in ..."
}
