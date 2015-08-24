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

function check_freespace {
    test_space=( $(df .) )
    (( ${test_space[11]} < 6000 )) && return 1 ## spazio minore di (circa) 5 megabyte
    return 0
}

function force_wget {
    dler=$downloader_in
    downloader_in=Wget
    ch_dler=1
    print_c 3 "Il server non permette l'uso di $dler: il download verrà effettuato con $downloader_in"
}

function check_axel {
    rm -f "$path_tmp"/axel_o*_test*

    axel -U "$user_agent" -n $axel_parts -o "$path_tmp"/axel_o_test "$url_in_file" 2>&1 >> "$path_tmp"/axel_stdout_test &
    pid_axel_test=$!

    while [[ ! "$(cat "$path_tmp"/axel_stdout_test 2>/dev/null)" =~ (Starting download|HTTP/1.1 [0-9]{3} ) ]]
    do
	if ! check_pid $pid_axel_test
	then
	    break
	fi
	sleep 0.5
    done
    kill -9 $pid_axel_test
    rm -f "$path_tmp"/axel_o*_test*

    if [[ "$(cat "$path_tmp"/axel_stdout_test 2>/dev/null)" =~ (Unable to connect to server|Server unsupported|400 Bad Request|403 Forbidden|Too many redirects) ]]
    then
	result="1"
    else 
	result="0"
    fi

    rm -f "$path_tmp"/axel_stdout_test
    return "$result"
}

function check_wget {
    wget_checked="$(wget -S --spider "$url_in_file" 2>&1)"
    if [[ "$wget_checked" =~ (Remote file does not exist|failed: Connection refused) ]]
    then
	return 1
    else 
	return 0
    fi
}

function download {
    export LANG="$prog_lang"
    export LANGUAGE="$prog_lang"
    unset headers

    if ! is_noresume "$url_in" &&
	    ! is_wget "$url_in" &&
	    ! is_rtmp "$url_in" &&
	    ! check_wget
    then
	if [[ "$wget_checked" =~ (HTTP/1.1 503) ]]
	then
	    _log 2
	else
	    _log 3
	fi
	return 1
    fi

    if [ $downloader_in == Axel ] &&
	   ! check_axel
    then
	force_wget
    fi

    if is_noresume "$url_in"
    then
	links_loop - "$url_in"
	_log 18
    fi

    case $downloader_in in
	Axel)
	    [ -n "$file_in" ] && argout="-o" && fileout="$file_in"

	    if [ -f "$path_tmp"/cookies.zdl ]
	    then
		export AXEL_COOKIES="$path_tmp/cookies.zdl"
		axel -U "$user_agent" -n $axel_parts "${url_in_file}" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &

	    elif [ -f "$path_tmp"/flashgot_cookie.zdl ]
	    then
		COOKIES="$(cat "$path_tmp"/flashgot_cookie.zdl)"
		if [ -n "$COOKIES" ]
		then
		    headers="-H \"Cookie:$COOKIES\""
		    axel -U "$user_agent" -n $axel_parts "$headers" "$url_in_file" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
		else
		    axel -U "$user_agent" -n $axel_parts "$url_in_file" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
		fi
	    else
		axel -U "$user_agent" -n $axel_parts "$url_in_file" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
	    fi
	    pid_in=$!
	    echo -e "${pid_in}
$url_in
Axel
${pid_prog}
$file_in
$url_in_file
$axel_parts" > "$path_tmp/${file_in}_stdout.tmp"
	    ;;
	
	Wget)
	    if [ -f "$path_tmp"/cookies.zdl ]
	    then
		COOKIES="$path_tmp/cookies.zdl"

	    elif [ -f "$path_tmp"/flashgot_cfile.zdl ]
	    then
		COOKIES="$path_tmp/flashgot_cfile.zdl"
	    fi

	    if [ -n "${post_data}" ]
	    then
		method_post="--post-data=${post_data}"
	    fi

	    if [ -n "$file_in" ]
	    then
		argout="-O"
		fileout="$file_in"
	    else
		argout="--trust-server-names"
	    fi

            ## -t 1 -T $max_waiting 
	    wget --user-agent="$user_agent"            \
		 --no-check-certificate                \
		 --retry-connrefused                   \
		 -c -nc -k -S                          \
		 --load-cookies=$COOKIES               \
		 $method_post "$url_in_file"           \
		 $argout "$fileout"                    \
		 -a "$path_tmp/${file_in}_stdout.tmp" &
	    pid_in=$!

	    echo -e "${pid_in}
$url_in
Wget
${pid_prog}
$file_in
$url_in_file" > "$path_tmp/${file_in}_stdout.tmp"
	    ;;
	
	RTMPDump)
	    if [ -z "$downloader_cmd" ]
	    then
		downloader_cmd="rtmpdump -r \"$streamer\" --playpath=\"$playpath\""
	    fi

	    pid_list_0="$(pid_list_for_prog "rtmpdump")"

	    eval $downloader_cmd -o "$file_in" &>>"$path_tmp/${file_in}_stdout.tmp" &
	    
	    ## pid_in=$!
	    pid_list_1="$(pid_list_for_prog "rtmpdump")"

	    if [ -z "$pid_list_0" ]
	    then
		pid_in="$pid_list_1"
	    else
		pid_in=$(grep -v "$pid_list_0" <<< "$pid_list_1")
	    fi

	    echo -e "${pid_in}
$url_in
RTMPDump
${pid_prog}
$file_in
$streamer
$playpath
$(date +%s)" > "$path_tmp/${file_in}_stdout.tmp"

	    unset downloader_cmd
	    ;;
	
	cURL)
	    if [ -z "$downloader_cmd" ]
	    then
		downloader_cmd="curl \"$streamer playpath=$playpath\""
	    fi

	    pid_list_0="$(pid_list_for_prog "curl")"

	    (
		eval $downloader_cmd -o "$file_in" 2>> "$path_tmp/${file_in}_stdout.tmp" 
		links_loop - "$url_in"
	      
	    ) 2>/dev/null &

	    pid_list_1="$(pid_list_for_prog "curl")"

	    if [ -z "$pid_list_0" ]
	    then
		pid_in="$pid_list_1"
	    else
		pid_in=$(grep -v "$pid_list_0" <<< "$pid_list_1")
	    fi

	    echo -e "${pid_in}
$url_in
cURL
${pid_prog}
$file_in
$streamer
$playpath" > "$path_tmp/${file_in}_stdout.tmp"

	    unset downloader_cmd
	    ;;
    esac
    
    if [ -n "$user" ] && [ -n "$host" ]
    then
	accounts_alive[${#accounts_alive[*]}]="${user}@${host}:${pid_in}"
	unset user host
    fi
    unset post_data checked
    export LANG="$user_lang"
    export LANGUAGE="$user_language"
    rm -f "$path_tmp/._stdout.tmp" "$path_tmp/_stdout.tmp"
    
    ## è necessario aspettare qualche secondo
    countdown- 5
}

function check_in_loop { 
    if data_stdout
    then
	num_dl=$(cat "$path_tmp/dl-mode")
	if [ -z "$num_dl" ] || (( "${#pid_alive[*]}" < "$num_dl" ))
	then
	    return 1 ## rompe il loop (esce dall'attesa) => procede con un altro download
	else
	    return 0 ## rimane nel loop (in attesa)
	fi
    fi
    return 1
}

function check_in_file { 	## return --> no_download=1 / download=0
    sanitize_file_in
    url_in_bis="${url_in::100}"
    file_in_bis="${file_in}__BIS__${url_in_bis//\//_}.${file_in##*.}"
    if [ -n "$exceeded" ]
    then
	_log 4
	break_loop=true
	no_newip=true
	unset exceeded
	return 1

    elif [ -n "$not_available" ]
    then
	[ -n "$url_in_file" ] && _log 3
	no_newip=true
	unset not_available
	return 1

    elif [ "$url_in_file" != "${url_in_file//{\"err\"/}" ]
    then
	_log 2
	unset no_newip
	return 1

    elif [ -z "$url_in_file" ] ||                               \
	( [ -z "$file_in" ] && [ "$downloader_in" == "Axel" ] )
    then
	_log 2
	unset no_newip
    fi

    if [ -n "$file_in" ]
    then
	length_saved_in=0
		    
	no_newip=true
	if data_stdout
	then
	    if [ -z "$file_in" ]
	    then
		return 1
	    fi
	fi

	if [ -f "$file_in" ]
	then
	    ## --bis abilitato di default
	    [ "$resume" != "enabled" ] && bis=true
	    if [ "$bis" == true ]
	    then
		homonymy_treating=( resume_dl rewrite_dl bis_dl )
	    else
		homonymy_treating=( resume_dl rewrite_dl )
	    fi
	    
	    for i in ${homonymy_treating[*]}
	    do
		if [ "$downloader_in" == "Wget" ]
		then
		    case "$i" in
			resume_dl|rewrite_dl) 
			    if [ -n "$length_in" ] &&                     
				   (( $length_in > $length_saved_in )) &&      
				   ( [ -z "$bis" ] || [ "$no_bis" == true ] )
			    then
				rm -f "$file_in" "${file_in}.st" 
	 			unset no_newip
	 			[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
		    esac

		elif [ "$downloader_in" == "RTMPDump" ]
		then
		    case "$i" in
			resume_dl|rewrite_dl) 
			    [ -f "$path_tmp/${file_in}_stdout.tmp" ] &&                                       
				test_completed=$(grep 'Download complete' < "$path_tmp/${file_in}_stdout.tmp")

			    if [ -f "${file_in}" ] &&                        
				   [ -z "$test_completed" ] &&                  
				   ( [ -z "$bis" ] || [ "$no_bis" == true ] )
			    then 
				unset no_newip
				[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
		    esac

		elif [ "$downloader_in" == "Axel" ]
		then
		    case "$i" in
			resume_dl) 
			    if [ -f "${file_in}.st" ] &&
				   ( [ -z "$bis" ] || [ "$no_bis" == true ] )
			    then                     
				unset no_newip
				[ ! -z "$url_in_file" ] && return 0
			    fi
			    ;;
			rewrite_dl)
			    if ( [ -z "$bis" ] || [ "$no_bis" == true ] ) &&
				   [ -n "$length_in" ] && (( $length_in > $length_saved_in ))
			    then
				rm -f "$file_in" "${file_in}.st" 
	 			unset no_newip
	 			[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
		    esac
		fi
		## case bis_dl
	        if [ "$i" == bis_dl ] && [ -z "$no_bis" ]
		then
		    file_in="$file_in_bis"

		    if [ ! -f "$file_in_bis" ]
		    then
			return 0

		    elif [ -f "$file_in_bis" ] ||
			     ( [ "${downloader_out[$i]}" == "RTMPDump" ] &&
				   [ -n "$test_completed" ] )
		    then
			links_loop - "$url_in"

		    fi
		fi
	    done
	    
	    ## ignore link
	    if [[ "$length_saved_in" =~ ^[0-9]+$ ]] && (( "$length_saved_in" > 0 ))
	    then
		_log 1

	    elif [[ "$length_saved_in" =~ ^[0-9]+$ ]] && (( "$length_saved_in" == 0 ))
	    then
		rm -f "$file_in" "$file_in".st

	    fi
	    break_loop=true
	    no_newip=true

	elif [ ! -z "$url_in_file" ] ||
		 ( [ ! -z "$playpath" ] && [ ! -z "$streamer" ] )
	then
	    return 0

	fi
    fi
    return 1
}


function links_loop {
    local url_test="$2"
    if [ "$1" == "+" ] && ! url "$url_test"
    then
	_log 12 "$url_test"
	links_loop - "$url_test"
    else
	[ "$1" == "+" ] && url_test="${url_test%'#20\x'}"
	line_file "$1" "$url_test" "$path_tmp/links_loop.txt"
    fi
}

function kill_downloads {
    if data_stdout
    then
	[ -n "${pid_alive[*]}" ] && kill -9 ${pid_alive[*]} &>/dev/null
    fi
}
