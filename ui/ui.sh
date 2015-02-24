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

function links_box {
    header_box "Links"
    header_dl "Servizi"
    echo -e "${BBlue}Video in streaming saltando il player del browser:${Color_Off}\n$(cat $path_usr/streaming.txt)\n\n${BBlue}File hosting:${Color_Off}\n$(cat $path_usr/hosting.txt) e, dopo aver risolto il captcha e generato il link, anche Sharpfile, Depositfiles ed altri servizi\n\n${BBlue}Tutti i file scaricabili con le seguenti estensioni dei browser:${Color_Off}\nFlashgot di Firefox/Iceweasel/Icecat, funzione 'M-x zdl' di Conkeror e script 'zdl-xterm' (XXXTerm/Xombrero e altri)\n" 
    header_dl "Comandi della modalità standard (M è il tasto Meta, cioè <Alt>)"
    echo -e "<${BGreen} M-x RETURN ${Color_Off}>\tesegue i download (qui sotto, elencare i link uno per riga) [e${BGreen}x${Color_Off}ec]"
    echo -e "<${BGreen} M-e ${Color_Off}>\t\tavvia l'${BGreen}e${Color_Off}ditor predefinito"
    echo -e "<${BYellow} M-i ${Color_Off}>\t\tmodalità ${BYellow}i${Color_Off}nterattiva\n"
    echo -e "<${BRed} M-q ${Color_Off}>\t\tchiudi ZDL senza interrompere i downloader [${BRed}q${Color_Off}uit]"
    echo -e "<${BRed} M-k ${Color_Off}>\t\tuccidi tutti i processi [${BRed}k${Color_Off}ill]"
    separator-
    echo
}

function interactive_and_return {
    stty echo
    zdl -i
    stty -echo
    header_z
    echo -e "\n${BBlue}Downloader:${Color_Off} $downloader_in\t${BBlue}Directory:${Color_Off} $PWD\n"
    links_box
}

function run_editor {
    $editor $path_tmp/links_loop.txt
    header_z
    echo -e "\n${BBlue}Downloader:${Color_Off} $downloader_in\t${BBlue}Directory:${Color_Off} $PWD\n"
    links_box
}

function show_downloads_extended {
    header_z
    header_box "Modalità interattiva"
    echo -e "\n${BBlue}Directory di destinazione:${Color_Off} $PWD\n"
    check_instance_daemon
    if [ $? == 1 ]; then
	print_c 1 "$PROG è attivo in modalità demone\n"
	daemon_pid=$test_pid
    else
##	if [[ $(pidprog_in_dir "$PWD") ]]; then
	check_instance_prog
	if [ $? == 1 ]; then
	    print_c 1 "$PROG è attivo in $PWD in modalità standard nel terminale $tty\n"
	else
	    print_c 3 "Non ci sono istanze attive di $PROG in $PWD\n"
	fi
    fi
    data_stdout

    last_out=$(( ${#pid_out[*]}-1 ))
    for i in `seq 0 $last_out`; do
	human_length ${length_out[$i]} ## --> $length_H
	
	header_dl "Numero download: $i"
	check_pid ${pid_out[$i]}
	if [ $? == 1 ] && [ ! -f "${file_out[$i]}" ] && [ ! -z "${progress_out[$i]}" ]; then
	    print_c 3 "${downloader_out[$i]} sta scaricando a vuoto: ${file_out[$i]} non esiste"
	fi
	is_rtmp "${url_out[$i]}"
	if [ $? == 1 ]; then
	    echo -e "${BBlue}File:${Color_Off} ${file_out[$i]}" 
	    echo -e "${BBlue}Downloader:${Color_Off} ${downloader_out[$i]} ${BYellow}protocollo RTMP$Color_Off\n${BBlue}Link:${Color_Off} ${url_out[$i]}"
	    echo -e "${BBlue}Streamer:${Color_Off} ${streamer_out[$i]}"
	    echo -e "${BBlue}Playpath:${Color_Off} ${playpath_out[$i]}" 
	else
	    echo -e "${BBlue}File:${Color_Off} ${file_out[$i]}" 
	    [ ! -z "${alias_file_out[$i]}" ] && echo "${BBlue}Alias:${Color_Off} ${alias_file_out[$i]}"
	    echo -e "${BBlue}Grandezza:${Color_Off} ${length_H} ${BBlue}Downloader:${Color_Off} ${downloader_out[$i]}\n${BBlue}Link:${Color_Off} ${url_out[$i]}"
	    echo -e "${BBlue}Url del file:${Color_Off} ${url_out_file[$i]}" 
	fi
	if [ ${downloader_out[$i]} == cURL ]; then
	    check_pid ${pid_out[$i]}
	    if [ $? == 1 ]; then
		[ ${speed_out[$i]} == ${speed_out[$i]%[km]} ] && speed="${speed_out[$i]}B/s"
		[ ${speed_out[$i]} != ${speed_out[$i]%k} ] && speed="${speed_out[$i]%k}KB/s"
		[ ${speed_out[$i]} != ${speed_out[$i]%m} ] && speed="${speed_out[$i]%m}MB/s"
		human_length ${length_saved[$i]}
		echo -n -e "${BBlue}Stato:${Color_Off} "
		print_c 1 "${length_saved[$i]} ($length_H) ${BBlue}${speed}"
	    elif [ -f "${file_out[$i]}" ]; then
		human_length ${length_saved[$i]}
		echo -n -e "${BBlue}Stato:${Color_Off} "
		print_c 1 "${length_saved[$i]} ($length_H) terminato"
	    else
		echo -n -e "${BBlue}Stato:${Color_Off} "
		print_c 3 "Download non attivo"
	    fi
	else
	    make_progress
	    print_c "" "${BBlue}Stato:${diff_bar_color} ${progress}"
	fi
	echo
    done
    return 1
}


function human_length { ## input in bytes
    if [ ! -z $1 ]; then
	length_B=$1
	length_K=$(( $length_B/1024 ))
	length_M=$(( $length_K/1024 ))
	if (( $length_M>0 )); then
	    length_H="${length_M} MB"
	elif (( $length_K>0 )); then
	    length_H="${length_K} KB"
	else
	    length_H="${length_B} B"
	fi
    fi
}


function interactive {
    while true ; do
	header_z
	header_box "Modalità interattiva"
	echo
	unset tty list file_stdout file_out alias_file_out url_out downloader_out pid_out length_out
	show_downloads_extended
	unset num_dl
	[ -f "$path_tmp/.dl-mode" ] && [[ $(cat "$path_tmp/.dl-mode") =~ ^([1-9]+)$ ]] && num_dl="${BASH_REMATCH[1]}"
	[ ! -f "$path_tmp/.dl-mode" ] && num_dl=1
	[ -z "$num_dl" ] && num_dl=illimitati
	header_box "Opzioni [numero download alla volta: $num_dl]"
	echo -e "<${BYellow} s ${Color_Off}> ${BYellow}s${Color_Off}eleziona uno o più download (per riavviare, eliminare, riprodurre file audio/video)\n"

	echo -e "<${BGreen} e ${Color_Off}> modifica la coda dei link da scaricare, usando l'${BGreen}e${Color_Off}ditor predefinito\n"
	echo -e "<${BGreen} 1-9 ${Color_Off}> scarica ${BGreen}un numero da 1 a 9${Color_Off} file alla volta"
	echo -e "<${BGreen} m ${Color_Off}> scarica ${BGreen}m${Color_Off}olti file alla volta\n"
	[ -z "$tty" ] && [ -z "$daemon_pid" ] && echo -e "<${BGreen} d ${Color_Off}> avvia ${BGreen}d${Color_Off}emone"
	echo -e "<${BGreen} c ${Color_Off}> ${BGreen}c${Color_Off}ancella i file temporanei dei download completati\n"
	echo -e "<${BRed} K ${Color_Off}> interrompi tutti i download e ogni istanza di ZDL nella directory (${BRed}K${Color_Off}ill-all)"
	[ ! -z "$daemon_pid" ] && echo -e "<${BRed} Q ${Color_Off}> ferma il demone di $name_prog in $PWD lasciando attivi Axel e Wget se avviati"
	echo -e "\n<${BBlue} q ${Color_Off}> esci da $PROG --interactive (${BBlue}q${Color_Off}uit)"
	echo -e "<${BBlue} * ${Color_Off}> ${BBlue}aggiorna lo stato${Color_Off}\n"
	cursor off
	read -e -n 1 -t 15 action
	cursor on
	if [ "$action" == "s" ]; then
	    fclear
	    header_z
	    echo
	    show_downloads_extended
	    header_box "Seleziona (Riavvia/sospendi, Elimina, Riproduci audio/video)"
	    print_c 2 "Seleziona i numeri dei download, separati da spazi (puoi non scegliere):"
	    read -e input
	    if [ ! -z "$input" ]; then
		unset inputs
		inputs=( $input )
		echo
		header_box "Riavvia o Elimina"
		print_c 2 "Cosa vuoi fare con i download selezionati?"
		echo
		echo -e "<${BYellow} r ${Color_Off}> ${BYellow}r${Color_Off}iavviarli se è attiva un'istanza di ZDL, altrimenti sospenderli
<${BRed} E ${Color_Off}> ${BRed}e${Color_Off}liminarli definitivamente (e cancellare il file scaricato)
<${BRed} T ${Color_Off}> ${BRed}t${Color_Off}erminarli definitivamente SENZA cancellare il file scaricato (cancella il link dalla coda di download)

<${BGreen} p ${Color_Off}> riprodurre (${BGreen}p${Color_Off}lay) i file audio/video
<${BGreen} c ${Color_Off}> ${BGreen}c${Color_Off}ancellare i file temporanei dei download completati

<${BBlue} * ${Color_Off}> ${BBlue}schermata principale${Color_Off}\n"
		print_c 2 "Scegli cosa fare: ( r | E | T | p | c | * ):"
		read -e input2
		for ((i=0; i<${#inputs[*]}; i++)); do
		    [[ ! "${inputs[$i]}" =~ ^[0-9]+$ ]] && unset inputs[$i]
		done
		if [ "$input2" == "r" ]; then
		    for i in ${inputs[*]}; do
			kill ${pid_out[$i]} 2>/dev/null # && ( print_c 1 "Download terminato: ${file_in[$i]} (${url_in[$i]})" ; read )
			if [ ! -f "${file_out[$i]}.st" ] && [ ! -f "${alias_file_out[$i]}.st" ]; then
			    rm -f "${file_out[$i]}" "${alias_file_out[$i]}"
			fi
		    done
		elif [ "$input2" == "E" ]; then
		    for i in ${inputs[*]}; do
			kill ${pid_out[$i]} 2>/dev/null
			rm -f "${file_out[$i]}" "${alias_file_out[$i]}" "${file_out[$i]}.st" "${alias_file_out[$i]}.st" "$path_tmp"/"${file_out[$i]}_stdout.tmp"
			links_loop - "${url_out[$i]}"
		    done
		elif [ "$input2" == "T" ]; then
		    for i in ${inputs[*]}; do
			kill ${pid_out[$i]} 2>/dev/null
			rm -f "$path_tmp"/"${file_out[$i]}_stdout.tmp"
			links_loop - "${url_out[$i]}"
		    done
		elif [ "$input2" == "c" ]; then
		    clean_completed
		elif [ "$input2" == "p" ]; then
		    if [ -z "$player" ]; then
			configure_key 10
			get_conf
		    fi
		    if [ ! -z "$player" ]; then
			for ii in ${inputs[*]}; do
			    playing_files="$playing_files ${file_out[$ii]// /\\ }"
			done
			echo "ecco:$player $playing_files"
			$player $playing_files &>/dev/null &
		    fi
		fi
	    fi
	elif [[ "$action" =~ ^([1-9]+)$ ]]; then
	    echo "$action" > "$path_tmp/.dl-mode"
	elif [ "$action" == "m" ]; then
	    echo > "$path_tmp/.dl-mode"
	elif [ "$action" == "e" ]; then
	    $editor "$path_tmp/links_loop.txt"
	elif [ "$action" == "c" ]; then
	    clean_completed
	elif [ "$action" == "q" ]; then
	    fclear
	    break
	elif [ "$action" == "K" ]; then
	    [ ! -z "$daemon_pid" ] && kill -9 $daemon_pid && unset daemon_pid 2>/dev/null
##		[[ $(pidprog_in_dir "$PWD") ]] && kill -9 $(pidprog_in_dir "$PWD") 2>/dev/null
	    check_instance_prog
	    [ $? == 1 ] && [ $pid != $PPID ] && kill -9 $pid 2>/dev/null
	    kill_downloads
	elif [ "$action" == "d" ] && [ -z "$tty" ]; then
	    zdl --daemon
	elif [ "$action" == "Q" ]; then
	    kill $daemon_pid && unset daemon_pid 2>/dev/null
	fi
    done
    echo -e "\e[0m\e[J"
    exit
}


function clean_completed {
    data_stdout
    if [ $? == 1 ]; then
	last_out=$(( ${#pid_out[*]}-1 ))
	for j in `seq 0 $last_out`; do
	    length_saved=0
	    [ -f "${file_out[$j]}" ] && length_saved=`ls -l "./${file_out[$j]}" | awk '{ print($5) }'`
	    if [ -f "${file_out[$j]}" ] && [ ! -f "${file_out[$j]}.st" ] && [ "$length_saved" == "${length_out[$j]}" ];then
		rm  "$path_tmp"/"${file_out[$j]}_stdout.tmp"
	    fi

	    if [ ${downloader_out[$j]} == cURL ] && [ ! -z "${length_saved[$j]}" ] && (( "${length_saved[$j]}">0 )); then
		check_pid "${pid_out[$j]}"
		if [ $? != 1 ]; then
		    rm  "$path_tmp"/"${file_out[$j]}_stdout.tmp"
		fi
	    fi
	    if [ ${downloader_out[$j]} == RTMPDump ]; then
		test_completed=$(tail -n1 "$path_tmp"/"${file_out[$j]}_stdout.tmp")
		check_pid "${pid_out[$j]}"
		if [ $? != 1 ] && [ "$test_completed" == "Download complete" ]; then
		    rm  "$path_tmp"/"${file_out[$j]}_stdout.tmp"
		fi
	    fi
	done
    fi
}


function show_downloads {
    if [ "$daemon" != "true" ]; then
	echo
	header_dl "Downloading in $PWD"
	data_stdout
	if [ $? == 1 ]; then
	    last_stdout=$(( ${#pid_out[*]}-1 ))
	    for i in `seq 0 $last_stdout`; do
		if [ ! -z "${url_out[$i]}" ]; then
		    echo -e " ${BBlue}File:${Color_Off} ${file_out[$i]}"
		    echo -e " ${BBlue}Link:${Color_Off} ${url_out[$i]}"

		    if [ ${downloader_out[$i]} == cURL ]; then
			check_pid ${pid_out[$i]}
			if [ $? == 1 ]; then
			    [ ${speed_out[$i]} == ${speed_out[$i]%[km]} ] && speed="${speed_out[$i]}B/s"
			    [ ${speed_out[$i]} != ${speed_out[$i]%k} ] && speed="${speed_out[$i]%k}KB/s"
			    [ ${speed_out[$i]} != ${speed_out[$i]%m} ] && speed="${speed_out[$i]%m}MB/s"
			    human_length ${length_saved[$i]}
			    print_c 1 " ${downloader_out[$i]}: ${length_saved[$i]} ($length_H) ${BBlue}${speed}"
			elif [ -f "${file_out[$i]}" ]; then
			    human_length ${length_saved[$i]}
			    print_c 1 " ${downloader_out[$i]}: ${length_saved[$i]} ($length_H) terminato"
			else
			    print_c 3 " ${downloader_out[$i]}: Download non attivo"
			fi
		    else
			make_progress
			print_c "" "${diff_bar_color} ${downloader_out[$i]}: ${progress}"
		    fi
		    ii=$(( $i+1 ))
		    if [ $i != $last_stdout ] && [ -f "$path_tmp/${file_out[$ii]}_stdout.tmp" ]; then 
			separator-
		    fi
		fi
	    done
	else
	    echo
	    print_c 3 " Nessun download rilevato"
	    echo
	fi
	separator-
	echo -e "\n\n\n"
    fi
    sleeping $sleeping_pause
}


function make_progress {
    unset progress
    size_bar=0
    check_pid ${pid_out[$i]}
    if [ $? != 1 ]; then
	if [[ "${downloader_out[$i]}" =~ ^(Wget|RTMPDump)$ ]]; then
	    progress="Download non attivo"
	fi
	diff_bar_color="${BRed}"
	bar_color="${On_Red}"
	speed="${diff_bar_color}non attivo${Color_Off}"
	eta=""
    else
	if [ ! -z "${num_speed[$i]}" ] && [ "${num_speed[$i]}" != "0" ] && [ ! -z "${num_percent[$i]//.}" ]; then
	    diff_bar_color="${BGreen}"
	    bar_color="${On_Green}"
	    speed="${num_speed[$i]}${type_speed[$i]}"
	    eta="${eta[$i]}"
	else 
	    diff_bar_color="${BYellow}"
	    bar_color="${On_Yellow}"
	    speed="${diff_bar_color}attendi...${Color_Off}"
	    eta=""
	fi		    
    fi
    [ -z "${num_percent[$i]//.}" ] && num_percent[$i]=0
    [[ "${num_percent[$i]//.}" =~ ^[0-9]+$ ]] && size_bar=$(( ($COLUMNS-40)*${num_percent[$i]}/100 )) || size_bar=0
    diff_size_bar=$(( ($COLUMNS-40)-${size_bar} ))

    unset bar diff_bar
    for column in `seq 1 $size_bar`; do
	bar="${bar_color}${bar} " 
    done
    for column in `seq 1 $diff_size_bar`; do
	diff_bar="${Color_Off}${diff_bar_color}${diff_bar}|"
    done
    bar="${bar}${diff_bar}"

    test_completed=$(grep 'Download complete' < "$path_tmp/${file_out[$i]}_stdout.tmp")
    if ( [ ! -z "$test_completed" ] && [ ${downloader_out[$i]} == RTMPDump ] ) || ( [ -f "${file_out[$i]}" ] && [ ! -f "${file_out[$i]}.st" ] && [ "${length_saved[$i]}" == "${length_out[$i]}" ] && [ "${length_out[$i]}" != 0 ] && [ ! -z "${length_out[$i]}" ] );then
	progress="Download completato"
	diff_bar_color="${BGreen}"
    fi
    [ -z "$progress" ] && progress="${bar}${Color_Off}${diff_bar_color} ${num_percent[$i]}%${Color_Off}${BBlue} ${speed}${Color_Off} ${eta}"
}


function sleeping {
    timer=$1
    if [ -z "$daemon" ] && [ -z "$pipe" ]; then
	read -es -t $timer -n 1 action &>/dev/null
	[ ! -z "${action//[0-9]}" ] && echo -n -e "\r \r"
	case $action in
#	    q) exit ;;
	    i) zdl -i
		header_z
		print_c 1 "\nModalità interattiva terminata: di seguito l'output di gestione dei download\n"
		header_box "Modalità non interattiva/standard"
		;;
	esac
    else
	/bin/sleep $timer
    fi
}
