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


($0 ~ tty){
    patterns[2] = tty ".+zdl (-l|--lite)"
    patterns[3] = tty ".+zdl --interactive"
    patterns[4] = tty ".+zdl --configure)"
    patterns[5] = tty ".+zdl --list-extensions"
    patterns[6] = tty "p*info.+zdl"
    patterns[7] = tty ".+/links_loop.txt"

    for (i=2; i<8; i++) {
	if (level<i && $0 ~ patterns[i]) {
	    exit 1
	}
    }
}


