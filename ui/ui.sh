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
# Gianluca Zoni
# http://inventati.org/zoninoz    
# zoninoz@inventati.org
#

function show_downloads {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	if data_stdout
	then
	    stdbuf -oL -eL                                          \
		   awk -f $path_usr/libs/common.awk                 \
		   -f $path_usr/ui/colors-${background}.awk.sh      \
		   -f $path_usr/ui/ui.awk                           \
		   -v col="$COLUMNS"                                \
		   -v Color_Off="$Color_Off"                        \
		   -v Background="$Background"                      \
		   -e "BEGIN {$awk_data display()}" 
	fi
    else
	data_stdout
    fi
}

function show_downloads_lite {
    local no_clear="$1"
    [ -n "$no_clear" ] && force_header=force
        
    cursor off
    
    (( odd_run++ ))
    (( odd_run>1 )) && odd_run=0
    
    if data_stdout "no_check"
    then       
	rm -f "$path_tmp"/no-clear-lite
	header_lite $force_header
	
	stdbuf -oL -eL                                         \
	       awk -f $path_usr/libs/common.awk                \
	       -f $path_usr/ui/colors-${background}.awk.sh     \
	       -f $path_usr/ui/ui.awk                          \
	       -v col="$COLUMNS"                               \
	       -v lines="$LINES"                               \
	       -v no_clear="$no_clear"                         \
	       -v this_mode="lite"                             \
	       -v odd_run="$odd_run"                           \
	       -v Color_Off="$Color_Off"                       \
	       -v Background="$Background"                     \
	       -e "BEGIN {$awk_data display()}" 

    elif [ -f "$start_file" ]
    then
	header_lite
	check_wait_connecting &&
	    print_header " Connessione in corso ..." "$BYellow" ||
		print_header " Connessione in corso . . . " "$BGreen"

	[ -f "$path_tmp"/no-clear-lite ] ||
	    [ -f "$path_tmp"/stop-binding ] ||
	    clear_lite
    fi
}

function check_wait_connecting {
    if [ -f "$path_tmp"/wait_connecting ]
    then
	rm "$path_tmp"/wait_connecting 
	return 1

    else
	touch "$path_tmp"/wait_connecting
	return 0
    fi
}

function show_downloads_extended {
    unset instance_pid daemon_pid

    fclear
    header_z
    header_box_interactive "Modalità interattiva"

    [ -f "$path_tmp/downloader" ] && downloader_in=$(cat "$path_tmp/downloader")
    echo -e "\n${BBlue}Downloader:${Color_Off} $downloader_in\t${BBlue}Directory:${Color_Off} $PWD\n"

    if check_instance_daemon
    then
	print_c 1 "$PROG è attivo in modalità demone (pid: $daemon_pid)\n"
	instance_pid="$daemon_pid"
	
    else
	if check_instance_prog
	then
	    if [ "$this_tty" == "$that_tty" ]
	    then
		term_msg="in questo stesso terminale: $this_tty"

	    else
		term_msg="in un altro terminale: $that_tty"
	    fi
	    
	    echo -e "${BGreen}$PROG è attivo in modalità standard $term_msg\n${Color_Off}"

	    if [ "$that_tty" != "$this_tty" ]
	    then
		instance_pid="$that_pid"

	    else
		unset instance_pid
	    fi
	else
	    echo -e "${BRed}Non ci sono istanze attive di $PROG\n${Color_Off}"
	fi
    fi

    if data_stdout "no_check"
    then
	stdbuf -oL -eL                                             \
	       awk -f $path_usr/libs/common.awk                    \
	       -f $path_usr/ui/colors-${background}.awk.sh         \
	       -f $path_usr/ui/ui.awk                              \
	       -v col="$COLUMNS"                                   \
	       -v zdl_mode="extended"                              \
	       -v Color_Off="$Color_Off"                           \
	       -v Background="$Background"                         \
	       -e "BEGIN {$awk_data display()}" 
    fi
}


function services_box {
    fclear
    header_z
    header_box_interactive "Estensioni"
    print_C 4 "\nVideo in streaming saltando il player del browser:"
    cat $path_usr/streaming.txt 2>/dev/null
    
    print_C 4 "\nFile hosting:"
    cat $path_usr/hosting.txt 2>/dev/null

    print_C 4 "\nLink generati dal web (anche dopo captcha):"
    echo -e "$(cat $path_usr/generated.txt 2>/dev/null) ed altri servizi"
    
    print_C 4 "\nShort links:"
    cat $path_usr/shortlinks.txt 2>/dev/null

    print_C 4 "\nTutti i file scaricabili con le seguenti estensioni dei browser:"
    echo -e "Flashgot di Firefox/Iceweasel/Icecat, funzione 'M-x zdl' di Conkeror e script 'zdl-xterm' (XXXTerm/Xombrero e altri)"

    print_C 4 "\nTutti i file scaricabili con i seguenti programmi:"
    cat $path_usr/programs.txt 2>/dev/null
    echo
}


function standard_box {
    [ "$this_mode" == "lite" ] && header_lite_msg=" LITE"
    stdbox=true
    
    [ "$this_mode" == help ] &&
	header_msg="Help dei comandi" ||
	    header_msg="Modalità in standard output${header_lite_msg}"
    header_box "$header_msg"
    
    echo -e -n "$init_msg"
    
    [ -f "$path_tmp/downloader" ] && 
	downloader_in=$(cat "$path_tmp/downloader")
    print_c 0 "\n\n${BBlue}Downloader:${Color_Off} $downloader_in\t${BBlue}Directory:${Color_Off} $PWD\n"
    #[ -z "$1" ] && services_box
    
    commands_box
    if [ -z "$1" ] &&
	   [ -n "$binding" ]
    then
	echo -e "${BBlue}       │${Color_Off}"
	header_box "Readline: immetti URL e link dei servizi"
	echo -e ""

    elif [ "$1" == help ] &&
	   [ -z "$binding" ]
    then
	echo -en "${BBlue}       │${Color_Off}"
	pause

    elif [ "$this_mode" != "lite" ] &&
	   [ -z "$binding" ]
    then
	separator- 7
	print_c 0 "\n"
    fi
}


function commands_box {
    header_dl "Comandi in modalità standard output (tasto M=Meta: <Alt>, <Ctrl> o <Esc>)"

    echo -e "${BGreen} INVIO ${BBlue}│${Color_Off}  immetti un link e digita ${BGreen}INVIO
${BGreen} M-x   ${BBlue}│${Color_Off}  esegue i download [e${BGreen}x${Color_Off}ec]
${BGreen} M-e   ${BBlue}│${Color_Off}  avvia l'${BGreen}e${Color_Off}ditor predefinito
${BGreen} M-c   ${BBlue}│${Color_Off}  ${BGreen}c${Color_Off}ancella le informazioni dei download completati
       ${BBlue}│${Color_Off} 
${BYellow} M-i   ${BBlue}│${Color_Off}  modalità ${BYellow}i${Color_Off}nterattiva
${BYellow} M-C   ${BBlue}│${Color_Off}  ${BYellow}C${Color_Off}onfigura $PROG
       ${BBlue}│${Color_Off} 
${BRed} M-q   ${BBlue}│${Color_Off}  chiudi ZDL senza interrompere i downloader [${BRed}q${Color_Off}uit]
${BRed} M-k   ${BBlue}│${Color_Off}  uccidi tutti i processi [${BRed}k${Color_Off}ill]
       ${BBlue}│${Color_Off}
${BBlue} M-t   │${Color_Off}  sfoglia il ${BBlue}t${Color_Off}utorial
${BBlue} M-l   │${Color_Off}  ${BBlue}l${Color_Off}ista dei servizi abilitati
${BBlue} M-h   │${Color_Off}  visualizza questo riquadro [${BBlue}h${Color_Off}elp]"

}

function readline_links {
    local link    
    ## binding = {  true -> while immissione URL
    ##             unset -> break immissione URL                    }
    binding=true    

    [ "$this_mode" != lite ] &&
	msg_end_input="Immissione URL terminata: avvio download"
    ## bind -x "\"\C-l\":\"\"" 2>/dev/null
    bind -x "\"\C-x\":\"unset binding; print_c 1 '${msg_end_input}'; return\"" 2>/dev/null
    bind -x "\"\ex\":\"unset binding; print_c 1 '${msg_end_input}'; return\"" 2>/dev/null

    cursor on
    
    while :
    do
	trap_sigint
	read -e link
	#input_text link
	
	if [ -n "${link// }" ]
	then
	    link=$(sanitize_url "$link")
	    set_link + "$link"
	    unset break_loop
	fi
    done
}


function trap_sigint {
    local next="$1"
    [ -z "$next" ] && next='trap "echo -n \"\"" SIGINT'
    
    if [[ "$1" == ^[0-9]+$ ]]
    then
	kill_pids="kill -9 $@; kill -9 $loops_pid; kill -9 $pid_prog"
	trap "$kill_pids" SIGINT
    else
	## trap "trap SIGINT; stty echo; kill -9 $loops_pid; exit 1" SIGINT
	########
	## disattivato per il bind aggiuntivo con ctrl:
	## \C-c per cancellare i file temporanei dei download completati
	trap "no_complete=true; data_stdout; unset no_complete; $next" SIGINT
    fi
}

function bindings {
    if [ "$this_mode" != "lite" ] ||
	   [ -n "$binding" ]
    then
	trap_sigint

    elif [ "$this_mode" == "lite" ]
    then

	trap_sigint return
    fi
    
    check_instance_prog

    stty stop ''
    stty start ''
    stty -ixon
    stty -ixoff
    stty -echoctl
    
    ## Alt:
    bind -x "\"\ei\":\"change_mode interactive\"" 2>/dev/null
    bind -x "\"\eh\":\"change_mode help\"" 2>/dev/null
    bind -x "\"\ee\":\"change_mode editor\"" 2>/dev/null
    bind -x "\"\el\":\"change_mode list\"" 2>/dev/null
    bind -x "\"\et\":\"change_mode info\"" 2>/dev/null
    bind -x "\"\eq\":\"quit_clear; clean_countdown; cursor on; kill_pid_urls irc-pids &>/dev/null; kill_external &>/dev/null; kill -9 $loops_pid &>/dev/null; kill -1 $pid_prog\"" &>/dev/null
    bind -x "\"\ek\":\"quit_clear; clean_countdown; cursor on; kill_pid_urls xfer-pids &>/dev/null; kill_pid_urls irc-pids &>/dev/null; kill_downloads &>/dev/null; kill_server; kill_ffmpeg; kill -9 $loops_pid &>/dev/null; kill -9 $pid_prog\"" &>/dev/null
    bind -x "\"\ec\":\"no_complete=true; data_stdout; unset no_complete; export READLINE_LINE=' '\"" &>/dev/null
    bind -x "\"\eC\":\"change_mode configure\"" 2>/dev/null
    
    ## Ctrl:
    bind -x "\"\C-i\":\"change_mode interactive\"" 2>/dev/null
    bind -x "\"\C-h\":\"change_mode help\"" 2>/dev/null
    bind -x "\"\C-e\":\"change_mode editor\"" 2>/dev/null
    bind -x "\"\C-l\":\"change_mode list\"" 2>/dev/null
    bind -x "\"\C-t\":\"change_mode info\"" 2>/dev/null
    bind -x "\"\C-q\":\"quit_clear; clean_countdown; cursor on; kill_pid_urls irc-pids &>/dev/null; kill_external &>/dev/null; kill -9 $loops_pid &>/dev/null; kill -1 $pid_prog\"" &>/dev/null
    bind -x "\"\C-k\":\"quit_clear; clean_countdown; cursor on; kill_pid_urls xfer-pids &>/dev/null; kill_pid_urls irc-pids &>/dev/null; kill_downloads &>/dev/null; kill_server; kill_ffmpeg; kill -9 $loops_pid &>/dev/null; kill -9 $pid_prog\"" &>/dev/null
    bind -x "\"\C-c\":\"no_complete=true; data_stdout; unset no_complete; export READLINE_LINE=' '\"" &>/dev/null
    bind -x "\"\C-C\":\"change_mode configure\"" 2>/dev/null
}

function change_mode {
    local cmd=$1
    local change_out

    start_mode_in_tty "$cmd" "$this_tty"
    #cursor off

    case $cmd in
	configure)
	    zdl --configure
	    init
	    source $path_usr/ui/widgets.sh
	    ;;

	interactive)
	    zdl --interactive
	    ;;
	
	editor)
	    $editor "$path_tmp"/links_loop.txt
	    clean_file "$start_file"
	    ;;
    
	info)
	    command -v pinfo &>/dev/null &&
		pinfo -x zdl ||
		    info zdl
	    ;;
	
	list)
	    zdl --list-extensions
	    ;;

	'help')
	    $path_usr/help_bindings.sh
	    ;;
    esac
    
    start_mode_in_tty "$this_mode" "$this_tty"
    export READLINE_LINE=" "
    
    if [ "$this_mode" != "lite" ] ||
	   [ -n "$binding" ]
    then
	change_out=$(
	    fclear
	    header_z
	    standard_box
		  )
	echo -en "$change_out"
	trap_sigint
	
	[ -n "$binding" ] &&
	    command -v setterm &>/dev/null &&
	    setterm -cursor on

    elif [ "$this_mode" == "lite" ]
    then
	header_lite
	trap_sigint return
    fi

    if [ "$this_mode" != "lite" ] &&
	   [ -z "$binding" ]
    then
	zero_dl show ||
	    show_downloads
    fi
}

function interactive {
    this_mode=interactive
    start_mode_in_tty "$this_mode" "$this_tty"
    
    trap "trap SIGINT; die" SIGINT

    while true
    do
	unset instance_pid daemon_pid that_pid that_tty list file_stdout file_out url_out downloader_out pid_out length_out

	show_downloads_extended
	max_dl=$(cat "$path_tmp/max-dl" 2>/dev/null)
	
	[ ! -f "$path_tmp/max-dl" ] && max_dl=1
	if [ -z "$max_dl" ]
	then
	    num_downloads=illimitati
	else
	    num_downloads=$max_dl
	fi
	
	header_box_interactive "Opzioni [numero download alla volta: $num_downloads]"
	echo -e "${BYellow}   s ${Color_Off}│ ${BYellow}s${Color_Off}eleziona uno o più download (per riavviare, eliminare, riprodurre file audio/video)\n     │
${BGreen}   e ${Color_Off}│ modifica la coda dei link da scaricare, usando l'${BGreen}e${Color_Off}ditor predefinito
     │"
	local Axel Aria2 Wget
	Axel="${BGreen}   a ${Color_Off}│ scarica con ${BGreen}a${Color_Off}xel\n"
	Aria2="${BGreen}   A ${Color_Off}│ scarica con ${BGreen}A${Color_Off}ria2\n"
	Wget="${BGreen}   w ${Color_Off}│ scarica con ${BGreen}w${Color_Off}get\n"
	
	unset $downloader_in
	echo -en "$Axel$Aria2$Wget" 
	
	echo -e "     │\n${BGreen} 0-9 ${Color_Off}│ scarica ${BGreen}un numero da 0 a 9${Color_Off} di file alla volta (pausa di $PROG = 0)
${BGreen}   m ${Color_Off}│ scarica ${BGreen}m${Color_Off}olti file alla volta
     │"

	
	[ -z "$daemon_pid" ] && [ -z "$that_pid" ] &&
	    echo -e "${BGreen}   d ${Color_Off}│ avvia ${BGreen}d${Color_Off}emone"

	echo -e "${BGreen}   c ${Color_Off}│ ${BGreen}c${Color_Off}ancella i file temporanei dei download completati
     │
${BRed}   K ${Color_Off}│ interrompi tutti i download e ogni istanza di ZDL nella directory (${BRed}K${Color_Off}ill-all)"

	( [ -n "$daemon_pid" ] || [ -n "$instance_pid" ] ) &&
	    echo -e "${BRed}   Q ${Color_Off}│ ferma un'istanza attiva di $PROG in $PWD lasciando attivi i downloader già avviati"
	
	echo -e "     │\n${BBlue}   q ${Color_Off}│ esci da $PROG --interactive (${BBlue}q${Color_Off}uit)"
	echo -e "${BBlue}   * ${Color_Off}│ ${BBlue}aggiorna lo stato${Color_Off} (automatico ogni 15 secondi)
     │"

	read -s -n 1 -t 15 action

	case "$action" in
	    s)
		fclear
		header_z
		echo
		show_downloads_extended
		header_box_interactive "Seleziona (Riavvia/sospendi, Elimina, Riproduci audio/video)"
		#echo -e -n "${BYellow}Seleziona i numeri dei download, separati da spazi (puoi non scegliere):${Color_Off}\n"
		print_c 2 "Seleziona i numeri dei download, separati da spazi (puoi non scegliere):"

		input_text inputs array
		
		if [ -n "${inputs[*]}" ]
		then
		    echo
		    header_box_interactive "Riavvia o Elimina"
		    echo -e -n "${BYellow}Cosa vuoi fare con i download selezionati?${Color_Off}\n\n"

		    echo -e "${BYellow} r ${Color_Off}│ ${BYellow}r${Color_Off}iavviarli se è attiva un'istanza di ZDL (con --multi >0), altrimenti sospenderli
${BRed} E ${Color_Off}│ ${BRed}e${Color_Off}liminarli definitivamente (e cancellare il file scaricato)
${BRed} T ${Color_Off}│ ${BRed}t${Color_Off}erminarli definitivamente SENZA cancellare il file scaricato (cancella solo il link dalla coda di download)
   │
${BGreen} p ${Color_Off}│ riprodurre (${BGreen}p${Color_Off}lay) i file audio/video
   │
${BBlue} * ${Color_Off}│ ${BBlue}schermata principale${Color_Off}\n"

		    echo -e -n "${BYellow}Scegli cosa fare: ( r | E | T | p | * ):${Color_Off}\n"

		    input_text input
		    
		    for ((i=0; i<${#inputs[*]}; i++))
		    do
			[[ ! "${inputs[$i]}" =~ ^[0-9]+$ ]] && unset inputs[i]
		    done

		    case "$input" in
			r)
			    
			    for i in ${inputs[*]}
			    do
				kill_url "${url_out[$i]}" 'xfer-pids'
				kill_url "${url_out[$i]}" 'irc-pids'

				kill -9 ${pid_out[$i]} &>/dev/null
				if [ ! -f "${file_out[$i]}.st" ] &&
				       [ ! -f "${file_out[$i]}.aria2" ] &&
				       [ ! -f "${file_out[$i]}.zdl" ] &&
				       [ "${percent_out[i]}" != 100 ]
				then
				    rm -f "${file_out[$i]}" 
				fi
			    done
			    ;;

			E)
			    for i in ${inputs[*]}
			    do
				kill_url "${url_out[$i]}" 'xfer-pids'
				kill_url "${url_out[$i]}" 'irc-pids'
				
				kill -9 ${pid_out[$i]} &>/dev/null
				rm -f "${file_out[$i]}" "${file_out[$i]}.st" "${file_out[$i]}.zdl" "${file_out[$i]}.aria2" "$path_tmp"/"${file_out[$i]}_stdout.tmp"
				set_link - "${url_out[$i]}"
			    done
			    ;;

			T)
			    for i in ${inputs[*]}
			    do
				kill -9 ${pid_out[$i]} &>/dev/null
				rm -f "$path_tmp"/"${file_out[$i]}_stdout.tmp"
				set_link - "${url_out[$i]}"
			    done
			    ;;

			p)
			    if [ -n "$player" ] #&>/dev/null
			    then
				for i in ${inputs[*]}
				do
				    playing_files+=( "${file_out[$i]}" )
				done

				nohup $player "${playing_files[@]}" &>/dev/null &
				unset playing_files

			    else
				configure_key 9
				get_conf
			    fi
			    ;;
		    esac
		fi
		;;
	    
	    [0-9])
		echo "$action" > "$path_tmp/max-dl"
		#unlock_fifo max-downloads "$PWD" &
		init_client 2>/dev/null
		;;
	
	    m)
		echo > "$path_tmp/max-dl"
		;;
	    
	    e)
		$editor "$path_tmp/links_loop.txt"
		clean_file "$path_tmp/links_loop.txt"
		;;
	    
	    c)
		no_complete=true
		data_stdout
		unset no_complete
		;;
	    
	    q)
		fclear
		break
		;;
	    
	    a)
		set_downloader "Axel" 
		;;
	    
	    A)
		set_downloader "Aria2" 
		;;
	    
	    w)
		set_downloader "Wget" 
		;;
	    
	    Q)
		[ -n "$daemon_pid" ] && {
		    kill "$daemon_pid" &>/dev/null
		    rm -f "$path_tmp"/.date_daemon
		    unset daemon_pid
		}

		[ -n "$instance_pid" ] && {
		    kill -9 "$instance_pid" &>/dev/null
		    rm -f "$path_tmp"/.date_daemon
		    unset instance_pid
		}

		;;
	    
	    K)
		kill_downloads
		#kill_server
		[ -n "$instance_pid" ] && {
		    kill -9 "$instance_pid" &>/dev/null
		    rm -f "$path_tmp"/.date_daemon
		    wait "$instance_pid"
		    unset instance_pid
		} 
		;;
	    
	    d)
		[ -z "$daemon_pid" ] && [ -z "$that_pid" ] && {
		    zdl --daemon &>/dev/null
		    start_mode_in_tty "$this_mode" "$this_tty"
		}
		;;
	esac

	unset action input
    done
    
    die
}

function die {
    stty echo
    fclear
    exit
}

function sleeping {
    timer=$1
    ## l'interazione è stata sostituita con 'bind' e i processi sono in background: lo schermo non è più influenzato dalla tastiera
    #
    # if [ -z "$zdl_mode" ] && [ -z "$pipe" ]; then
    # 	read -es -t $timer -n 1 
    # else
	sleep $timer
    # fi
}

function input_text {
    declare -n ref="$1"
    local sttyset
    
    cursor on
    sttyset=$(stty -a|tail -n4)
    stty sane

    if [ "$2" == array ]
    then	
	ref=( $(rlwrap -o cat) )

    else
	ref=$(rlwrap -o cat)
    fi
    
    stty $sttyset
    cursor off
}
