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


# chiavi di configurazione --    valori predefiniti  --    descrizione per il config-manager
key_conf[0]=downloader;          val_conf[0]=Aria2;        string_conf[0]="Downloader predefinito (Axel|Aria2|Wget)"
key_conf[1]=axel_parts;          val_conf[1]="32";         string_conf[1]="Numero di parti in download parallelo per Axel"
key_conf[2]=aria2_connections;   val_conf[2]="16";         string_conf[2]="Numero di connessioni in parallelo per Aria2"
key_conf[3]=mode;                val_conf[3]=single;       string_conf[3]="Modalità di download predefinita (single|multi)"
key_conf[4]=stream_mode;         val_conf[4]=single;       string_conf[4]="Modalità di download predefinita per lo stream dal browser (single|multi)"
key_conf[5]=num_dl;              val_conf[5]="";           string_conf[5]="Numero massimo di download simultanei"
key_conf[6]=background;          val_conf[6]=black;        string_conf[6]="Colore sfondo (black|transparent)"
key_conf[7]=language;            val_conf[7]=$LANG;        string_conf[7]="Lingua"
key_conf[8]=reconnecter;         val_conf[8]="";           string_conf[8]="Script/comando/programma per riconnettere il modem/router"
key_conf[9]=autoupdate;          val_conf[9]=enabled;      string_conf[9]="Aggiornamenti automatici di ZDL (enabled|*)"
key_conf[10]=player;             val_conf[10]="";          string_conf[10]="Script/comando/programma per riprodurre un file audio/video"
key_conf[11]=editor;             val_conf[11]="nano";      string_conf[11]="Editor predefinito per modificare la lista dei link in coda"
key_conf[12]=resume;             val_conf[12]="";          string_conf[12]="Recupero file omonimi come con opzione --resume (enabled|*)"
key_conf[13]=zdl_mode;           val_conf[13]="";          string_conf[13]="Modalità predefinita di avvio (lite|daemon|stdout)"
key_conf[14]=tcp_port;           val_conf[14]="";          string_conf[14]="Porta TCP aperta per i torrent di Aria2 (verifica le impostazioni del tuo router)"
key_conf[15]=udp_port;           val_conf[15]="";          string_conf[15]="Porta UDP aperta per i torrent di Aria2 (verifica le impostazioni del tuo router)"

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

path_conf="$HOME/.${prog}"
file_conf="$path_conf/$prog.conf"

source "$file_conf"
[ -z "$background" ] && background=${val_conf[6]}

declare -A list_proxy_url
## elenco chiavi proxy_server: proxy_list, ip_adress
proxy_server='ip_adress'
list_proxy_url['ip_adress']="http://www.ip-adress.com/proxy_list/" ###"http://zoninoz.hol.es"  ### 
list_proxy_url['proxy_list']="http://proxy-list.org/en/index.php"

user_agent="Mozilla/5.0 (X11; Linux x36_64; rv:10.0.7) Gecko/20100101 Firefox/10.0.7 Iceweasel/10.0.7"
user_lang="$LANG"
user_language="$LANGUAGE"
prog_lang='en_US.UTF-8:en'

newip_providers=(
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

## functions

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
    if [ -f "$file_conf" ]
    then
	item="$1"
	while read line
	do
	    if [[ "$line" =~ ^[\ ]*${item}=\"*([^\"]+)[\"\ ]*$ ]]
	    then
		echo "${BASH_REMATCH[1]}"
		return 0
	    fi
	done < "$file_conf" 
    fi
    return 1
}

function set_item_conf {
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
	    echo  "${item}=$value" >> "${file_conf}"
	fi
    fi
}

function get_conf {
    source "$file_conf"
    [ -z "$zdl_mode" ] &&
	zdl_mode=stdout
    
    if [ -z "$this_mode" ]
    then
	this_mode="$zdl_mode"
    fi
    
    ## downloader predefinito
    if [ -f "$path_tmp/downloader" ]
    then
	downloader_in=$(cat "$path_tmp/downloader")
	
    else
	[ -z "$downloader" ] &&
	    downloader=${val_conf[0]}

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
    fi
    ## CYGWIN
    if [ -e "/cygdrive" ] &&
	   (( $axel_parts_conf>10 ))
    then
	axel_parts_conf=10
    fi
    axel_parts="$axel_parts_conf"
    

    ## connessioni di Aria2:
    if [ -z "$aria2_connections" ]
    then
	aria2_connections=16
    fi
    ## Valori massimi:
    if [ -d /cygdrive ]
    then
	((aria2_connections>8)) &&
	    aria2_connections=8

    else
	((aria2_connections>16)) &&
	    aria2_connections=16
    fi

    
    ## single/multi
    if [ "$mode" == "single" ]
    then
	num_dl=1

    elif [ "$mode" == "multi" ]
    then
	unset num_dl
    fi

    if [ -f "$path_tmp/dl-mode" ]
    then
	num_dl="$(cat "$path_tmp/dl-mode")"

    else
	echo "$num_dl" > "$path_tmp/dl-mode"
    fi
	
    if [ "$stream_mode" == "multi" ]
    then
	stream_params="-m"
    fi

    ## editor
    if [[ ! $(command -v $editor 2>/dev/null) ]]
    then
	unset editor
    fi
    
    [ "$background" == "black" ] &&
	Background="$On_Black" && Foreground="$White" ||
	    unset Background Foreground

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

    if check_instance_prog
    then
	rm -f "$path_tmp"/*rewriting 
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

