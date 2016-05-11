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

function init_log {
    if [ -z "$log" ]
    then
	echo "File log di $name_prog:" > $file_log
	log=1
    fi
    echo >> $file_log
    date >> $file_log
}

function _log {
    [ -n "$2" ] &&
	url_in="$2"
    
    [ -n "$file_in" ] &&
	msg_file_in=" $file_in"
    
    case $1 in
	1)
	    msg="File$msg_file_in già presente in $PWD: $url_in non verrà processato."
	    links_loop - "${url_in}"
	    ;;
	2)
	    [ -n "$errMsg" ] &&
		errMsg=":\n$errMsg"
	    msg="$url_in --> File$msg_file_in non disponibile, riprovo più tardi${errMsg}"
	    ;;
	3)
	    msg="$url_in --> Indirizzo errato o file non disponibile" 
	    links_loop - "$url_in"
	    rm -f "$path_tmp"/"$file_in"_stdout.* "$path_tmp"/filename_"$file_in".txt
	    ;;
	4)
	    msg="Il file$msg_file_in supera la dimensione consentita dal server per il download gratuito (link: $url_in)"
	    links_loop - "$url_in"
	    ;;
	5)
	    msg="Connessione interrotta: riprovo più tardi"
	    ;;
	6)
	    msg="$url_in --> File$msg_file_in troppo grande per lo spazio libero in $PWD su $dev"
	    print_c 3 "$msg"
	    echo "$msg" >> $file_log
	    exit
	    ;;
	7)
	    msg="$url_in --> File$msg_file_in già in download (${url_out[$i]})"
	    ;;
	8)
	    msg="$url_in --> Indirizzo errato o file non disponibile.\nErrore nello scaricare la pagina HTML del video. Controllare che l'URL sia stato inserito correttamente o che il video non sia privato."
	    links_loop - "$url_in"
	    ;;
	9)
	    msg="$url_in --> Titolo della pagina HTML non trovato. Controlla l'URL."
	    links_loop - "$url_in"
	    ;;
	10)
	    msg="$url_in --> Firma del video non trovata"
	    ;;
	11)
	    msg="$url_in --> File$msg_file_in scaricabile solo da utenti \"Premium\" o registrati"
	    links_loop - "$url_in"
	    ;;
	12)
	    msg="$url_in --> Non è un URL adatto per $name_prog\n"
	    ;;
	13)
	    msg="$url_in --> Il file$msg_file_in non sarà scaricato, perché corrisponde alla regex: $no_file_regex"
	    links_loop - "$url_in"
	    ;;
	14)
	    msg="$url_in --> Il file$msg_file_in non sarà scaricato, perché non corrisponde alla regex: $file_regex"
	    links_loop - "$url_in"
	    ;;
	15)
	    msg="$url_in --> Il link non sarà processato, perché corrisponde alla regex: $no_url_regex"
	    links_loop - "$url_in"
	    ;;
	16)
	    msg="$url_in --> Il link non sarà processato, perché non corrisponde alla regex: $file_regex"
	    links_loop - "$url_in"
	    ;;
	17)
	    msg="$url_in --> File$msg_file_in ancora in trasferimento e non ancora disponibile: riprova fra qualche ora" 
	    links_loop - "$url_in"
	    ;;
	18)
	    msg="$url_in --> resume non supportato: il download del file$msg_file_in potrebbe terminare incompleto"
	    ;;
	19)
	    msg="$url_in --> Download non supportato: controllo età utente" 
	    links_loop - "$url_in"
	    ;;
	20)
	    msg="$url_in --> Download non supportato: installa lo script youtube-dl"
	    links_loop - "$url_in"
	    ;;
	21)
	    msg="$url_in --> Download supportato da youtube-dl, avviato ma non gestito da $PROG"
	    links_loop - "$url_in"
	    ;;
	22)
	    # msg="Il file ${fprefix%__M3U8__}.ts non può essere ricostruito perché incompleto:\nmanca almeno il segmento $i"
	    msg="Manca il segmento $i: tentativo di recupero con Wget estraendo l'URL da un file temporaneo"
	    unset break_loop
	    ;;
	23)
	    msg="Operazione non riuscita perché $dep non è installato"
	    ;;
	
	24)
	    msg="Impossibile completare l'operazione: manca il file temporaneo per il recupero del segmento"
	    unset break_loop
	    ;;
	25)
	    msg="Raggiunto il limite di download per il tuo indirizzo IP o account (link: $url_in): prova --proxy o --reconnect"
	    no_msg=true
	    ;;
    esac
    
    ##  if [ -z "$no_msg" ] || [ -n "$from_loop" ]
    if [ -z "$break_loop" ] 
    then
	init_log
	print_c 3 "$msg"
	echo "$msg" >> $file_log
	# no_msg=true
	# unset from_loop
	[ "$1" != 18 ] && break_loop=true
    fi
}
