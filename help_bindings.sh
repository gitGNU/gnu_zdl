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

path_usr="/usr/local/share/zdl"
source $path_usr/config.sh
source $path_usr/ui/widgets.sh
source $path_usr/ui/ui.sh
source $path_usr/libs/core.sh

if [ "$background" == "black" ]
then
    Background="$On_Black"
fi

[ -n "$Background" ] && Foreground="$White"
Color_Off="\033[0m${Foreground}${Background}" #\033[40m"

downloader_in=$(cat .zdl_tmp/downloader)

this_mode=help
fclear
header_z
standard_box help

