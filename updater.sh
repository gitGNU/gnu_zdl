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
# Copyright (C) 2012
# Free Software Foundation, Inc.
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (project administrator and first inventor)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#


function update_zdl-wise {
    if [ ! -e "/cygdrive" ]; then
	print_c 1 "Compilazione automatica di zdl-wise.c"
	gcc extensions/zdl-wise.c -o extensions/zdl-wise 2>/dev/null 
    fi
}


function update_zdl-conkeror {
    [ -f "$path_conf/conkerorrc.zdl" ] && rm "$path_conf/conkerorrc.zdl"
    if [ -e /cygdrive ]; then
	rc_path="${win_home}/.conkerorrc"
    else
	rc_path="$HOME/.conkerorrc"
    fi
    if [ -f "$rc_path" ]; then
	mv "$rc_path" conkerorrc.js
	mkdir -p "$rc_path"
	code_conkerorrc="$(cat conkerorrc.js)"
	code_conkerorrc="${code_conkerorrc//require(\"conkerorrc.zdl\");}"
	code_conkerorrc="${code_conkerorrc//require(\"$path_conf\/conkerorrc.zdl\");}"
	code_conkerorrc="${code_conkerorrc//require(\"$SHARE\/extensions\/conkerorrc.zdl\");}"
	code_conkerorrc="${code_conkerorrc//\/\/ ZigzagDownLoader}"
	echo "${code_conkerorrc}" > "$rc_path"/conkerorrc.js
    else
	mkdir -p "$rc_path"
    fi
    code_zdlmod="$(cat $SHARE/extensions/conkerorrc.zdl)"
    echo "${code_zdlmod//'{{{CYGDRIVE}}}'/$cygdrive}" > "$rc_path"/zdl.js
}


function try {
    cmd=$*
    $cmd 2>/dev/null
    if [ "$?" != 0 ]; then
	sudo $cmd 
	if [ "$?" != 0 ]; then
	    su -c "$cmd" || ( print_c 3 "$failure"; return 1 )
	fi
    fi
}

function update {
    PROG=ZigzagDownLoader
    prog=zdl
    BIN="/usr/local/bin"
    SHARE="/usr/local/share/zdl"
    URL_ROOT="http://download.savannah.gnu.org/releases/zdl/"
    axel_url="http://www.inventati.org/zoninoz/html/upload/files/axel-2.4-1.tar.bz2" #http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
    success="Aggiornamento completato"
    failure="Aggiornamento non riuscito"
    path_conf="$HOME/.$prog"
    if [ -e /cygdrive ]; then
	win_home=$(cygpath -u "$HOMEDRIVE$HOMEPATH")
	win_progfiles=$(cygpath -u "$PROGRAMFILES")
    fi 
    cygdrive=$(realpath /cygdrive/?/cygwin 2>/dev/null)
    [ -z "$cygdrive" ] && cygdrive=$(realpath /cygdrive/?/Cygwin 2>/dev/null)
    cygdrive="${cygdrive#*cygdrive\/}"
    cygdrive="${cygdrive%%\/*}"
    [ -z "$cygdrive" ] && cygdrive="C"    

    header_box "\e[1mAggiornamento automatico di ZigzagDownLoader\e[0m\n"

    rm -fr "$path_tmp"/*.gz "$path_tmp"/*.sig "$prog"
    cd "$path_tmp"
    print_c 1 "Download in corso: attendere..."
    wget "$URL_ROOT" -r -l 1 -A gz,sig,txt -np -nd -q
    cd ..
    if [ -f "$path_conf"/zdl.sig ]; then
	test_version=$(diff "$path_conf"/zdl.sig "$path_tmp"/*.sig )
    fi
    if [ -z "$test_version" ] && [ -f "$path_conf"/zdl.sig ]; then
	print_c 1 "$PROG è già alla versione più recente"
    else
	cd "$path_tmp"
	package=$(ls *.tar.gz)
	print_c 1 "Aggiornamento di $PROG con $package"
	tar -xzf "$package"

	mv "${package%.tar.gz}" $prog
	cd $prog
	update_zdl-wise

	chmod +rx -R .
	print_c 1 "Aggiornamento automatico in $BIN"
	try mv zdl zdl-xterm $BIN
	[ "$?" != 0 ] && return

	if [ -e /cygdrive ]; then
	    code_batch=$(cat $SHARE/zdl.bat)
	    echo "${code_batch//'{{{CYGDRIVE}}}'/$cygdrive}" > /${prog}.bat && bold "\nScript batch di avvio installato: $(cygpath -m /)/zdl.bat "
	fi

	cd ..

	print_c 1 "Aggiornamento automatico in $SHARE/$prog"
	[ ! -e "$SHARE" ] && try mkdir -p "$SHARE"
	try rm -rf "$SHARE"
	try cp -r "$prog" "$SHARE"

	update_zdl-conkeror
	
	cp *.sig "$path_conf"/zdl.sig
	
	print_c 1 "Aggiornamento automatico completato"
	pause
	cd ..
	$prog ${args[*]}
	exit
    fi
}
