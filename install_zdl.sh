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
# Gianluca Zoni
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
		mv axel-2.4-1bl1.tar.bz2 axel-2.4-1bl1.tar.bz2.old &>/dev/null
		wget http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
		tar -xvjf axel-2.4-1bl1.tar.bz2
		cd -
	fi
}

function install_batch {
	wget "${install_url}.bat" -O /zdl.bat && bold "Script batch di avvio installato: C:\Cygwin\zdl.bat "
}

install_url="http://inventati.org/zoninoz/html/upload/files/zdl"
install_path="/usr/local/bin/zdl"
install_tmp="/tmp/zdl"
success="Installazione completata"
unsuccess="Installazione non riuscita"
PROG=ZigzagDownLoader

## ZigzagDownLoader


echo -e "\e[1mInstallazione di ZigzagDownLoader\e[0m\n"

wget "$install_url" -O "$install_tmp"

err=`mv "$install_tmp" "$install_path" 2>&1`
if [ -z "$err" ]; then
	chmod a+rx "$install_path" && echo "$success"
else
	err=`sudo mv "$install_tmp" "$install_path" 2>&1`
	if [ -z "$err" ]; then
		sudo chmod a+rx "$install_path" && echo "$success"
	else
		echo -n "(Root)"
		err=`su -c "mv \"$install_tmp\" \"$install_path\" ; chmod a+rx \"$install_path\""`
		if [ -z "$err" ]; then
			echo "$success"
		else
			echo "$unsuccess"
		fi
	fi
fi

## Axel
if [ -e "/cygdrive" ]; then
	install_batch
	install_axel-cygwin
else
	check_downloader
fi

bold "Per informazioni su ZigzagDownLoader (zdl): zdl --help"
exit