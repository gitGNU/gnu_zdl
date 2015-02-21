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

function check_pid {
    ck_pid=$1
    if [ ! -z $ck_pid ]; then
	ps ax | awk "{ print $ps_ax_pid }" | while read ck_alive; do
	    if [ "$ck_alive" == "$ck_pid" ]; then
		return 1
	    fi
	done
    fi
}


function check_instance_prog {
    if [ -f "$path_tmp/pid.zdl" ]; then
	test_pid=`cat "$path_tmp/pid.zdl" 2>/dev/null`
	check_pid "$test_pid"
	if [ $? == 1 ]; then
	    pss=`ps ax|grep "$test_pid"`
	    max=`echo -e "$pss" | wc -l`
	    for line in `seq 1 $max`; do
		proc=`echo -e "$pss" |sed -n "${line}p"`
		pid=`echo "$proc" | awk "{ print $ps_ax_pid }"`
		tty=`echo "$proc" | awk "{ print $ps_ax_tty }"`
		if [ "$pid" == "${test_pid}" ] && [ "$pid" != "$pid_prog" ]; then
		    return 1
		fi
	    done
	fi
    fi
}



function check_lock {
    test_lock=`ls "$path_tmp"/${prog}_lock_* 2>/dev/null`
    echo "lockfile=$lock_file"
    read -p "test=$test_lock"
    
    if [ ! -z "$test_lock" ]; then
	pid="${test_lock#*_lock_}"
	read -p "pid_test=$pid"
	check_pid $pid
	if [ $? == 1 ]; then
	    rm "$test_lock"
	    return 1
	fi
    else
	touch "$lock_file"
    fi
    touch "$lock_file"
}


function redirect_links {
    header_box "Links da processare"
    links="${links##\\n}"
    echo -e "${links//'\n'/\n\n}\n"
    separator-
    print_c 1 "\nLa gestione dei download è inoltrata a un'altra istanza attiva di $PROG (pid $test_pid), nel seguente terminale: $tty"
    rm -f "$path_tmp/lock.zdl\n"
    [ ! -z "$xterm_stop" ] && xterm_stop
    exit 1
}


## versione che non funziona con cygwin perché output di 'ps' è diverso
#
# function check_instance_daemon_old {
#     test_instance=$( ps ax | grep "$prog" |grep "silent $PWD" )
#     test_instance=${test_instance#*'silent '}
#     if [ ! -z "$test_instance" ] && [ "$test_instance" == "$PWD" ]; then
# 	return 1
#     else
# 	return 0
#     fi
# }

function check_instance_daemon {
    while read line; do
	test_pid=$(awk '{print $1}' <<< "$line")

	if [[ "$test_pid" =~ ^[0-9]+$ ]] && [ -d "/proc/$test_pid" ] && [[ $(grep silent /proc/$test_pid/cmdline) ]] && [[ $(sed -r 's|.+silent(.+)$|\1|g' < /proc/$test_pid/cmdline) == "$PWD" ]]; then
	    return 1
	fi
    done <<< "$(ps ax |grep bash)"
    return 0
}

function is_rtmp {
    for h in ${rtmp[*]}; do
	[ "$1" != "${1//$h}" ] && return 1
    done
    return 0
}

function sanitize_file_in {
    file_in="${file_in// /_}"
    file_in="${file_in//\'/_}"
    file_in="${file_in##*/}"
    file_in="${file_in::255}"
}

function human_eta {
    if [ ! -z "$1" ]; then
	minutes=$(( $1/60 ))
	hours=$(( $minutes/60 ))
	minutes=$(( $minutes-($hours*60) ))
	echo "${hours}h${minutes}m"
    fi
}

function zdl-ext {
    ## $1 == (download|streaming)
    while read line; do
	test_ext_type=$(grep "## zdl-extension types:" < $path_usr/extensions/$line 2>/dev/null |grep "$1")
	if [ ! -z "$test_ext_type" ]; then
	    grep '## zdl-extension name:' < $path_usr/extensions/$line 2>/dev/null | sed -r 's|.*(## zdl-extension name: )(.+)|\2|g' |sed -r 's|\, |\n|g'
	fi
    done <<< "$(ls -1 $path_usr/extensions/)"
}

function zdl-ext-sorted {
    local extensions
    while read line; do
	extensions="${extensions}$line\n"
    done <<< "$(zdl-ext $1)"
    extensions=${extensions%\\n}

    echo $(sed -r 's|$|, |g' <<< "$(echo -e "${extensions}" |sort)") |sed -r 's|(.+)\,$|\1|g'
}

function line_file { 	## usage with op=+|- : links_loop $op $link
    op="$1"                    ## operator
    item="$2"                  ## line
    file_target="$3"           ## file target
    rewriting="$3-rewriting"   ## to linearize parallel rewriting file target
    if [ "$op" != "in" ]; then
	if [ -f "$rewriting" ];then
	    while [ -f "$rewriting" ]; do
		sleeping 0.1
	    done
	fi
	touch "$rewriting"
    fi

    if [ ! -z "$item" ]; then
	case $op in
	    +)
		line_file "in" "$item" "$file_target"
		if [ "$?" != 1 ]; then
		    echo "$item" >> "$file_target"
		fi
		rm -f "$rewriting"
		;;
	    -)
		if [ -f "$file_target" ]; then
		    sed -e "s|^$item$||g" \
			-e '/^$/d' -i "$file_target"

		    if (( $(wc -l < "$file_target") == 0 )); then
			rm "$file_target"
		    fi
		fi
		rm -f "$rewriting"
		;;
	    in) 
		if [ -f "$file_target" ]; then
		    if [[ $(grep "^${item}$" "$file_target") ]]; then 
			return 1
		    fi
		fi
		return 5
		;;
	esac
    fi
}

function run_in_dir {
    line_file "$1" "$2" "/tmp/.stdrun.zdl"
}

function pidprog_in_dir { ## $1 = testing directory
    if [ -f /tmp/.stdrun.zdl ]; then
	grep "$1" /tmp/.stdrun.zdl | awk '{print $1}' | while read line; do
	    check_pid $line
	    [ $? == 1 ] && echo $line
	done
    fi
}
