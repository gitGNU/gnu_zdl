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
    while read line; do
	extensions_download="$extensions_download$line, "
    done <<< "$(zdl-extensions download)"
    extensions_download=${extensions_download%\, }

    while read line; do
	extensions_streaming="$extensions_streaming$line, "
    done <<< "$(zdl-extensions streaming)"
    extensions_streaming=${extensions_streaming%\, }

echo -e -n "$(header_z)
${BBlue}Uso (l'ordine degli argomenti non è importante):${Color_Off}
\t${BWhite}zdl [OPZIONI] [FILE_1 FILE_2 ...] [LINK_1 LINK_2 ...] [DIR]${Color_Off}

FILE_n                          Nomi dei file da cui estrarre i LINK.
                                I file devono essere testuali
                                oppure container DLC (se omessi, 
                                $PROG processa i LINK in memoria 
                                nella DIR e quelli in input)

LINK_n                          URL dei file oppure delle pagine web 
                                dei servizi di hosting, streaming 
                                o di reindirizzamento (se omessi, 
                                $PROG processa quelli in memoria 
                                nella DIR e nei FILE)

DIR                             Directory di avvio di $PROG 
                                e di destinazione dei download 
                                (se omessa, è quella corrente)


$(header_box Opzioni)
${BBlue}Le opzioni brevi non seguite da valori possono essere contratte:${Color_Off} '-ufmd' equivale a '-u -f -m -d'

-h,     --help                  Help di ZigzagDownLoader (ZDL)

        --wget                  Forza l'uso di Wget
        --axel                  Forza l'uso di Axel

-m [N], --multi [NUM]	        Download parallelo. È possibile indicare
                                il numero massimo di download da effettuare
                                contemporaneamente
        
	--login		        Utilizza eventuali account registrati per i
                                servizi abilitati (configurare ${PROG})

-u,     --update   	        Aggiorna $PROG
-f,     --force                 Forza l'aggiornamento manuale di $PROG

        --clean    	        Cancella eventuali file temporanei dalla
	           	        directory di destinazione, prima di effettuare
	           	        il download 

-i,     --interactive           Avvia l'interfaccia interattiva di ZDL per i
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
                                
-d,	--daemon 	        Avvia ZDL in modalità \"demone\" (può essere
                                controllato attraverso l'interfaccia
                                interattiva) 

	--ip 		        Scrive l'indirizzo IP attuale, prima di
			        effettuare altre operazioni

        --reconnect             Forza la riconnessione del modem al termine
                                di ogni download, utilizzando
                                uno script/comando/programma (configurare ${PROG})
                         

${BBlue}Avvio con proxy:${Color_Off}
	--proxy			Avvia ZDL attivando un proxy
				automaticamente (il tipo di proxy
				predefinito è Transparent) 

	--proxy=[t|a|e]     	Avvia ZDL attivando un proxy del tipo
			    	definito dall'utente:
			    		 t = Transparent
			    		 a = Anonymous
			    		 e = Elite
			
	--proxy=IP:PORTA	Avvia ZDL attivando il proxy indicato
				dall'utente, per l'intera durata del
				download (il proxy viene sostituito
				automaticamente solo per i link dei
				servizi abilitati che necessitano di
				un nuovo indirizzo IP) 


${BBlue}Configurazione:${Color_Off} 
-c,	--configure		Interfaccia di configurazione di ZDL, 
			  	permette anche di salvare eventuali
				account dei servizi di hosting


${BBlue}Per scaricare lo stream incorporando ${PROG} in nuovi script${Color_Off}, 
il modello generico dei parametri per le componenti aggiuntive (rispettare l'ordine): 
	--stream [PARAMETRI] [--noXterm]


$(header_box Servizi)
${BBlue}Video in streaming saltando il player del browser:${Color_Off}
${extensions_streaming}

${BBlue}File hosting (per link Cineblog01 dipende da cURL):${Color_Off}
${extensions_download} e, dopo aver risolto il captcha e generato il link, anche Sharpfile, Depositfiles ed altri servizi

${BBlue}Tutti i file scaricabili con le seguenti estensioni dei browser:${Color_Off}
Flashgot (Firefox/Iceweasel/Icecat)


$(header_box 'Dipendenze consigliate')
Axel                            Acceleratore di download

FFmpeg/AVConv                   Convertitore per MP3/FLAC

cURL/RTMPDump                   Downloader per servizi RTMP

XTerm                           Terminale grafico predefinito per GNU/Linux

Flashgot                        Estensione di Firefox/Iceweasel/Icecat

${BBlue}$PROG è compatibile con:${Color_Off} 
XXXTerm/Xombrero                Script 'zdl-xterm' in /usr/local/bin

Conkeror                        Funzione 'M-x zdl' autoinstallata

${BBlue}Dipendenze per Windows:${Color_Off} 
Cygwin (x86 32-bit)             Distribuzione per il porting di software
                                di sistemi POSIX su Microsoft Windows

Wget                            Downloader principale di $PROG, 
                                da installare su Cygwin


$(header_box 'Altre info')
${BBlue}Licenza:${Color_Off}
ZDL è rilasciato con licenza GPL (General Public Licence, v.3 e superiori). 


${BBlue}Per informazioni e per collaborare al progetto:${Color_Off}
http://nongnu.org/zdl
https://savannah.nongnu.org/projects/zdl

Gianluca Zoni (zoninoz)
http://inventati.org/zoninoz" | less --RAW-CONTROL-CHARS 	
    echo
    echo
    exit 1

}


function usage_man {
    echo -e -n '\e[0m\e[J'
    echo -e -n "\e[0m\e[J
ZigzagDownLoader ($PROG) - Download manager

\e[1mUso (l'ordine degli argomenti non è importante): \e[0m
zdl [opzioni] [file_1 file_2 ...] [link_1 link_2 ...]

\e[1mOpzioni:\e[0m 
-h,     --help		Manuale di ZigzagDownLoader (ZDL)

	--wget	   	Forza l'uso di Wget
	--axel 		Forza l'uso di Axel

-m,     --multi	   	Download parallelo
        
	--login		Utilizza eventuali account registrati

-u,     --update   	Aggiorna ZDL 

        --clean    	Cancella eventuali file temporanei dalla
	           	directory di destinazione, prima di effettuare
	           	il download 

-i,     --interactive   Avvia l'interfaccia interattiva di ZDL per i
			download che hanno come destinazione la
			directory attuale. I download gestiti possono
			essere attivi o registrati nei file temporanei
			della directory

-d,	--daemon 	Avvia ZDL in modalità \"demone\" (può essere
                        controllato attraverso l'interfaccia
                        interattiva) 

	--ip 		Scrive l'indirizzo IP attuale, prima di
			effettuare altre operazioni



\e[1mAvvio con proxy:\e[0m
	--proxy			Avvia ZDL attivando un proxy
				automaticamente (il tipo di proxy
				predefinito è Transparent) 

	--proxy=[t|a|e]     	Avvia ZDL attivando un proxy del tipo
			    	definito dall'utente:
			    		 t = Transparent
			    		 a = Anonymous
			    		 e = Elite
			
	--proxy=IP:PORTA	Avvia ZDL attivando il proxy indicato
				dall'utente, per l'intera durata del
				download (il proxy viene sostituito
				automaticamente solo per i link dei
				servizi abilitati che necessitano di
				un nuovo indirizzo IP) 

\e[1mConfigurazione:\e[0m 
-c,	--configure		Interfaccia di configurazione di ZDL, 
			  	permette anche di salvare eventuali
				account dei servizi di hosting


\e[1mPer scaricare lo stream dai browser\e[0m (anche file
multimediali), il modello generico dei parametri per le
componenti aggiuntive (rispettare l'ordine, più avanti le istruzioni
dettagliate): 
	--stream [PARAMETRI] [--noXterm]



\e[1mIl gestore di download ZigzagDownLoader: manuale e consigli d'uso.\e[0m

ZDL è abilitato per il download da ogni tipo di link valido, compresi
lo stream video (per esempio da Youtube, Putlocker, Nowvideo,
Dailymotion...) per mezzo di estensioni dei browser, ed i file
condivisi attraverso i seguenti servizi di hosting e di streaming,
direttamente dal link:
Putlocker (scarica il file in formato AVI, se si tratta di un filmato
disponibile anche in streaming), Youtube, Dailymotion, Metacafe,
Topvideo, Nowdownload, Rapidshare, Tusfiles, Cyberlocker, Mediafire,
Easybytez, Uload e Glumbouploads (Sharpfile, Depositfiles e altri
servizi, dopo aver risolto il captcha, anche avviando ZDL con il
browser attraverso le componenti aggiuntive compatibili). Inoltre, ZDL
converte i redirect di Likeupload, avviando automaticamente il
download dai link reindirizzati.  


\e[1mZDL può essere avviato in diversi modi:\e[0m

    \e[1mA) PER IMMETTERE LINK E AVVIARE NUOVI DOWNLOAD\e[0m

	1) Generando automaticamente la lista dei link per il
	   download:

		- apri un terminale ed entra nella directory che dovrà
	  	  contenere i file scaricati

		- avvia ZDL digitando il comando seguito da eventuali
                  opzioni 

		- copia i link dei file da scaricare e incollali nel
	  	  terminale (vai a capo dopo ogni link)

		- premi la chiocciolina \"@\"


	2) Utilizzando uno o più file preparati con un editor di testi
	   (andare a capo dopo ogni link) e raggiungibili dalla directory
	   di destinazione (indica un path valido):

	   	- apri un terminale ed entra nella directory che dovrà
		  contenere i file scaricati
		- digita il seguente comando e premi invio:
		  	 zdl path/file_1 path/file_2 ... path/file_n


	3) Indicando direttamente a ZDL i link da processare (se link
	   validi dovessero essere dichiarati non validi, usare il modo
	   1), per esempio:
	    	zdl link_1 link_2 ... link_n


	4) Dal browser web, attraverso l'uso di componenti aggiuntive
	   (più in basso le istruzioni), allo scopo di catturare e
	   salvare lo stream di un video o un altro file di qualsiasi
	   tipo. 


        5) In modalità \"demone\"


      I file e i link dei punti 2) e 3) possono essere
      mescolati. Tutti i link degli input sono salvati nel file
     links.txt, nella directory di destinazione. 


    \e[1mB) PER GESTIRE DOWNLOAD GIÀ AVVIATI NELLE MODALITÀ \"NON\e[0m
       \e[1mINTERATTIVA\" E \"DEMONE\"\e[0m 

        - Avviando la modalità interattiva in due modi:

	  1) in console dalla directory di destinazione dei download,
             con il comando \e[1mzdl -i\e[0m oppure
	     \e[1mzdl --interactive\e[0m

	  2) nella modalità \"non interattiva\" (standard), digitando
	     il tasto \"i\" 

\e[1mZDL può essere fermato in diversi modi:\e[0m

        - Se i download sono gestiti dalla modalità \"non
          interattiva\"/standard:

	  1) digitando Control+c (in questo caso saranno interrotti
             anche i download di Axel)

	  2) digitando il tasto \"q\" (tutti i download già avviati
             nella directory corrente con Wget e Axel non saranno
             interrotti, ma non verranno più gestiti da ZDL)


        - Se i download sono gestiti dalla modalità \"demone\":
          attraverso la modalità interattiva (\e[1mzdl -i\e[0m)
          avviata nella directory gestita dal demone, digitando il
          tasto di stop: \"s\" (in questo caso i download avviati con
          Axel e Wget non sarano interrotti, ma non verranno gestiti
          da ZDL) 


\e[1mAltre informazioni utili.\e[0m

Per i servizi di hosting seguenti è consigliato l'uso della funzione
\"multi\" (aggiungere l'argomento -m alle istruzioni sopra elencate)
per procedere con il download in parallelo, eventualmente attraverso
l'uso di proxy: Easybytez, Sharpfile e Mediafire

Per scaricare da Sharpfile, Depositfiles e da altri servizi,
attualmente è necessario utilizzare il browser per risolvere il
captcha, generare il link ed avviare ZDL attraverso le componenti
aggiuntive compatibili dei browser o copiandolo ed incollandolo nel
terminale, per passarlo a ZDL.

In caso di interruzione del download (per esempio a causa di
disconnessione), i file scaricati attraverso Axel possono riprendere
il download dal punto di interruzione (solo se nella cartella che
contiene il file scaricato è ancora presente il file omonimo con
estensione \".st\"). Se i file interrotti sono stati scaricati con
Wget, non possono essere recuperati e verranno riscaricati
automaticamente da capo. I servizi seguenti sono abilitati solo per il
download con Wget: Easybytez, Dailymotion. Gli altri servizi
(Nowdownload, Rapidshare, Putlocker, Tusfiles, Cyberlocker, Mediafire,
Uload, Glumbouploads, Sharpfile, Depositfiles, ...) sono abilitati in
modo predefinito per Axel. In ogni caso ZDL provvederà automaticamente
a recuperare il download o a rieseguirlo da capo. Nel caso in cui
anche ZDL è stato terminato, il recupero manuale è possibile
riavviando ZDL e digitando la chiocciolina \"@\".

Il file links.txt contiene tutti i link processati da ZDL, da ogni
input possibile: i file ed i link passati a ZDL come argomenti o
attraverso liste contenute in file di testo o passati attraverso
componenti aggiuntive dei browser oppure, in mancanza di tali dati, i
link incollati al terminale, prima di avviare il download digitando
\"@\". Il file links.txt serve soprattutto al recupero manuale dei
link di download interrotti, nel caso in cui non fossero più
disponibili i file temporanei di ZDL (per esempio, nel caso di errato
utilizzo dell'opzione [--clean])

L'argomento [--wget|--axel], wget oppure axel, consente la scelta del
downloader. Axel è un acceleratore di download fortemente consigliato
e abilitato in modo predefinito per tutti i link e per quasi tutti i
servizi di hosting. L'argomento [-c|--configure] consente di
configurare il downloader di default, cioè di selezionare Wget al
posto di Axel senza dover attivare Wget manualmente adottando
l'argomento \"--wget\".

L'argomento [--clean] cancella eventuali residui di file temporanei di
ZDL nella directory di destinazione, prima di iniziare a processare i
link immessi dall'utente.

La funzione [-i|--interactive] permette di visualizzare i download di
ZDL utilizzando un altro terminale oppure dallo stesso terminale di
avvio dei download attraverso Wget nel caso in cui ZDL è terminato
(per decisione dell'utente, premendo Ctrl+C, oppure
accidentalmente). Infatti, i download di Wget procedono in background
e non muoiono insieme a ZDL (tecnicamente possono essere tutti uccisi
\"terminando il terminale\"). Per uccidere uno o più processi già
avviati (definitivamente oppure per riavviarli automaticamente), anche
con ZDL perfettamente attivo, da un altro terminale entrare nella
directory di destinazione e digitare \"zdl -i\" o \"zdl
--interactive\": comparirà un'interfaccia con cui poter interagire con
i processi di ZDL.

È possibile (ed è raccomandato) far processare, nella stessa lista,
link di mirror diversi per uno stesso file (per esempio: se vogliamo
scaricare file.part1.rar, file.part2.rar e file.part3.rar e abbiamo
copie di questi file in servizi di hosting differenti, si consiglia di
usare tutti i link disponibili, perché ZDL processerà tutti i link e
scaricherà una sola copia dei file, utilizzando il link migliore).

L'argomento [--login] attiva il login automatico nel caso la
configurazione di ZDL comprenda uno o più account per l'uso di un
servizio di hosting. In particolare, la registrazione di molti account
per Easybytez non solo permette il download di file di grandezza fino
a 600 MB, ma consente anche lo scaricamento parallelo di più file
senza l'uso di proxy (in questo caso è necessario specificare anche
[-m|--multi]). Per configurare l'uso di account: zdl [-c|--configure]

Inoltre, ZDL accetta come argomenti un numero illimitato di file di
testo contenenti link ed è stato progettato anche per scaricare il
file di uno stream video. Per quest'ultima operazione è
particolarmente indicato l'utilizzo di Flashgot, componente aggiuntivo
di Firefox/Iceweasel (http://flashgot.net/). È disponibile anche
un'integrazione manuale di ZDL con Chrome/Chromium attraverso l'uso di
alcune estensioni (qualitativamente inferiori a Flashgot, più avanti
le istruzioni).

Infine, la funzione [--ip] mostra l'indirizzo IP corrente.




\e[1mUn altro modo di usare ZDL, per aggiungere opzioni al download
dal browser.\e[0m La spiegazione di seguito con un esempio, partendo
da un problema pratico:


\e[1mProblema:\e[0m

voglio scaricare dei file da Easybytez usando Flashgot, ma voglio
anche usare le opzioni --login, --multi e --clean, che non sono
impostate di default. Come posso utilizzare queste funzioni aggiuntive
usando il browser (con Flashgot), se queste possono essere attivate
solo dal terminale?


\e[1mSoluzione:\e[0m

  - avvio zdl in un terminale, dalla directory di destinazione,
    utilizzando tutte le opzioni di cui ho bisogno:
    		  zdl -m --login --clean

  - usando Firefox, clicco con il tasto destro del mouse sui link dei
    file da scaricare e avvio il download con Flashgot: il download
    non viene effettuato subito e i link vengono registrati da zdl per
    essere processati da un'altra istanza attiva del programma (quella
    nel terminale)

  - quando ho finito di registrare i link, torno al terminale e, senza
    scrivere nulla, digito la chiocciolina @


\e[1mCome aggiungere estensioni personalizzate e sperimentali.\e[0m
ZDL incorpora il codice che trova in tutti gli script *.sh nella
directory \$HOME/.zdl/extensions/

Per esempio:

## add-on Pippo

if [ \"\$url_in\" != \"\${url_in//'http://pippo.org'}\" ]; then
   url_in_file=\"\${url_in//'http://pippo.org'/http://USER:PASSWORD@pippo.org}\"
   file_in=\"\${url_in##*/}\"
   unset multi
   axel_parts=3 
fi

L'esempio può essere usato come modello, modificando l'url del
download aggiungendo USER e PASSWORD per i link di pippo.org
(variabile \$url_in_file), indicando come ricavare il nome del file da
scaricare (variabile \$file_in), aggiungendo o modificando opzioni,
come disattivare la funzione multi (serve a scaricare più file in
parallelo) e stabilire il numero di parti da scaricare con Axel (il
grado di accelerazione, che per default è 32 ma che per diversi server
può essere eccessivo o insufficiente, peggiorando le prestazioni).

In questo modo, è possibile estendere ZDL ad altri servizi di file
hosting (anche a scopo sperimentale), aggiungere opzioni mirate e
personalizzate o implementare il funzionamento del programma,
utilizzando le variabili e le funzioni disponibili nello script
/usr/local/bin/zdl, senza modificare il sorgente, scrivendo
semplicemente un file *.sh nella directory \$HOME/.zdl/extensions/



\e[1mIntegrazione con Firefox/Iceweasel 
CONFIGURAZIONE MANUALE DI FLASHGOT.\e[0m 

La configurazione manuale di Flashgot non dovrebbe essere necessaria,
perché ZDL avvia un controllo della configurazione di Flashgot dopo
ogni aggiornamento del software o della configurazione ed
eventualmente, se glielo consente la propria configurazione (zdl
--configure), provvede a configurarlo automaticamente.

Configurazione manuale di Flashgot per ZDL:

	1) dopo aver installato flashgot, il componente aggiuntivo di
	   Firefox, avvia Firefox (o Iceweasel) e apri la
	   finestra per la gestione delle opzioni di flashgot:

	   (dal menu di firefox)--> Strumenti --> FlashGot --> Altre opzioni... 

	2) nel tab \"Generale\" aggiungi \"ZigzagDownLoader\" come
	   downloader

	3) ancora nel tab \"Generale\", il \"Percorso
	   dell'eseguibile:\"
	   - su GNU/LINUX: /usr/local/bin/zdl
	   - su WINDOWS: \Cygwin\zdl.bat

	4) sempre nel tab \"Generale\", in \"Modello dei parametri\",
	   incolla la seguente stringa:
	   --stream [URL] [FNAME] [FOLDER] [CFILE] [COOKIE] [REFERER]

	5) nel tab \"FlashGot Media\" scegli \"ZigzagDownLoader\" come
	   \"Download manager\" 




\e[1mIntegrazione con Chrome/Chromium 
ESTENSIONI DI CHROME/CHROMIUM E CONFIGURAZIONE.\e[0m 

Non è attualmente prevista una configurazione automatica delle
estensioni di Chrome/Chromium, quindi sarà necessario configurarle
manualmente come segue. 

Le estensioni di Chrome/Chromium che permettono l'uso di ZDL come
download manager esterno sono le seguenti:

* \e[1mDownload Assistant\e[0m:
  http://mac.softpedia.com/get/Internet-Utilities/Chrome-Extensions/Download-Assistant.shtml

  - istruzioni per l'\e[1minstallazione\e[0m e informazioni
    utili:
      http://www.lffl.org/2011/03/chrome-utilizzare-un-download-manager.html

  - \e[1mconfigurazione\e[0m per ZDL (dal menu: Strumenti -> Estensioni)

    1) clicca su \e[1mOpzioni\e[0m dell'estensione

    2) in \e[1mAdd More Downloaders\e[0m, aggiungi
       \e[1mZigzagDownLoader\e[0m nella colonna \e[1mName\e[0m

    3) aggiungi
       \e[1mzdl --stream \"\$URL\" \"\$FILE_NAME\" --noXterm
       \e[0m nella colonna \e[1mCommand line\e[0m

    4) clicca sul bottone \e[1mSave & Close\e[0m

* \e[1mSimple Get\e[0m:
  http://www.chromeextensions.org/other/simple-get/

  - istruzioni per l'\e[1minstallazione\e[0m come per Download-Assistant

  - \e[1mconfigurazione\e[0m per ZDL, \e[1mOpzioni\e[0m:

    1) in corrispondenza di \e[1mPath:\e[0m scrivi
       \e[1m/usr/local/bin/zdl\e[0m 

    2) in \e[1mParameters\e[0m scrivi:
       \e[1m--stream [SG_URL] [SG_DESTINATION]\e[0m

    3) clicca sul bottone \e[1mSave\e[0m

Le estensioni qua sopra funzionano anche con \e[1mFVD Video Downloader\e[0m 
[https://chrome.google.com/webstore/detail/lfmhcpmkbdkbgbmkjoiopeeegenkdikp]
(per scaricare i video in streaming: clicca con il tasto
\e[1mdestro\e[0m del mouse sui \e[1mlink\e[0m che compaiono nella
tendina aperta dall'estensione, poi scegli il download manager
ZigzagDownLoader)



\e[1mFunzione interattiva di Conkeror.\e[0m

ZDL implementa automaticamente il browser Conkeror con la nuova
funzione \"zdl\".  Per attivarla, digita: \e[1mM+x zdl\e[0m

Dopo aver avviato il comando, il minibuffer di Conkeror: 

     - chiede di selezionare la \e[1mdirectory\e[0m di destinazione 

     - offre la  possibilità di utilizzare le \e[1mopzioni\e[0m di zdl
       (lasciare il campo vuoto per non selezionarle) 

     - mostra e indicizza i \e[1mlink\e[0m nel buffer corrente (per
       esempio la pagina web), per procedere nella selezione del link
       (il link della pagina corrente corrisponde all'indice 0) 

     - avvia ZDL in un terminale xterm oppure, se è stata selezionata
       l'opzione --daemon (oppure -d), in background. In ogni caso è
       possibile gestire i download utilizzando l'interfaccia
       interattiva: \e[1mzdl -i\e[0m 



\e[1mXXXTerm (Xombrero) e altri software.\e[0m

ZDL dispone anche dello script \e[1m/usr/local/bin/zdl-xterm\e[0m, che
può essere avviato da qualunque applicazione e da un terminale. È
stato pensato per rendere possibile l'avvio di ZDL in contesti diversi
da quelli previsti dal programma. In particolare, XXXTerm può avviare
uno script bash, utilizzando il comando \e[1m:run_script\e[0m,
passandogli un solo argomento: il link della pagina corrente. Questo
rende impossibile l'avvio standard di zdl in un'istanza di xterm,
perché \e[1m:run_script\e[0m non accetta ulteriori parametri. L'avvio
di zdl in un nuovo terminale virtuale xterm è reso possibile da
\e[1mzdl-xterm\e[0m.

\e[1mUso in XXXTerm:\e[0m 

     - comando \e[1m:run_script\e[0m

     - digita: \e[1mzdl-xterm\e[0m

     - il programma avvia un'istanza di xterm che:
       * chiede in quale \e[1mdirectory\e[0m scaricare il file (è
         possibile evitare questa interazione configurando zdl-xterm:
     	 inserisci in \e[1m/usr/local/bin/zdl-xterm\e[0m, come valore
     	 della variabile \e[1mdefault_directory\e[0m all'inizio dello
     	 script, il path di una \e[1mdirectory valida\e[0m)

       * zdl-xterm avvia zdl sull'\e[1mURL corrente\e[0m


\e[1mSemplificazione per XXXTerm.\e[0m 
Per utilizzare zdl-xterm con più rapidità, XXXTerm può essere
configurato in molti modi. 

\e[1mUn suggerimento:\e[0m
     - apri il file \e[1m$HOME/.xxxterm.conf\e[0m

     - inserisci il seguente testo:
       \e[1mdefault_script = zdl-xterm\e[0m
       \e[1mkeybinding = run_script,C-z\e[0m 

Con la configurazione suggerita, digitando \e[1mCtrl+z\e[0m si avvia
il prompt di \e[1m:run_script\e[0m con il campo già occupato dal nome
dello script \e[1mzdl-xterm\e[0m: è sufficiente premere \e[1minvio\e[0m.




\e[1mAGGIORNARE ZDL.\e[0m 
Se è disponibile una nuova versione del programma, ZDL si aggiorna
automaticamente. È possibile disabilitare l'aggiornamento automatico
modificando la configurazione (zdl --configure).  
Inoltre, per aggiornare manualmente ZDL è sufficiente usare
l'opzione -u (--update). 



\e[1mINSTALLAZIONE PER GNU/LINUX\e[0m

 -  Scarica l'installatore (è uno script per la Bash):
    http://download.savannah.gnu.org/releases/zdl/install_zdl.sh

 -  Attribuisci i diritti di esecuzione allo script:
    chmod +x install_zdl.sh 

 -  esegui lo script: ./install_zdl.sh



\e[1mINSTALLAZIONE PER WINDOWS.\e[0m 
ZDL funziona anche su Windows.

Installazione su Windows in due fasi: 

FASE 1) Installazione di Cygwin 32 bit 

     - installatore automatico di Cygwin (serve anche ad aggiornare il
       sistema emulato e ad installare nuovi pacchetti): 
       http://cygwin.com/setup_x86.exe

     - con l'installatore di Cygwin, installa il pacchetto \"Wget\"


FASE 2) Installazione di ZDL

     - salva nella cartella \\\cygwin il seguente file:
       http://download.savannah.gnu.org/releases/zdl/install_zdl.sh
       
     - avvia Cygwin installato nella fase 1

     - digita il seguente comando: /install_zdl.sh



Uso di ZDL su Windows: avvia Cygwin e utilizza ZDL nel terminale
avviato, come descritto in questa guida. 




\e[1mLICENZA.\e[0m 
ZDL è rilasciato con licenza GPL (General Public Licence, v.3 e
superiori). 


\e[1mPer informazioni e per collaborare al progetto:\e[0m
https://savannah.nongnu.org/projects/zdl


Gianluca Zoni (zoninoz)
http://inventati.org/zoninoz"|less --RAW-CONTROL-CHARS	
    echo
    echo
    exit 1
}
