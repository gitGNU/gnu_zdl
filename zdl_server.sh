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
path_webui="$path_usr/webui"
template_index="$path_webui/index.html"
path_tmp=".zdl_tmp"

path_conf="$HOME/.zdl"
file_conf="$path_conf/zdl.conf"


path_server="/tmp/zdl.d"
server_data="$path_server/data.json"
server_paths="$path_server/paths.txt"
server_index="$path_server/index.html"

source $path_usr/config.sh
source $path_usr/libs/core.sh
source $path_usr/libs/downloader_manager.sh
source $path_usr/libs/DLstdout_parser.sh
source $path_usr/libs/utils.sh
source $path_usr/libs/log.sh

pid_prog=$$
socket_port="$1"
add_server_pid "$socket_port"

json_flag=true

for item in socket-ports downloader max-downloads status
do
    [ ! -e "$path_server"/"$item".fifo ] &&
	mkfifo "$path_server"/"$item".fifo
done	
unset item

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
declare -i DEBUG=0
declare -i VERBOSE=0
declare -a REQUEST_HEADERS
declare    REQUEST_URI=""
declare -a HTTP_RESPONSE=(
    [200]="OK"
    [400]="Bad Request"
    [403]="Forbidden"
    [404]="Not Found"
    [405]="Method Not Allowed"
    [500]="Internal Server Error"
)
declare DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
    "Date: $DATE"
    "Expires: $DATE"
    "Server: ZigzagDownLoader"
)
##########



function recv {
    ((DEBUG)) &&
	echo "< $@" >>zdl_server.log
}

function send {
    ((DEBUG)) &&
	echo "> $@" >>zdl_server.log

    echo -ne "$*\r\n"
}

function add_response_header {
    RESPONSE_HEADERS+=("$1: $2")
}

function send_response_header {
    local header
    
    send "HTTP/1.1 $1 ${HTTP_RESPONSE[$1]}"

    for header in "${RESPONSE_HEADERS[@]}"
    do
	send "$header"
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
	get_mime_server mime "$file"
	add_response_header "Content-Type" "$mime"
	add_response_header "Content-Length" "$(size_file "$file")"
	send_response_header "$code"

	if ! check_port $socket_port
	then
	    if [ "$file" == "$path_server"/status.$socket_port ] &&
		   grep RELOAD "$file" &>/dev/null
	    then
		get_status
	    fi
	    
	    cat "$file"
	fi
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
    declare -n mime="$1"
    mime=''
    
    case "$2" in
        *\.css)
	    mime="text/css"
	    ;;
	*\.js)
	    mime="text/javascript"
	    ;;
	*\.json)
	    mime="application/json"
	    #mime="text/html"
	    ;;
	*)
	    mime=$(get_mime "${file}")
	    ;;
    esac

    if [ -n "$mime" ]
    then
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

function clean_data {
    echo -e "$1" | tr -d "\r"
}


function get_file_output {
    declare -n result="$1"
    local file="$2"
    
    if [[ "$file" =~ ^\/tmp\/zdl.d\/ ]]
    then
	result="$file"

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
	
	result="$file"
    fi
}

function create_json {
    local test_data path
    rm -f "$server_data"

    if [ -s "$server_paths" ]
    then
	echo -ne '[' >"$server_data"

	while read path
	do
	    cd "$path"
	    if [ -d "$path_tmp" ]
	    then
		if data_stdout &&
			! grep -P '\[$' "$server_data" &>/dev/null
		then
		    echo -en "," >>"$server_data"
		fi
	    fi

	done <"$server_paths"

	sed -r "s|,$|]\n|g" -i "$server_data"
	
	grep -P '^\[$' "$server_data" &>/dev/null &&
	    echo > "$server_data"
	
	return 0
    fi
    return 1
}

function send_json {
    while :
    do
	create_json
	touch "$server_data" "$server_data".$socket_port
	current_timeout=$(date +%s)
	if ! cmp_file "$server_data" "$server_data".$socket_port ||
		check_port $socket_port ||
		(( (current_timeout - start_timeout) > 240 ))
	then
	    break
	fi
	
	sleep 1
    done
    ##sleep 1
    cp "$server_data" "$server_data".$socket_port
    
    file_output="$server_data"

    if [ -z "$http_method" ]
    then
	cat "$server_data"
	return 1
    fi
    return 0
}

function get_status {
    local path="$1"
    [ -z "$path" ] && path="$PWD"
    
    if test -d "$path"
    then
	cd "$path"
	
	if check_instance_prog ||
		check_instance_daemon
	then
	    status="running" 
	else
	    status="not-running"
	fi
	
	echo "$status" > "$path_server"/status.$socket_port
    fi
}

function init_client {
    local file item

    for item in downloader max-downloads socket-ports
    do
	unlock_fifo $item "$PWD" &
    done
    
    [ -n "$(ls "$path_server"/*.$socket_port 2>/dev/null)" ] &&
	{
	    for file in "$path_server"/*.$socket_port
	    do
		echo RELOAD > $file
	    done
	}
}

function run_cmd {
    local line=( "$@" )
    local file link pid path
    unset file_output
    
    case "${line[0]}" in
	init-client)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    init_client 
	    ;;
	
    	get-data)
	    send_json || return
	    ;;

	add-link)
	    ## PATH -> LINK
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    cd "${line[i]}"
		
		## link
		link=$(urldecode "${line[i]}") 
		
		url "$link" &&
		    {
			if check_instance_prog
			then
			    set_link + "$link"

			else
			    set_line_in_file + "$PWD" "$server_paths"
			    mkdir -p "$path_tmp"
			    date +%s >"$path_tmp"/.date_daemon
			    nohup /bin/bash zdl "$link" --silent "$PWD" &>/dev/null &
			fi
		    }
	    done
	    ;;

	del-link)
	    ## PATH -> LINK ~ PID
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    cd "${line[i]}"

		if url "${line[i]}"
		then
		    unset json_flag
		    data_stdout
		    json_flag=true

		    for ((j=0; j<${#pid_out[@]}; j++))
		    do
			if [ "${url_out[j]}" == "${line[i]}" ]
			then
			    set_link - "${url_out[j]}"

			    kill -9 "${pid_out[j]}" &>/dev/null 

			    rm -f "${file_out[j]}"         \
			       "${file_out[j]}".st         \
			       "${file_out[j]}".aria2      \
			       "${file_out[j]}".zdl        \
			       "$path_tmp"/"${file_out[j]}_stdout.tmp"
			fi
		    done
		fi
	    done
	    ;;

	stop-link)
	    ## PATH -> LINK ~ PID
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    cd "${line[i]}"

		if url "${line[i]}"
		then
		    unset json_flag
		    data_stdout
		    json_flag=true

		    for ((j=0; j<${#pid_out[@]}; j++))
		    do
			if [ "${url_out[j]}" == "${line[i]}" ]
			then
			    kill -9 "${pid_out[j]}" &>/dev/null 
			fi
		    done
		fi
	    done 
	    ;;

	get-links)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ -f "$path_tmp/links_loop.txt" ]
	    then
		file_output="$path_tmp/links_loop.txt"

	    else
		echo > "$path_server/empty"
		file_output="$path_server/empty"
	    fi
	    
	    if [ -z "$http_method" ]
	    then
		cat "$file_output"
		return
	    fi
	    ;;

	set-links)
	    ## path:
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    ## links:
	    urldecode "${line[2]}" > "$path_tmp/links_loop.txt"
	    ;;
	
	get-downloader)
	    ## [1]=PATH
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if test -f "$path_tmp/downloader"
	    then
		if [ "${line[2]}" != 'force' ]
		then
		    lock_fifo downloader path
		    [ -d "$path" ] &&
			cd "$path"
		    
		else
		    unset line[2] 	    
		fi
		
	    else
		mkdir -p "$path_tmp"
		get_item_conf 'downloader' >"$path_tmp/downloader"
	    fi

	    file_output="$path_tmp/downloader"
	    if [ -z "$http_method" ]
	    then
		cat "$file_output"
		return
	    fi	    
	    ;;

	set-downloader)
	    ## [1]=PATH; [2]=DOWNLOADER
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    echo "${line[2]}" >"$path_tmp/downloader"
	    unlock_fifo downloader "$PWD" &
	    ;;

	get-max-downloads)
	    ## [1]=PATH;
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if test -f "$path_tmp/max-dl"
	    then
		if [ "${line[2]}" != 'force' ]
		then
		    lock_fifo max-downloads path
		    [ -d "$path" ] &&
			cd "$path"
		    
		else
		    unset line[2] 	    
		fi
	    else
		mkdir -p "$path_tmp"
		get_item_conf 'max_dl' >"$path_tmp/max-dl"
	    fi

	    file_output="$path_tmp/max-dl"
	    if [ -z "$http_method" ]
	    then
		cat "$file_output"
		return
	    fi	    
	    ;;

	set-max-downloads)
	    ## [1]=PATH, [2]=NUMBER:(0->...)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ -z "${line[2]}" ] || [[ "${line[2]}" =~ ^[0-9]+$ ]] 
	    then
		echo "${line[2]}" >"$path_tmp/max-dl"
		unlock_fifo max-downloads "$PWD" &
	    fi
	    ;;

	get-status)
	    test -d "${line[1]}" &&
		cd "${line[1]}"
	    
	    while : 
	    do
		touch "$path_server"/status.$socket_port
		
		if check_instance_prog &>/dev/null ||
			check_instance_daemon &>/dev/null
		then
		    status="running" 
		else
		    status="not-running"
		fi
		
		current_timeout=$(date +%s)

		if [ "$status" != "$(cat "$path_server"/status.$socket_port)" ] ||
		       check_port $socket_port &>/dev/null ||
		       (( (current_timeout - start_timeout) > 240 )) ||
		       [ "${line[2]}" == 'force' ]
		then
		    echo "$status" > "$path_server"/status.$socket_port
		    break
		fi
		
		sleep 1
	    done
	    
	    file_output="$path_server"/status.$socket_port
	    if [ -z "$http_method" ]
	    then
		cat "$file_output"
		return
	    fi
	    ;;

	get-dirs)
	    unset file_output dirs text_output
	    
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    text_output+="<a href=\"javascript:browse('$PWD/..');\"><img src=\"folder-blue.png\" /> ..</a><br>"
	    while read dir
	    do
		real_dir=$(realpath "$dir")
		text_output+="<a href=\"javascript:browse('${real_dir}');\"><img src=\"folder-blue.png\" /> ${dir}</a><br>"
	    done < <(ls -d1 */)

	    echo "$text_output" > "$path_server"/browsing.$socket_port
	    file_output="$path_server"/browsing.$socket_port	    
	    ;;

	clean-complete)
	    while read path
	    do
		test -d "$path" &&
		    cd "$path"
		
		no_complete=true
		data_stdout
		unset no_complete
		
	    done < "$server_paths"
	    ;;

	run-server)
	    if [[ "${line[1]}" =~ ^[0-9]+$ ]] &&
		   check_port "${line[1]}"
	    then
		run_zdl_server "${line[1]}" &>/dev/null
		
	    else
		echo "already-in-use" >"$path_server"/run-server.$socket_port
		file_output="$path_server"/run-server.$socket_port
	    fi
	    ;;

	get-sockets)
	    touch "$path_server"/socket-ports \
		  "$path_server"/ports.json

	    if [ "${line[1]}" != 'force' ]
	    then
		read < "$path_server"/socket-ports.fifo

	    else
		unset line[1] 	    
	    fi

	    if [ -s "$path_server"/socket-ports ]
	    then
		echo -n '[' > "$path_server"/ports.json
		while read port
		do
		    if [[ "$port" =~ ^[0-9]+$ ]]
		    then
			if check_port $port 
			then
			    set_line_in_file - "$port" "$path_server"/socket-ports 
			    
			else
			    echo -n "$port," >> "$path_server"/ports.json				
			fi
		    fi
		done < "$path_server"/socket-ports
		
		if grep '\[$' "$path_server"/ports.json
		then
		    echo > "$path_server"/ports.json

		else
		    sed -r 's|,$|]|' -i "$path_server"/ports.json
		fi

		file_output="$path_server"/ports.json
	    fi

	    file_output="$path_server"/ports.json
	    ;;
	
	run-zdl)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    {
			cd "${line[i]}"
			
			if ! check_instance_prog &>/dev/null &&
				! check_instance_daemon &>/dev/null
			then
			    set_line_in_file + "$PWD" "$server_paths"
			    mkdir -p "$path_tmp"
			    date +%s >"$path_tmp"/.date_daemon
			    nohup /bin/bash zdl --silent "$PWD" &>/dev/null &
			fi
		    }
	    done
	    ;;

	quit-zdl)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    {
			cd "${line[i]}"

			if [ -d "$path_tmp" ]
			then
			    pid=$(cat "$path_tmp/.pid.zdl")

			    check_pid $pid &&
				kill -9 $pid &>/dev/null
			    
			    rm -f "$path_tmp"/.date_daemon
			    unset pid
			fi
		    }
	    done &>/dev/null
	    ;;

	kill-zdl)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		test -d "${line[i]}" &&
		    {
			cd "${line[i]}"

			if [ -d "$path_tmp" ]
			then
			    pid=$(cat "$path_tmp/.pid.zdl")

			    check_pid $pid &&
				kill -9 $pid &>/dev/null
			    kill_downloads

			    rm -f "$path_tmp"/.date_daemon
			    unset pid
			fi
		    }
	    done
	    ;;

	kill-server)
	    kill_server "${line[1]}"
	    ;;
	
	kill-all)
	    while read path
	    do
	    	kill_downloads

		instance_pid=$(cat "$path_tmp"/.pid.zdl)
		[ -n "$instance_pid" ] && {
		    kill -9 "$instance_pid" &>/dev/null
		    rm -f "$path_tmp"/.date_daemon
		    unset instance_pid
		} 
	    done < "$server_paths"

	    while read port
	    do
		[ "$port" == "$socket_port" ] ||
		    kill_server "$port"
		
	    done < "$path_server"/socket-ports

	    kill_server "$socket_port"
	    ;;
    esac

    if [ -z "$file_output" ] &&
	   [ -n "$http_method" ]
    then
       echo > "$path_server/empty"
       file_output="$path_server/empty"
    fi
}

function run_data {
    local data=( ${1//'&'/ } )
    local name value last
    local line_cmd=()

    for ((i=0; i<${#data[*]}; i++))
    do
	## name=$(urldecode "${data[i]%'='*}")
	value="$(urldecode "${data[i]#*'='}")"
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
	
    case "${line[0]}" in
	GET)
	    unset GET_DATA file_output
	    http_method=GET
	    start_timeout=$(date +%s)
	    
	    get_file_output file_output "${line[1]}"
	    
	    if [[ "${line[1]}" =~ '?' ]]
	    then
	    	GET_DATA="$(clean_data "${line[1]#*\?}")"
	    fi
	    ;;
	POST)
	    unset POST_DATA file_output
	    http_method=POST
	    get_file_output file_output "${line[1]}"
	    ;;
	*)
	    http_server ||
		run_cmd "${line[@]}"
	    ;;
    esac
done

