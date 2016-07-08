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
    ## per spazio minore di 50 megabyte (51200 Kb), return 1
    
    test_space=( $(df .) )
    (( test_space[11] < 51200 )) &&
	return 1

    return 0
}

function force_dler {
    dler=$downloader_in
    downloader_in="$1"
    ch_dler=1
    print_c 3 "Il server non permette l'uso di $dler: il download verrà effettuato con $downloader_in"
}


function dler_type {
    case "$1" in
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

    elif dler_type "youtube-dl" "$url_in"
    then
	if [ -n "$(command -v youtube-dl 2>/dev/null)" ]
	then
	    force_dler "youtube-dl"
	else
	    _log 20
	fi

    elif dler_type "rtmp" "$url_in"
    then
	if [ -n "$(command -v rtmpdump 2>/dev/null)" ]
	then
	    force_dler "RTMPDump"
    	    url_in_file="http://DOMA.IN/PATH"
	    
	elif [ -n "$(command -v curl 2>/dev/null)" ]
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
    downwait=5
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
	Aria2)
	    [ -n "$file_in" ] && argout="-o" && fileout="$file_in"
	
	    if [ -f "$path_tmp"/cookies.zdl ]
	    then
		opt_cookies="--load-cookies=$path_tmp/cookies.zdl"

	    elif [ -f "$path_tmp"/flashgot_cookie.zdl ]
	    then
		COOKIES="$(cat "$path_tmp"/flashgot_cookie.zdl)"
		if [ -n "$COOKIES" ]
		then
		    headers+=( "-H" "Cookie:$COOKIES" )
		fi

	    fi

	    length_in=$(wget -S --spider "$url_in_file" 2>&1 |
			    grep 'Content-Length:'           |
			    sed -r 's|\s*Content-Length:\s+(.+)|\1|g')

	    # -s $aria2_parts                           \
	    # -j $aria2_parts                           \

	    stdbuf -oL -eL                                   \
		   aria2c -U "$user_agent"                   \
		   -k 1M                                     \
		   -x 16                                     \
		   --continue=true                           \
		   --header="${headers[@]}"                  \
		   $opt_cookies                              \
		   --auto-file-renaming=false                \
		   -o "$fileout"                             \
		   "$url_in_file"                            \
		   >>"$path_tmp/${file_in}_stdout.tmp" &

	    pid_in=$!
	    touch "$file_in".aria2
		    
	    echo -e "${pid_in}
$url_in
Aria2
${pid_prog}
$file_in
$url_in_file
$aria2_parts
Content-Length: $length_in" > "$path_tmp/${file_in}_stdout.tmp"
	    ;;

	Axel)
	    [ -n "$file_in" ] && argout="-o" && fileout="$file_in"
	
	    if [ -f "$path_tmp"/cookies.zdl ]
	    then
		export AXEL_COOKIES="$path_tmp/cookies.zdl"

	    elif [ -f "$path_tmp"/flashgot_cookie.zdl ]
	    then
		COOKIES="$(cat "$path_tmp"/flashgot_cookie.zdl)"
		if [ -n "$COOKIES" ]
		then
		    headers+=( "-H" "Cookie:$COOKIES" )
		fi
	    fi

	    stdbuf -oL -eL                                  \
		   axel -U "$user_agent"                    \
		   -n $axel_parts                           \
		   "${headers[@]}"                          \
		   "$url_in_file"                           \
		   $argout "$fileout"                       \
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
	    stdbuf -oL -eL                               \
		   wget --user-agent="$user_agent"       \
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
    unset post_data checked headers
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

		elif [[ "$downloader_in" =~ (Aria2|Axel) ]]
		then
		    [ "$downloader_in" == Axel ] && rm -f "${file_in}" "${file_in}.aria2"
		    [ "$downloader_in" == Aria2 ] && rm -f "${file_in}.st"
		    
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
    [ -f "$path_tmp/external-dl_pids.txt" ] && kill $(cat "$path_tmp/external-dl_pids.txt")
    if data_stdout
    then
	[ -n "${pid_alive[*]}" ] && kill -9 ${pid_alive[*]} &>/dev/null
    fi
}
