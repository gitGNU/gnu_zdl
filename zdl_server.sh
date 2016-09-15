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
template_index="$path_usr/webui/index.html"
path_tmp=".zdl_tmp"

path_server="/tmp/zdl.d"
server_data="$path_server/data.json"
server_paths="$path_server/paths.txt"
server_index="$path_server/index.html"

source $path_usr/libs/core.sh
source $path_usr/libs/downloader_manager.sh
source $path_usr/libs/DLstdout_parser.sh
source $path_usr/libs/utils.sh
source $path_usr/libs/log.sh

json_flag=true

## node.js:
if [ -d /cygdrive ] &&
       ! command -v node &>/dev/null &&
       [ -f "/usr/local/share/zdl/node.exe" ]
then
    chmod 777 /usr/local/share/zdl/node.exe
    nodejs="/usr/local/share/zdl/node.exe"

elif command -v nodejs &>/dev/null
then
    nodejs=nodejs

elif command -v node &>/dev/null
then
    nodejs=node
fi


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
##########



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

    if [ -f "$file" ]
    then
	mime=$(get_mime_server "$file")
	add_response_header "Content-Type" "$mime"
	add_response_header "Content-Length" "$(size_file "$file")"
	send_response_header "$code"
	
	cat "$file"
    fi
	
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

    if [ -f "$file" ]
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


function create_json {
    if [ -s "$server_paths" ]
    then
	echo -ne '[' >"$server_data"

	while read path
	do
	    cd "$path"
	    data_stdout
	    echo -en "," >>"$server_data"
	done <"$server_paths"

	sed -r "s|,$|]\n|g" -i "$server_data"
	
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
	    template="$template_index"
	    file="$server_index"

	else
	    file="$path_usr/webui/${file#\/}"
	fi

	if [ -f "$template" ] &&
	       grep '__START_PATH__' "$template" &>/dev/null
	then
	    sed -r "s|__START_PATH__|$PWD|g" "$template" >"$file"		
	fi
	
	echo "$file"
    fi
}

function run_cmd {
    local line=( "$@" )
    local file link pid

    case "${line[0]}" in
    	get-data)
	    create_json
	    file_output="$server_data"
	    if [ -z "$http_method" ]
	    then
		cat "$server_data"
		return
	    fi
	    ;;

	del-link)
	    ## PATH -> LINK ~ PID
	    create_json
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    cd "${line[i]}"

		if url "${line[i]}"
		then
		    link="${line[i]}"

		    res=$($nodejs -e "
var path = '$PWD'; 
var link = '$link'; 
var json = $(cat $server_data);
var out; 
for (var i = 0; i<json.length; i += 1) {
  if (json[i]['path'] === path && json[i]['link'] === link) {
    out = 'pid=' + json[i]['pid'] + '; ' + 'file=\"' + json[i]['file'] + '\";';
    break;
  }
}
console.log(out);
                    ")

		    eval $res
		    set_link - "$link"
		    kill -9 "$pid" &>/dev/null 
		    rm -f "$file" "$file".st "$file".aria2 "$file".zdl "$path_tmp"/"${file}_stdout.tmp"
		    unset link pid file
		fi
	    done
	    ;;

	add-link)
	    ## PATH -> LINK
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    cd "${line[i]}"

		## link
		url "${line[i]}" &&		    
		    set_link + "${line[i]}"
	    done
	    ;;
	stop-link)
	    ## PATH -> LINK ~ PID
	    create_json
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    cd "${line[i]}"

		if url "${line[i]}"
		then
		    link="${line[i]}"

		    res=$($nodejs -e "
var path = '$PWD'; 
var link = '$link'; 
var json = $(cat $server_data);
var out; 
for (var i = 0; i<json.length; i += 1) {
  if (json[i]['path'] === path && json[i]['link'] === link) {
    out = 'pid=' + json[i]['pid'] + '; ' + 'file=\"' + json[i]['file'] + '\";';
    break;
  }
}
console.log(out);
                    ")

		    eval $res
		    kill -9 "$pid" &>/dev/null 
		    unset link pid file
		fi
	    done
	    
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
    local line_cmd=()

    for ((i=0; i<${#data[*]}; i++))
    do
	name=$(urldecode "${data[i]%'='*}")
	value=$(urldecode "${data[i]#*'='}")
	line_cmd+=( "$value" )
    done

    [ -n "${line_cmd[*]}" ] && run_cmd "${line_cmd[@]}"
}

function http_server {
    case $http_method in
	GET)
	    [[ "${line[*]}" =~ keep-alive ]] &&
		{
		    if [ -n "$GET_DATA" ]
		    then
			run_data "$GET_DATA"
		    fi

		    if [ -f "$file_output" ]
		    then
			[ "$file_output" == "$server_data" ] &&
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
	    unset POST_DATA file_output
	    http_method=POST
	    file_output=$(get_file_output "${line[1]}")
	    ;;
	*)
	    http_server ||
		run_cmd "${line[@]}"
	    ;;
    esac
done

