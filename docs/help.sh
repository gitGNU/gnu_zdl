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


function usage {
    streaming="$(fold -w 80 -s $path_usr/streaming.txt)"
    hosting="$(fold -w 80 -s $path_usr/hosting.txt)"
    generated="$(fold -w 80 -s $path_usr/generated.txt)"
    shortlinks="$(fold -w 80 -s $path_usr/shortlinks.txt)"
    programs="$(fold -w 80 -s $path_usr/programs.txt)"
    
    echo -en "ZigzagDownLoader (ZDL)

Uso (l'ordine degli argomenti non è importante):
  zdl [OPZIONI] [FILE_1 FILE_2 ...] [LINK_1 LINK_2 ...] [DIR]

         FILE_n                Nomi dei file da cui estrarre i LINK.
                               I file devono essere testuali
                               oppure container DLC o file TORRENT, 
                               questi ultimi contrassegnati rispettivamente 
                               dalle estensioni .dlc e .torrent
                               ($PROG processa comunque i LINK in memoria
                               nella DIR e quelli in input)

         LINK_n                URL dei file oppure delle pagine web 
                               dei servizi di hosting, streaming 
                               o di reindirizzamento (se omessi, 
                               $PROG processa quelli in memoria 
                               nella DIR e nei FILE). 
                               Per scaricare via IRC/XDCC, il link
                               deve avere la seguente forma (porta 
                               non necessaria se è 6667):
                                 irc://[HOST[:PORT]]/[CHAN]/msg [PRIVMSG]
                               
                               ZDL accetta anche i link di xWeasel 
                               (con protocollo xdcc://)

         DIR                   Directory di avvio di $PROG 
                               e di destinazione dei download 
                               (se omessa, è quella corrente)
  

OPZIONI
  Le opzioni brevi non seguite da valori possono essere contratte:
  '-ufmd' equivale a '-u -f -m -d'


  -h,  --help                  Help di ZigzagDownLoader ($PROG)

       --list-extensions       Elenco delle estensioni di $PROG 

       --aria2                 Scarica con Aria2
       --wget                  Scarica con Wget
       --axel                  Scarica con Axel

  -m [N], --multi=[NUM]        Download parallelo. È possibile indicare
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

  -d,  --daemon 	       Avvia ZDL in modalità \"demone\" (può essere
                               controllato attraverso l'interfaccia
                               interattiva) 

  -l,  --lite                  Avvia ZDL in modalità in standard output \"lite\" 
                               (sono validi i comandi della modalità in 
                               \"standard output\") 

       --out=<PROG|FILE>       Restituisce in output i nomi dei file 
                               dei download completati, in due modi alternativi:
                                 PROG: programma che può \"aprire\" il file 
                                       scaricato
                                 FILE: file testuale in cui sono registrati 
                                       i nomi dei file

       --mp3                   Convertono i file (anche da video in audio) 
       --flac                  in MP3 oppure in FLAC: dipende da FFMpeg/AVConv
                                
       --ip		       Scrive l'indirizzo IP attuale, prima di
                               effettuare altre operazioni

       --reconnect             Forza la riconnessione del modem al termine
                               di ogni download, utilizzando
                               uno script/comando/programma (configurare ${PROG})

  -r,  --resume                Recupera o riscarica file parzialmente scaricati.
                               Agisce in caso di omonimia fra file (leggi il manuale).
                               Può essere configurato come comportamento predefinito.

       --no-complete           Cancella i file temporanei dei download completati


IRC/XDCC:
  -x,  --xdcc                  Avvia l'inserimento interattivo di tre dati:
                               1) l'host del server IRC (HOST)
                               2) il canale a cui connettersi (CHAN)
                               3) il messaggio privato (PRIVMSG) che contiene 
                                  il comando XDCC SEND

                               Il download via IRC/XDCC può essere affettuato, 
                               alternativamente e senza usare opzioni, inserendo le 
                               informazioni nel link, che deve avere la forma 
                               seguente (porta non necessaria se è 6667):
                                  irc://[HOST[:PORT]]/[CHAN]/msg [PRIVMSG]


Torrent (Aria2):
  -T <FILE>,  --torrent-file=<FILE>     File torrent per Aria2: 
                                        può non avere estensione .torrent

       --tcp-port=<NUM>        Porte TCP e UDP aperte: 
       --udp-port=<NUM>        verificare le impostazioni del router


Filtri:
       --scrape-url=<URL>      Estrae gli URL/link dalla pagina web indicata e
                               li accoda all'elenco registrato

       --scrape-url            Estrae gli URL (i link) dalle pagina web indicate 
                               come LINK

       --url=<REGEX>           Processa solo gli URL (i link) che corrispondono 
                               alla REGEX

       --no-url=<REGEX>        Non processa gli URL (i link) che corrispondono 
                               alla REGEX

       --file=<REGEX>          Scarica solo file il cui nome corrisponde alla REGEX

       --no-file=<REGEX>       Non scarica i file il cui nome corrisponde alla REGEX

       --no-rev                Non scarica i file con estensione '.rev'

       --no-sub                Non scarica i file il cui nome contiene le stringhe 
                               'Sub' o 'sub' (per file video sottotitolati)


Editor per i link (può essere usato in qualunque momento con Meta-e):
sostituisce l'interfaccia iniziale per l'immissione dei link

  -e,  --editor                Editor predefinito (si può configurare con 'zdl -c')

       --emacs, --emacs-nw     Emacs e la sua versione '-nw' (senza grafica)
       --jed                   piccolo editor in stile GNU Emacs
       --jupp                  Jupp
       --mcedit                Midnight Commander Editor
       --mg                    micro editor in stile GNU Emacs
       --nano                  Nano
       --vi, --vim             Vi e Vim
       --zile                  micro editor in stile GNU Emacs


Avvio con proxy:
       --proxy		       Avvia ZDL attivando un proxy
		               automaticamente (il tipo di proxy
		               predefinito è Transparent) 

       --proxy=<t|a|e>         Avvia ZDL attivando un proxy del tipo
		               definito dall'utente:
			    	 t = Transparent
			    	 a = Anonymous
			    	 e = Elite
			
       --proxy=<IP:PORTA>      Avvia ZDL attivando il proxy indicato
		               all'utente, per l'intera durata del
		               download (il proxy viene sostituito
			       automaticamente solo per i link dei
			       servizi abilitati che necessitano di
			       un nuovo indirizzo IP) 


Configurazione:
  -c,  --configure	       Interfaccia di configurazione di ZDL, 
			       permette anche di salvare eventuali
			       account dei servizi di hosting


Per scaricare lo stream incorporando ${PROG} in nuovi script, 
il modello generico dei parametri per le componenti aggiuntive (rispettare l'ordine): 
       --stream [PARAMETRI] [--noXterm]


SERVIZI
______ Video in streaming saltando il player del browser:
$streaming

______ File hosting:
$hosting

______ Link generati dal web (anche dopo captcha):
$generated

______ Short links:
$shortlinks

______ Tutti i file scaricabili con i seguenti programmi:
$programs

______ Tutti i file scaricabili con le seguenti estensioni dei browser:
Flashgot di Firefox/Iceweasel/Icecat, funzione 'M-x zdl' di Conkeror
e script 'zdl-xterm' (XXXTerm/Xombrero e altri)


DOCUMENTAZIONE
  - ipertesto in formato info, consultabile con: 'info zdl'
  - ipertesto in formato html: http://nongnu.org/zdl
  - pagina di manuale in stile Unix: 'man zdl'


COPYING
  ZDL è rilasciato con licenza GPL (General Public Licence, v.3 e superiori). 


Per informazioni e per collaborare al progetto:
  - http://nongnu.org/zdl
  - https://savannah.nongnu.org/projects/zdl
  - https://joindiaspora.com/tags/zdl

Gianluca Zoni (zoninoz)
http://inventati.org/zoninoz
" | less
    echo
    echo
    exit 1
}
