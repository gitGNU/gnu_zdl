#!/bin/bash

path_server="$HOME"/.zdl/zdl.d

function kill_server {
    local port="$1"
    [ -z "$port" ] && port="$socket_port"

    rm -f "$path_server"/matched

    ps ax | while read -a psline
	    do
		if [[ "${psline[0]}" =~ ^([0-9]+)$ ]] &&
		       grep -P "socat.+LISTEN:${port}.+zdl_server\.sh" /proc/${psline[0]}/cmdline &>/dev/null
		then
		    kill "${psline[0]}"
		    touch "$path_server"/matched
		fi
	    done
    
    [ -f "$path_server"/matched ] && kill_server "$port"
}

while read port
do
    kill_server "$port"
    
done < "$path_server"/socket-ports
