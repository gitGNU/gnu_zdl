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

## zdl-extension types: streaming download
## zdl-extension name: Openload

function OL_decode {
    local INDEX="$1"
    
    chunk=$($nodejs -e "var x = '$hiddenurl2'; var s=[];for(var i=0;i<x.length;i++){var j=x.charCodeAt(i);if((j>=33)&&(j<=126)){s[i]=String.fromCharCode(33+((j+14)%94));}else{s[i]=String.fromCharCode(j);}}; var tmp=s.join(''); var str = tmp.substring(0, tmp.length - 1) + String.fromCharCode(tmp.slice(-1).charCodeAt(0) + $INDEX); console.log(str)")

    if [ -n "$chunk" ]
    then
	url_in_file=$(wget -S --spider \
			   --referer="$URL_in" \
			   --keep-session-cookies                    \
    			   --load-cookies="$path_tmp"/cookies.zdl    \
    			   --user-agent="$user_agent"                \
			   "https://openload.co/stream/$chunk" 2>&1 |
			  grep Location | head -n1 |
			  sed -r 's|.*Location: (.+)$|\1|g')

	[ -z "$file_in" ] && file_in="${url_in_file##*\/}"

	if [[ "$url_in_file" =~ \/x\.mp4$ ]] &&
	       ((INDEX < 5))
	then
	    OL_decode $((INDEX+1))

	elif ((INDEX >= 5))
	then
	    _log 32
	fi
    fi
}


function OL_decode2 {
    local hidden1="$1"
    local hidden2="$2"
    local INDEX="$3"
    [ -z "$INDEX" ] &&
	INDEX=1
    
    chunk=$($nodejs -e "var x = '$hidden2';
	var y = '$hidden1';
	var magic = y.slice(-1).charCodeAt(0);
	y = y.split(String.fromCharCode(magic-1)).join('	');
	y = y.split(y.slice(-1)).join(String.fromCharCode(magic-1));
	y = y.split('	').join(String.fromCharCode(magic));
	var s=[];for(var i=0;i<y.length;i++){var j=y.charCodeAt(i);if((j>=33)&&(j<=126)){s[i]=String.fromCharCode(33+((j+14)%94));}else{s[i]=String.fromCharCode(j);}}
	var tmp=s.join('');
	var str = tmp.substring(0, tmp.length - 1) + String.fromCharCode(tmp.slice(-1).charCodeAt(0) + 3);
	console.log(str);
	")

    if [ -n "$chunk" ]
    then
	url_in_file=$(wget -S --spider \
			   --referer="$URL_in" \
			   --keep-session-cookies                    \
    			   --load-cookies="$path_tmp"/cookies.zdl    \
    			   --user-agent="$user_agent"                \
			   "https://openload.co/stream/$chunk" 2>&1 |
			  grep Location | head -n1 |
			  sed -r 's|.*Location: (.+)$|\1|g')

	[ -z "$file_in" ] && file_in="${url_in_file##*\/}"
    fi
}
 
function OL_decode3 {
    local hidden1="$1"
    local hidden2="$2"

    echo "function(){" > "$path_tmp/decoded.js"
    echo "var y = '$hidden1';" >> "$path_tmp/decoded.js"
    echo "var x = '$hidden2';" >> "$path_tmp/decoded.js"
    grep var "$path_tmp/aadecoded.js" |grep -vP '(x|y) =' >>"$path_tmp/decoded.js"
    grep 'function ' "$path_tmp/aadecoded.js" -A2 >> "$path_tmp/decoded.js"
    echo "return str;}()" >> "$path_tmp/decoded.js"

    chunk=$(nodejs_eval "$path_tmp/decoded.js")

    if [ -n "$chunk" ]
    then
	url_in_file=$(wget -S --spider \
			   --referer="$URL_in" \
			   --keep-session-cookies                    \
    			   --load-cookies="$path_tmp"/cookies.zdl    \
    			   --user-agent="$user_agent"                \
			   "https://openload.co/stream/$chunk" 2>&1 |
			  grep Location | head -n1 |
			  sed -r 's|.*Location: (.+)$|\1|g')

	[ -z "$file_in" ] && file_in="${url_in_file##*\/}"
    fi
}



if [[ "$url_in" =~ (openload\.) ]]
then
    URL_in="$(sed -r 's|\/F\/|/f/|g' <<< "$url_in")"
    URL_in="$(sed -r 's|\/embed\/|/f/|g' <<< "$url_in")"

    html=$(wget -t 1 -T $max_waiting                      \
    		-qO-                                      \
    		--retry-connrefused                       \
    		--keep-session-cookies                    \
    		--save-cookies="$path_tmp"/cookies.zdl    \
    		--user-agent="$user_agent"                \
    		"${URL_in}")

    file_in=$(grep '<title>' <<< "$html" |sed -r 's/.+\<title>([^|]+)\ \|\ openload.+/\1/g')

    if [[ "$file_in" =~ ([fF]{1}ile [nN]{1}ot [fF]{1}ound) ]]
    then
	_log 3
	
    elif [ -n "$html" ]
    then
	awk '/\^o/{print}' <<< "$html"   |
	    head -n1                |
	    sed -r 's|[^>]+>(.+)</script.+|\1|g' >"$path_tmp/aaencoded.js" 

	php_aadecode "$path_tmp/aaencoded.js" >"$path_tmp/aadecoded.js"
	
	hiddenurl1=$(grep '"streamurl' -B2 <<< "$html" | head -n1 |
			   sed -r 's|.+\">(.+)<\/span>.*|\1|g')

	hiddenurl1=$(htmldecode "$hiddenurl1")
	hiddenurl1="${hiddenurl1//\\/\\\\}"
	hiddenurl1="${hiddenurl1//\'/\\\'}"
	hiddenurl1="${hiddenurl1//\"/\\\"}"
	hiddenurl1="${hiddenurl1//\`/\\\`}"
	hiddenurl1="${hiddenurl1//\$/\\\$}"

	hiddenurl2=$(grep '"streamurl' -B1 <<< "$html" | head -n1 |
			   sed -r 's|.+\">(.+)<\/span>.*|\1|g')
	
	hiddenurl2=$(htmldecode "$hiddenurl2")
	hiddenurl2="${hiddenurl2//\\/\\\\}"
	hiddenurl2="${hiddenurl2//\'/\\\'}"
	hiddenurl2="${hiddenurl2//\"/\\\"}"
	hiddenurl2="${hiddenurl2//\`/\\\`}"
	hiddenurl2="${hiddenurl2//\$/\\\$}"

	countdown- 6
	
	# OL_decode 1
	# OL_decode2 "$hiddenurl1" "$hiddenurl2"
	OL_decode3 "$hiddenurl1" "$hiddenurl2"
    fi

    end_extension
fi


