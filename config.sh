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


function add_conf { #only if item doesn't exist
    item="$1"
    name="${item%%=*}="
    unset noadd
    if [ -f "$file_conf" ]; then
	lines=`cat "$file_conf" |wc -l`
	for line in `seq 1 $lines`; do
	    text=`cat "$file_conf" | sed -n "${line}p"`
	    if [ "$text" != "${text#$name}" ] || [ "$text" == "$item" ]; then
		noadd=1
		break
	    fi
	done
	
	if [ -z "$noadd" ]; then
	    echo "$item" >> "$file_conf"
	    unset noadd
	fi
    fi
}

function set_default_conf {
    mkdir -p "$path_conf"
    touch "$file_conf"
    add_conf "downloader=Axel"
    if [ ! -e "/cygdrive" ]; then
	add_conf "axel_parts=32"
    else
	add_conf "axel_parts=10"
    fi
    
    add_conf "skin=color"
    add_conf "# single or multi, to set the default downloading mode (single=sequential, multi=parallel)"
    add_conf "mode=single"
    add_conf "stream_mode=multi"
    add_conf "# modem router credentials"
    add_conf "admin="
    add_conf "passwd="
    add_conf "language=$LANG"
    add_conf "flashgot=enabled"
    add_conf "autoupdate=enabled"
}

function get_item_conf {
    if [ -f  "$file_conf" ]; then
	item=$1
	lines=`cat "$file_conf" |wc -l`
	for line in `seq 1 $lines`; do
	    text=`cat "$file_conf" | sed -n "${line}p"`
	    if [ "$text" != "${text#${item}=}" ]; then
		value="${text#${item}=}"
		value="${value%% *}"
		value="${value//\"}"
		break
	    fi
	done
    fi
}

function set_item_conf {
    if [ -f  "$file_conf" ]; then
	item=$1
	value=$2
	lines=`cat "$file_conf" |wc -l`
	for line in `seq 1 $lines`; do
	    text=`cat "$file_conf" | sed -n "${line}p"`
	    if [ "$text" != "${text#${item}=}" ]; then
		echo "${item}=$value" >> "${file_conf}.new"
		
	    else
		echo "$text" >> "${file_conf}.new"
	    fi
	done
	if [ -f "${file_conf}.new" ]; then
	    mv "${file_conf}" "${file_conf}.old"
	    mv "${file_conf}.new" "${file_conf}"
	fi
    fi
}

function get_conf_old {
    if [ -e "/cygdrive" ]; then
	print_c 1 "Attendi: lettura configurazione..."
    fi
    get_item_conf "downloader"
    downloader_in="$value"
    if [ -z "$downloader_in" ]; then
	downloader_in=Axel
    fi
    
    get_item_conf "axel_parts"
    axel_parts_conf="$value"
    if [ -z "$axel_parts_conf" ]; then
	axel_parts_conf=32
    fi
	## CYGWIN
    if [ -e "/cygdrive" ];then
	if (( $axel_parts_conf>10 )); then
	    axel_parts_conf=10
	fi
    fi
    axel_parts=$axel_parts_conf
    
    get_item_conf "skin"
    skin="$value"
    if [ -z "$skin" ]; then
	skin=color
    fi
    
    get_item_conf "mode"
    mode="$value"
    if [ "mode" == "multi" ]; then
	multi=1
    else
	multi=0
    fi
    
    get_item_conf "admin"
    admin="$value"
    
    get_item_conf "passwd"
    passwd="$value"
    
    get_item_conf "language"
    language="$value"
    
    get_item_conf "flashgot"
    flashgot="$value"
    
    get_item_conf "autoupdate"
    autoupdate="$value"
}

function get_conf {
    source "$file_conf"
    downloader_in="$downloader"
    if [ -z "$downloader_in" ]; then
	downloader_in=Axel
    fi
    
    axel_parts_conf="$axel_parts"
    if [ -z "$axel_parts_conf" ]; then
	axel_parts_conf=32
    fi
	## CYGWIN
    if [ -e "/cygdrive" ];then
	if (( $axel_parts_conf>10 )); then
	    axel_parts_conf=10
	fi
    fi
    axel_parts=$axel_parts_conf
    
    if [ -z "$skin" ]; then
	skin=color
    fi
    
    if [ "mode" == "multi" ]; then
	multi=1
    else
	multi=0
    fi
    
    if [ "stream_mode" == "multi" ]; then
	stream_params="-m"
    fi
}


function configure_accounts {
    mkdir -p "$path_conf"/accounts
    ##
    ## esempio per implementare il login per nuovi servizi di hosting:
    ##
    # while true; do
    # 	print_c 2 "Servizi di hosting abilitati per l'uso di account:"
    # 	echo -e "\t1) easybytez" #\n\t2) uload\n\t3) glumbouploads\n"
    # 	print_c 2 "Scegli il servizio (1):"
    # 	cursor off
    # 	read -n 1 option_1
    # 	cursor on
    # 	case $option_1 in
    # 	    1)
    # 		host="easybytez"
    # 		break
    # 		;;
    # 	    2)
    # 		host="uload"
    # 		break
    # 		;;
    # 	    3)	
    # 		host="glumbouploads"
    # 		break
    # 		;;
    # 	esac
    # done
    ##

    
    print_c 1 "\rAttualmente $name_prog è abilitato per gli account di Easybytez\n"
    host="easybytez"
    
    while true; do
	touch "$path_conf"/accounts/$host
	header_z
	get_accounts
	show_accounts

	echo
	header_box "Opzioni"
	echo -e "\t<${BBlue} 1 ${Color_Off}> aggiungi un account\n\t<${BBlue} 2 ${Color_Off}> elimina un account\n\t<${BBlue} * ${Color_Off}> torna alla pagina principale di configurazione\n"

	cursor off
	read -n 1 option_2
	echo -e -n "\r \r"
	cursor on
	case $option_2 in
	    1)	##add
		while true; do
		    header_box "Registra un account per il login automatico ($host)"
		    print_c 2 "\rNome utente:"
		    read user
		    print_c 2 "Password (i caratteri non saranno stampati):"
		    read -ers pass
		    print_c 2 "Ripeti la password (per verifica):"
		    read -ers pass2
		    if [ ! -z "$user" ] && [ ! -z "$pass" ] && [ "$pass" == "$pass2" ]; then
			lines=`cat "$path_conf"/accounts/$host |wc -l`
			unset noadd
			for line in `seq 1 $lines`; do
			    account=`cat "$path_conf"/accounts/$host |sed -n "${line}p" |awk '{ print($1) }'`
			    if [ "$account" == "$user" ]; then
				noadd=1
				break
			    fi
			done
			if [ -z "$noadd" ]; then
			    echo "$user $pass" >> "$path_conf"/accounts/$host
			fi
		    elif [ "$pass" != "$pass2" ]; then
			print_c 3 "Ripeti l'operazione: password non corrispondenti\n"
		    else
			print_c 3 "Ripeti l'operazione: nome utente o password mancante\n"
		    fi
		    echo
		    print_c 2 "Vuoi registrare un nuovo account? (s|*)"
		    cursor off
		    read -n 1 new_input
		    cursor on
		    [ "$new_input" != "s" ] && break
		done
		;;
	    2)	##remove
		while true; do
		    print_c 2 "Nome utente dell'account da cancellare:"
		    read user
		    
		    if [ ! -z "$user" ]; then
			break
		    else
			print_c 3 "Ripeti l'operazione: nome utente mancante"
		    fi
		done
		lines=`cat "$path_conf"/accounts/$host |wc -l`
		unset noadd
		for line in `seq 1 $lines`; do
		    account=`cat "$path_conf"/accounts/$host |sed -n "${line}p" |awk '{ print($1) }'`
		    if [ "$account" != "$user" ]; then
			cat "$path_conf"/accounts/$host |sed -n "${line}p" >> "$path_conf"/accounts/host
		    fi
		done
		rm -f "$path_conf"/accounts/$host
		if [ -f "$path_conf"/accounts/host ]; then
		    cat "$path_conf"/accounts/host > "$path_conf"/accounts/$host
		fi
		;;
	    *)	##return	
		break
		;;
	esac
    done
}

function init {
    prog=`basename $0`
    name_prog="ZigzagDownLoader"
    PROG=`echo $prog | tr a-z A-Z`
    path_tmp=".${prog}_tmp"
    mkdir -p "$path_tmp"

    ## set default config data
    updatecols=`cat ~/.bashrc | grep "shopt -s checkwinsize"`
    if [ -z "$updatecols" ]; then 
	echo "shopt -s checkwinsize" >> ~/.bashrc && echo "RIAVVIA IL TERMINALE: $PROG ha aggiunto in ~/.bashrc l'aggiornamento automatico del rilevamento delle dimensioni del display o della finestra di esecuzione." && exit
    fi
    
    log=0
    
    touch "$path_tmp/lock.zdl"
    file_log="${prog}_log.txt"
    rm -f $file_log
    
    path_conf="$HOME/.${prog}"
    file_conf="$path_conf/$prog.conf"
    mkdir -p "$path_conf/extensions"
    if [ ! -f "$file_conf" ]; then
	touch "$path_conf/flashgot_updated"
	echo "# ZigzagDownLoader configuration file" > "$file_conf"
    fi
    if [ -f "$path_conf/updated" ] || [ ! -f "$file_conf" ]; then
	set_default_conf
    fi
    
    tags=( `ps ax |sed -n '1p'` )
    for i in `seq 0 $(( ${#tags[*]}-1 ))`; do
	j=$(( $i+1 ))
	[ "${tags[$i]}" == "PID" ] && ps_ax_pid="\$$j"
	[ "${tags[$i]}" == "TTY" ] && ps_ax_tty="\$$j"
    done
    [ -z "$pid_prog" ] && pid_prog=$$ 
    pid_in=1
    
    # CYGWIN
    if [ -e "/cygdrive" ];then
	kill -SIGWINCH $$
	dev_cygwin=${HOME#'/cygdrive/'}
	dev_cygwin="${dev_cygwin%%'/'*}:"
    fi
    
    init_colors
    user_agent="Mozilla/5.0 (X11; Linux x36_64; rv:10.0.7) Gecko/20100101 Firefox/10.0.7 Iceweasel/10.0.7"
    user_lang="$LANG"
    user_language="$LANGUAGE"
    prog_lang='en_US.UTF-8:en'

    # bar_char="z"
    # url_update="http://inventati.org/zoninoz/html/upload/files/zdl"
    # url_gcc="http://inventati.org/zoninoz/html/upload/files/gcc.exe"
    # url_path_update="http://inventati.org/zoninoz/html/upload/files/"
    # url_version="http://inventati.org/zoninoz/html/upload/files/zdl_version.txt"
    max_waiting=40
    if [ -e "/cygdrive" ] && [ ! -f "/zdl.bat" ]; then
	wget "${url_update}.bat" -O /zdl.bat -q && print_c 1 "\nScript batch di avvio installato: $(cygpath -m /)\zdl.bat "
    fi
    
    newip_providers=( mediafire uploaded easybytez uload glumbouploads billionuploads )
    ## skin dark
    # echo -n -e "${White}${On_Black}\e[J"

# 	if [ "$flashgot" == "enabled" ];then
# 		flashgot_autoconf
# 	else
# 		restore_ffprefs
# 	fi
    proxy_server="proxy_list"
    list_proxy_url["ip_adress"]="http://www.ip-adress.com/proxy_list/"
    list_proxy_url["proxy_list"]="http://proxy-list.org/en/index.php"

    ## pausa per immissione di comandi per la modalità non-interattiva, con `read' al posto di `sleep'
    sleeping_pause=5

    ## per determinare se lo stdin è una pipe (disattivare l'interazione della funzione sleeping)
    stdin="$(ls -l /dev/fd/0)"
    stdin="${stdin/*-> /}"
    #ftype="$(stat --printf=%F $stdin)"
    # if   [[ "$ftype" == 'character special file' ]]; then
	# echo Terminal
    if [ "${stdin}" != "${stdin//'pipe:['}" ]; then     # if [[ "$ftype" == 'regular file' ]]; then
	# echo Pipe: $stdin
	pipe=true
    # else
	# echo Unknown: $stdin
    fi
    version_ffprefs_new=294
}
