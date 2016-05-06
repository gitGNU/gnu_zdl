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

function host_login {
    unset user pass
    host="$1"

    if [ -z "${accounts_user_loop[*]}" ] &&
	   [ -z "${accounts_pass_loop[*]}" ]
    then
	get_accounts
	
	if [ -n "${accounts_user[*]}" ]
	then
	    accounts_user_loop=( ${accounts_user[*]} )
	    accounts_pass_loop=( ${accounts_pass[*]} )
	fi
    fi	

    if [ -n "${accounts_user_loop[*]}" ] &&
	   [ -n "${accounts_pass_loop[*]}" ]
    then
	max=$(( ${#accounts_user_loop[*]}-1 ))
	j=$max

	if [ -n "${accounts_alive[*]}" ]
	then
	    for i in `seq 0 $max`
	    do
		for account_alive in ${accounts_alive[*]}
		do
		    if [ "${account_alive#${accounts_user_loop[$i]}@${host}:}" != "${account_alive}" ]
		    then
			if check_pid "${account_alive#${accounts_user_loop[$i]}@${host}:}"
			then
			    (( j++ ))
			    accounts_user_loop[$j]="${accounts_user_loop[$i]}"
			    accounts_pass_loop[$j]="${accounts_pass_loop[$i]}"

			    accounts_user_loop[$i]=""
			    accounts_pass_loop[$i]=""
			fi
		    fi
		done
	    done
	fi

	accounts_user_loop=( ${accounts_user_loop[*]} )
	accounts_pass_loop=( ${accounts_pass_loop[*]} )
	
	user="${accounts_user_loop[0]}"
	pass="${accounts_pass_loop[0]}"
	
	accounts_user_loop[ ${#accounts_user_loop[*]} ]="${accounts_user_loop[0]}"
	accounts_pass_loop[ ${#accounts_pass_loop[*]} ]="${accounts_pass_loop[0]}"
	
	accounts_user_loop[0]=""
	accounts_pass_loop[0]=""
    fi

    if [ -z "$user" ] ||
	   [ -z "$pass" ]
    then
	print_c 3 "Nessun account disponibile"

    else
	print_c 1 "Login: ${user}@${host}"
    fi
}
