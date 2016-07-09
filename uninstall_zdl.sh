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
    echo "Uso: ./uninstall_zdl.sh [--purge] [-h|--help]"
}

function try {
    cmdline=( "$@" )
    
    if ! "${cmdline[@]}" 2>/dev/null 
    then	
	if ! sudo "${cmdline[@]}" 2>/dev/null 
	then
	    su -c "${cmdline[@]}" || (
		print_c 3 "$failure: ${cmdline[@]}"
		return 1
	    )
	fi
    fi
}


PROG=ZigzagDownLoader
prog=zdl
BIN="/usr/local/bin"
SHARE="/usr/local/share/zdl"
success="Disinstallazione completata"
failure="Disinstallazione non riuscita"
path_conf="$HOME/.$prog"

option=$1

echo -e "\e[1mDisinstallazione di $PROG\e[0m\n"

if [ "$option" == "--help" ] ||
       [ "$option" == "-h" ]
then
    usage
    exit

else
    read -p "Vuoi davvero disinstallare ZigzagDownLoader? [sì|*]" result
    
    if [ "$result" == "sì" ]
    then
	if [ "$option" == "--purge" ]
	then
	    rm -rf $HOME/.zdl
	fi
	try rm -rf "$SHARE" $BIN/zdl $BIN/zdl-xterm
	[ -e /cygdrive ] && rm /zdl.bat
    fi
fi
