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

function init_colors {
	# Reset
	#Color_Off='\e[0m'       # Text Reset
    Color_Off='\e[0m\e[0;37m\e[40m'
    
	# Regular Colors
    Black='\e[0;30m'        # Nero
    Red='\e[0;31m'          # Rosso
    Green='\e[0;32m'        # Verde
    Yellow='\e[0;33m'       # Giallo
    Blue='\e[0;34m'         # Blu
    Purple='\e[0;35m'       # Viola
    Cyan='\e[0;36m'         # Ciano
    White='\e[0;37m'        # Bianco
    
	# Bold
    BBlack='\e[1;30m'       # Nero
    BRed='\e[1;31m'         # Rosso
    BGreen='\e[1;32m'       # Verde
    BYellow='\e[1;33m'      # Giallo
    BBlue='\e[1;34m'        # Blu
    BPurple='\e[1;35m'      # Viola
    BCyan='\e[1;36m'        # Ciano
    BWhite='\e[1;37m'       # Bianco
    
	# Underline
    UBlack='\e[4;30m'       # Nero
    URed='\e[4;31m'         # Rosso
    UGreen='\e[4;32m'       # Verde
    UYellow='\e[4;33m'      # Giallo
    UBlue='\e[4;34m'        # Blu
    UPurple='\e[4;35m'      # Viola
    UCyan='\e[4;36m'        # Ciano
    UWhite='\e[4;37m'       # Bianco
    
	# Background
    On_Black='\e[40m'       # Nero
    On_Red='\e[41m'         # Rosso
    On_Green='\e[42m'       # Verde
    On_Yellow='\e[43m'      # Giallo
    On_Blue='\e[44m'        # Blu
    On_Purple='\e[45m'      # Purple
    On_Cyan='\e[46m'        # Ciano
    On_White='\e[47m'       # Bianco
    
	# High Intensty
    IBlack='\e[0;90m'       # Nero
    IRed='\e[0;91m'         # Rosso
    IGreen='\e[0;92m'       # Verde
    IYellow='\e[0;93m'      # Giallo
    IBlue='\e[0;94m'        # Blu
    IPurple='\e[0;95m'      # Viola
    ICyan='\e[0;96m'        # Ciano
    IWhite='\e[0;97m'       # Bianco
    
	# Bold High Intensty
    BIBlack='\e[1;90m'      # Nero
    BIRed='\e[1;91m'        # Rosso
    BIGreen='\e[1;92m'      # Verde
    BIYellow='\e[1;93m'     # Giallo
    BIBlue='\e[1;94m'       # Blu
    BIPurple='\e[1;95m'     # Viola
    BICyan='\e[1;96m'       # Ciano
    BIWhite='\e[1;97m'      # Bianco
    
	# High Intensty backgrounds
    On_IBlack='\e[0;100m'   # Nero
    On_IRed='\e[0;101m'     # Rosso
    On_IGreen='\e[0;102m'   # Verde
    On_IYellow='\e[0;103m'  # Giallo
    On_IBlue='\e[0;104m'    # Blu
    On_IPurple='\e[10;95m'  # Viola
    On_ICyan='\e[0;106m'    # Ciano
    On_IWhite='\e[0;107m'   # Bianco
}

# function check_output {
#     check_instance i
#     if ( [ $? != 2 ] || [ "$pid_prog" == "$pid" ] ) && [ -z "$daemon" ]; then
# 	$*
#     fi
# }

function print_c {
    if [ ! -f "$path_tmp/.stop_stdout" ] && [ -z "$daemon" ]; then
	# check_instance i
	# if [ $? != 2 ] || [ "$pid_prog" == "$pid" ]; then
	    case "$1" in
		0)
		    echo -n -e ""
		    ;;
		1)
		    echo -n -e '\e[1;32m' #verde
		    ;;
		2)
		    echo -n -e '\e[1;33m' #giallo
		    ;;	
		3)
		    echo -n -e '\e[1;31m' #rosso
		    ;;	
		4)
		    echo -n -e "$BBlue"
		    ;;	

	    esac
	    echo -n -e "$2\n"
	    echo -n -e "${Color_Off}"
#	fi
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
    # check_instance i
    # if ( [ $? != 2 ] || [ "$pid_prog" == "$pid" ] ) &&
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
    # check_instance i
    # if ( [ $? != 2 ] || [ "$pid_prog" == "$pid" ] ) &&
    if [ "$redir_lnx" == true ] || ( [ ! -f "$path_tmp/.stop_stdout" ] && [ -z "$daemon" ] ); then
	echo
	header ">>>>>>>> Digita <Invio> per continuare " "$On_Blue$BWhite" "\<"
	cursor off
	read -e
	cursor on
    fi
}

function xterm_stop {
    # check_instance i
    # if ( [ $? != 2 ] || [ "$pid_prog" == "$pid" ] )
    if [ -z "$daemon" ]; then
	echo
	header ">>>>>>>> Digita <Invio> per chiudere Xterm " "$On_Blue$BWhite" "\<"
	cursor off
	read -e
	cursor on
    fi
}

function zclock {
    week=( "dom" "lun" "mar" "mer" "gio" "ven" "sab" )
    echo -n -e "$(date +%R) │ ${week[$( date +%w )]} $(date +%d·%m·%Y)"
}

