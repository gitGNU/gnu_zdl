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

#### layout

source "$path_usr/ui/colors.awk.sh"

function print_c {
    if [ ! -f "$path_tmp/.stop_stdout" ] && [ -z "$daemon" ]; then
	case "$1" in
	    0)
		echo -n -e ""
		;;
	    1)
		echo -n -e "$BGreen" 
		;;
	    2)
		echo -n -e "$BYellow"
		;;	
	    3)
		echo -n -e "$BRed" 
		;;	
	    4)
		echo -n -e "$BBlue"
		;;	
	    
	esac
	echo -n -e "$2\n"
	echo -n -e "${Color_Off}"
    fi
}

function separator- {
    if [ -z "$daemon" ]; then
	header "" "$BBlue" "─"
    fi
}

function fclear {
    if [ -z "$daemon" ]; then
	echo -n -e "\ec${White}${On_Black}\e[J"
    fi
}

function cursor {
    if [ -z "$daemon" ]; then
	stato=$1
	case $stato in
	    off)
		echo -e -n "\033[?30;30;30c" ;;
	    on)
		echo -e -n "\033[?0;0;0c" ;;
	esac
    fi
}

function header { # $1=label ; $2=color ; $3=header pattern
    if [ -z "$daemon" ]; then
	text="$1"
	[ ! -z "$text" ] && text=" $text " 
	color="$2"
	hpattern="$3"
	[ -z "$hpattern" ] && hpattern="\ "

	eval printf -v line "%.0s${hpattern}" {1..$(( $COLUMNS-${#text} ))}
	echo -e "${color}${text}$line${Color_Off}"
    fi
}


function header_z {
    if [ -z "$daemon" ]; then
	fclear
	text_start="$name_prog ($prog)"
	text_end="$(zclock)"
	eval printf -v text_space "%.0s\ " {1..$(( $COLUMNS-${#text_start}-${#text_end}-3 ))}
	header "$text_start$text_space$text_end" "$On_Blue" 
    fi
}

function header_box {
    if [ ! -f "$path_tmp/.stop_stdout" ] && [ -z "$daemon" ]; then
	if [ -z "$daemon" ]; then
	    header "$1" "$Black${On_White}" "─"
	fi
    fi
}

function header_box_interactive {
    header "$1" "$Black${On_White}" "─"
}

function header_dl {
    if [ -z "$daemon" ]; then
	header "$1 " "$White${On_Blue}" 
    fi
}

function pause {
    if [ "$redir_lnx" == true ] || ( [ ! -f "$path_tmp/.stop_stdout" ] && [ -z "$daemon" ] ); then
	echo
	header ">>>>>>>> Digita <Invio> per continuare " "$On_Blue$BWhite" "\<"
	cursor off
	read -e
	cursor on
    fi
}

function xterm_stop {
    if [ ! -f "$path_tmp/.stop_stdout" ] && [ -z "$daemon" ] && [ -z "$pipe_out" ]; then
	echo
	header ">>>>>>>> Digita <Invio> per uscire " "$On_Blue$BWhite" "\<"
	cursor off
	read -e
	cursor on
    fi
}

function zclock {
    week=( "dom" "lun" "mar" "mer" "gio" "ven" "sab" )
    echo -n -e "$(date +%R) │ ${week[$( date +%w )]} $(date +%d·%m·%Y)"
}

