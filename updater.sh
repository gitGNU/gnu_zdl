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


function update_zdl-wise {
    if [ ! -e "/cygdrive" ]; then # && [ ! -e "/bin/gcc.exe" ]; then
	gcc $SHARE/extensions/zdl-wise.c -o $SHARE/extensions/zdl-wise 2>/dev/null || sudo gcc $SHARE/extensions/zdl-wise.c -o $SHARE/extensions/zdl-wise 2>/dev/null || su -c "gcc $SHARE/extensions/zdl-wise.c -o $SHARE/extensions/zdl-wise" 2>/dev/null || print_c 3 "\nCompilazione del sorgente zdl-wise.c non riuscita"
    fi
}


function update_zdl-conkeror {
    if [ -f "$HOME/.conkerorrc" ]; then
	[ -f "$path_conf/conkerorrc.zdl" ] && rm "$path_conf/conkerorrc.zdl"
	text_conkerorrc=$(cat "$HOME/.conkerorrc")
	if [ "$text_conkerorrc" != "${text_conkerorrc//$path_conf\/conkerorrc.zdl}" ]; then
	    cp "$HOME/.conkerorrc" "$HOME/.conkerorrc.old"
	    echo "${text_conkerorrc//require(\"$path_conf\/conkerorrc.zdl\");}" > "$HOME/.conkerorrc"
	fi
	test=$(cat "$HOME/.conkerorrc"|grep "$SHARE/conkerorrc.zdl" |tail -n 1)
	test2=$(echo "${test#*'//'}" |grep "$SHARE/conkerorrc.zdl")
	if [ -z "$test" ]; then
	    echo -e "\n// ZigzagDownLoader\nrequire(\"$SHARE/conkerorrc.zdl\");" >> "$HOME/.conkerorrc"
	elif [ "$test" != "$test2" ] && [ ! -z "$test2" ]; then
	    print_c 3 "\nLa funzione ZDL di Conkeror è stata disattivata dall'utente nel file $HOME/.conkerorrc: per riattivarla, cancella i simboli di commento \"\\\\\""
	fi
    fi
}


# function update {
#     remote_version=`wget "$url_version" -O - -q`
#     local_version=`cat "$path_conf/version.txt" 2>/dev/null`
#     if [ "${remote_version#*'.'}" != "${local_version#*'.'}" ] && [ ! -z "$remote_version" ]; then
# 	print_c 2 "\nAggiornamento di $PROG ..."
# 	if [ -e "/cygdrive" ]; then
# 	    wget "${url_update}.bat" -O /zdl.bat -q && print_c 1 "\nScript batch di avvio aggiornato: $(cygpath -m /)\zdl.bat "
# 	    chmod a+rx /zdl.bat
# 	fi
	
# 	wget "$url_update" -O /tmp/$prog -q && print_c 1 "\n$PROG scaricato"
# 	update_zdl-xterm
# 	update_zdl-conkeror
# 	update_zdl-wise
# 	err=`mv /tmp/*${prog}* /usr/local/bin/ 2>&1`
# 	if [ -z "$err" ]; then
# 	    chmod a+rx /usr/local/bin/*${prog}* && print_c 1 "Aggiornamento di $PROG effettuato con successo in /usr/local/bin/" || print_c 3 "\nErrore nell'aggiornamento nell'assegnazione dei diritti di esecuzione, contatta gli sviluppatori: http://nongnu.org/zdl" 
# 	    touch "$path_conf/updated"
# 	else
# 	    err=`sudo mv /tmp/*${prog}* /usr/local/bin/ 2>&1`
# 	    if [ -z "$err" ]; then
# 		sudo chmod a+rx /usr/local/bin/*${prog}* && print_c 1 "Aggiornamento di $PROG effettuato con successo in /usr/local/bin/" || print_c 3 "\nErrore nell'aggiornamento nell'assegnazione dei diritti di esecuzione" 
# 		touch "$path_conf/updated"
# 	    else
# 		echo -n "(Root)"
# 		err=`su -c "mv /tmp/*${prog}* /usr/local/bin/ ; chmod a+rx /usr/local/bin/*${prog}*"`
# 		if [ -z "$err" ]; then
# 		    print_c 1 "Aggiornamento di $PROG effettuato con successo in /usr/local/bin/"
# 		    touch "$path_conf/updated"
# 		else
# 		    print_c 3 "Aggiornamento automatico non riuscito"
# 		fi
# 	    fi
# 	fi
# 	pause
# 	if [ -f "$path_conf/updated" ];then 
# 	    touch "$path_conf/noclear"
# 	    echo "$remote_version" > "$path_conf/version.txt"
# 	    echo
# 	    exec $0 "${args[*]}"
# 	    exit
# 	fi
#     else
# 	print_c 1 "$PROG è alla versione più recente."
#     fi
# }


################


function install {
    origin="$1"
    path_dest="$2"
    err=$( mv "$file_origin" "$path_dest/" 2>&1 )
    if [ -z "$err" ]; then
	chmod a+rx "$path_dest/$origin" && print_c 1 "$path_dest/$origin aggiornato" || print_c 3 "\nErrore nell'assegnazione dei diritti di esecuzione, contatta gli sviluppatori: http://nongnu.org/zdl" 
	touch "$path_conf/updated"
    else
	err=$(sudo mv "$file_origin" "$path_dest/" 2>&1 )
	if [ -z "$err" ]; then
	    sudo chmod a+rx "$path_dest/$origin" && print_c 1 "$path_dest/$origin aggiornato" || print_c 3 "\nErrore nell'assegnazione dei diritti di esecuzione, contatta gli sviluppatori: http://nongnu.org/zdl" 
	    touch "$path_conf/updated"
	else
	    echo -n "(Root)"
	    err=$(su -c "mv \"$file_origin\" \"$path_dest/\" ; chmod a+rx \"$path_dest/$origin\"")
	    if [ -z "$err" ]; then
		print_c 1 "$path_dest/$origin aggiornato"
		touch "$path_conf/updated"
	    else
		print_c 3 "Aggiornamento automatico non riuscito"
	    fi
	fi
    fi
    
}


BIN="/usr/local/bin"
SHARE="/usr/local/share/${prog}"

function update {
    wget http://download.savannah.gnu.org/releases/zdl/ -A sig -O /tmp/zdl.sig -q
    version_diff=$(diff "/tmp/zdl.sig" "$SHARE/*.sig" )
    if [ ! -z "$version_diff" ]; then
	print_c 2 "\nAggiornamento di $PROG ..."

	mkdir -p "$path_conf/src"
	cd "$path_conf/src"
	wget http://download.savannah.gnu.org/releases/zdl/ -r -l 1 -A gz,sig,txt -np -nd -q
	tar -xzf *.tar.gz
	mkdir -p $SHARE 2>&1 || sudo mkdir -p $SHARE 2>/dev/null || su -c "mkdir -p $SHARE" 2>/dev/null || ( print_c 3 "Aggiornamento fallito: impossibile creare la directory $SHARE"; return )
	cd ${prog}
	install $prog $BIN/
	install ${prog}-xterm $BIN/
	[ -e /cygdrive ] && install ${prog}/${prog}.bat / && print_c 1 "\nScript batch di avvio aggiornato: $(cygpath -m /)\zdl.bat "

	sudo rm -r $SHARE/${prog}/*
	install "${prog}/*" $SHARE
	update_zdl-conkeror
	update_zdl-wise
    else
 	print_c 1 "$PROG è alla versione più recente."
    fi
}
