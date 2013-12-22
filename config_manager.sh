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


function configure {
    
    while true; do
	header_z
	header_box "Preferenze"
	print_c 2 "Scegli un'opzione (1|2|3)"
	echo -e "\t<${BBlue} 1 ${Color_Off}> modifica la configurazione\n\t<${BBlue} 2 ${Color_Off}> gestisci gli account dei servizi di hosting\n\t<${BBlue} 3 ${Color_Off}> esci\n"
	
	cursor off
	read -n 1 option_0
	cursor on
	echo -e -n "\r \r"
	case $option_0 in
	    1)	header_z
		header_box "Configurazione di $name_prog"
		get_conf
		show_conf
		print_c 2 "Seleziona l'elemento predefinito da modificare (1-10 | *):"
		read opt
		if [[ "$opt" =~ [0-9] ]] && [[ -z "${opt//[0-9]}" ]] && (( $opt > 0 )) && (( $opt < 11 )); then 
		    (( opt-- ))
		    print_c 2 "Scrivi il nuovo valore per <${item_options[$opt]}>:"
		    if [ "${item_options[$opt]}" == "passwd" ]; then
			read -ers new_value
		    else
			read new_value
		    fi
		    set_item_conf ${item_options[$opt]} $new_value
		    touch "$path_conf/updated"
		    if [ "${item_options[$opt]}" == "flashgot" ]; then
			touch "$path_conf/flashgot_updated"
		    fi
		fi
		;;
	    2)	
		configure_accounts
		;;
	    3) 	echo -e -n "\e[0m\e[J"
		exit
		;;
	esac
    done
}

function show_conf {
    echo -e " 1)\tDownloader predefinito (Axel|Wget): $downloader_in"
    echo -e " 2)\tNumero di parti in download parallelo per Axel: $axel_parts"
    echo -e " 3)\tModalità di download predefinita (single|multi): $mode"
    echo -e " 4)\tModalità di download predefinita per lo stream dal browser (single|multi): $stream_mode"
    echo -e " 5)\tNumero massimo di download simultanei: $num_multi"
    echo -e " 6)\tAspetto (color): $skin"
    echo -e " 7)\tLingua: $language"
    echo -e " 8)\tNome utente del modem-router: $admin"
    unset p
    for i in `seq 1 ${#passwd}`; do
	p="${p}*"
    done 
    echo -e " 9)\tPassword del modem-router: $p"
    echo -e "10)\tAggiornamenti automatici di $PROG (enabled|*): $autoupdate"
    echo

    item_options=( downloader axel_parts mode stream_mode num_multi skin language admin passwd autoupdate )
}

function show_accounts {
    header_box "Account registrati per $host:"

    if [ ! -z "${accounts_user[*]}" ];then
	for name_account in ${accounts_user[*]}; do
	    echo "$name_account"
	done
    else
	print_c 3 "Nessun account registrato per $host"
    fi
}

function get_accounts {
    unset accounts_user accounts_pass
    if [ -f "$path_conf"/accounts/$host ];then
	lines=`cat "$path_conf"/accounts/$host |wc -l`
	for line in `seq 1 $lines`; do
	    accounts_user[${#accounts_user[*]}]=`cat "$path_conf"/accounts/$host | sed -n "${line}p"|awk '{ print($1) }'`
	    accounts_pass[${#accounts_pass[*]}]=`cat "$path_conf"/accounts/$host | sed -n "${line}p"|awk '{ print($2) }'`
	done
    fi
}
