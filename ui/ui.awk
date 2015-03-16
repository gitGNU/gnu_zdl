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

function print_c (type, text) {
    if (type = 0) result = ""
    if (type = 1) result = BGreen
    if (type = 2) result = BYellow
    if (type = 3) result = BRed
    if (type = 4) result = BBlue
    return result text "\n" Color_Off
}

function human_length (length_B) { 
    length_K = length_B/1024
    length_M = length_K/1024
    if (length_M > 0) {
	return length_M " MB"
    } else if (length_K > 0) {
	return length_K " KB"
    } else {
	return length_B " B"
    }
}

function header (text, pattern, fgcolor, bgcolor,       max, pattern_line) {
    max = 0
    if (length(text) > 0) {
	text = " " text " "
	max = length(text)
    }
    for (h=0; h<(col - max); h++) {
	pattern_line = pattern_line pattern
    }
    pattern_line = fgcolor bgcolor text pattern_line Color_Off
    return pattern_line
}

function separator () {
    return header("", "─", BBlue, On_Black)
}

function show_downloads_extended () {
    for (i in pid_out) {
	length_H = human_length(length_out[i])
	title = "Numero download: "i
	box = header(title, " ", White, On_Blue)
	code = code box "\n"

	if (downloader_out[i] ~ /cURL|RTMPDump/) {
	    code = code BBlue "File: " Color_Off file_out[i] "\n"
	    code = code BBlue "Downloader: " Color_Off downloader_out[i] BYellow " protocollo RTMP" Color_Off "\n"
	    code = code BBlue "Link: " Color_Off url_out[i] "\n"
	    code = code BBlue "Streamer: " Color_Off streamer_out[i] "\n"
	    code = code BBlue "Playpath: " Color_Off playpath_out[i] "\n"
	} else {
	    code = code BBlue "File: " Color_Off file_out[i] "\n"
	    code = code BBlue "Grandezza: " Color_Off length_H BBlue "\tDownloader: " Color_Off downloader_out[i] "\n"
	    code = code BBlue "Link: " Color_Off url_out[i] "\n"
	    code = code BBlue "Url del file: " Color_Off url_out_file[i] "\n"
	}

	if (downloader_out[i] == "cURL") {
	    if (check_pid(pid_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BBlue "Stato: " Color_Off BGreen length_saved[i] " (" length_H ") " BBlue speed_out[i] speed_out_type[i] Color_Off "\n\n"
	    } else if (exists(file_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BBlue "Stato: " Color_Off BGreen length_saved[i] " (" length_H ") terminato" Color_Off "\n\n"
	    } else {
		code = code BBlue "Stato: " Color_Off BRed "Download non attivo" Color_Off "\n\n"
	    }
	} else if ((percent_out[i] == 100) ||                                     \
		   ((cmd | getline) && (downloader_out[i] == "RTMPDump"))  || \
		   ((length_saved[i] == length_out[i]) && (length_out[i] > 0) && (! exists(file_out[i]".st")))) {
	    close(cmd)
	    diff_bar_color = BGreen
	    progress_bar = "Download completato"
	} else {
	    progress_bar = make_progress()
	    code = code BBlue "Stato: " diff_bar_color progress_bar Color_Off "\n\n"
	}
    }
    return code
}

function show_downloads () {
    for (i in pid_out) {
	code = code BBlue "File: " Color_Off file_out[i] BBlue "\nLink: " Color_Off url_out[i] "\n"
	if (downloader_out[i] == "cURL") {
	    if (check_pid(pid_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BGreen downloader_out[i] ": " length_saved[i] " (" length_H ") " BBlue speed_out[i] speed_out_type[i] "\n" blue_line
	    } else if (exists(file_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BGreen downloader_out[i] ": " length_saved[i] " (" length_H ") terminato\n" blue_line
	    } else {
		code = code BRed downloader_out[i] ": Download non attivo\n" blue_line
	    }
	} else { 
	    cmd = "grep 'Download complete' < .zdl_tmp/" file_out[i] "_stdout.tmp"
	    length_saved[i] = size_file(file_out[i])
	    if ((percent_out[i] == 100) ||                                     \
		((cmd | getline) && (downloader_out[i] == "RTMPDump"))  ||     \
		((length_saved[i] == length_out[i]) && (length_out[i] > 0) && (! exists(file_out[i]".st")))) {
		close(cmd)
		diff_bar_color = BGreen
		progress_bar = "Download completato"
	    } else {
		progress_bar = make_progress()
	    }
	    code = code diff_bar_color downloader_out[i] ": " progress_bar "\n" blue_line
	}
    }
    return code "\n\n\n\n\n"
}


function make_progress (size_bar, progress_bar) {
    size_bar = 0
    if (! check_pid(pid_out[i])) {
 	if (downloader_out[i] ~ /^(Wget|RTMPDump)$/) {
 	    progress = "Download non attivo"
 	}
 	diff_bar_color = BRed 
 	bar_color = On_Red
 	speed = diff_bar_color "non attivo" Color_Off
 	eta = ""
    } else {
	if (speed_out[i] > 0) {
	    diff_bar_color = BGreen
	    bar_color = On_Green 
	    speed = speed_out[i] speed_out_type[i]
	    eta = eta_out[i]
	} else {
	    diff_bar_color = BYellow
	    bar_color = On_Yellow
	    speed = diff_bar_color " attendi..." Color_Off
	    eta = ""
	}		    
    }
    if (! int(percent_out[i])) percent_out[i] = 0
    size_bar = (col-40) * int(percent_out[i])/100
    diff_size_bar = (col-40) - size_bar

    bar = ""
    diff_bar = ""
#     eval printf -v bar "%.0s\ " {1..$size_bar}
#     eval printf -v diff_bar "%.0s\|" {1..$diff_size_bar}
    for (k=0; k<size_bar; k++) bar = bar " "
    for (k=0; k<diff_size_bar; k++) diff_bar = diff_bar "|"
    progress_bar = bar_color bar Color_Off diff_bar_color diff_bar
    
    if (! progress) progress = progress_bar Color_Off diff_bar_color " " percent_out[i] "% " Color_Off BBlue speed Color_Off " " eta
    return progress
}

function display () {
    bash_colors()
    blue_line = separator()
    if (extended>0) {
	result = show_downloads_extended()
    } else {
	result = show_downloads()
    }
    printf result
}
