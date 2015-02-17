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

#### Axel

function check_downloader {
    if [ "$downloader_in" == "Axel" ]; then
	while [ -z "`command -v axel 2>/dev/null`" ]; do
	    fclear
	    print_c 3 "ATTENZIONE: Axel non è installato nel tuo sistema"
	    
	    echo -e "$PROG può scaricare con Wget ma raccomanda fortemente Axel, perché:\n\t- può accelerare sensibilmente il download
\t- permette il recupero dei download in caso di interruzione
					
Per ulteriori informazioni su Axel: http://alioth.debian.org/projects/axel/

\t1) Installa automaticamente Axel da pacchetti
\t2) Installa automaticamente Axel da sorgenti
\t3) Esci da $PROG per installare Axel manualmente (puoi trovarlo qui: http://pkgs.org/search/?keyword=axel)
\t4) Ignora Axel e continua con Wget
\t5) Configura Wget di default
\t6) Ripristina la condizione iniziale (Axel di default)"
	    
	    print_c 2 "Scegli cosa fare (1-6)"
	    read input
	    
	    case $input in
		
		1) install_pk ;;
		2) install_src ;;
		3) exit ;;
		4) downloader_in=Wget ; break ;;
		5) set_item_conf "downloader" "Wget" ;;
		6) set_item_conf "downloader" "Axel" ;;
		
	    esac
	done
    fi
}

function install_test {
    
    if [ -z "`command -v axel 2>/dev/null`" ]; then
	print_c 3 "Installazione automatica non riuscita"
	case $1 in
	    pk) echo "$2 non ha trovato il pacchetto di Axel" ;;
	    src) echo "Errori nella compilazione o nell'installazione";;
	esac
    fi
    echo
    pause
}

function install_pk {
    print_c 1 "Installo Axel ..."
    if [ `command -v apt-get 2>/dev/null` ]; then
	DEBIAN_FRONTEND=noninteractive sudo apt-get --no-install-recommends -q -y install axel || ( echo "Digita la password di root" ; DEBIAN_FRONTEND=noninteractive su -c "apt-get --no-install-recommends -q -y install axel" )
	install_test pk apt-get
    elif [ `command -v yum 2>/dev/null` ]; then
	sudo yum install axel || ( echo "Digita la password di root" ; su -c "yum install axel" )
	install_test pk yum
    elif [ `command -v pacman 2>/dev/null` ]; then
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
