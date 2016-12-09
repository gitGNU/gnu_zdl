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

## news:
TAG1='## NEW: ...ARIA2!'
TAG2='## ARIA2: già chiesto'


# chiavi di configurazione  --   valori predefiniti  --    descrizione per il config-manager
key_conf[0]=downloader;          val_conf[0]=Aria2;        string_conf[0]="Downloader predefinito (Axel|Aria2|Wget)"
key_conf[1]=axel_parts;          val_conf[1]="32";         string_conf[1]="Numero di parti in download parallelo per Axel"
key_conf[2]=aria2_connections;   val_conf[2]="16";         string_conf[2]="Numero di connessioni in parallelo per Aria2"
key_conf[3]=max_dl;              val_conf[3]="1";          string_conf[3]="Numero massimo di download simultanei (numero intero|<vuota=senza limiti>)"
key_conf[4]=background;          val_conf[4]=black;        string_conf[4]="Colore sfondo (black|transparent)"
key_conf[5]=language;            val_conf[5]=$LANG;        string_conf[5]="Lingua"
key_conf[6]=reconnecter;         val_conf[6]="";           string_conf[6]="Script/comando/programma per riconnettere il modem/router"
key_conf[7]=autoupdate;          val_conf[7]=enabled;      string_conf[7]="Aggiornamenti automatici di ZDL (enabled|*)"
key_conf[8]=player;              val_conf[8]="";           string_conf[8]="Script/comando/programma per riprodurre un file audio/video"
key_conf[9]=editor;              val_conf[9]="nano";       string_conf[9]="Editor predefinito per modificare la lista dei link in coda"
key_conf[10]=resume;             val_conf[10]="";          string_conf[10]="Recupero file omonimi come con opzione --resume (enabled|*)"
key_conf[11]=zdl_mode;           val_conf[11]="stdout";    string_conf[11]="Modalità predefinita di avvio (lite|daemon|stdout)"
key_conf[12]=tcp_port;           val_conf[12]="";          string_conf[12]="Porta TCP aperta per i torrent di Aria2 (verifica le impostazioni del tuo router)"
key_conf[13]=udp_port;           val_conf[13]="";          string_conf[13]="Porta UDP aperta per i torrent di Aria2 (verifica le impostazioni del tuo router)"
key_conf[14]=socket_port;        val_conf[14]="8080";      string_conf[14]="Porta TCP per creare socket, usata da opzioni come --socket e --web-ui"
key_conf[15]=browser;            val_conf[15]="firefox";   string_conf[15]="Browser per l'interfaccia web: opzione --web-ui"
key_conf[16]=web_ui;             val_conf[16]="1";         string_conf[16]="Seleziona l'interfaccia web predefinita (1|2)"

declare -A try_counter
try_end_default=5
try_end=$try_end_default

declare -A _downloader
_downloader['Axel']=axel
_downloader['Aria2']=aria2c
_downloader['Wget']=wget

prog=zdl 
name_prog="ZigzagDownLoader"
PROG="ZDL"  #`echo $prog | tr a-z A-Z`
path_tmp=".${prog}_tmp"
mkdir -p "$path_tmp"

path_server="$HOME"/.zdl/zdl.d
mkdir -p "$path_server"

path_conf="$HOME/.${prog}"
file_conf="$path_conf/$prog.conf"

file_socket_account="$path_conf"/.socket-account

source "$file_conf"
[ -z "$background" ] && background=${val_conf[4]}

declare -A list_proxy_url
## elenco chiavi proxy_server: proxy_list, ip_adress
proxy_server='ip_adress'
list_proxy_url['ip_adress']="http://www.ip-adress.com/proxy_list/" ###"http://zoninoz.hol.es"  ### 
list_proxy_url['proxy_list']="http://proxy-list.org/en/index.php"

user_agent="Mozilla/5.0 (X11; Linux x36_64; rv:10.0.7) Gecko/20100101 Firefox/10.0.7 Iceweasel/10.0.7"
user_lang="$LANG"
user_language="$LANGUAGE"
prog_lang='en_US.UTF-8:en'

newip_hosts=(
    rockfile
    uptobox
    mediafire
    easybytez
    uload
    glumbouploads
    billionuploads
)

rtmp_links=(
    zinwa\.
    streamin\.
    vidhappy\.
    videopremium\.
)

wget_links=(
    dailymotion\/cdn
    dmcdn\.net
    uploaded\.
    easybytez\.
    rapidgator\.
    uploadable\.
    nitroflare\.
    rai\.tv
    idowatch\.
    dropbox\.
    subyshare\. 
)
#    videomega\.

##youtubedl_links=( rai\.tv )

aria2_links=(
    ^magnet\:
    \.torrent$
)

dcc_xfer_links=(
    ^irc\:
)

noresume_links=(
    uploadable\.
    rapidgator\.
    uploaded\.
)

no_check_links=(
    nowdownload\.
    dropbox\.
    pastebin\.
    ^magnet\:
    \.torrent$
    ^irc\:
    \.dfiles\.
)
#no_check_links=( tusfiles\. nowdownload\. )

no_check_ext=(
    dropbox\.
    pastebin\.
    easybytez\.
    tusfiles\.
    'mega.(co|nz)'
    ^magnet\:
    \.torrent$
    ^irc\:
    \.dfiles\.
)

## massima durata tentativi di connessione (Wget)
max_waiting=40

## durata attesa 
sleeping_pause=3
#[ -d /cygdrive ] && sleeping_pause=2


## NODEJS:

if [ -d /cygdrive ] &&
       ! command -v node &>/dev/null &&
       [ -f "/usr/local/share/zdl/node.exe" ]
then
    chmod 777 /usr/local/share/zdl/node.exe
    nodejs="/usr/local/share/zdl/node.exe"

elif command -v nodejs &>/dev/null
then
    nodejs=nodejs

elif command -v node &>/dev/null
then
    nodejs=node
fi

evaljs=$path_usr/libs/eval.js



## FFMPEG:

command -v avconv &>/dev/null && ffmpeg="avconv"
command -v ffmpeg &>/dev/null && ffmpeg="ffmpeg"





############
## functions

function create_socket_account {
    local user="$1"
    local pass="$2"
    
    create_hash "${user}${pass}" > "$file_socket_account"
}

function set_default_conf {
    mkdir -p "$path_conf"
    touch "$file_conf"
    if [ ! -e "/cygdrive" ]
    then
	val_conf[1]=32
    else
	val_conf[1]=10
    fi
    
    for ((i=0; i<${#key_conf[*]}; i++))
    do
	[[ ! $(grep ^${key_conf[$i]}= "$file_conf") ]] &&
	    echo "${key_conf[$i]}=${val_conf[$i]}" >> "$file_conf"
    done
}

function get_item_conf {	
    awk "{match(\$0,/^\ *$1=\"*([^\"]+)\"*$/,pattern); if (pattern[1]) print pattern[1]}" "$file_conf"
}

function set_item_conf {
    local item value line
    
    if [ -f "$file_conf" ]
    then
	item="$1"
	value="\"$2\""

	if grep -P '^[ ]*'${item}= "${file_conf}" &>/dev/null
	then
	    while read line
	    do
		if [[ "$line" =~ ^[\ ]*${item}= ]]
		then
		    echo "${item}=$value" >> "${file_conf}.new"
		    
		else
		    echo "$line" >> "${file_conf}.new"
		fi
	    done < "$file_conf"

	    if [ -f "${file_conf}.new" ]
	    then
		mv "${file_conf}" "${file_conf}.old"
		mv "${file_conf}.new" "${file_conf}"
	    fi
	    
	else
	    echo "${item}=$value" >> "${file_conf}"
	fi
    fi
}

function get_conf {
    source "$file_conf"
    if [ -z "$zdl_mode" ]
    then
	zdl_mode=stdout
	set_item_conf zdl_mode stdout
    fi
    
    if [ -z "$this_mode" ]
    then
	this_mode="$zdl_mode"	
    fi
    
    ## downloader predefinito
    if [ -f "$path_tmp/downloader" ]
    then
	downloader_in=$(cat "$path_tmp/downloader")
	
    else
	if [ -z "$downloader" ]
	then
	    downloader=${val_conf[0]}
	    set_item_conf downloader ${val_conf[0]}
	fi

	for dlr in "$downloader" Aria2 Axel Wget
	do
	    if command -v "${_downloader[$dlr]}" &>/dev/null
	    then
		downloader_in="$dlr"
		break
	    fi
	done
	set_downloader "$downloader_in"
    fi    

    ## parti di Axel:
    axel_parts_conf="$axel_parts"
    if [ -z "$axel_parts_conf" ]
    then
	axel_parts_conf=32
	set_item_conf axel_parts_conf 32
    fi
    ## CYGWIN
    if [ -e "/cygdrive" ] &&
	   (( $axel_parts_conf>10 ))
    then
	axel_parts_conf=10
	set_item_conf axel_parts_conf 10
    fi
    axel_parts="$axel_parts_conf"
    

    ## connessioni di Aria2:
    if [ -z "$aria2_connections" ]
    then
	aria2_connections=16
	set_item_conf aria2_connections 16
    fi
    ## Valori massimi:
    if [ -d /cygdrive ]
    then
	((aria2_connections>8)) &&
	    aria2_connections=8
	
	set_item_conf aria2_connections 8

    else
	((aria2_connections>16)) &&
	    aria2_connections=16
	
	set_item_conf aria2_connections 16
    fi

    #### pulizia vecchi parametri
    ## single/multi
    if [ "$mode" == "single" ]
    then
	max_dl=1
	sed -r "/(^mode=|num_dl|stream_mode)/d" -i "$file_conf"
	set_item_conf max_dl 1

    elif [ "$mode" == "multi" ]
    then
	unset max_dl
	sed -r "/(^mode=|num_dl|stream_mode)/d" -i "$file_conf"
	set_item_conf max_dl ''
    fi
    ##
    ##############################
    
    if [ -f "$path_tmp/max-dl" ]
    then
	max_dl="$(cat "$path_tmp/max-dl")"

    else
	echo "$max_dl" > "$path_tmp/max-dl"
    fi
	
    ## editor
    if ! command -v "$(trim "${editor%% *}")" &>/dev/null
    then
	unset editor
	set_item_conf editor ''
    fi

    ## socket
    if [ -z "$socket_port" ]
    then
	socket_port=${val_conf[14]}
	set_item_conf socket_port ${val_conf[14]}
    fi

    if [ -z "$web_ui" ]
    then
	web_ui=${val_conf[16]}
	set_item_conf web_ui "$web_ui"
    fi

    if [ -z "$background" ]
    then
	background=${val_conf[4]}
	set_item_conf background "$background"
    fi
    
    [ "$background" == "black" ] &&
	Background="$On_Black" && Foreground="$White" ||
	    unset Background Foreground

    [[ "$(tty)" =~ tty ]] &&
	background=tty
    
    Color_Off="\033[0m${Foreground}${Background}" 
}


function check_editor {
    [ -n "$EDITOR" ] &&
	editor="$EDITOR" &&
	return

    [[ -n $(ls -L /usr/bin/editor 2>/dev/null) ]] &&
	editor=/usr/bin/editor &&
	return

    for cmd in nano "emacs -nw" nano mcedit vim vi
    do
	[[ -n $(command -v $cmd) ]] &&
	    editor=$cmd &&
	    return
    done
}

function check_default_downloader {
    if command -v aria2c &>/dev/null &&
	    [ -f "$file_conf" ]
    then
	if [ "$(get_item_conf downloader)" == "Aria2" ]
	then
	    sed -r "s|$TAG1||g" -i "$file_conf"
	    
	elif [ "$(get_item_conf downloader)" != "Aria2" ] &&
		! grep "$TAG2" "$file_conf" &>/dev/null 
	then
	    unset def
	    while [[ ! "$def" =~ ^(sì|no)$ ]]
	    do
		echo
		header_box "NOVITÀ:"
		print_c 4 "$PROG supporta Aria2:"
		print_c 0 "\t- acceleratore di download\n\t- più potente e stabile di Axel\n\t- scarica anche i torrent (sia dai \"file torrent\" sia dai link \"magnet\")\n\t- molto altro ancora...\n"

		print_c 4 "NOTA BENE:"
		print_c 0 "- puoi sempre modificare le impostazioni predefinite con il comando 'zdl --configure' oppure cambiando il valore della variabile 'downloader' nel file $file_conf"
		print_c 0 "- puoi sempre usare il downloader che preferisci attraverso i parametri --wget, --axel e --aria2 oppure dai comandi dell'interfaccia interattiva\n"

		print_c 2 "Vuoi utilizzarlo come downloader predefinito? (sì|no):"
		read -e def

		case $def in
		    sì)
			set_item_conf downloader Aria2

			sed -r "s|$TAG1||g" -i "$file_conf"
			break
			;;
		    no)
			sed -r "s|$TAG1||g" -i "$file_conf"
			echo "$TAG2" >> "$file_conf"
			break
			;;
		esac
	    done 
	fi
    fi
}

function init {
    mkdir -p "$path_tmp"

    file_log="${prog}_log.txt"
    
    [ -z "$pid_prog" ] && pid_prog=$$ 

    get_conf
    this_tty=$(tty)

    if ! check_instance_prog &&
	    ! check_instance_daemon
    then
	rm -f "$path_tmp"/*rewriting "$path_tmp"/reconnect "$path_tmp"/proxy*
    fi
    
    # CYGWIN
    if [ -e "/cygdrive" ]
    then
	kill -SIGWINCH $$
    fi
    
    if [ -f "$file_log" ]
    then
	log=1
    fi

    rm -rf "$path_tmp/links_loop.txt-rewriting"
    [ -z "$editor" ] && check_editor
    
    trap_sigint
}

