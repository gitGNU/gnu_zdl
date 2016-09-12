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
    "Content-Type: text/html"
)

function recv {
    ((${VERBOSE})) &&
	echo "< $@" >&2
}

function send {
    ((${VERBOSE})) &&
	echo "> $@" >&2

    echo "$*"
}

function add_response_header {
    RESPONSE_HEADERS+=("$1: $2")
}

function send_response_binary {
    local code="$1"
    local file="${2}"
    local transfer_stats=""
    local tmp_stat_file="/tmp/_send_response_$$_"

    send "HTTP/1.1 $1 ${HTTP_RESPONSE[$1]}"

    for i in "${RESPONSE_HEADERS[@]}"
    do
	send "$i"
    done
    send

    if ((${VERBOSE}))
    then
	## Use dd since it handles null bytes
	dd 2>"${tmp_stat_file}" < "${file}"
	transfer_stats=$(<"${tmp_stat_file}")
	echo -en ">> Transferred: ${file}\n>> $(awk '/copied/{print}' <<< "${transfer_stats}")\n" >&2
	rm "${tmp_stat_file}"
	
    else
	## Use dd since it handles null bytes
	dd 2>"${DUMP_DEV}" < "${file}"
    fi
}

function send_response {
    local code="$1"
    send "HTTP/1.1 $1 ${HTTP_RESPONSE[$1]}"

    for i in "${RESPONSE_HEADERS[@]}"
    do
        send "$i"
    done
    send

    while IFS= read -r line
    do
	send "${line}"
    done
}

function send_response_ok_exit {
    send_response 200
    exit 0
}

function send_response_ok_exit_binary {
    send_response_binary 200  "${1}"
    exit 0
}

function fail_with {
    send_response "$1" <<< "$1 ${HTTP_RESPONSE[$1]}"
    exit 1
}

function serve_file {
    local file="$1"
    local CONTENT_TYPE=""

    case "${file}" in
        *\.css)
	    CONTENT_TYPE="text/css"
	    ;;
	*\.js)
	    CONTENT_TYPE="text/javascript"
	    ;;
	*)
	    CONTENT_TYPE=$(file -b --mime-type "${file}")
	    ;;
    esac

    add_response_header "Content-Type"  "${CONTENT_TYPE}"
    CONTENT_LENGTH=$(stat -c'%s' "${file}")
    add_response_header "Content-Length" "${CONTENT_LENGTH}"

    ## Use binary safe transfer method since text doesn't break.
    send_response_ok_exit_binary "${file}"
}

function urldecode {
    [ "${1%/}" == "" ] && echo "/" ||
	    echo -e "$(sed 's/%\([[:xdigit:]]\{2\}\)/\\\x\1/g' <<< "${1%/}")"
}

function serve_static_string() {
    add_response_header "Content-Type" "text/plain"
    send_response_ok_exit <<< "$1"
}

function on_uri_match() {
    local regex="$1"
    shift
    [[ "${REQUEST_URI}" =~ $regex ]] && 
        "$@" "${BASH_REMATCH[@]}"
}

function unconditionally() {
    "$@" "$REQUEST_URI"
}

###########


function create_json {
    if [ -s /tmp/zdl.d/paths.txt ]
    then
	echo -ne '{' >/tmp/zdl.d/data.json

	while read path
	do
	    cd "$path"
	    data_stdout
	    echo -en "," >>/tmp/zdl.d/data.json
	done </tmp/zdl.d/paths.txt

	sed -r "s|,$|}\n|g" -i /tmp/zdl.d/data.json
    fi
}


while read -a line
do
    case ${line[0]} in
	GET)
	    create_json
	    get_http=true
	    echo "HTTP/1.1 200 ${HTTP_RESPONSE[200]}"
	    
	    for i in "${RESPONSE_HEADERS[@]}"
	    do
		echo "$i"
	    done
	    echo

	    if [[ "${line[1]}" =~ ^\/tmp\/zdl.d\/ ]]
	    then
		web_template="${line[1]}"

	    else
		[ "${line[1]}" == '/' ] && line[1]=index.html
		web_template="$path_usr/webui/${line[1]#\/}"
	    fi
	    ;;

	get-data)
	    create_json
	    cat /tmp/zdl.d/data.json
	    ;;
	## PATH sempre primo argomento (dal generale al particolare: per poter evitare il secondo quando opzionale perché compreso)
	delete-link)
	    ## [1]=PATH [2]=LINK
	    ;;
	add-link)
	    ## [1]=PATH [2]=LINK
	    ;;
	stop-link)
	    ## [1]=(PATH|ALL); [2]=(LINK|ALL); 
	    ;;
	set-downloader)
	    ## [1]=(PATH|ALL); [2]=DOWNLOADER
	    ;;
	set-number)
	    ## [1]=PATH oppure 'ALL' [2]=NUMBER:(0->...)
	    ;;
	'clear')
	    ## [1]=PATH oppure 'ALL'
	    ;;
	'kill')
	    ## [1]=PATH oppure 'ALL'
	    ;;
    esac

    #### HTTP:
    if [ -n "$get_http" ]
    then
	recv "${line[*]}"
	
	if [[ "${line[*]}" =~ keep-alive ]]
	then
	    JSON=$(cat /tmp/zdl.d/data.json 2>/dev/null)
	    web_page=$(sed -r "s|__JSON__|$JSON|g" $web_template)
	    echo "$web_page"

	    break
	fi
    fi
done

