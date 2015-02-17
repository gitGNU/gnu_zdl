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

function show_downloads_extended {
    header_z
    header_box "Modalità interattiva"
    echo -e "\n${BBlue}Directory di destinazione:${Color_Off} $PWD\n"
    if [ ! -z "$daemon_pid" ]; then
	print_c 1 "$PROG è attivo in modalità demone\n"
    fi
    data_stdout
    if [ $? == 1 ]; then
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
    else
	print_c 3 "Nessun download rilevato in $PWD\n"	
    fi
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
	silents=$(ps ax |grep "$prog" |grep "$PWD" |grep "silent")
	for ((i=1; i<=$(wc -l <<< "${silents}" ); i++)); do
	    silent=$(sed -n ${i}p <<< "$silents" )
	    if [[ "${silent##*silent }" =~ ^${PWD}$ ]]; then
		daemon_pid=$(awk '{print $1}' <<< "$silent")
		break
	    fi
	done
	header_z
	header_box "Modalità interattiva"
	echo
	unset list file_stdout file_out alias_file_out url_out downloader_out pid_out length_out
	show_downloads_extended
	if [ $? == 1 ] || [ ! -z "$daemon_pid" ]; then
	    header_box "Opzioni"
	    echo -e "<${BYellow} s ${Color_Off}> seleziona uno o più download (per riavviare, eliminare, riprodurre file audio/video)"
	    echo -e "<${BGreen} c ${Color_Off}> cancella i file temporanei dei download completati\n"
	    echo -e "<${BBlue} q ${Color_Off}> esci da $PROG --interactive"
	    [ ! -z "$daemon_pid" ] && echo -e "<${BBlue} Q ${Color_Off}> ferma il demone di $name_prog in $PWD lasciando attivi Axel e Wget se avviati\n"
	    echo -e "<${BBlue} * ${Color_Off}> aggiorna lo stato\n"
	    cursor off
	    read -n 1 -t 15 action
	    cursor on
	    if [ "$action" == "s" ]; then
		fclear
		header_z
		echo
		show_downloads_extended
		header_box "Seleziona (Riavvia, Elimina, Riproduci audio/video)"
		print_c 2 "Seleziona i numeri dei download, separati da spazi (puoi non scegliere):"
		read input
		if [ ! -z "$input" ]; then
		    unset inputs
		    inputs=( $input )
		    echo
		    header_box "Riavvia o Elimina"
		    print_c 2 "Vuoi che i download selezionati siano terminati definitivamente oppure che siano riavviati automaticamente più tardi?"
		    echo
		    echo -e "<${BYellow} r ${Color_Off}> per riavviarli
<${BRed} e ${Color_Off}> per eliminarli definitivamente (e cancellare il file scaricato)
<${BRed} t ${Color_Off}> per terminarli definitivamente SENZA cancellare il file scaricato (cancella il link dalla coda di download)
<${BGreen} p ${Color_Off}> per riprodurre i file audio/video

<${BGreen} c ${Color_Off}> per cancellare i file temporanei dei download completati

<${BBlue} * ${Color_Off}> per tornare alla schermata principale\n"
		    print_c 2 "Scegli cosa fare: ( r | e | t | c | * ):"
		    read input2
		    if [ "$input2" == "r" ]; then
			for i in ${inputs[*]}; do
			    kill ${pid_out[$i]} 2>/dev/null # && ( print_c 1 "Download terminato: ${file_in[$i]} (${url_in[$i]})" ; read )
			    if [ ! -f "${file_out[$i]}.st" ] && [ ! -f "${alias_file_out[$i]}.st" ]; then
				rm -f "${file_out[$i]}" "${alias_file_out[$i]}"
			    fi
			done
		    elif [ "$input2" == "e" ]; then
			for i in ${inputs[*]}; do
			    kill ${pid_out[$i]} 2>/dev/null
			    rm -f "${file_out[$i]}" "${alias_file_out[$i]}" "${file_out[$i]}.st" "${alias_file_out[$i]}.st" "$path_tmp"/"${file_out[$i]}_stdout.tmp"
			    links_loop - "${url_out[$i]}"
			done
		    elif [ "$input2" == "t" ]; then
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
			    for i in ${inputs[*]}; do
				$player "${file_out[$i]}" &>/dev/null &
			    done
			fi
		    fi
		fi
	    elif [ "$action" == "c" ]; then
		clean_completed
	    elif [ "$action" == "q" ]; then
		fclear
		break
	    elif [ "$action" == "Q" ]; then
		kill $daemon_pid 2>/dev/null
		fclear
		break
	    fi
	else
	    break
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
	read -t $timer -n 1 action 2>/dev/null
	[ ! -z "${action//[0-9]}" ] && echo -n -e "\r \r"
	case $action in
	    q) exit ;;
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
