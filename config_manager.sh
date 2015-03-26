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

function configure_key {
    opt=$1
    if [[ "$opt" =~ ^[0-9]+$ ]] && \
	(( $opt > 0 )) && \
	(( $opt <= ${#key_conf[*]} ))
    then 
	(( opt-- ))
	header_box "Scrivi il nuovo valore"

	if [ "${key_conf[$opt]}" == "$reconnecter" ]
	then
	    extra_string=" [è necessario indicare il path completo e valido]"
	fi
	print_c 2 "${string_conf[$opt]} (chiave: ${key_conf[$opt]})$extra_string:"
	read new_value
	
	if [[ "${key_conf[$opt]}" =~ (reconnecter|player|editor) ]] && \
	    [[ -z $(command -v ${new_value%% *} 2>/dev/null) ]]
	then
	    print_c 3 "Riconfigurazione non riuscita: programma inesistente${extra_string}"
	    pause
	else
	    set_item_conf ${key_conf[$opt]} "$new_value"
	fi
	touch "$path_conf/updated"
    fi
}

function configure {
    unset zdl_mode
    while true
    do
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
		unset zdl_mode
		print_c 2 "\nSeleziona l'elemento predefinito da modificare (1-${#key_conf[*]} | *):"
		read opt
		configure_key $opt
		;;
	    2)	
		configure_accounts
		;;
	    3) 	echo -e -n "\e[0m\e[J"
		fclear
		exit
		;;
	esac
    done
}

function show_conf {
    for ((i=0; i<${#key_conf[*]}; i++))
    do
	echo -e "\t< ${BBlue}$(( $i+1 ))$Color_Off > ${string_conf[$i]}: ${BBlue}$(eval echo \$${key_conf[$i]})$Color_Off"
    done
}

function show_accounts {
    header_box "Account registrati per $host:"

    if [ ! -z "${accounts_user[*]}" ];then
	for name_account in ${accounts_user[*]}
	do
	    echo "$name_account"
	done
    else
	print_c 3 "Nessun account registrato per $host"
    fi
}

function get_accounts {
    unset accounts_user accounts_pass
    if [ -f "$path_conf"/accounts/$host ];then
	lines=$(wc -l < "$path_conf"/accounts/$host)
	for line in $(seq 1 $lines)
	do
	    accounts_user[${#accounts_user[*]}]=`cat "$path_conf"/accounts/$host | sed -n "${line}p"|awk '{ print($1) }'`
	    accounts_pass[${#accounts_pass[*]}]=`cat "$path_conf"/accounts/$host | sed -n "${line}p"|awk '{ print($2) }'`
	done
    fi
}
