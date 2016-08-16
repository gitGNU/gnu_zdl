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


function force_dler {
    dler=$downloader_in
    downloader_in="$1"
    ch_dler=1
    [ "$dler" != "$downloader_in" ] &&
	print_c 3 "Il server non permette l'uso di $dler: il download verrà effettuato con $downloader_in"
}


function dler_type {
    case "$1" in
	aria2)
	    type_links=( "${aria2_links[@]}" )
	    ;;
	dcc_xfer)
	    type_links=( "${dcc_zfer_links[@]}" )
	    ;;
	rtmp)
	    type_links=( "${rtmp_links[@]}" )
	    ;;
	youtube-dl)
	    type_links=( "${youtubedl_links[@]}" )
	    ;;
	wget)
	    type_links=( "${wget_links[@]}" )
	    ;;
	no-resume)
	    type_links=( "${noresume_links[@]}" )
	    ;;
	no-check)
	    type_links=( "${no_check_links[@]}" )
	    ;;
	no-check-ext)
	    type_links=( "${no_check_ext[@]}" )
	    ;;
    esac
    
    for h in ${type_links[*]}
    do
	[[ "$2" =~ ($h) ]] && return
    done
    return 1
}

function check_dler_forcing {
    if dler_type "wget" "$url_in"
    then
	force_dler "Wget"

    elif dler_type "aria2" "$url_in"
    then
	if command -v aria2c &>/dev/null
	then
	    force_dler "Aria2"
	fi

    elif dler_type "dcc_xfer" "$url_in"
    then
	force_dler "DCC_Xfer"	

    elif dler_type "youtube-dl" "$url_in"
    then
	if command -v youtube-dl &>/dev/null
	then
	    force_dler "youtube-dl"
	else
	    _log 20
	fi

    elif dler_type "rtmp" "$url_in"
    then
	if command -v rtmpdump &>/dev/null
	then
	    force_dler "RTMPDump"
    	    url_in_file="http://DOMA.IN/PATH"
	    
	elif command -v curl &>/dev/null
	then
	    force_dler "cURL"
	    url_in_file="http://DOMA.IN/PATH"
	else
	    print_c 3 "$url_in --> il download richiede l'uso di RTMPDump, che non è installato" | tee -a $file_log
	    links_loop - "$url_in"
	    break_loop=true
	fi
    fi
    
}

function check_axel {
    unset result_ck
    rm -f "$path_tmp"/axel_*_test

    axel -U "$user_agent" -n $axel_parts $headers -o "$path_tmp"/axel_o_test "$url_in_file" -v 2>&1 >> "$path_tmp"/axel_stdout_test &
    pid_axel_test=$!

    while [[ ! "$(cat "$path_tmp"/axel_stdout_test)" =~ (Starting download|HTTP/[0-9.]+ [0-9]{3} ) ]] &&
	      check_pid $pid_prog
    do
	if ! check_pid $pid_axel_test ||
		(( $loops>40 ))
	then
	    unset loops
	    (( $loops>40 )) && result_ck=1
	    break
	fi
	sleep 0.5
	(( loops++ ))
    done
    
    kill -9 $pid_axel_test 2>/dev/null

    if [[ "$(cat "$path_tmp"/axel_stdout_test 2>/dev/null)" =~ (Connection gone.|Unable to connect to server|Server unsupported|400 Bad Request|403 Forbidden|Too many redirects) ]] &&
	   [ -z "$result_ck" ]
    then
	result_ck="1"
    else 
	result_ck="0"
    fi

    rm -f "$path_tmp"/axel_*_test
    return "$result_ck"
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
    downwait=6
    export LANG="$prog_lang"
    export LANGUAGE="$prog_lang"

    if ! dler_type "no-check" "$url_in" &&
	    [ -z "$debrided" ]
    then
	if ! dler_type "no-resume" "$url_in" &&
		! dler_type "rtmp" "$url_in" &&
		! dler_type "wget" "$url_in" &&
		! dler_type "youtube-dl" "$url_in" &&
		! check_wget
	then
	    if [[ ! "$wget_checked" =~ (HTTP/[0-9.]+ 503) ]]
	    then
		_log 2 #3
		return 1
	    fi
	    if [[ "$wget_checked" =~ (HTTP/[0-9.]+ 404) ]]
	    then
		_log 3
		return 1
	    fi
	fi

	if [ "$downloader_in" == "Axel" ] &&
	       ! check_axel
	then
	    force_dler "Wget"
	fi

	if dler_type "no-resume" "$url_in"
	then
	    links_loop - "$url_in"
	    _log 18
	fi

    else
	unset debrided
    fi

    case "$downloader_in" in
	DCC_Xfer)
	    unset irc ctcp
	    declare -A ctcp
	    declare -A irc
	    if [[ "$url_in" =~ ^irc:\/\/([^/]+)\/([^/]+)\/([^/]+) ]]
	    then
		MSG=$(urldecode "${BASH_REMATCH[3]}")
		MSG="${MSG#ctcp}"
		MSG="${MSG#msg}"
		MSG=$(trim "$MSG")
		
		irc=(
		    [host]="${BASH_REMATCH[1]}"
		    [port]=6667
		    [chan]="${BASH_REMATCH[2]}"
		    [msg]="${MSG}"
		    [nick]=$(obfuscate "$USER")
		)
	    fi
#		    [nick]=$(obfuscate "$USER")
	    [[ "${irc[host]}" =~ ^(.+)\:([0-9]+)$ ]] &&
		{
		    irc[host]="${BASH_REMATCH[1]}"
		    irc[port]="${BASH_REMATCH[2]}"
		}

	    # rm -f "$path_tmp/${irc[nick]}" "$path_tmp/${irc[nick]}".fifo
	    # mkfifo "$path_tmp/${irc[nick]}".fifo

	    stdbuf -i0 -o0 -e0 \
		   $path_usr/irc_client.sh "${irc[host]}" "${irc[port]}" "${irc[chan]}" "${irc[msg]}" "${irc[nick]}" "$url_in" "$this_tty" &
	    pid_in=$!
	    echo "$pid_in" >>"$path_tmp/external-dl_pids.txt"
	    
	    while [ ! -f "$path_tmp/${irc[nick]}" ]
	    do sleep 0.1
	    done

	    downwait=10
	    file_in=$(head -n1 "$path_tmp/${irc[nick]}")
	    url_in_file=$(tail -n1 "$path_tmp/${irc[nick]}")
	    rm -f "$path_tmp/${irc[nick]}"
	    
	    if [ "$url_in_file" != "${url_in_file#\/}" ]
	    then
		##	    echo -e "$pid_in	    
		echo -e "____PID_IN____
$url_in
DCC_Xfer
${pid_prog}
$file_in
$url_in_file" >"$path_tmp/${file_in}_stdout.tmp"

	    else
		downwait=0
	    fi
	;;

	Aria2)

	    if [[ "$url_in_file" =~ ^(magnet:) ]] ||
		   [ -f "$url_in_file" ]
	    then
	    	[ -n "$tcp_port" ] &&
		    opts+=( "--listen-port=$tcp_port" )

		[ -n "$udp_port" ] &&
		    opts+=( '--enable-dht=true' "--dht-listen-port=$udp_port" )
		
	    elif [ -n "$file_in" ]
	    then		
		fileout=( -o "$file_in" )
		
		if [ -f "$path_tmp"/cookies.zdl ]
		then
		    opts+=( --load-cookies="$path_tmp/cookies.zdl" )
		    
		elif [ -f "$path_tmp"/flashgot_cookie.zdl ]
		then
		    COOKIES="$(cat "$path_tmp"/flashgot_cookie.zdl)"
		    if [ -n "$COOKIES" ]
		    then
			headers+=( "Cookie:$COOKIES" )
		    fi
		fi

		if [ -n "${headers[*]}" ]
		then
		    for header in "${headers[@]}"
		    do
			opts+=( --header="$header" )
		    done
		fi
		
		opts+=(
		    -U "$user_agent"
		    -k 1M
		    -x $aria2_connections
		    --continue=true
		    --auto-file-renaming=false
		    --allow-overwrite=true              
		    --follow-torrent=false 
		    --human-readable=false
		)
	    fi

	    ##################
	    ## -s $aria2_parts
	    ## -j $aria2_parts
	    ##################

	    stdbuf -oL -eL                                   \
		   aria2c                                    \
		   "${opts[@]}"                              \
		   "${fileout[@]}"                           \
		   "$url_in_file"                            \
		   &>>"$path_tmp/${file_in}_stdout.tmp" &

	    pid_in=$!    
		    
	    echo -e "${pid_in}
$url_in
Aria2
${pid_prog}
$file_in
$url_in_file
$aria2_parts" >"$path_tmp/${file_in}_stdout.tmp"
	    ;;

	Axel)
	    [ -n "$file_in" ] &&
		fileout+=( -o "$file_in" )
	
	    if [ -f "$path_tmp"/cookies.zdl ]
	    then
		export AXEL_COOKIES="$path_tmp/cookies.zdl"

	    elif [ -f "$path_tmp"/flashgot_cookie.zdl ]
	    then
		COOKIES="$(cat "$path_tmp"/flashgot_cookie.zdl)"
		if [ -n "$COOKIES" ]
		then
		    headers+=( "Cookie:$COOKIES" )
		fi
	    fi

	    if [ -n "${headers[*]}" ]
	    then
		for header in "${headers[@]}"
		do
		    opts+=( -H "$header" )
		done
	    fi

	    opts+=(
		-U "$user_agent"
		-n $axel_parts
	    )

	    
	    stdbuf -oL -eL                                  \
		   axel                                     \
		   "${opts[@]}"                             \
		   "$url_in_file"                           \
		   "${fileout[@]}"                          \
		   >> "$path_tmp/${file_in}_stdout.tmp" &

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

	    if [ -n "$COOKIES" ]
	    then
	    	opts+=( --load-cookies="$COOKIES" )
	    fi

	    if [ -n "${post_data}" ]
	    then
		opts+=( --post-data="${post_data}" )
	    fi

	    if [ -n "$file_in" ]
	    then
		fileout+=( -O "$file_in" )
	    else
		fileout+=( "--trust-server-names" )
	    fi

	    opts+=(
		--user-agent="$user_agent"
		--no-check-certificate
		--retry-connrefused
		-c -nc -k -S       
	    )
	    
            ## -t 1 -T $max_waiting
	    stdbuf -oL -eL                               \
		   wget                                  \
		   "${opts[@]}"                          \
		   "$url_in_file"                        \
		   "${fileout[@]}"                       \
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
	    
	    downwait=10
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

	FFMpeg)
	    ## URL-FILE.M3U8
	    ffmpeg -y -i "$url_in_file" -c copy "$file_in" 2>&1 |
		tr '\r' '\n' > "$path_tmp/${file_in}_stdout.tmp" &
	    pid_in=$!
	    echo -e "${pid_in}
$url_in
FFMpeg
${pid_prog}
$file_in" > "$path_tmp/${file_in}_stdout.tmp"

 	    ;;
	
	youtube-dl)
	    ## provvisorio per youtube-dl non gestito	    
	    _log 21
	    echo
	    header_dl "youtube-dl in $PWD"

	    if [ -n "$DISPLAY" ] &&
		   [ ! -e /cygdrive ]
	    then
		xterm -tn "xterm-256color"                                              \
		      -fa "XTerm*faceName: xft:Dejavu Sans Mono:pixelsize=12" +bdc      \
		      -fg grey -bg black -title "ZigzagDownLoader in $PWD"              \
		      -e "youtube-dl \"$url_in_file\"" &
		
	    else
		[ -f "$path_tmp/external-dl_pids.txt" ] && kill $(cat "$path_tmp/external-dl_pids.txt") 
		
		youtube-dl "$url_in_file" --newline &>> "$path_tmp/${file_in}_stdout.ytdl" &
 		pid_ytdl=$!
		
		echo -e "${pid_in}
$url_in
youtube-dl
${pid_prog}
$file_in
$url_in_file" > "$path_tmp/${file_in}_stdout.ytdl"
		
		echo "$pid_ytdl" >> "$path_tmp/external-dl_pids.txt"
		
		while check_pid $pid_ytdl
		do
		    sleep 2
		    print_r 0 "$(tail -n1 "$path_tmp/${file_in}_stdout.ytdl")                                                                        "
		done
		rm -f "$path_tmp/${file_in}_stdout.ytdl"
	    fi
	    ;;
    esac
    
    if [ -n "$user" ] && [ -n "$host" ]
    then
	accounts_alive[${#accounts_alive[*]}]="${user}@${host}:${pid_in}"
	unset user host
    fi
    unset post_data checked headers opts fileout COOKIES header
    export LANG="$user_lang"
    export LANGUAGE="$user_language"
    rm -f "$path_tmp/._stdout.tmp" "$path_tmp/_stdout.tmp"
    
    ## è necessario aspettare qualche secondo
    countdown- $downwait
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

    elif [ -z "$url_in_file" ] ||                               
	( [ -z "$file_in" ] && [[ "$downloader_in" =~ (Aria2|Axel) ]] )
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
				rm -f "$file_in" "${file_in}.st" "${file_in}.aria2" #"${file_in}.zdl"  
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

		elif [[ "$downloader_in" =~ (Aria2|Axel) ]]
		then
		    [ "$downloader_in" == Axel ] && rm -f "${file_in}" "${file_in}.aria2"
		    [ "$downloader_in" == Aria2 ] && rm -f "${file_in}.st"
		    #[ "$downloader_in" == DCC_Xfer ] && rm -f "${file_in}.zdl"
		    
		    case "$i" in
			resume_dl) 
			    if ( [ -f "${file_in}.st" ] || [ -f "${file_in}.aria2" ] ) &&
				   ( [ -z "$bis" ] || [ "$no_bis" == true ] )
			    then                     
				unset no_newip
				[ -n "$url_in_file" ] && return 0
			    fi
			    ;;
			rewrite_dl)
			    if ( [ -z "$bis" ] || [ "$no_bis" == true ] ) &&
				   [ -n "$length_in" ] && (( $length_in > $length_saved_in ))
			    then
				rm -f "$file_in" "${file_in}.st" "${file_in}.aria2" 
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

	elif [ -n "$url_in_file" ] ||
		 ( [ -n "$playpath" ] && [ -n "$streamer" ] )
	then
	    return 0

	fi
    fi
    return 1
}


function links_loop {
    local url_test="${2}"
    if [ "$1" == "+" ] &&
	   ! url "$url_test"
    then
	_log 12 "$url_test"
	links_loop - "$url_test"

    else
	[ "$1" == "+" ] &&
	    url_test="${url_test%'#20\x'}"

	line_file "$1" "$url_test" "$path_tmp/links_loop.txt"
    fi
}

