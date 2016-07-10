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


# chiavi di configurazione -- valori predefiniti  --          descrizione per il config-manager
key_conf[0]=downloader;       val_conf[0]=Aria2;              string_conf[0]="Downloader predefinito (Axel|Aria2|Wget)"
key_conf[1]=axel_parts;       val_conf[1]="";                 string_conf[1]="Numero di parti in download parallelo per Axel"
key_conf[2]=mode;             val_conf[2]=single;             string_conf[2]="Modalità di download predefinita (single|multi)"
key_conf[3]=stream_mode;      val_conf[3]=single;             string_conf[3]="Modalità di download predefinita per lo stream dal browser (single|multi)"
key_conf[4]=num_dl;           val_conf[4]="";                 string_conf[4]="Numero massimo di download simultanei"
key_conf[5]=background;       val_conf[5]=black;              string_conf[5]="Colore sfondo (black|transparent)"
key_conf[6]=language;         val_conf[6]=$LANG;              string_conf[6]="Lingua"
key_conf[7]=reconnecter;      val_conf[7]="";                 string_conf[7]="Script/comando/programma per riconnettere il modem/router"
key_conf[8]=autoupdate;       val_conf[8]=enabled;            string_conf[8]="Aggiornamenti automatici di ZDL (enabled|*)"
key_conf[9]=player;           val_conf[9]="";                 string_conf[9]="Script/comando/programma per riprodurre un file audio/video"
key_conf[10]=editor;          val_conf[10]="nano";            string_conf[10]="Editor predefinito per modificare la lista dei link in coda"
key_conf[11]=resume;          val_conf[11]="";                string_conf[11]="Recupero file omonimi come con opzione --resume (enabled|*)"
key_conf[12]=zdl_mode;        val_conf[12]="";                string_conf[12]="Modalità predefinita di avvio (lite|daemon|<vuota>)"
key_conf[13]=tcp_port;        val_conf[13]="";                string_conf[13]="Porta TCP aperta per i torrent di Aria2 (verifica le impostazioni del tuo router)"
key_conf[14]=udp_port;        val_conf[14]="";                string_conf[14]="Porta UDP aperta per i torrent di Aria2 (verifica le impostazioni del tuo router)"

declare -A _downloader
_downloader['Axel']=axel
_downloader['Aria2']=aria2c
_downloader['Wget']=wget

prog=$(basename $0)
name_prog="ZigzagDownLoader"
PROG="ZDL"  #`echo $prog | tr a-z A-Z`
path_tmp=".${prog}_tmp"

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

)

## massima durata tentativi di connessione (Wget)
max_waiting=40

## durata attesa 
sleeping_pause=3
#[ -d /cygdrive ] && sleeping_pause=2

init_colors

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
    run_mode=$zdl_mode
    source "$file_conf"
    if [ -n "$run_mode" ]
    then
	zdl_mode="$run_mode"
    fi
    
    ## downloader predefinito
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
    
    # if [ -z "$skin" ]; then
    # 	skin=${val_conf[5]}
    # fi

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

    if [ "$background" == "black" ]
    then
	Background="$On_Black"
    fi
    
    init_colors
    Color_Off="\033[0m${White}${Background}" #\033[40m"
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
    
    while true
    do
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
		while true
		do
		    header_box "Registra un account per il login automatico ($host)"
		    print_c 2 "\rNome utente:"
		    read user
		    print_c 2 "Password (i caratteri non saranno stampati):"
		    read -ers pass
		    print_c 2 "Ripeti la password (per verifica):"
		    read -ers pass2
		    if [ ! -z "$user" ] && [ ! -z "$pass" ] && [ "$pass" == "$pass2" ]
		    then
			lines=`cat "$path_conf"/accounts/$host |wc -l`
			unset noadd
			for line in `seq 1 $lines`
			do
			    account=`cat "$path_conf"/accounts/$host |sed -n "${line}p" |awk '{ print($1) }'`
			    if [ "$account" == "$user" ]
			    then
				noadd=1
				break
			    fi
			done
			if [ -z "$noadd" ]
			then
			    echo "$user $pass" >> "$path_conf"/accounts/$host
			fi
			
		    elif [ "$pass" != "$pass2" ]
		    then
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
		while true
		do
		    print_c 2 "Nome utente dell'account da cancellare:"
		    read user
		    
		    if [ ! -z "$user" ]
		    then
			break
		    else
			print_c 3 "Ripeti l'operazione: nome utente mancante"
		    fi
		done
		lines=`cat "$path_conf"/accounts/$host |wc -l`
		unset noadd
		for line in `seq 1 $lines`
		do
		    account=`cat "$path_conf"/accounts/$host |sed -n "${line}p" |awk '{ print($1) }'`
		    if [ "$account" != "$user" ]
		    then
			cat "$path_conf"/accounts/$host |sed -n "${line}p" >> "$path_conf"/accounts/host
		    fi
		done
		rm -f "$path_conf"/accounts/$host
		
		if [ -f "$path_conf"/accounts/host ]
		then
		    cat "$path_conf"/accounts/host > "$path_conf"/accounts/$host
		fi
		;;
	    *)	##return	
		break
		;;
	esac
    done
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
	    sed -r "s|$TAG2||g" -i "$file_conf"
	    
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
			sed -r "s|$TAG2||g" -i "$file_conf" 
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
    
    path_conf="$HOME/.${prog}"
    file_conf="$path_conf/$prog.conf"
        
    [ -z "$pid_prog" ] && pid_prog=$$ 

    check_instance_prog
    [ "$?" != 1 ] && rm -f "$path_tmp"/*rewriting
    
    # CYGWIN
    if [ -e "/cygdrive" ]
    then
	kill -SIGWINCH $$
    fi

    get_conf

    if [ -f "$file_log" ]
    then
	log=1
    fi

    rm -rf "$path_tmp/links_loop.txt-rewriting"
    [ -z "$editor" ] && check_editor

    trap_sigint
}

