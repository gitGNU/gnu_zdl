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

function init_log {
    if [ $log == 0 ]; then
	echo -e "File log di $name_prog:\n" > $file_log
	log=1
    fi
    echo | tee -a $file_log
    date >> $file_log
}

function _log {
    [ ! -z "$2" ] && [ -z "$file_in" ] && url_in="$2"
    case $1 in
	1)
	    if [ ! -z "$from_loop" ] || [ -z "$no_msg" ]; then
		init_log
		print_c 3  "File $file_in già presente in $PWD: $url_in non verrà processato."  | tee -a $file_log
		links_loop - "$url_in"
		no_msg=true
		unset from_loop
	    fi
	    ;;
	2)
	    if [ ! -z "$url_in" ]; then
		url_in_log=" (link di download: $url_in) "
	    fi
	    if [ ! -z "$from_loop" ] || [ -z "$no_msg" ]; then
		init_log
		print_c 3  "$url_in --> File ${file_in}${url_in_log} non disponibile, riprovo più tardi"  | tee -a $file_log
		no_msg=true
		unset from_loop
	    fi
	    ;;
	3)
	    if [ ! -z "$from_loop" ] || [ -z "$no_msg" ]; then
		init_log
		print_c 3  "$url_in --> Indirizzo errato o file non disponibile" | tee -a $file_log
		links_loop - "$url_in"
		no_msg=true
		unset from_loop
	    fi
	    ;;
	4)
	    if [ ! -z "$from_loop" ] || [ -z "$no_msg" ]; then
		init_log
		print_c 3 "Il file $file_in supera la dimensione consentita dal server per il download gratuito (link: $url_in)" | tee -a $file_log
		links_loop - "$url_in"
		no_msg=true
		unset from_loop
	    fi
	    ;;
	5)
	    init_log
	    print_c 3 "Connessione interrotta: riprovo più tardi" | tee -a $file_log
	    echo
	    ;;
	6)
	    init_log
	    print_c 3 "$url_in --> File $file_in troppo grande per lo spazio libero in $PWD su $dev" | tee -a $file_log
	    exit
	    #links_loop - "$url_in"
	    echo
	    ;;
	7)
	    init_log
	    print_c 3 "$url_in --> File $file_in già in download (${url_out[$i]})" | tee -a $file_log
	    echo
	    ;;
	8)
	    init_log
	    print_c 3  "$url_in --> Indirizzo errato o file non disponibile.\nErrore nello scaricare la pagina HTML del video. Controllare che l'URL sia stato inserito correttamente o che il video non sia privato." | tee -a $file_log
	    links_loop - "$url_in"
	    echo
	    ;;
	9)
	    init_log
	    print_c 3 "$url_in --> Titolo della pagina HTML non trovato. Controlla l'URL." | tee -a $file_log
	    links_loop - "$url_in"
	    echo
	    ;;
	10)
	    init_log
	    print_c 3 "$url_in --> Firma del video non trovata" | tee -a $file_log
	    echo
	    ;;
	11)
	    if [ ! -z "$from_loop" ] || [ -z "$no_msg" ]; then
		init_log
		print_c 3  "$url_in --> File scaricabile solo da utenti \"Premium\"" | tee -a $file_log
		links_loop - "$url_in"
		no_msg=true
		unset from_loop url_in file_in url_in_file
	    fi
	    ;;
	12)
	    init_log
	    print_c 3  "$url_in --> Non è un URL adatto per $name_prog" | tee -a $file_log
	    if [ ! -z "$from_loop" ] || [ -z "$no_msg" ]; then
		no_msg=true
		unset from_loop	
	    fi
	    ;;
    esac
}
