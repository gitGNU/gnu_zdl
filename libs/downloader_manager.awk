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

function check_in_url (url_in) {       
    for (i in pid_out) {
	if (sprintf(CONVFMT, url_out[i]) == sprintf(CONVFMT, url_in)) {
	    print bash_var("file_in", file_out[$i]) ## stesso URL => stesso filename
	    if (pid_alive[i]) { # ||					\
		# (							\
		#     exists(file_out[i]) &&				\
		#     ! exists(file_out[i] ".st") &&			\
		#     length_saved[i] != 0 &&				\
		#     length_saved[i] == length_out[i] &&			\
		#     percent_out[i] == 100				\
		#     ))							\
		echo "pippo"
		exit 1 ## no download
	    }
	}
    }
    exit 0
}

# function check_in_file { 	## return --> no_download=1 / download=5
#     sanitize_file_in
#     url_in_bis="${url_in::100}"
#     file_in_bis="${file_in}__BIS__${url_in_bis//\//_}.${file_in##*.}"
#     if [ ! -z "$exceeded" ]; then
# 	_log 4
# 	break_loop=true
# 	no_newip=true
# 	unset exceeded
# 	return 1
#     elif [ ! -z "$not_available" ]; then
# 	[ ! -z "$url_in_file" ] && _log 3
# 	no_newip=true
# 	unset not_available
# 	return 1
#     elif [ "$url_in_file" != "${url_in_file//{\"err\"/}" ]; then
# 	_log 2
# 	unset no_newip
# 	return 1
#     elif [ -z "$url_in_file" ] || ( [ -z "${file_in}" ] && [ "$downloader_in" == "Axel" ] ); then
# 	_log 2
# 	unset no_newip
#     fi

#     if [ ! -z "${file_in}" ]; then
# 	length_saved=0
# 	length_alias_saved=0
		    
# 	no_newip=true
# 	if data_stdout
# 	then
# 	    for ((i=0; i<${#pid_out[*]}; i++)); do
# 		if [ "${file_out[$i]}" == "$file_in" ] || [ "$file_in" == "${alias_file_out[$i]}" ]; then
# 		    if check_pid ${pid_out[$i]}
# 		    then
# 			return 1
# 		    fi
# 		    length_saved=${length_saved[$i]} 
# 		    [ -f "${alias_file_out[$i]}" ] && length_alias_saved=$(size_file "${alias_file_out[$i]}") || length_alias_saved=0
# 		    if [[ "${length_out[$i]}" =~ ^[0-9]+$ ]] && ( (( ${length_out[$i]}>$length_saved )) && (( ${length_out[$i]}>$length_alias_saved )) ); then
# 			length_check="${length_out[$i]}"
# 		    else
# 			unset length_check
# 		    fi
# 		    if [ "${file_out[$i]}" == "$file_in" ] && [ "$url_in" == "${url_out[$i]}" ]; then
# 			no_bis=true
# 		    fi
# 		    break
# 		elif [ "$file_in" != "${file_out[$i]}" ] && [ "$url_in" == "${url_out[$i]}" ] && [ "$file_in_bis" != "${file_out[$i]}" ]; then
# 		    rm -f "$path_tmp/${file_out[$i]}_stdout.tmp" "${file_out[$i]}" "${file_out[$i]}.st" 
# 		fi
# 	    done
# 	fi

# 	if [ -f "${file_in}" ]; then
# 	    ## --bis abilitato di default
# 	    [ "$resume" != "enabled" ] && bis=true
# 	    if [ "$bis" == true ]; then
# 		homonymy_treating=( resume_dl rewrite_dl bis_dl )
# 	    else
# 		homonymy_treating=( resume_dl rewrite_dl )
# 	    fi
	    
# 	    for i in ${homonymy_treating[*]}; do
# 		if [ "$downloader_in" == Wget ]; then
# 		    case "$i" in
# 			resume_dl|rewrite_dl) 
# 			    if [ ! -z "$length_check" ] && (( $length_check>$length_saved )) && ( [ -z "$bis" ] || [ "$no_bis" == true ] ); then
# 				rm -f "$file_in" "${file_in}.st" 
# 	 			unset no_newip
# 	 			[ ! -z "$url_in_file" ] && return 5
# 			    fi
# 			    ;;
# 		    esac
# 		elif [ "$downloader_in" == RTMPDump ]; then
# 		    case "$i" in
# 			resume_dl|rewrite_dl) 
# 			    [ -f "$path_tmp/${file_in}_stdout.tmp" ] && test_completed=$(grep 'Download complete' < "$path_tmp/${file_in}_stdout.tmp")
# 			    if [ -f "${file_in}" ] && [ -z "$test_completed" ] && ( [ -z "$bis" ] || [ "$no_bis" == true ] ); then 
# 				unset no_newip
# 				[ ! -z "$url_in_file" ] && return 5
# 			    fi
# 			    ;;
# 		    esac
# 		elif [ "$downloader_in" == Axel ]; then
# 		    case "$i" in
# 			resume_dl) 
# 			    if [ -f "${file_in}.st" ] && ( [ -z "$bis" ] || [ "$no_bis" == true ] ); then 
# 				unset no_newip
# 				[ ! -z "$url_in_file" ] && return 5
# 			    fi
# 			    ;;
# 			rewrite_dl)
# 			    if ( [ -z "$bis" ] || [ "$no_bis" == true ] ) && [ ! -z "$length_check" ] && (( $length_check>$length_saved )); then
# 				rm -f "$file_in" "${file_in}.st" 
# 	 			unset no_newip
# 	 			[ ! -z "$url_in_file" ] && return 5
# 			    fi
# 			    ;;
# 		    esac
# 		fi
# 		## case bis_dl
# 	        if [ "$i" == bis_dl ] && [ -z "$no_bis" ]; then
# 		    file_in="${file_in_bis}"
# 		    if [ ! -f "${file_in_bis}" ]; then
# 			return 5
# 		    elif [ -f "${file_in_bis}" ] || ( [ ${downloader_out[$i]} == RTMPDump ] && [ ! -z "$test_completed" ] ); then
# 			links_loop - "$url_in"
# 		    fi
# 		fi
# 	    done
	    
# 	    ## ignore link
# 	    if [[ "$length_saved" =~ ^[0-9]+$ ]] && (( "$length_saved" > 0 )); then
# 		_log 1
# 	    elif [[ "$length_saved" =~ ^[0-9]+$ ]] && (( "$length_saved" == 0 )); then
# 		rm -f "$file_in" "$file_in".st
# 	    fi
# 	    break_loop=true
# 	    no_newip=true
# 	elif [ ! -z "$url_in_file" ] || ( [ ! -z "$playpath" ] && [ ! -z "$streamer" ] ); then
# 	    return 5
# 	fi
#     fi
#     return 1
# }

