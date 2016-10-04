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

function install_phpcomposer {
    cd /tmp
    try php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    try php -r "if (hash_file('SHA384', 'composer-setup.php') === '92102166af5abdb03f49ce52a40591073a7b859a86e8ff13338cf7db58a19f7844fbc0bb79b2773bf30791e935dbd938') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    try php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer
    try php -r "unlink('composer-setup.php');"
    cd -
}

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
    cmdline=( "$@" )
    
    if ! "${cmdline[@]}" 2>/dev/null 
    then	
	if ! sudo "${cmdline[@]}" 2>/dev/null 
	then
	    su -c "${cmdline[@]}" || (
		print_c 3 "$failure: ${cmdline[@]}"
		return 1
	    )
	fi
    fi
}

function install_dep {
    local dep="$1"
    
    declare -A alert_msg
    alert_msg['axel']="$PROG può scaricare con Wget ma raccomanda fortemente Axel, perché:\n
	- può accelerare sensibilmente il download
	- permette il recupero dei download in caso di interruzione
	
Per ulteriori informazioni su Axel: http://alioth.debian.org/projects/axel/
"
    
    alert_msg['xterm']="$PROG utilizza XTerm se avviato da un'applicazione grafica come Firefox/Iceweasel/Icecat (tramite Flashgot), Chrome/Chromium (attraverso Download Assistant o Simple Get), XXXTerm/Xombrero e Conkeror:
"
    for cmd in "${!deps[@]}"
    do
	[ "$dep" == "${deps[$cmd]}" ] && break
    done

    while ! command -v $cmd &>/dev/null
    do
	print_c 3 "ATTENZIONE: $dep non è installato nel tuo sistema"

	echo -e "${alert_msg[dep]}
1) Installa automaticamente $dep da pacchetti
2) Installa automaticamente $dep da sorgenti
3) Salta l'installazione di $dep e continua con l'installazione di $PROG e delle altre sue dipendenze
4) Esci da $PROG per installare $dep manualmente (puoi trovarlo qui: http://pkgs.org/search/?keyword=$dep)"

	print_c 2 "Scegli cosa fare (1-4):"

	cursor on
	read -e input
	cursor off
	
	case $input in
	    1) install_pk $dep ;;
	    2) install_src $dep ;;
	    3) break ;;
	    4) exit 1 ;;
	esac
    done
}

function install_test {
    local test_type installer dep cmd
    test_type=$1
    installer=$2
    dep=$3

    for cmd in "${!deps[@]}"
    do
	[ "$dep" == "${deps[$cmd]}" ] && break
    done

    if ! command -v $cmd &>/dev/null
    then
	print_c 3 "Installazione automatica non riuscita"
	case $test_type in
	    pk)
		echo "$installer non ha trovato il seguente pacchetto: $dep"
		;;
	    src)
		echo "Errori nella compilazione o nell'installazione"
		;;
	esac

	pause
	return 1
    else
	return 0
    fi
}

function install_pk {
    local dep
    dep=$1
    
    print_c 1 "Installazione di: $dep"

    if command -v apt-get &>/dev/null
    then
	DEBIAN_FRONTEND=noninteractive
	try apt-get --no-install-recommends -q -y install $dep
	install_test pk apt-get $dep &&
	    return 0

    elif command -v yum &>/dev/null
    then
	try yum install axel
	install_test pk yum $dep &&
	    return 0

    elif command -v pacman &>/dev/null
    then
	try pacman -S axel 2>/dev/null
	install_test pk pacman $dep &&
	    return 0

    else
	return 1
    fi
}

function make_install {
    make
    sudo make install ||
	(
	    echo "Digita la password di root"
	    su -c "make install"
	)
    make clean
    install_test src $1
}


function install_src {
    local dep
    dep=$1
    
    case $dep in
	axel)
	    cd /usr/src
	    wget https://alioth.debian.org/frs/download.php/file/3015/axel-2.4.tar.gz

	    tar -xzvf axel-2.4.tar.gz
	    cd axel-2.4
	    
	    make_install $dep
	    ;;

	xterm)
	    cd /usr/src
	    wget http://invisible-island.net/datafiles/release/xterm.tar.gz
	    
	    tar -xzvf xterm.tar.gz
	    cd xterm-300

	    make_install $dep
	    ;;
    esac
}


function update {
    PROG=ZigzagDownLoader
    prog=zdl
    BIN="/usr/local/bin"
    SHARE="/usr/local/share/zdl"
    ## sources: http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
    axel_url="http://www.inventati.org/zoninoz/html/upload/files/axel-2.4-1.tar.bz2" 
    success="Aggiornamento completato"
    failure="Aggiornamento non riuscito"
    path_conf="$HOME/.$prog"
    file_conf="$path_conf/$prog.conf"

    if [ "$installer_zdl" == "true" ]
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

    find $SHARE/extensions/ -type f |
	grep -P extensions/[^/]+.sh$  >> "$path_conf"/extensions/README.txt
    
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

    if [ -e /cygdrive ]
    then
	## DIPENDENZE
	#
	## CYGWIN
	
	mirrors=(
	    "http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/"
	    "http://bo.mirror.garr.it/mirrors/sourceware.org/cygwinports/"
	)
	
	install_axel-cygwin
	cd /tmp
	
	if ! command -v apt-cyg &>/dev/null
	then
	    print_c 1 "Installazione di apt-cyg"

	    wget http://rawgit.com/transcode-open/apt-cyg/master/apt-cyg
	    install apt-cyg /bin
	fi

	if ! command -v node &>/dev/null
	then
	    print_c 1 "Installazione di Nodejs.exe in $SHARE"
	    wget -O $SHARE/node.exe https://nodejs.org/dist/v4.4.4/win-x86/node.exe
	fi

	if ! command -v ffmpeg &>/dev/null
	then
	    print_c 1 "Installazione di FFMpeg"
	    
	    rm -f /tmp/list-pkts.txt
	    apt-cyg mirror "${mirrors[1]}"
	    apt-cyg install ffmpeg | tee -a /tmp/list-pkts.txt
	    
	    unset pkts
	    mapfile pkts <<< "$(grep Unable /tmp/list-pkts.txt | sed -r 's|.+ ([^\ ]+)$|\1|g')"
	    print_c 1 "\nRecupero pacchetti non trovati:\n${pkts[*]}\n"
	    apt-cyg mirror "${mirrors[0]}"
	    apt-cyg install ${pkts[*]} 
	fi
	
	if ! command -v rtmpdump &>/dev/null
	then
	    print_c 1 "Installazione di RTMPDump"
	    
	    apt-cyg mirror "${mirrors[1]}"
	    apt-cyg install rtmpdump
	fi

	declare -A deps
	deps['aria2c']=aria2
	deps['nano']=nano
	deps['diff']=diffutils
	deps['base64']=coreutils
	deps['xxd']=vim-common
	deps['pinfo']=pinfo
	deps['openssl']=openssl
	deps['php']=php
	deps['socat']=socat

	for cmd in "${!deps[@]}"
	do
	    if ! command -v $cmd &>/dev/null 
	    then
		apt-cyg mirror "${mirrors[0]}"
		print_c 1 "Installazione di ${deps[$cmd]}"
		apt-cyg install ${deps[$cmd]}
	    fi
	done

	## funzione necessaria per php-aaencoder: 
	if ! php -r 'echo mb_strpos("", "")' 2>/dev/null
	then
	    apt-cyg mirror "${mirrors[0]}"
	    apt-cyg install php-mbstring
	fi

	## per installare COMPOSER (installatore di pacchetti php: vedi funzione in alto) 
	#
	# apt-cyg apt-cyg mirror http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin/
	#
	# for pack in php php-json php-phar php-iconv
	# do
	#     if ! command -v "$pack" &>/dev/null
	#     then
	# 	apt-cyg install "$pack"
	#     fi
	# done
	#
	# if ! command -v composer &>/dev/null
	# then
	#     install_phpcomposer
	# fi
	
	apt-cyg mirror "${mirrors[0]}"
	apt-cyg install bash-completion 2>/dev/null

    else
	## DIPENDENZE
	#
	## GNU/LINUX
	
	declare -A deps
	deps['pinfo']=pinfo
	deps['aria2c']=aria2
	deps['axel']=axel
	deps['nodejs']=nodejs
	deps['php']=php5-cli
	deps['cmp']=diffutils
	deps['socat']=socat
	## deps['ffmpeg']=ffmpeg
	
	command -v X &>/dev/null &&
	    deps['xterm']=xterm

	for cmd in "${!deps[@]}"
	do
	    if ! command -v $cmd  &>/dev/null 
	    then
		print_c 1 "Installazione di ${deps[$cmd]}"
		install_dep ${deps[$cmd]}
	    fi
	done
    fi

    check_default_downloader
    
    print_c 1 "$op automatic${suffix} completat${suffix}"

    if [ -z "$installer_zdl" ]
    then
	pause
	cd $dir_dest
	$prog "${args[@]}"
	exit
    fi
}


