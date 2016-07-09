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

if [ "$installer_zdl" == "true" ]
then
    source "ui/colors.awk.sh"
else
    source "$path_usr/ui/colors.awk.sh"
fi

function print_case {
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
}
    
function print_c {
    if [ ! -f "$path_tmp/.stop_stdout" ] &&
	   [ -z "$zdl_mode" ] ||
	       [ -n "$redirected_link" ]
    then
	print_case "$1"
	
	echo -n -e "$2\n"
	echo -n -e "${Color_Off}"
    fi
}

function print_C {
    ## print_c FORCED
    print_case "$1"
    
    echo -n -e "$2\n"
    echo -n -e "${Color_Off}"
}

function print_r {
    if [ ! -f "$path_tmp/.stop_stdout" ] &&
	   [ -z "$zdl_mode" ] ||
	       [ -n "$redirected_link" ]
    then
	print_case "$1"
	
	echo -n -e "\r$2"
	echo -n -e "${Color_Off}"
    fi
}

function sprint_c {
    if [ ! -f "$path_tmp/.stop_stdout" ] &&
	   [ -z "$zdl_mode" ] ||
	       [ -n "$redirected_link" ]
    then
	case "$1" in
	    0)
		echo -n ""
		;;
	    1)
		echo -n "$BGreen" 
		;;
	    2)
		echo -n "$BYellow"
		;;	
	    3)
		echo -n "$BRed" 
		;;	
	    4)
		echo -n "$BBlue"
		;;	
	    
	esac
	echo -n "$2\n"
	echo -n "${Color_Off}"
    fi
}

function separator- {
    if [ -z "$zdl_mode" ]
    then
	header "" "$BBlue" "─"
    fi
}

function fclear {
    if [ "$zdl_mode" != "daemon" ]
    then
	#	echo -n -e "\033c${White}${Background}\033[J"
	echo -ne "\033c${Color_Off}\033[J"
    fi
}

function cursor {
    if [ -z "$zdl_mode" ]
    then
	stato=$1
	case $stato in
	    off)
		echo -e -n "\033[?30;30;30c"
		;;
	    on)
		echo -e -n "\033[?0;0;0c"
		;;
	esac
    fi
}

function header { # $1=label ; $2=color ; $3=header pattern
    text="$1"
    [ -n "$text" ] && text=" $text " 
    color="$2"
    hpattern="$3"
    [ -z "$hpattern" ] && hpattern="\ "
    
    eval printf -v line "%.0s${hpattern}" {1..$(( $COLUMNS-${#text} ))}
    echo -e "${color}${text}$line${Color_Off}"
}


function header_z {
    if [ -z "$zdl_mode" ]
    then
	fclear
	text_start="$name_prog ($prog)"
	text_end="$(zclock)"
	eval printf -v text_space "%.0s\ " {1..$(( $COLUMNS-${#text_start}-${#text_end}-3 ))}
	header "$text_start$text_space$text_end" "$On_Blue" 
    fi
}

function header_box {
    if [ ! -f "$path_tmp/.stop_stdout" ] ||
	       [ -n "$redirected_link" ]
    then
	if [ -z "$zdl_mode" ]
	then
	    header "$1" "$Black${On_White}" "─"
	fi
    fi
}

function header_box_interactive {
    header "$1" "$Black${On_White}" "─"
}

function header_dl {
    if [ -z "$zdl_mode" ]
    then
	header "$1 " "$White${On_Blue}" 
    fi
}

function pause {
    if [ ! -f "$path_tmp/.stop_stdout" ]   &&
	   [ "$zdl_mode" != "daemon" ]     ||
	       [ "$1" == "force" ]         ||
	       [ "$redir_lnx" == true ]    ||
	       [ -n "$redirected_link" ]
    then
	echo
	header ">>>>>>>> Digita <Invio> per continuare " "$On_Blue$BWhite" "\<"
	cursor off
	read -e
	cursor on
    fi
}

function xterm_stop {
    if [ "$1" == "force" ] ||
	   ( [ ! -f "$path_tmp/.stop_stdout" ]   &&
		 [ "$zdl_mode" != "daemon" ]     &&
		 [ -z "${pipe_out[*]}" ]         ||
		     [ -n "$redirected_link" ] )
    then
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

