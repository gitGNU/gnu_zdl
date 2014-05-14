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


#### change IP address

function newip_add_provider {
    if [ -z $no_newip ]; then
	for provider in ${newip_providers[*]} ; do	
	    [ "$url_in" != "${url_in//$provider.}" ] && newip[${#newip[*]}]=$provider
	done
    fi
}

function check_ip {
    if [ "${newip[*]}" != "${newip[*]//$1}" ]; then 
	if [ ! -z "$admin" ] && [ ! -z "$passwd" ]; then
	    [ "$multi" == "1" ] && new_ip_proxy
	    [ "$multi" == "0" ] && new_ip_router
	else
	    new_ip_proxy
	fi
    fi
}

function my_ip {
    #myip=`wget -q -O - -t 1 -T 20 checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
    myip=$(wget -q -O - -t 1 -T 20 http://indirizzo-ip.com/ip.php)
    echo
    separator "─"
    if [ ! -z "$myip" ]; then
	print_c 1 "Indirizzo IP: $myip"
    else
	print_c 3 "Indirizzo IP non rilevato"
    fi
    separator "─"
    echo
}

# function add_newip {
# 	[ "$url_in" != "${url_in//mediafire.}" ] && newip[${#newip[*]}]=mediafire
# 	[ "$url_in" != "${url_in//uploaded.}" ] && newip[${#newip[*]}]=uploaded
# 	#[ "$url_in" != "${url_in//shareflare.}" ] && newip[${#newip[*]}]=shareflare
# 	[ "$url_in" != "${url_in//easybytez.}" ] && newip[${#newip[*]}]=easybytez
# 	#[ "$url_in" != "${url_in//sharpfile.}" ] && newip[${#newip[*]}]=sharpfile
# 	[ "$url_in" != "${url_in//billionuploads.}" ] && newip[${#newip[*]}]=billionuploads
# }

function new_ip_router {
    noproxy
    if [ ! -z "$admin" ] && [ ! -z "$passwd" ]; then
	print_c 1 "Cambio indirizzo IP..."
	wget --http-passwd=$passwd --http-user=$admin 192.168.0.1/stanet.stm  -O - &>/dev/null
	wget --http-passwd=$passwd --http-user=$admin --post-data="disconnect=1" 192.168.0.1/cgi-bin/statusprocess.exe -O - &>/dev/null
    else
	echo
	print_c 3 "Funzione di cambio indirizzo IP via router disattivata"
    fi
}

function noproxy {
    unset http_proxy
    export http_proxy
}

## servizi che offrono liste di proxy
function ip_adress {
    ## ip-adress.com
    
    for proxy_type in ${proxy_types[*]}; do
	less "$path_tmp/proxy.tmp"|grep "Proxy_Details" |grep "${proxy_type}" >> "$path_tmp/proxy2.tmp"
    done
    
    max=`wc -l "$path_tmp/proxy2.tmp" | awk '{ print($1) }'`
    
    string_line=`cat "$path_tmp/proxy2.tmp" |sed -n "${line}p"`
    
    proxy="${string_line#*Proxy_Details\/}"
    [ "$proxy" != "${proxy%:Anonymous*}" ] && proxy_type="Anonymous"
    [ "$proxy" != "${proxy%:Transparent*}" ] && proxy_type="Transparent"
    [ "$proxy" != "${proxy%:Elite*}" ] && proxy_type="Elite"
    proxy="${proxy%:${proxy_type}*}"
}

# function proxy_list {
#     ## proxy-list.org
    
#     proxy_tmp=$( cat "$path_tmp/proxy.tmp" |grep "ago" )
#     proxy_tmp=${proxy_tmp//"</tr>"/"\n"}
#     for proxy_type in ${proxy_types[*]}; do
# 	echo -e "$proxy_tmp" |grep "${proxy_type}" >> "$path_tmp/proxy2.tmp"
#     done
#     max=`wc -l "$path_tmp/proxy2.tmp" | awk '{ print($1) }'`
    
#     string_line=`cat "$path_tmp/proxy2.tmp" |sed -n "${line}p"`

#     proxy="${string_line#*'<td>'}"
#     proxy="${proxy%%'</td>'*}"
# }			

function proxy_list {
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

    if [ -f "$path_tmp/proxy2.tmp" ]; then
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
    unset close unreached speed num_speed type_speed
    rm -f "$path_tmp/proxy.tmp"
    while true; do
	proxy=""
	## tipi di proxy: Anonymous Transparent Elite
	if [ -z "${proxy_types[*]}" ]; then 
	    proxy_types=( "Transparent" )
	fi

	[ "$url_in" != "${url_in//uploaded.}" ] && proxy_types=( "Anonymous" "Elite" )
	#[ "$url_in" != "${url_in//mediafire.}" ] && proxy_types=( "Elite" )
	#[ "$url_in" != "${url_in//uload.}" ] && proxy_types=( "Anonymous" "Elite" )
	#[ "$url_in" != "${url_in//shareflare.}" ] && proxy_types=( "Transparent" )
	#[ "$url_in" != "${url_in//easybytez.}" ] && proxy_types=( "Transparent" )
	[ "$url_in" != "${url_in//glumbouploads.}" ] && proxy_types=( "Anonymous" "Elite" )
	ptypes="${proxy_types[*]}"
	print_c 1 "Aggiorna proxy (${ptypes// /, }):"
	old=$http_proxy
	
	noproxy
	line=1
	while [ -z "$proxy" ] ; do		
	    if [ ! -f "$path_tmp/proxy.tmp" ]; then
		wget -q -t 1 -T 20 --user-agent="Anonimo" ${list_proxy_url[$proxy_server]} -O "$path_tmp/proxy.tmp" &>/dev/null
	    fi
	    rm -f "$path_tmp/proxy2.tmp"
	    $proxy_server
	    ##
	    ## CODICE PER  http://www.ip-adress.com/proxy_list/  ---> CON UNA SOLA "d"
	    ##
	    # for proxy_type in ${proxy_types[*]}; do
	    # 	less "$path_tmp/proxy.tmp"|grep "Proxy_Details" |grep "${proxy_type}" >> "$path_tmp/proxy2.tmp"
	    # done
	    #
	    # max=`wc -l "$path_tmp/proxy2.tmp" | awk '{ print($1) }'`
	    # 		#cat "$path_tmp/proxy2.tmp"
	    # string_line=`cat "$path_tmp/proxy2.tmp" |sed -n "${line}p"`
	    #
	    # proxy="${string_line#*Proxy_Details\/}"
	    # [ "$proxy" != "${proxy%:Anonymous*}" ] && proxy_type="Anonymous"
	    # [ "$proxy" != "${proxy%:Transparent*}" ] && proxy_type="Transparent"
	    # [ "$proxy" != "${proxy%:Elite*}" ] && proxy_type="Elite"
	    # proxy="${proxy%:${proxy_type}*}"
	    ##
	    z=$(( ${#proxy_done[*]}-1 ))
	    if (( $z<0 )) || [ "$z" == "" ]; then z=0 ; fi
	    
	    for p in `seq 0 $z`; do
		if [ "${proxy_done[$p]}" == "$proxy" ]; then
		    proxy=""
		fi
	    done
	    
	    if [ "$string_line" == "" ]; then
		echo -n -e "."
		sleeping 3
		(( search_proxy++ ))
		[ $search_proxy == 100 ] && print_c 3 "Finora nessun proxy disponibile: tentativo con proxy disattivato" && noproxy && close=true && break
	    fi
	    if [ $line == $max ] || [ "$string_line" == "" ]; then
		rm -f "$path_tmp/proxy.tmp"
		line=0
	    fi
	    (( line++ ))
	    [ "$proxy" != "" ] && [ "${proxy_done[*]}" == "${proxy_done[*]//$proxy}" ] && proxy_done[${#proxy_done[*]}]="$proxy"
	done
	unset search_proxy
	[ ! -z $close ] && break
	http_proxy=$proxy
	export http_proxy
	echo -n "Proxy: $http_proxy ($proxy_type)"
	echo
	unset myip
	print_c 2 "Test velocità di download:"
	i=0
	while (( $i<3 )); do
	    i=${#speed[*]}
	    speed[$i]=`wget -t 1 -T $max_waiting -O /dev/null "$url_in" 2>&1 | grep '\([0-9.]\+ [KM]B/s\)'`
	    if [ ! -z "${speed[$i]}" ]; then
		speed[$i]="${speed[$i]#*'('}"
		speed[$i]="${speed[$i]%%)*}"
		
		type_speed[$i]="${speed[$i]//[0-9. ]}"
		num_speed[$i]="${speed[$i]//${type_speed[$i]}}"
		num_speed[$i]="${num_speed[$i]//[ ]*}"
		num_speed[$i]="${num_speed[$i]//[.,]*}"
		
		if [ "${type_speed[$i]}" == 'B/s' ]; then
		    num_speed[$i]="0"
		elif [ "${type_speed[$i]}" == 'MB/s' ]; then
		    num_speed[$i]=$(( ${num_speed[$i]}*1024 ))
		fi
	    else
		speed[$i]="0 KB/s"
		num_speed[$i]="0"
		type_speed[$i]='KB/s'
	    fi
	    
	    echo "${speed[$i]}"
	done 2>/dev/null
	
	if [ -z $unreached ]; then
	    
	    for k in ${num_speed[*]}; do
		if (( $maxspeed<$k )); then 
		    maxspeed=$k 
		fi 
	    done
	    
	    if (( $maxspeed<$minspeed )); then
		print_c 3 "La massima velocità di download raggiunta usando il proxy è inferiore a quella minima richiesta ($minspeed KB/s)"
	    else
		print_c 1 "Massima velocità di download raggiunta usando il proxy $http_proxy: $maxspeed KB/s"
		break
	    fi 2>/dev/null
	fi
	unset unreached speed
    done
    unset maxspeed
    echo
    rm -f "$path_tmp/proxy.tmp"
    old_proxy="$proxy"
    export LANG="$user_lang"
    export LANGUAGE="$user_language"
}
