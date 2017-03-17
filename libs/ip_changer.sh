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

function newip_add_host {
    local host
    
    if [ -z $no_newip ]
    then
	for host in ${newip_hosts[*]}
	do	
	    [ "$url_in" != "${url_in//$host.}" ] &&
		newip[${#newip[*]}]=$host
	done
    fi
}

function check_ip {
    local ip="$1"
    
    if [ -f "$path_tmp/reconnect" ] &&
	   command -v "${reconnecter%% *}" &>/dev/null
    then
	noproxy
	print_c 4 "\nAvvio programma di riconnessione del modem/router: $reconnecter\n"

	if show_mode_in_tty "$this_mode" "$this_tty"
	then
	    $reconnecter
	    rm -rf "$path_tmp/links_timer.txt"
	else
	    $reconnecter &>/dev/null
	    rm -rf "$path_tmp/links_timer.txt"
	fi
	
    elif [ -f "$path_tmp"/proxy ] &&
	     [[ ! "$(cat "$path_tmp"/proxy)" =~ [0-9.]+ ]]
    then
	unset newip 
	new_ip_proxy
	
    elif [ "${newip[*]}" != "${newip[*]//$ip}" ]
    then
	if [ -f "$path_tmp/reconnect" ] &&
	       command -v "${reconnecter%% *}" &>/dev/null
	then
	    noproxy
	    print_c 4 "\nAvvio programma di riconnessione del modem/router: $reconnecter\n"

	    if show_mode_in_tty "$this_mode" "$this_tty"
	    then
		$reconnecter
		rm -rf "$path_tmp/links_timer.txt"
	    else
		$reconnecter &>/dev/null
		rm -rf "$path_tmp/links_timer.txt"
	    fi

	else
	    new_ip_proxy
	fi

	
    elif [ -s "$path_tmp"/proxy ] &&
	     [[ "$(cat "$path_tmp"/proxy)" =~ [0-9.]+ ]]
	 #[ "$update_defined_proxy" == "true" ]
    then
	export http_proxy=$(cat "$path_tmp"/proxy)
    fi
}

function get_ip {
    declare -n real_ip="$1"
    declare -n proxy_ip="$2"

    if [ -n "$2" ] && [ -s "$path_tmp"/proxy-active ]
    then
	export http_proxy=$(cat "$path_tmp"/proxy-active)
	proxy_ip=$(wget -qO- -t1 -T20 http://indirizzo-ip.com/ip.php)
	unset http_proxy
    fi
    
    real_ip=$(wget -qO- -t1 -T20 http://indirizzo-ip.com/ip.php)
}


function noproxy {
    unset http_proxy
    export http_proxy
}

## servizi che offrono liste di proxy
function ip_adress {
    ## ip-adress.com

    rm -f "$path_tmp/proxy2.tmp"
    
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

function check_speed {	
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
	print_c 0 "${speed[i]}"

	if (( "${num_speed[0]}" == 0 ))
	then
	    break

	elif (( "${num_speed[i]}" >= 25 ))
	then
	    print_c 1 "Velocità di download sufficiente usando il proxy $http_proxy: ${num_speed[i]} KB/s"
	    echo "$http_proxy" > "$path_tmp"/proxy-active
	    return 0
	fi
    done 2>/dev/null
    
    for k in ${num_speed[*]}
    do
    	(( $maxspeed<$k )) && maxspeed=$k 
    done
    
    if (( $maxspeed<$minspeed ))
    then
    	print_c 3 "La massima velocità di download raggiunta usando il proxy è inferiore a quella minima richiesta ($minspeed KB/s)"
	rm -f "$path_tmp"/proxy-active
	return 1

    else
    	print_c 1 "Massima velocità di download raggiunta usando il proxy $http_proxy: $maxspeed KB/s"
    	return 0
    fi 
}

function new_ip_proxy {
    export LANG="$prog_lang"
    export LANGUAGE="$prog_lang"
    
    maxspeed=0
    minspeed=25
    unset speed type_speed search_proxy num_speed
    rm -f "$path_tmp/proxy.tmp"

    if [ -s "$path_tmp"/proxy ]
    then
	proxy_types=( $(cat "$path_tmp"/proxy) )
    fi
    
    ##########################################
    ## tipi di proxy: Anonymous Transparent Elite
    ## da impostare nelle estensioni in cui si fa uso di check_ip:
    ## proxy_types=( ELENCO TIPI DI PROXY )
    ##
    ## predefinito:
    if [ -z "${proxy_types[*]}" ]
    then
	proxy_types=( "Transparent" )
    fi
    ##########################################
    
    while true
    do
	noproxy
	unset proxy
	print_c 1 "\nAggiorna proxy (${proxy_types[*]// /, }):"
	
	line=1
	while [ -z "$proxy" ]
	do		
	    if [ ! -f "$path_tmp/proxy.tmp" ]
	    then
		wget -q -t 1 -T 20                              \
		     --user-agent="$user_agent"                 \
		     ${list_proxy_url[$proxy_server]}           \
		     -qO "$path_tmp/proxy.tmp"
		
		print_c 4 "Ricerca lista proxy $proxy_server: ${list_proxy_url[$proxy_server]}"
	    fi

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
		
		(( $search_proxy >= 100 )) &&
		    print_c 3 "Finora nessun proxy disponibile: tentativo con proxy disattivato" &&
		    noproxy &&
		    break
	    fi

	    if (( "$line" >= "$max" )) ||
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

	(( $search_proxy >= 100 )) && break
	unset search_proxy num_speed
	
	http_proxy="$proxy"
	export http_proxy
	print_c 0 "Proxy: $http_proxy ($proxy_type)\n"

	unset myip
	unset speed

	check_speed && break ||
		show_downloads

    done
    unset maxspeed 
    
    rm -f "$path_tmp/proxy.tmp"

    export LANG="$user_lang"
    export LANGUAGE="$user_language"
    print_c 4 "\nAvvio connessione: $url_in ..."
}

