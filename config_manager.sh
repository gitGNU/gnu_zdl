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

function colorize_values {
    local text
    text="$1"
    
    bg_color="$(print_case $2)"
    
    text="${text//\(/\($BBlue}"
    text="${text//|/$bg_color|$BBlue}"
    text="${text//\)/$bg_color\)}"

    sprint_c "$bg_color" "$text" "$bg_color"
}

function check_read {
    local input
    if [ -z "$1" ]
    then
	print_c 2 "Nessun valore inserito: vuoi cancellare il valore precedente? (sì|*)"
	cursor on
	read -e input
	cursor off
	
	if [ "$input" == "sì" ]
	then
	    return 0

	else
	    return 1
	fi
    fi
    return 0
}

function configure_key {
    opt=$1
    if [[ "$opt" =~ ^[0-9]+$ ]] && 
	   (( $opt > 0 )) && 
	   (( $opt <= ${#key_conf[*]} ))
    then 
	(( opt-- ))
	header_box "Scrivi il nuovo valore"

	if [ "${key_conf[$opt]}" == "$reconnecter" ]
	then
	    extra_string=" [è necessario indicare il path completo e valido]"
	fi
	
	print_c 2 "$(colorize_values "${string_conf[$opt]}" 2) (nome: $(sprint_c 3 "${key_conf[$opt]}" 2))$extra_string:"
	cursor on
	read -e new_value
	cursor off
	
	check_read "$new_value" &&
	    if [[ "${key_conf[$opt]}" =~ (reconnecter|player|editor) ]] &&
		   ! command -v ${new_value%% *} >/dev/null
	    then
		print_c 3 "Riconfigurazione non riuscita: programma inesistente${extra_string}"
		pause

	    else
		set_item_conf ${key_conf[$opt]} "$new_value"
	    fi
	
	touch "$path_conf/updated"
    fi
}

function show_conf {
    header_box "Configurazione attuale:"
    for ((i=0; i<${#key_conf[*]}; i++))
    do
	printf "%b %+4s %b│  " "${BBlue}" "$(( $i+1 ))" "$Color_Off"
	echo -ne "$(colorize_values "${string_conf[$i]}" 5): $(sprint_c 1 "$(eval echo \$${key_conf[$i]})")\n"
    done
}

function configure {
    this_mode="configure"
    start_mode_in_tty "$this_mode" "$this_tty"
    
    while true
    do
	fclear
	header_z
	header_box "Preferenze"
	echo -e "   ${BBlue} 1 ${Color_Off}│  Modifica la configurazione
   ${BBlue} 2 ${Color_Off}│  Gestisci gli account dei servizi di hosting
   ${BBlue} q ${Color_Off}│  Esci
"
	print_c 2 "$(colorize_values "Scegli un'opzione (1|2|q)" 2)"
	
	cursor off
	read -s -n1 option_0
	cursor on
	echo -en "\r \r"
	case $option_0 in
	    1)
		while true
		do
		    fclear
		    header_z
		    header_box "Configurazione di $name_prog"

		    print_c 0 "La configurazione è composta da ${BRed}nomi${Color_Off} e ${BBlue}valori${Color_Off}.\n"
		    print_c 2 "Per ogni nome può essere specificato un valore:"
		    print_c 0 "- i $(sprint_c 4 "valori alternativi disponibili"), in blu, possono essere suggeriti tra le parentesi tonde e separati dalla barra verticale
- di fianco, in rosso, è indicato il $(sprint_c 3 "nome") a cui verrà assegnato il valore
- $(sprint_c 4 "*") significa un valore qualsiasi diverso dagli altri, anche nullo
- gli attuali $(sprint_c 1 "valori registrati") sono in verde\n\n"

		    ## get_conf
		    source "$file_conf"

		    show_conf
		    
		    print_c 2 "\nSeleziona l'elemento predefinito da modificare ($(sprint_c 4 "1-${#key_conf[*]}" 2) | $(sprint_c 4 "q" 2) per tornare indietro):"
		    cursor on
		    read -e opt
		    cursor off

		    [ "$opt" == "q" ] && break 
		    configure_key $opt
		done
		;;
	    2)	
		configure_accounts
		;;

	    q) 	echo -e -n "\e[0m\e[J"
		fclear
		exit
		;;
	esac
    done
}

function configure_accounts {
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
    
    host="easybytez"

    while true
    do
	init_accounts
	
	header_box "Opzioni"
	echo -e "   ${BBlue} 1 ${Color_Off}│  Aggiungi/modifica un account
   ${BBlue} 2 ${Color_Off}│  Elimina un account
   ${BBlue} 3 ${Color_Off}│  Visualizza password degli account
   ${BBlue} q ${Color_Off}│  Torna alla pagina principale di configurazione
"

	cursor off
	read -s -n1 option_2
	echo -e -n "\r \r"
	cursor on
	case $option_2 in
	    1)	##add
		while true
		do
		    ## clean file "$path_conf"/accounts/$host
		    init_accounts

		    header_box "Registra un account per il login automatico ($host)"

		    print_c 2 "\rNome utente:"
		    cursor on
		    read -e user
		    cursor off
		    
		    if [ -n "$user" ]
		    then
			
			print_c 2 "Password (i caratteri non saranno stampati):"
			read -ers pass
			
			print_c 2 "Ripeti la password (per verifica):"
			read -ers pass2

			if [ -n "$pass" ] &&
			       [ "$pass" == "$pass2" ]
			then
			    grep -P "^$user\s.+$" "$path_conf"/accounts/$host &>/dev/null &&
				sed -r "s|^$user\s.+$|$user $pass|g" -i "$path_conf"/accounts/$host ||
				    echo "$user $pass" >>"$path_conf"/accounts/$host
			    
			elif [ "$pass" != "$pass2" ]
			then
			    print_c 3 "Ripeti l'operazione: password non corrispondenti"
			else
			    print_c 3 "Ripeti l'operazione: nome utente o password mancante"
			fi

			print_c 2 "\nVuoi registrare un nuovo account? (s|*)"
			cursor off
			read -s -n1 new_input
			cursor on
			[ "$new_input" != "s" ] && break

		    else
			print_c 3 "Nessun nome utente selezionato"
			pause
			break
		    fi
		done
		;;
	    2)	##remove
		print_c 2 "Nome utente dell'account da cancellare:"
		cursor on
		read -e user
		cursor off
		
		if grep -P "^$user\s.+$" "$path_conf"/accounts/$host &>/dev/null
		then
		    sed -r "s|^$user\s.+$||g" -i "$path_conf"/accounts/$host

		else
		    print_c 3 "Nessun account selezionato"
		    pause
		fi
		;;

	    3)
		init_accounts pass
		pause
		;;
	    q)	##quit
		break
		;;
	esac
    done
}


function show_accounts {
    local accounts
    header_box "Account registrati per $host:"

    accounts=$(cat "$path_conf"/accounts/$host)

    [ -z "$accounts" ] &&
	print_c 3 "Nessun account registrato" &&
	return 1

    if [ "$1" == "pass" ]
    then
	get_accounts
	((length_user+=4))
	
	print_c 4 "$(printf "%+${length_user}s ${Color_Off}│${BBlue} %s" "Utenti:" "Password:")"
	for ((i=0; i<${#accounts_user[@]}; i++))
	do
	    print_c 0 "$(printf "%+${length_user}s │ %s" "${accounts_user[i]}" "${accounts_pass[i]}")"
	done

    else
	print_c 4 "Lista utenti registrati:"
	awk '{print $1}' <<< "$accounts"
    fi
    return 0
}

function get_accounts {
    unset accounts_user accounts_pass

    if [ -f "$path_conf"/accounts/$host ]
    then
	while read line
	do
	    username=${line%% *}
	    accounts_user+=( "$username" )

	    ((${#username}>length_user)) &&
		length_user="${#username}"
	    
	    accounts_pass+=( "${line#* }" )
	    
	done < "$path_conf"/accounts/$host
    fi
}


function init_accounts {
    mkdir -p "$path_conf"/accounts
    touch "$path_conf"/accounts/$host
    ftemp="$path_tmp/init_accounts"
    awk '($0)&&!($0 in a){a[$0]; print}' "$path_conf"/accounts/$host >$ftemp
    mv $ftemp "$path_conf"/accounts/$host

    fclear
    header_z
    show_accounts $1
    echo
}

