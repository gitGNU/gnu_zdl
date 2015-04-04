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

function tty () {
    c = "tty"
    c | getline t
    close(c)
    return t
}


function check_instance_daemon () {
    pid = $1
    c = "cat /proc/" pid "/cmdline" #2>/dev/null"
    c | getline dir
    close(c)
    if (dir ~ /zdl.+silent/) {
	sub(/.+silent/, "", dir)
	if (sprintf (CONVFMT, dir) == sprintf (CONVFMT, ENVIRON["PWD"])) { 
	    result = 0
	    print pid
	    exit
	}
    }
}

function check_pid (pid,   test) {
    if (pid)
	if (exists("/proc/" pid "/cmdline")) 
	    return 1
    return 0
}

function exists(file,   line) {
    if (file) {
	if ((getline line < file) > 0 ) {
	    close(file)
	    return 1
	}
    }
    return 0
}

function size_file (filename) {
    ## in bytes
    c = "stat -c '%s' "filename" 2>/dev/null"
    c | getline result
    close(c)
    return result
}

function bash_array (name, i, value) {
    return name"["i"]=\""value"\"; "
}

function bash_var (name, value) {
    return name"=\""value"\"; "
}

function seconds_to_human (seconds,         minutes, hours) {
    minutes = int(seconds/60)
    hours = int(minutes/60)
    minutes = minutes - (hours * 60)
    seconds = seconds - (minutes * 60) - (hours * 60 * 60)
    return hours "h" minutes "m" seconds "s"
}

function cat (file,      c, line) {
    if (exists(file)) {
	chunk2 = ""
	c = "cat " file
	while (c | getline line) {
	    chunk2 = chunk2 line
	}
	close(c)
	return chunk2
    }
}

function rm_line (line, file) {
    code = code "line_file - \"" line "\" \"" file "\"; "
}
