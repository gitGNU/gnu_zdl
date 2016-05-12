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

## Axel - Cygwin
function install_axel-cygwin {
    ## source: http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
    cygaxel_url="http://www.inventati.org/zoninoz/html/upload/files/axel-2.4-1.tar.bz2" 
    
    if ! command -v axel &>/dev/null
    then
	cd /
	wget "$cygaxel_url"
	tar -xvjf "${cygaxel_url##*'/'}"
	cd -
    fi
}

##############


function update_zdl-wise {
    if [ ! -e "/cygdrive" ]
    then
	print_c 1 "Compilazione automatica di zdl-wise.c"
	gcc extensions/zdl-wise.c -o extensions/zdl-wise 2>/dev/null 
    fi
}


function update_zdl-conkeror {
    [ -f "$path_conf/conkerorrc.zdl" ] && rm "$path_conf/conkerorrc.zdl"

    if [ -e /cygdrive ]
    then
	rc_path="${win_home}/.conkerorrc"
    else
	rc_path="$HOME/.conkerorrc"
    fi

    if [ -f "$rc_path" ]
    then
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
    
    if ! $cmd 2>/dev/null 
    then	
	if ! sudo $cmd 2>/dev/null 
	then
	    su -c "$cmd" || ( print_c 3 "$failure: $cmd"; return 1 )
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
    file_conf="$path_conf/$prog.conf"

    if [ "$installer" == "true" ]
    then
	op="Installazione"
	suffix="a"
    else
	op="Aggiornamento"
	suffix="o"
    fi

    if [[ -z "$(grep 'shopt -s checkwinsize' $HOME/.bashrc)" ]]
    then
	echo "shopt -s checkwinsize" >> ~/.bashrc 
    fi

    mkdir -p "$path_conf/extensions"

    if [ ! -f "$file_conf" ]
    then
	echo "# ZigzagDownLoader configuration file" > "$file_conf"
    fi

    if [ -e /cygdrive ]
    then
	win_home=$(cygpath -u "$HOMEPATH")
	win_progfiles=$(cygpath -u "$PROGRAMFILES")

	cygdrive=$(realpath /cygdrive/?/cygwin 2>/dev/null)
	[ -z "$cygdrive" ] && cygdrive=$(realpath /cygdrive/?/Cygwin 2>/dev/null)
	cygdrive="${cygdrive#*cygdrive\/}"
	cygdrive="${cygdrive%%\/*}"
	[ -z "$cygdrive" ] && cygdrive="C"

	
    fi
    # update_zdl-wise

    chmod +rx -R .

    
    if ! try mv zdl zdl-xterm $BIN
    then
	print_c 3 "$op non riuscit${suffix}. Riprova un'altra volta"
	exit 1
    else
	print_c 1 "$op automatic${suffix} in $BIN"
    fi
    
    [ "$?" != 0 ] && return
    cd ..

    [ ! -e "$SHARE" ] && try mkdir -p "$SHARE"
    if [ -f $SHARE/node.exe ]
    then
	cp $SHARE/node.exe /tmp/
    fi
    try rm -rf "$SHARE"
    try mkdir -p /usr/share/info
    try mkdir -p /usr/share/man/it/man1
    try install zdl/docs/zdl.1 /usr/share/man/it/man1/
    try rm -f /usr/share/man/man1/zdl.1
    try ln -s /usr/share/man/it/man1/zdl.1 /usr/share/man/man1/zdl.1
    try mandb -q
    try install -m 644 zdl/docs/zdl.info /usr/share/info/
    try install-info --info-dir=/usr/share/info /usr/share/info/zdl.info &>/dev/null
    try mkdir -p /etc/bash_completion.d/
    try install -T zdl/docs/zdl.completion /etc/bash_completion.d/zdl
    try mv "$prog" "$SHARE"

    if [ $? != 0 ]
    then
	print_c 3 "$op non riuscit${suffix}. Riprova un'altra volta"
	exit 1
    else
	print_c 1 "$op automatic${suffix} in $SHARE/$prog"
    fi

    if [ -e /cygdrive ]
    then
	code_batch=$(cat $SHARE/zdl.bat)
	echo "${code_batch//'{{{CYGDRIVE}}}'/$cygdrive}" > /${prog}.bat && print_c 1 "\nScript batch di avvio installato: $(cygpath -m /)/zdl.bat "
	chmod +x /${prog}.bat
    fi

    update_zdl-conkeror

    cp *.sig "$path_conf"/zdl.sig 2>/dev/null
    rm -fr *.gz *.sig "$prog"
    cd ..
    dir_dest=$PWD

    source $SHARE/config.sh
    set_default_conf

    echo -e "Di seguito, le estensioni già esistenti di ZigzagDownLoader, 
in $SHARE/extensions/
NB: 
- eventuali estensioni omonime dell'utente saranno ignorate
- puoi controllare il flusso del processo assegnando 
  i nomi ai file delle estensioni: 
  ZDL leggerà i file in ordine lessicografico 
  (anche per sostituire o arricchire le estensioni già esistenti)
- le nuove estensioni dell'utente devono essere collegate in
  $SHARE/extensions/
  (puoi collegarle automaticamente con: zdl -fu)

ESTENSIONI:
" > "$path_conf"/extensions/README.txt
    find $SHARE/extensions/ -type f |grep -P extensions/[^/]+.sh$  >> "$path_conf"/extensions/README.txt
    
    if [[ $(ls "$path_conf"/extensions/*.sh 2>/dev/null) ]]
    then
	for extension in "$path_conf"/extensions/*.sh 
	do
	    if [ ! -f $SHARE/extensions/"${extension##*\/}" ]
	    then
		try ln -s "$extension" $SHARE/extensions/"${extension##*\/}"
	    fi
	done
    fi    

    ## DIPENDENZE
    #
    ## Cygwin:

    if [ -e /cygdrive ]
    then
	install_axel-cygwin
	cd /tmp
	
	if ! command -v apt-cyg &>/dev/null
	then
	    echo -e "
Installazione di apt-cyg
"
	    wget http://rawgit.com/transcode-open/apt-cyg/master/apt-cyg
	    install apt-cyg /bin
	fi

	if ! command -v ffmpeg &>/dev/null
	then
	    echo -e "
Installazione di FFMpeg
"
	    rm -f /tmp/list-pkts.txt
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwinports/
	    apt-cyg install ffmpeg | tee -a /tmp/list-pkts.txt
	    
	    unset pkts
	    mapfile pkts <<< "$(grep Unable /tmp/list-pkts.txt | sed -r 's|.+ ([^\ ]+)$|\1|g')"
	    print_c 1 "\nRecupero pacchetti non trovati:\n${pkts[*]}\n"
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/
	    apt-cyg install ${pkts[*]} 
	fi
	
	if ! command -v rtmpdump &>/dev/null
	then
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwinports/
	    apt-cyg install rtmpdump
	fi
	
	if ! command -v nano &>/dev/null
	then
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/
	    apt-cyg install nano
	fi
	
	if ! command -v diff &>/dev/null
	then
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/
	    apt-cyg install diffutils
	fi

	if ! command -v base64 &>/dev/null
	then
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/
	    apt-cyg install coreutils
	fi

	if ! command -v xxd &>/dev/null
	then
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin
	    apt-cyg install vim-common
	fi

	if ! command -v pinfo &>/dev/null
	then
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin
	    apt-cyg install pinfo
	fi

	if ! command -v openssl &>/dev/null
	then
	    apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/
	    apt-cyg install openssl
	fi

	if ! command -v node &>/dev/null
	then
	    if [ ! -f /tmp/node.exe ]
	    then
		print_c 1 "Installazione di Nodejs.exe in $SHARE"
		wget -O $SHARE/node.exe https://nodejs.org/dist/v4.4.4/win-x86/node.exe

	    else
		cp /tmp/node.exe $SHARE/
	    fi
	fi

	apt-cyg install bash-completion

	
	## GNU/LINUX
    else
	if ! command -v pinfo &>/dev/null 
	then
	    print_c 1 "Installazione di pinfo"
	    try apt-get -qq -y install pinfo &>/dev/null
	fi

	if ! command -v nodejs &>/dev/null 
	then
	    print_c 1 "Installazione di Nodejs"
	    try apt-get -qq -y install nodejs &>/dev/null
	fi
    fi

    print_c 1 "$op automatic${suffix} completat${suffix}"
    pause

    if [ -z "$installer" ]
    then
	cd $dir_dest
	$prog ${args[*]}
	exit
    fi
}


