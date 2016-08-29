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

[[ "$(tty)" =~ tty ]] &&
    background=tty

if [ "$installer_zdl" == "true" ]
then
    source "ui/colors-${background}.awk.sh"
else
    source "$path_usr/ui/colors-${background}.awk.sh"
fi

init_colors

function print_case {    
    case "$1" in
	0)
	    echo -ne ""
	    ;;
	1)
	    echo -ne "$BGreen" 
	    ;;
	2)
	    echo -ne "$BYellow"
	    ;;	
	3)
	    echo -ne "$BRed" 
	    ;;	
	4)
	    echo -ne "$BBlue"
	    ;;	
	5)
	    echo -ne "$Color_Off"
	    ;;	
    esac
}
    
function print_c {
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	       [ -n "$redirected_link" ]
    then
	print_case "$1"
	
	echo -ne "$2\n"
	[ -z "$3" ] &&
	    echo -ne "${Color_Off}" ||
		print_case "$3"
    fi
}

function print_C {
    ## print_c FORCED
    print_case "$1"
    
    echo -ne "$2\n"
    echo -ne "${Color_Off}"
}

function print_r {
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	       [ -n "$redirected_link" ]
    then
	print_case "$1"
	
	echo -ne "\r$2"
	[ -z "$3" ] &&
	    echo -ne "${Color_Off}" ||
		print_case "$3"
    fi
}

function sprint_c {
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	       [ -n "$redirected_link" ]
    then
	print_case "$1"
	echo -n "$2"

	[ -z "$3" ] &&
	    echo -n "${Color_Off}" ||
		print_case "$3"
    fi
}

function separator- {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	if [[ "$1" =~ ^([0-9]+)$ ]]
	then
	    COLS=$COLUMNS
	    COLUMNS="$1"
	    header "" "$BBlue" "─"
	    echo -ne "$BBlue┴"
	    COLUMNS=$((COLS-$1-1))
	    header "" "$BBlue" "─"

	else
	    header "" "$BBlue" "─"
	    print_c 0 ""
	fi
    fi
}

function fclear {
    if [ -z "$already_clean" ] &&
	   show_mode_in_tty "$this_mode" "$this_tty"
    then
	## echo -ne "\033c${White}${Background}\033[J"
	echo -ne "\033c${Color_Off}\033[J"

    else
	unset already_clean
	export already_clean
    fi
    rm -f "$path_tmp"/no-clear-lite
}

function cursor {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	stato=$1
	case $stato in
	    off)
		#echo -en "\033[?30;30;30c"
		stty -echo
		setterm --cursor off
		;;
	    on)
		#echo -en "\033[?0;0;0c"
		stty echo
		setterm --cursor on
		;;
	esac
    fi
}

function header { # $1=label ; $2=color ; $3=header pattern
    local text line hpattern color
    text="$1"
    [ -n "$text" ] && text=" $text " 
    color="$2"
    hpattern="$3"
    [ -z "$hpattern" ] && hpattern="\ "
    
    eval printf -v line "%.0s${hpattern}" {1..$(( $COLUMNS-${#text} ))}
    echo -en "${color}${text}$line${Color_Off}"
}


function header_z {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	cursor off
	stty -echo
	
	(( "$#" == 0 )) && {
	    text_start="$name_prog ($prog)"
	    text_end="$(zclock)"
	} || {
	    text_start="$1"
	    text_end="$2"
	}
	eval printf -v text_space "%.0s\ " {1..$(( $COLUMNS-${#text_start}-${#text_end}-3 ))}
	header "$text_start$text_space$text_end" "$On_Blue"
	print_c 0 ""
    fi
}

function header_box {
    local text line
    text=" $1 "
    
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	    [ -n "$redirected_link" ]
    then
	####### strano: header funziona solo all'inizio (!?)
	## header "$1" "${Black}${On_White}" "─"
	
	eval printf -v line "%.0s─" {1..$(( $COLUMNS-${#text} ))}
	print_c 0 "${Black}${On_White}$text$line${Color_Off}"
    fi
}

function header_box_interactive {
    header "$1" "$Black${On_White}" "─"
    print_c 0 ""
}

function header_dl {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	header "$1 " "$White${On_Blue}"
	print_c 0 ""
    fi
}

function pause {
    if show_mode_in_tty "$this_mode" "$this_tty" ||
	    [ "$1" == "force" ]                  ||
	    [ "$redir_lnx" == true ]             ||
	    [ -n "$redirected_link" ]
    then
	echo
	header ">>>>>>>> Digita <Invio> per continuare " "$On_Blue$BWhite" "\<"
	print_c 0 ""
	cursor off
	read -e
	cursor on
    fi
}

function xterm_stop {
    if [ "$1" == "force" ] ||
	   ( show_mode_in_tty "$this_mode" "$this_tty" &&
		   [ -z "${pipe_out[*]}" ]             ||
		       [ -n "$redirected_link" ] )
    then
	header ">>>>>>>> Digita <Invio> per uscire " "$On_Blue$BWhite" "\<"
	echo -ne "\n"
	cursor off
	read -e 
	cursor on
    fi
}

function zclock {
    week=( "dom" "lun" "mar" "mer" "gio" "ven" "sab" )
    echo -n -e "$(date +%R) │ ${week[$( date +%w )]} $(date +%d·%m·%Y)"
}

function header_lite {
    echo -en "\033[1;0H"
    header_z "ZigzagDownLoader in $PWD" "│ help: M-h"
    header
}

function clear_lite {
    if show_mode_in_tty "$this_mode" "$this_tty"
    then
	spaces=$(((LINES-i-3) * COLUMNS))
	eval printf "%.0s\ " {1..$spaces}

	touch "$path_tmp"/no-clear-lite
    fi
}

function quit_clear {
    case "$this_mode" in
	lite)
	    fclear
	    ;;
    esac
}
