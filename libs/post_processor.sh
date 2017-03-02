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

function post_m3u8 {
    ##  *.M3U8
    if ls *__M3U8__* &>/dev/null
    then
    	list_fname=$(ls -1 "$path_tmp"/filename_*__M3U8__* 2>/dev/null    |
    			    sed -r "s|$path_tmp/filename_(.+).txt|\1|g")

    	[ -z "$list_fname" ] &&
    	    list_fname=$(ls -1 *__M3U8__*)

    	list_fprefix=(
    	    $(grep -oP '.+__M3U8__' <<< "$list_fname" |
    		     awk '!($0 in a){a[$0]; print}')
    	)

    	for fprefix in "${list_fprefix[@]}"
    	do
    	    last_seg=$(grep "$fprefix" <<< "$list_fname" | wc -l)

    	    while (( $i<=$last_seg ))
    	    do
    		unset segments
    		for ((i=1; i<=$last_seg; i++))
    		do
    		    filename=$(grep -P "${fprefix}seg-[0-9]+-" <<< "$list_fname"     |
    				      head -n1                                       |
    				      sed -r "s|(${fprefix}seg-)[^-]+(-.+)|\1$i\2|g")

    		    if [ ! -f "$filename" ] ||
    		    	   [ ! -s "$filename" ]
    		    then
    		    	_log 22
    		    	url_resume=$(grep -h "seg-${i}-" "$path_tmp"/filename_"${fprefix}"* 2>/dev/null)

    			if url "$url_resume"
    			then
    		    	    wget -qO "$filename" "$url_resume" &&
    		    		print_c 1 "Segmento $i recuperato" &&
    		    		break
    			else
    			    _log 24
    			    exit 1
    			fi
    		    else
    	    	    	segments[i]="$filename"
    		    fi
    		done
    	    done

    	    print_header
    	    header_box "Creazione del file ${fprefix%__M3U8__}.mp4"

    	    if cat "${segments[@]}" > "${fprefix%__M3U8__}.ts" 2>/dev/null
    	    then
    		unset ffmpeg
    		command -v avconv &>/dev/null && ffmpeg="avconv"
    		command -v ffmpeg &>/dev/null && ffmpeg="ffmpeg"

    		if [ -z "$ffmpeg" ]
    		then
    		    dep=ffmpeg
    		    _log 23
		    
    		else
    		    preset=superfast # -preset [ultrafast | superfast | fast | medium | slow | veryslow | placebo]
    		    rm -f $ffmpeg-*.log

    		    if [ -e /cygdrive ]
    		    then
    			$ffmpeg -i "${fprefix%__M3U8__}.ts"       \
    				-report                           \
    				-acodec libfaac                   \
    				-ab 160k                          \
    				-vcodec libx264                   \
    				-crf 18                           \
    				-preset $preset                   \
    				-y                                \
    				"${fprefix%__M3U8__}.mp4"   &&
    			    rm -f "$fprefix"*
			
    		    else
    			( $ffmpeg -i "${fprefix%__M3U8__}.ts"       \
    				  -report                           \
    				  -acodec libfaac                   \
    				  -ab 160k                          \
    				  -vcodec libx264                   \
    				  -crf 18                           \
    				  -preset $preset                   \
    				  -y                                \
    				  "${fprefix%__M3U8__}.mp4" &>/dev/null &&
    				rm -f "$fprefix"* ) &
    			pid_ffmpeg=$!

    			ffmpeg_stdout $ffmpeg $pid_ffmpeg
    			unset key_to_continue
    		    fi
    		fi		
    	    fi
    	done
    fi
}

function post_process {
    local line
    ## mega.nz

    for line in *.MEGAenc
    do
	if [ -f "${path_tmp}/${line}.tmp" ] &&
	       [ ! -f "${line}.st" ]
	then
	    key=$(head -n1 "$path_tmp"/"$line".tmp)
	    iv=$(tail -n1 "$path_tmp"/"$line".tmp)

	    openssl enc -d -aes-128-ctr -K $key -iv $iv -in "$line" -out "${line%.MEGAenc}" &&
		rm -f "${path_tmp}/${line}.tmp" "$line" &&
		print_c 1 "Il file $line è stato decrittato come ${line%.MEGAenc}"
	fi
    done

    ## --mp3/--flac: conversione formato
    if [ -n "$format" ]
    then
	command -v avconv &>/dev/null && convert2format="avconv"
	command -v ffmpeg &>/dev/null && convert2format="ffmpeg"
	print_header
	header_box "Conversione in $format ($convert2format)"

	data_stdout
	if [ -n "$print_out" ] && [ -f "$path_tmp"/pipe_files.txt ]
	then
	    while read line
	    do
		if ! grep -P '^$line$' $print_out &>/dev/null
		then
		    echo "$line" >> "$print_out"
		fi
		
	    done < "$path_tmp"/pipe_files.txt 
	fi

	if [ -f "$print_out" ]
	then	    
	    for line in $(cat "$print_out")
	    do
		if [ -f "$line" ]
		then
		    mime="$(file -b --mime-type "$line")"
		    
		    if [[ "$mime" =~ (audio|video) ]]
		    then
			print_c 4 "Conversione del file: $line"
			[ "$this_mode" == "lite" ] && convert_params="-report -loglevel quiet"

			if [ -e /cygdrive ]
			then
			    $convert2format $convert_params                   \
					    -i "$line"                        \
					    -aq 0                             \
					    -y                                \
					    "${line%.*}.$format"         &&
				rm "$line"                               &&
				print_c 1 "Conversione riuscita: ${line%.*}.$format" ||
				    print_c 3 "Conversione NON riuscita: $line"
			    
			else
			    (
				nohup $convert2format                 \
				    -i "$line"                        \
				    -report                           \
				    -aq 0                             \
				    -y                                \
				    "${line%.*}.$format" &>/dev/null     &&
				    rm "$line"                           &&
				    print_c 1 "Conversione riuscita: ${line%.*}.$format" ||
					print_c 3 "Conversione NON riuscita: $line"
			    ) &
			    pid_ffmpeg=$!

			    ffmpeg_stdout $convert2format $pid_ffmpeg
			    unset key_to_continue
			fi
			print_header
		    fi
		fi
	    done

	    rm "$print_out"

	else
	    print_c 3 "Nessun file da covertire"
	fi
    fi
}
