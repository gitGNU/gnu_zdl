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
source $path_usr/libs/ip_changer.sh
source $path_usr/libs/log.sh

pid_prog=$$
socket_port="$1"
add_server_pid "$socket_port"

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

	if [ "$file" == "$path_server"/status.$socket_port ] &&
	       grep RELOAD "$file" &>/dev/null
	then
	    get_status
	fi
	
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
    local path
    rm -f "$server_data".$socket_port

    if [ -s "$server_paths" ]
    then	
	echo -ne '[' >"$server_data".$socket_port

	while read path
	do
	    cd "$path"
	    if [ -d "$path_tmp" ]
	    then
		if data_stdout &&
			! grep -P '\[$' "$server_data".$socket_port &>/dev/null
		then
		    echo -en "," >>"$server_data".$socket_port
		fi
	    fi

	done <"$server_paths"

	sed -r "s|,$|]\n|g" -i "$server_data".$socket_port
	
	grep -P '^\[$' "$server_data".$socket_port &>/dev/null &&
	    echo > "$server_data".$socket_port
	
	return 0
    fi
    return 1
}

function send_json {
    [ "$1" == force ] &&
	rm -f "$server_data".$socket_port.diff
    
    while :
    do
	create_json
	touch "$server_data".$socket_port "$server_data".$socket_port.diff
	current_timeout=$(date +%s)
	if ! cmp_file "$server_data".$socket_port "$server_data".$socket_port.diff ||
		check_port $socket_port ||
		(( (current_timeout - start_timeout) > 240 ))
	then
	    break
	fi
	
	sleep 2
    done
    ##sleep 0.1
    cp "$server_data".$socket_port "$server_data".$socket_port.diff
    
    file_output="$server_data".$socket_port

    if [ -z "$http_method" ]
    then
	cat "$server_data".$socket_port
	exit
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

function get_status_run {
    if [ -n "$1" ]
    then
	declare -n ref="$1"

	if check_instance_prog &>/dev/null ||
		check_instance_daemon &>/dev/null
	then
	    ref="running" 
	else
	    ref="not-running"
	fi
    fi
}

function get_status_sockets {
    declare -n ref="$1"
    
    ref='['    
    check_socket_ports "$1"
    ref="${ref%,}]"
}

function check_socket_ports {
    [ -n "$1" ] &&
	declare -n ref="$1"
       
    if [ -s "$path_server"/socket-ports ]
    then
	while read port
	do
	    if check_port $port 
	    then
		set_line_in_file - "$port" "$path_server"/socket-ports

	    elif [ -n "$1" ]
	    then
		ref+="\"$port\","
	    fi    
	    
	done < "$path_server"/socket-ports
    fi
}

function get_status_conf {
    declare -n ref="$1"

    ref='{'
    for key in ${key_conf[@]}
    do
	ref+="\"$key\":\"$(get_item_conf $key)\","
    done
    ref="${ref%,}}"
}

function create_status_json {
    local reconn
    
    [ -n "$1" ] &&
	declare -n string_output="$1" ||
	    string_output=string_output
    
    string_output="{"

    ## current path
    string_output+="\"path\":\"$PWD\","
    
    ## run status    
    get_status_run status
    string_output+="\"status\":\"$status\","

    ## downloader
    if [ ! -f "$path_tmp/downloader" ]
    then
	mkdir -p "$path_tmp"
	get_item_conf 'downloader' >"$path_tmp/downloader"
    fi
    string_output+="\"downloader\":\"$(cat "$path_tmp/downloader")\","

    ## max downloads
    if [ ! -f "$path_tmp/max-dl" ]
    then
	mkdir -p "$path_tmp"
	get_item_conf 'max_dl' >"$path_tmp/max-dl"
    fi
    string_output+="\"maxDownloads\":\"$(cat "$path_tmp/max-dl")\","

    ## reconnect
    [ -f "$path_tmp"/reconnect ] && reconn=enabled || reconn=disabled
    string_output+="\"reconnect\":\"$reconn\","
    
    ## run sockets
    get_status_sockets status
    string_output+="\"sockets\":$status,"

    ## conf
    get_status_conf status
    string_output+="\"conf\":$status"

    string_output+="}"
}

function send_ip {
    file_output="$path_server"/myip
    get_ip real_ip proxy_ip
    
    echo -e "Indirizzo IP attuale:\n$real_ip" > "$file_output"
    
    if [ -n "$proxy_ip" ]
    then
	echo -e "\n\nIndirizzo IP con proxy:\n$proxy_ip" >> "$file_output"
    fi
}


function run_cmd {
    local line=( "$@" )
    local file link pid path
    unset file_output
    
    case "${line[0]}" in
	init-client)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    init_client "${line[1]}" $socket_port
	    ;;

	reset-requests)
	    sleep 3

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    init_client "${line[1]}" $socket_port
	    ;;
	
    	get-data)
	    send_json ${line[1]} || return
	    ;;

	get-status)	    
	    ## status.json
	    file_output="$path_server"/status.$socket_port.json

	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ "${line[2]}" == 'force' ]
	    then
		echo "$PWD" > /tmp/zdl.d/path.$socket_port
		
		unset line[2]
		while ! check_port $socket_port
		do
		    [ -s /tmp/zdl.d/path.$socket_port ] &&
			cd $(cat /tmp/zdl.d/path.$socket_port)
		    
		    create_status_json string_output
		    current_timeout=$(date +%s)
			
		    if [ ! -s "$file_output" ] ||
			   [ "$string_output" != "$(cat "$file_output")" ] ||
			    (( (current_timeout - start_timeout) > 240 ))
		    then
			init_client "$PWD" "$socket_port"
			start_timeout=$(date +%s)
		    fi
		    sleep 2
		done &
		
	    else		
		lock_fifo status.$socket_port path
		if test -d "$path"
		then
		    echo "$path" > /tmp/zdl.d/path.$socket_port
		    cd "$path"
		fi
	    fi
	    
	    create_status_json string_output
	    echo -n "$string_output" >$file_output
	    ;;

	reconnect)
	    if test -d "${line[1]}"
	    then
		cd "${line[1]}"
	    fi

	    if test "${line[2]}" == 'true'
	    then
		if [ -n "$reconnecter" ]
		then
		    touch "$path_tmp"/reconnect

		else
		    rm -f "$path_tmp"/reconnect
		    file_output="$path_server"/reconn
		    echo "Non hai ancora configurato ZDL per la riconnessione automatica" > "$file_output"
		fi
		
	    elif test "${line[2]}" == 'false'
	    then
		rm -f "$path_tmp"/reconnect

	    elif test -z "${line[2]}"
	    then
		if [ -n "$reconnecter" ]
		then
		    $reconnecter &>/dev/null
		    send_ip

		else
		    rm -f "$path_tmp"/reconnect
		    file_output="$path_server"/reconn
		    echo "Non hai ancora configurato ZDL per la riconnessione automatica" > "$file_output"
		fi
	    fi	    
	    ;;

	get-ip)
	    send_ip
	    ;;

	get-free-space)
	    file_output="$path_server"/free-space
	    
	    if test -d "${line[1]}"
	    then
		cd "${line[1]}"
	    fi
	    
	    df -h . |
		awk '{if(match($4, /^[0-9]+/)) print $4}' > "$file_output"
	    ;;
	
	add-xdcc)
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		if test -d "${line[i]}"
		then
		    cd "${line[i]}"
		    continue
		fi

		link="$(urldecode "${line[i]}")"
		
		declare -A irc
		case $i in
		    2)
			irc[host]="${link#'irc://'}"
			irc[host]="${irc[host]%%'/'*}"
			err_msg="\nIRC host: ${link}"
			;;
		    
		    3)
			irc[chan]="${link##'#'}"
			err_msg+="\nIRC channel: ${link}"
			;;
		    
		    4)
			irc[msg]="${link#'/msg'}"
			irc[msg]="${irc[msg]#'/ctcp'}"
			irc[msg]="${irc[msg]## }"
			err_msg+="\nIRC msg: ${link}"
			;;
		esac
	    done
	    set_link + "irc://${irc[host]}/${irc[chan]}/msg ${irc[msg]}" ||
		{
	    	    file_output="$path_server"/msg-file
	    	    echo -e "$err_msg" > "$file_output"
		}
	    ;;

	add-link)
	    ## PATH -> LINK
	    unset list_err
	    
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		if test -d "${line[i]}"
		then
		    cd "${line[i]}"
		    continue
		fi
		
		## link
		link=$(urldecode "${line[i]}") 
		
		if url "$link" &&
			! check_instance_prog &&
			! check_instance_daemon
		then
		    mkdir -p "$path_tmp" &>/dev/null
		    date +%s >"$path_tmp"/.date_daemon
		    nohup /bin/bash zdl --silent "$PWD" &>/dev/null &
		    
		    while ! check_instance_daemon
		    do
			sleep 0.1
		    done
		fi
		set_link + "$link" ||
		    list_err+="\n$link"
	    done &>/dev/null

	    if [ -n "$list_err" ]
	    then
	    	file_output="$path_server"/msg-file
	    	echo -e "$list_err" > "$file_output"
	    fi
	    ;;

	del-link)
	    ## PATH -> LINK ~ PID
	    for ((i=1; i<${#line[@]}; i++))
	    do
		## path
		if test -d "${line[i]}"
		then
		    cd "${line[i]}"
		    continue
		fi

		link="$(urldecode "${line[i]}")"
		
		if url "$link"
		then
		    unset json_flag
		    data_stdout
		    json_flag=true

		    for ((j=0; j<${#pid_out[@]}; j++))
		    do
			if [ "${url_out[j]}" == "$link" ]
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
		if test -d "${line[i]}"
		then
		    cd "${line[i]}"
		    continue
		fi

		link="$(urldecode "${line[i]}")"
		
		if url "$link"
		then
		    unset json_flag
		    data_stdout
		    json_flag=true

		    for ((j=0; j<${#pid_out[@]}; j++))
		    do
			if [ "${url_out[j]}" == "$link" ]
			then
			    kill -9 "${pid_out[j]}" &>/dev/null 
			fi
		    done
		fi
	    done 
	    ;;

	play-link)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ -z "$player" ] #&>/dev/null
	    then
		file_output="$path_server"/msg-file
		echo -e "Non è stato configurato alcun player per audio/video" > "$file_output"

	    elif [[ ! "$(file -b --mime-type "${line[2]}")" =~ (audio|video) ]]
	    then
		file_output="$path_server"/msg-file
		echo -e "Non è un file audio/video" > "$file_output"

	    else
		nohup $player "${line[2]}" &>/dev/null &
	    fi
	    ;;

	get-file)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    file_output="$path_server"/file-text
	    sed -r 's|$|<br>|g' "${line[2]}" > "$file_output"
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
	    ;;

	set-links)
	    ## path:
	    unset list_err
	    
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    ## links:
	    echo -n > "$path_tmp"/links_loop.txt
	    while read link
	    do
		set_link + "$link" ||
		    list_err+="\n$link"
	    
	    done <<< "$(urldecode "${line[2]}")"

	    [ ! -s "$path_tmp"/links_loop.txt ] && rm -f "$path_tmp"/links_loop.txt*
	    
	    if [ -n "$list_err" ]
	    then
	    	file_output="$path_server"/msg-file
	    	echo -e "$list_err" > "$file_output"
	    fi
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
	    ;;

	set-downloader)
	    ## [1]=PATH; [2]=DOWNLOADER
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    echo "${line[2]}" >"$path_tmp/downloader"
	    #unlock_fifo downloader "$PWD" &
	    #unlock_fifo status.$socket_port &
	    init_client
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
	    ;;

	set-max-downloads)
	    ## [1]=PATH, [2]=NUMBER:(0->...)
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    if [ -z "${line[2]}" ] || [[ "${line[2]}" =~ ^[0-9]+$ ]] 
	    then
		echo "${line[2]}" >"$path_tmp/max-dl"
		#unlock_fifo max-downloads "$PWD" &
		#unlock_fifo status.$socket_port &
		init_client
	    fi
	    ;;

	get-status-run)
	    test -d "${line[1]}" &&
		cd "${line[1]}"
	    
	    get_status_run status ${line[2]}
	    
	    echo "$status" > "$path_server"/status.$socket_port	    
	    file_output="$path_server"/status.$socket_port
	    ;;

	browse-dirs)
	    file_output="$path_server"/browsing.$socket_port
	    
	    test -d "${line[1]}" &&
		cd "${line[1]}"

	    string_output="<a href=\"javascript:browseDir('$PWD/..');\"><img src=\"folder-blue.png\">..</a><br>"
	    while read dir
	    do
		real_dir=$(realpath "$dir")
		string_output+="<a href=\"javascript:browseDir('${real_dir}');\"><img src=\"folder-blue.png\">${dir}</a><br>"
	    done < <(ls -d1 */)

	    echo "$string_output" > "$file_output"	    
	    ;;

	browse)
	    file_output="$path_server"/browsing.$socket_port
	    path="${line[1]}"
	    id="${line[2]}"
	    type="${line[3]}"
	    key="${line[4]}"

	    test -d "$path" &&
		cd "$path"

	    string_output="<a href=\"javascript:browseFile('$id','$PWD/..');\"><img src=\"folder-blue.png\">../</a><br>"
	    while read file
	    do
		real_path=$(realpath "$file")
		
		if [ -d "$real_path" ]
		then
		    img="folder-blue.png"
		    string_output+="<a href=\"javascript:browseFile('$id','$real_path','$type','$key');\"><img src=\"folder-blue.png\">$file</a><br>"

		elif [ "$type" == torrent ] &&
			 [[ "$(file -b --mime-type "$real_path")" =~ ^application\/(octet-stream|x-bittorrent)$ ]]
		then		    
		    img='application-x-bittorrent.png'
		    string_output+="<a href=\"javascript:singlePath(ZDL.path).addLink('$id','$real_path');\"><img src=\"$img\">$file</a><br>"
		    
		elif [ "$type" == executable ] &&
			 [ -x "$real_path" ]
		then		    
		    img='application-x-desktop.png'
		    string_output+="<a href=\"javascript:setConf({key:'$key'},'$real_path');\"><img src=\"$img\">$file</a><br>"
		fi   

	    done < <(ls -1 --group-directories-first)

	    echo "$string_output" > "$file_output"	    
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

	    test -d "${line[1]}" &&
		cd "${line[1]}"
	    
	    init_client
	    ;;

	run-server)
	    if [[ "${line[1]}" =~ ^[0-9]+$ ]] &&
		   check_port "${line[1]}"
	    then
		run_zdl_server "${line[1]}" &>/dev/null
		init_client
		
	    else
		echo "already-in-use" >"$path_server"/run-server.$socket_port
		file_output="$path_server"/run-server.$socket_port
	    fi
	    ;;

	get-sockets)
	    touch "$path_server"/socket-ports

	    if [ "${line[1]}" != 'force' ]
	    then
		read < "$path_server"/socket-ports.fifo

	    else
		unset line[1] 	    
	    fi

	    check_socket_ports
	    
	    file_output="$path_server"/socket-ports
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
	    
	    init_client
	    ;;

	kill-server)
	    kill_server "${line[1]}" 
	    ;;
	
	kill-all)
	    ## tutte le istanze di ZDL (in tutti i path) e i downloader
	    while read path
	    do
		test -d "$path" &&
		    cd "$path"
		
	    	kill_downloads

		instance_pid=$(cat "$path_tmp"/.pid.zdl)
		[ -n "$instance_pid" ] &&
		    {
			kill -9 "$instance_pid" &>/dev/null
			rm -f "$path_tmp"/.date_daemon
			unset instance_pid
		    } 
	    done < "$server_paths"

	    init_client
	    ;;
	
	get-conf)
	    file_output="$path_server"/conf.$socket_port.json
	    
	    if [ "${line[1]}" != 'force' ]
	    then
		lock_fifo conf

	    else
		unset line[1]
	    fi

	    string_output='{'
	    
	    for item in ${key_conf[@]}
	    do
		string_output+="\"$item\":\"$(get_item_conf "$item")\","
	    done
	    string_output="${string_output%,}}"
	    
	    echo -n "$string_output" > "$file_output"
	    ;;
	
	set-conf)
	    set_item_conf "${line[1]}" "${line[2]}"
	    init_client
	    ;;
    esac

    if [ -z "$http_method" ]
    then
	test -f "$file_output" &&
	    cat "$file_output" ||
		send
	exit

    elif [ -z "$file_output" ]
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
			[[ "$file_output" =~ "$server_data" ]] &&
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

