#!/bin/bash 
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

path_usr="/usr/local/share/zdl"
path_tmp=".zdl_tmp"
file_data="/tmp/zdl.d/data.json"
file_paths="/tmp/zdl.d/paths.txt"

source $path_usr/libs/core.sh
source $path_usr/libs/downloader_manager.sh
source $path_usr/libs/DLstdout_parser.sh
source $path_usr/libs/utils.sh
source $path_usr/libs/log.sh

json_flag=true

#### HTTP:
declare -i DEBUG=1
declare -i VERBOSE=0
declare -a REQUEST_HEADERS
declare    REQUEST_URI=""
declare -a HTTP_RESPONSE=(
    [200]="OK"
    [400]="Bad Request"
    [403]="Forbidden"
    [404]="Not Found"
    [405]="Method Not Allowed"
    [500]="Internal Server Error")
declare DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
    "Date: $DATE"
    "Expires: $DATE"
    "Server: Slash Bin Slash Bash"
)

function recv {
    ((${DEBUG})) &&
	echo "< $@" >>zdl_server_log.txt
}

function send {
    ((${DEBUG})) &&
	echo "> $@" >>zdl_server_log.txt

    echo "$*"
}

function add_response_header {
    RESPONSE_HEADERS+=("$1: $2")
}

function send_response_header {
    send "HTTP/1.1 $1 ${HTTP_RESPONSE[$1]}"

    for h in "${RESPONSE_HEADERS[@]}"
    do
	send "$h"
    done
    send
}

function send_response {
    local code="$1"
    local file="$2"
    local mime=""
    local transfer_stats=""
    local tmp_stat_file="/tmp/_send_response_$$_"

    send_response_header "$code"

    if [ -s "$file" ]
    then
	mime=$(get_mime_server "$file")
	add_response_header "Content-Type" "$mime"
	add_response_header "Content-Length" "$(size_file "$file")"

	if [[ "$mime" =~ text\/html ]]
	then
	    template=$(cat "$file")

	else
	    cat "$file"
	    return
	fi

    elif [ -n "$file" ]
    then
	template="$file"
    fi

    [ -n "$template" ] &&
	[[ "$template" =~ __START_PATH__ ]] &&
	sed -r "s|__START_PATH__|$PWD|g" <<< "$template"
	
    #echo
    # if ((${VERBOSE}))
    # then
    # 	## Use dd since it handles null bytes
    # 	dd 2>"${tmp_stat_file}" < "${file}"
    # 	transfer_stats=$(<"${tmp_stat_file}")
    # 	echo -en ">> Transferred: ${file}\n>> $(awk '/copied/{print}' <<< "${transfer_stats}")\n" >&2
    # 	rm "${tmp_stat_file}"
	
    # else
    # 	## Use dd since it handles null bytes
    # 	dd 2>"${DUMP_DEV}" < "${file}"
    # fi
}

function send_response_ok_exit {
    send_response "200" "$1"
    exit 0
}

function fail_with {
    send_response "$1" <<< "$1 ${HTTP_RESPONSE[$1]}"
    exit 1
}

function get_mime_server {
    local mime
    case "$1" in
        *\.css)
	    mime="text/css"
	    ;;
	*\.js)
	    mime="text/javascript"
	    ;;
	*\.json)
	    mime="application/json"
	    ;;
	*)
	    mime=$(get_mime "${file}")
	    ;;
    esac

    if [ -n "$mime" ]
    then
	echo "$mime"
	return 0

    else
	return 1
    fi
}

function serve_file {
    local file="$1"

    if [ -s "$file" ]
    then
	if [[ "$http_method" =~ ^(GET|POST)$ ]]
	then
	    send_response_ok_exit "$file"

	else
	    cat "$file"
	    exit
	fi
	
    else
	return 1
    fi
}

# function urldecode {
#     [ "${1%/}" == "" ] && echo "/" ||
# 	    echo -e "$(sed 's/%\([[:xdigit:]]\{2\}\)/\\\x\1/g' <<< "${1%/}")"
# }

function serve_static_string {
    add_response_header "Content-Type" "text/plain"
    send_response_ok_exit <<< "$1"
}

function on_uri_match {
    local regex="$1"
    shift
    [[ "${REQUEST_URI}" =~ $regex ]] && 
        "$@" "${BASH_REMATCH[@]}"
}

function unconditionally {
    "$@" "$REQUEST_URI"
}




# function create_json {
#     if [ -s /tmp/zdl.d/paths.txt ]
#     then
# 	echo -ne '{' >/tmp/zdl.d/data.json

# 	while read path
# 	do
# 	    cd "$path"
# 	    data_stdout
# 	    echo -en "," >>/tmp/zdl.d/data.json
# 	done </tmp/zdl.d/paths.txt

# 	sed -r "s|,$|}\n|g" -i /tmp/zdl.d/data.json
#     fi
# }

function create_json {
    if [ -s "$file_paths" ]
    then
	echo -ne '[' >"$file_data"

	while read path
	do
	    cd "$path"
	    data_stdout
	    echo -en "," >>"$file_data"
	done <"$file_paths"

	sed -r "s|,$|]\n|g" -i "$file_data"
	
	return 0
    fi
    return 1
}

function clean_data {
    echo -e "$1" | tr -d "\r"
}


function get_file_output {
    local file="$1"
    if [[ "$file" =~ ^\/tmp\/zdl.d\/ ]]
    then
	echo "$file"

    else
	if [ "$file" == '/' ] ||
	       [ "$file" != "${file//'?'}" ]
	then
	    file=index.html
	fi
	echo "$path_usr/webui/${file#\/}"
    fi
}

function run_cmd {
    local line=( "$@" )

    case "${line[0]}" in
    	get-data)
	    file_output="$file_data"
	    if [ -z "$http_method" ]
	    then
		cat "$file_data"
		return
	    fi
	    ;;
	del-link)
	    ## [1]=PATH [>1]=LINK
	    cd "${line[1]}"
	    for ((i=2; i<${#line[@]}; i++))
	    do
		set_link - "${line[2]}"
	    done
	    ;;
	add-link)
	    ## [1]=PATH [>1]=LINK
	    cd "${line[1]}"
	    for ((i=2; i<${#line[@]}; i++))
	    do
		set_link + "${line[2]}"
	    done
	    ;;
	stop-link)
	    ## [1]=(PATH|ALL); [>1]=(LINK|ALL); 
	    ;;
	get-downloader)
	    ## [1]=PATH; [2]=DOWNLOADER
	    ;;
	set-downloader)
	    ## [1]=(PATH|ALL); [2]=DOWNLOADER
	    ;;
	get-number)
	    ## [1]=PATH; [2]=NUMBER:(0->...)
	    ;;
	set-number)
	    ## [1]=PATH oppure 'ALL' [2]=NUMBER:(0->...)
	    ;;
	clean)
	    ## [1]=PATH oppure 'ALL'
	    ;;
	kill-zdl)
	    ## [1]=PATH oppure 'ALL'
	    ;;
    esac
}

function run_data {
    local data=( ${1//'&'/ } )
    local name value last
    local line_cmd

    urldecode "${data[*]}" >>RUN_DATA

    for ((i=0; i<${#data[*]}; i++))
    do
	name=$(urldecode "${data[i]%'='*}")
	value=$(urldecode "${data[i]#*'='}")

	case "$name" in
	    cmd)
		line_cmd=( "$value" )
		last="$name"

		echo "${line_cmd[0]}" >>VALUE_CMD
		;;
	    path)
		if [ "$last" == cmd ]
		then
		    line_cmd+=( "$value" )
		    last=$name
		fi
		;;
	    link)
	    	if [[ "$last" =~ ^(path|link)$ ]]
		then
		    line_cmd+=( "$value" )
		    last=$name
		fi
		;;
	    downloader|number)
		if [ "$last" == path ]
		then
		    line_cmd+=( "$value" )
		    last=$name
		fi
		;;
	esac
    done

    [ -n "${line_cmd[*]}" ] && run_cmd "${line_cmd[@]}"
}

function http_server {
    case $http_method in
	GET)
	    [[ "${line[*]}" =~ keep-alive ]] &&
		{
		    echo  "${line[*]}" >>KEEP
		    if [ -n "$GET_DATA" ]
		    then
			run_data "$GET_DATA"
		    fi

		    if [ -n "$file_output" ]
		    then
			[ "$file_output" == "$file_data" ] &&
			    create_json
			
			serve_file "$file_output"

		    else
			exit
		    fi
		}
	    ;;
	
	POST)
	    [ "${line[0]}" == 'Content-Length:' ] &&
		length=$(clean_data "${line[1]}")
	    
	    if [[ "$length" =~ ^[0-9]+$ ]] && ((length>0)) &&
		   [ -z "$postdata" ]
	    then
		read -n 0
		read -n $length POST_DATA
		
		## post_data[INPUT_NAME]=URLENCODED_VALUE
		# declare -A post_data
		# eval post_data=( $(tr '&' ' ' <<< "$POST_DATA" |
		# 			  sed -r 's|([^ ]+)=([^ ]+)|[\1]="\2"|g') )

		# run_command "${post_data[cmd]}"                 \
		# 	    "$(urldecode ${post_data[path]})"   \
		# 	    "$(urldecode ${post_data[link]})"

		run_data "$POST_DATA"
		serve_file "$file_output"
	    fi
	    ;;
	*)
	    return 1
	    ;;
    esac
    return 0
}

while read -a line 
do
    recv "${line[*]}"
    
    case ${line[0]} in
	GET)
	    unset GET_DATA file_output
	    http_method=GET
	    file_output=$(get_file_output "${line[1]}")
	    
	    if [[ "${line[1]}" =~ '?' ]]
	    then
	    	GET_DATA=$(clean_data "${line[1]#*\?}")
	    fi
	    ;;
	POST)
	    http_method=POST
	    file_output=$(get_file_output "${line[1]}")
	    ;;
	*)
	    http_server ||
		run_cmd "${line[@]}"
	    ;;
    esac
done

