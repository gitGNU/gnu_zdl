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


function usage {

echo -e -n "$(header_z)
${BBlue}Uso (l'ordine degli argomenti non è importante):${Color_Off}
  ${BWhite}zdl [OPZIONI] [FILE_1 FILE_2 ...] [LINK_1 LINK_2 ...] [DIR]${Color_Off}

         FILE_n                Nomi dei file da cui estrarre i LINK.
                               I file devono essere testuali
                               oppure container DLC (se omessi, 
                               $PROG processa i LINK in memoria
                               nella DIR e quelli in input)

         LINK_n                URL dei file oppure delle pagine web 
                               dei servizi di hosting, streaming 
                               o di reindirizzamento (se omessi, 
                               $PROG processa quelli in memoria 
                               nella DIR e nei FILE)

         DIR                   Directory di avvio di $PROG 
                               e di destinazione dei download 
                               (se omessa, è quella corrente)
  

$(header_box Opzioni)
${BBlue}Le opzioni brevi non seguite da valori possono essere contratte:${Color_Off} '-ufmd' equivale a '-u -f -m -d'

  -h,  --help                  Help di ZigzagDownLoader (ZDL)

       --wget                  Forza l'uso di Wget
       --axel                  Forza l'uso di Axel

  -m [N], --multi [NUM]        Download parallelo. È possibile indicare
                               il numero massimo di download da effettuare
                               contemporaneamente
       
       --login	               Utilizza eventuali account registrati per i
                               servizi abilitati (configurare ${PROG})

  -u,  --update   	       Aggiorna $PROG
  -f,  --force                 Forza l'aggiornamento manuale di $PROG

       --clean  	       Cancella eventuali file temporanei dalla
	                       directory di destinazione, prima di effettuare
	         	       il download 

  -i,  --interactive           Avvia l'interfaccia interattiva di ZDL per i
	     	               download che hanno come destinazione la
			       directory attuale. I download gestiti possono
			       essere attivi o registrati nei file temporanei
			       della directory

       --out=<PROG|FILE>       Restituisce in output i nomi dei file 
                               dei download completati, in due modi alternativi:
                                 PROG: programma che può \"aprire\" il file 
                                       scaricato
                                 FILE: file testuale in cui sono registrati 
                                       i nomi dei file

       --mp3                   Convertono i file (anche da video in audio) 
       --flac                  in MP3 oppure in FLAC: dipende da FFMpeg/AVConv
                                
  -d,  --daemon 	       Avvia ZDL in modalità \"demone\" (può essere
                               controllato attraverso l'interfaccia
                               interattiva) 

       --ip		       Scrive l'indirizzo IP attuale, prima di
                               effettuare altre operazioni

       --reconnect             Forza la riconnessione del modem al termine
                               di ogni download, utilizzando
                               uno script/comando/programma (configurare ${PROG})
                         

${BBlue}Avvio con proxy:${Color_Off}
       --proxy		       Avvia ZDL attivando un proxy
		               automaticamente (il tipo di proxy
		               predefinito è Transparent) 

       --proxy=[t|a|e]         Avvia ZDL attivando un proxy del tipo
		               definito dall'utente:
			    	 t = Transparent
			    	 a = Anonymous
			    	 e = Elite
			
	--proxy=IP:PORTA       Avvia ZDL attivando il proxy indicato
		               all'utente, per l'intera durata del
		               download (il proxy viene sostituito
			       automaticamente solo per i link dei
			       servizi abilitati che necessitano di
			       un nuovo indirizzo IP) 


${BBlue}Configurazione:${Color_Off} 
  -c,  --configure	       Interfaccia di configurazione di ZDL, 
			       permette anche di salvare eventuali
			       account dei servizi di hosting


${BBlue}Per scaricare lo stream incorporando ${PROG} in nuovi script${Color_Off}, 
il modello generico dei parametri per le componenti aggiuntive (rispettare l'ordine): 
       --stream [PARAMETRI] [--noXterm]


$(header_box Servizi)
${BBlue}Video in streaming saltando il player del browser:${Color_Off}
$(zdl-ext-sorted streaming)

${BBlue}File hosting:${Color_Off}
$(zdl-ext-sorted download) e, dopo aver risolto il captcha e generato il link, anche Sharpfile, Depositfiles ed altri servizi

${BBlue}Tutti i file scaricabili con le seguenti estensioni dei browser:${Color_Off}
Flashgot di Firefox/Iceweasel/Icecat, funzione 'M-x zdl' di Conkeror e script 'zdl-xterm' (XXXTerm/Xombrero e altri)


$(header_box 'Documentazione')
  - ipertesto in formato info, consultabile con: ${BWhite}info zdl${Color_Off}
  - ipertesto in formato html: ${BWhite}http://nongnu.org/zdl${Color_Off}
  - pagina di manuale in stile Unix: ${BWhite}man zdl${Color_Off}

$(header_box 'Altre info')
${BBlue}Licenza:${Color_Off}
  ZDL è rilasciato con licenza GPL (General Public Licence, v.3 e superiori). 


${BBlue}Per informazioni e per collaborare al progetto:${Color_Off}
  - http://nongnu.org/zdl
  - https://savannah.nongnu.org/projects/zdl
  - https://joindiaspora.com/tags/zdl

Gianluca Zoni (zoninoz)
http://inventati.org/zoninoz" | less --RAW-CONTROL-CHARS 	
    echo
    echo
    exit 1

}