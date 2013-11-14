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



function bold {
	echo -e "\e[1m$1\e[0m"
}


#### Axel

function check_downloader {
	while [ -z "`which axel 2>/dev/null`" ]; do
		bold "ATTENZIONE: Axel non è installato nel tuo sistema"
		
		echo -e "$PROG può scaricare con Wget ma raccomanda fortemente Axel, perché:\n
	- può accelerare sensibilmente il download
	- permette il recupero dei download in caso di interruzione
	
Per ulteriori informazioni su Axel: http://alioth.debian.org/projects/axel/

1) Installa automaticamente Axel da pacchetti
2) Installa automaticamente Axel da sorgenti
3) Esci da $PROG per installare Axel manualmente (puoi trovarlo qui: http://pkgs.org/search/?keyword=axel)"

		bold "Scegli cosa fare (1-3)"
		read input
		
		case $input in
		
		1) install_pk ;;
		2) install_src ;;
		3) exit ;;
		
		esac
	done
}

function install_test {
	if [ -z "`which axel 2>/dev/null`" ]; then
		bold "Installazione automatica non riuscita"
		case $1 in
			pk) echo "$2 non ha trovato il pacchetto di Axel" ;;
			src) echo "Errori nella compilazione o nell'installazione";;
		esac
	fi
	echo
	bold "<Premi un tasto per continuare>"
	read
}

function install_pk {
	echo "Installo Axel ..."
	if [ `which apt-get 2>/dev/null` ]; then
		DEBIAN_FRONTEND=noninteractive sudo apt-get --no-install-recommends -q -y install axel || (  echo "Digita la password di root" ; DEBIAN_FRONTEND=noninteractive su -c "apt-get --no-install-recommends -q -y install axel" )
		install_test pk apt-get
	elif [ `which yum 2>/dev/null` ]; then
		sudo yum install axel || ( echo "Digita la password di root" ; su -c "yum install axel" )
		install_test pk yum
	elif [ `which pacman 2>/dev/null` ]; then
		sudo pacman -S axel 2>/dev/null || ( echo "Digita la password di root" ; su -c "pacman -S axel" )
		install_test pk pacman
	else
		install_test
	fi
}

function install_src {
	cd /usr/src
	wget http://alioth.debian.org/frs/download.php/3015/axel-2.4.tar.gz
	tar zxvf axel-2.4.tar.gz
	cd axel-2.4
	
	make
	sudo make install || ( echo "Digita la password di root" ; su -c "make install" )
	make clean
	install_test src
	cd -
}


function install_axel-cygwin {
	test_axel=`which axel`
	if [ -z $test_axel ]; then
		cd /
		wget "$axel_url"
		tar -xvjf "${axel_url##*'/'}"
		cd -
	fi
}


function install_zdl-wise {
    if [ ! -e "/cygdrive" ]; then 
	gcc extensions/zdl-wise.c -o extensions/zdl-wise 2>/dev/null || sudo gcc extensions/zdl-wise.c -o extensions/zdl-wise 2>/dev/null || su -c "gcc extensions/zdl-wise.c -o extensions/zdl-wise" 2>/dev/null || bold "\nCompilazione del sorgente zdl-wise.c non riuscita"
    fi
}


function install_zdl-conkeror {
    if [ -f "$HOME/.conkerorrc" ]; then
	[ -f "$path_conf/conkerorrc.zdl" ] && rm "$path_conf/conkerorrc.zdl"
	text_conkerorrc=$(cat "$HOME/.conkerorrc")
	if [ "$text_conkerorrc" != "${text_conkerorrc//$path_conf\/conkerorrc.zdl}" ]; then
	    cp "$HOME/.conkerorrc" "$HOME/.conkerorrc.old"
	    echo "${text_conkerorrc//require(\"$path_conf\/conkerorrc.zdl\");}" > "$HOME/.conkerorrc"
	fi
	test=$(cat "$HOME/.conkerorrc"|grep "$SHARE/extensions/conkerorrc.zdl" |tail -n 1)
	test2=$(echo "${test#*'//'}" |grep "$SHARE/extensions/conkerorrc.zdl")
	if [ -z "$test" ]; then
	    echo -e "\n// ZigzagDownLoader\nrequire(\"$SHARE/extensions/conkerorrc.zdl\");" >> "$HOME/.conkerorrc"
	elif [ "$test" != "$test2" ] && [ ! -z "$test2" ]; then
	    bold "\nLa funzione ZDL di Conkeror è stata disattivata dall'utente nel file $HOME/.conkerorrc: per riattivarla, cancella i simboli di commento \"\\\\\""
	fi
    fi
}


PROG=ZigzagDownLoader
prog=zdl
BIN="/usr/local/bin"
SHARE="/usr/local/share/zdl"
URL_ROOT="http://download.savannah.gnu.org/releases/zdl/"
axel_url="http://www.inventati.org/zoninoz/html/upload/files/axel-2.4-1.tar.bz2" #http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
success="Installazione completata"
failure="Installazione non riuscita"
path_conf="$HOME/.$prog"

echo -e "\e[1mInstallazione di ZigzagDownLoader\e[0m\n"

mkdir -p "$path_conf/src"
cd "$path_conf/src"
rm *.tar.gz* $prog -rf
wget "$URL_ROOT" -r -l 1 -A gz,sig,txt -np -nd -q
cp *.sig $path_conf/zdl.sig

package=$(ls *.tar.gz)
tar -xzf "$package"

mv "${package%.tar.gz}" $prog
cd $prog
install_zdl-wise

chmod +rx -R .
bold "Installazione in $BIN\n"
mv zdl zdl-xterm $BIN || sudo mv zdl zdl-xterm $BIN 2>/dev/null || su -c "mv zdl zdl-xterm $BIN" 2>/dev/null || ( print_c 3 "$failure"; exit )
[ -e /cygdrive ] && ( mv ${prog}.bat / ) && bold "\nScript batch di avvio installato: $(cygpath -m /)\zdl.bat "
cd ..

bold "Installazione in $SHARE\n"
rm -rf $SHARE 2>/dev/null || sudo rm -rf $SHARE 2>/dev/null || su -c "rm -rf $SHARE" 2>/dev/null  || ( print_c 3 "$failure"; exit )
cp -r $prog $SHARE 2>/dev/null || sudo cp -r $prog $SHARE 2>/dev/null || su -c "cp -r $prog $SHARE" 2>/dev/null || ( print_c 3 "$failure"; exit )

install_zdl-conkeror


## Axel
if [ -e "/cygdrive" ]; then
	install_axel-cygwin
else
	check_downloader
fi

bold "$success"
bold "Per informazioni su ZigzagDownLoader (zdl): zdl --help"
exit
