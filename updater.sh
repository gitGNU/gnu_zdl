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
	sudo $cmd 2>/dev/null
	if [ "$?" != 0 ]; then
	    su -c "$cmd" 2>/dev/null
	    if [ "$?" != 0 ]; then
		print_c 3 "$failure";
		return 1
	    fi
	fi
    fi
}


function update {
    PROG=ZigzagDownLoader
    prog=zdl
    BIN="/usr/local/bin"
    SHARE="/usr/local/share/zdl"
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

    update_zdl-wise

    chmod +rx -R .

    try mv zdl zdl-xterm $BIN 
    if [ $? != 0 ]; then
	print_c 3 "Aggiornamento non riuscito. Riprova un'altra volta"
	exit 1
    else
	print_c 1 "Aggiornamento automatico in $BIN"
    fi
    [ "$?" != 0 ] && return
    cd ..


    [ ! -e "$SHARE" ] && try mkdir -p "$SHARE"
    try rm -rf "$SHARE"
    try mkdir -p /usr/share/info
    try mkdir -p /usr/share/man/it/man1
    try install zdl/docs/zdl.1 /usr/share/man/it/man1/
    try rm -f /usr/share/man/man1/zdl.1
    try ln -s /usr/share/man/it/man1/zdl.1 /usr/share/man/man1/zdl.1
    try mandb -q
    try install -m 644 zdl/docs/zdl.info /usr/share/info/
    try install-info --info-dir=/usr/share/info /usr/share/info/zdl.info &>/dev/null
    try mv "$prog" "$SHARE"
    if [ $? != 0 ]; then
	print_c 3 "Aggiornamento non riuscito. Riprova un'altra volta"
	exit 1
    else
	print_c 1 "Aggiornamento automatico in $SHARE/$prog"
    fi
    
    if [ -e /cygdrive ]; then
	code_batch=$(cat $SHARE/zdl.bat)
	echo "${code_batch//'{{{CYGDRIVE}}}'/$cygdrive}" > /${prog}.bat && print_c 1 "\nScript batch di avvio installato: $(cygpath -m /)/zdl.bat "
	chmod +x /${prog}.bat
    fi

    update_zdl-conkeror
    
    cp *.sig "$path_conf"/zdl.sig
    rm -fr *.gz *.sig "$prog"
    cd ..
    dir_dest=$PWD

    ## Cygwin: dipendenze

    if [ -e /cygdrive ]
    then
	cd /tmp

	if [[ ! $(command -v apt-cyg 2>/dev/null) ]]
	then
	    echo -e "
Installazione di apt-cyg
"
	    wget http://rawgit.com/transcode-open/apt-cyg/master/apt-cyg
	    install apt-cyg /bin
	fi

	if [[ ! $(command -v ffmpeg 2>/dev/null) ]]
	then
	    echo -e "
Installazione di FFMpeg
"
	    rm -f /tmp/list-pkts.txt
	    apt-cyg -m ftp://ftp.cygwinports.org/pub/cygwinports install ffmpeg | tee -a /tmp/list-pkts.txt
	    
	    unset pkts
	    mapfile pkts <<< "$(grep Unable /tmp/list-pkts.txt | sed -r 's|.+ ([^\ ]+)$|\1|g')"
	    print_c 1 "\nRecupero pacchetti non trovati:\n${pkts[*]}\n"
	    apt-cyg -m http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/ install ${pkts[*]}
	fi

	if [[ ! $(command -v nano 2>/dev/null) ]]
	then
	    apt-cyg -m http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/ install nano
	fi
	if [[ ! $(command -v diff 2>/dev/null) ]]
	then
	    apt-cyg -m http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/ install diffutils
	fi
    fi
    print_c 1 "Aggiornamento automatico completato"
    pause
    cd $dir_dest
    $prog ${args[*]}

    exit
}

