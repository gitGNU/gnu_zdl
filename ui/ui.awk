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
    for (i=0; i<length(pid_out); i++) {
	length_H = human_length(length_out[i])
	if (exists(file_out[i]))
	    length_saved[i] = size_file(file_out[i])

	title = "Numero download: "i
	code = code header(title, " ", White, On_Blue) "\n"

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
		code = code BBlue "Stato: " Color_Off BGreen length_saved[i] " B (" length_H ") " BBlue speed_out[i] speed_out_type[i] Color_Off "\n\n"
	    } else if (exists(file_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BBlue "Stato: " Color_Off BGreen length_saved[i] " B (" length_H ") terminato" Color_Off "\n\n"
	    } else {
		code = code BBlue "Stato: " Color_Off BRed "Download non attivo" Color_Off "\n\n"
	    }
	} else {
	    progress_bar = make_progress()
	    code = code BBlue "Stato: " diff_bar_color progress_bar Color_Off "\n\n"
	}
    }
    return code
}

function show_downloads () {
    for (i=0; i<length(pid_out); i++) {
	code = code BBlue "File: " Color_Off file_out[i] BBlue "\nLink: " Color_Off url_out[i] "\n"
	if (downloader_out[i] == "cURL") {
	    if (check_pid(pid_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BGreen downloader_out[i] ": " length_saved[i] " B (" length_H ") " BBlue speed_out[i] speed_out_type[i] "\n" blue_line
	    } else if (exists(file_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BGreen downloader_out[i] ": " length_saved[i] " B (" length_H ") terminato\n" blue_line
	    } else {
		code = code BRed downloader_out[i] ": Download non attivo\n" blue_line
	    }
	} else {
	    progress_bar = make_progress()
	
	    if (downloader_out[i] == "RTMPDump")
		downloader = "RTMP"
	    else
		downloader = downloader_out[i]

	    code = code diff_bar_color downloader ": " progress_bar "\n" blue_line
	}
    }
    return code "\n\n\n\n\n"
}

function show_downloads_lite () {
    for (i=0; i<length(pid_out); i++) {
	file_out_chunk[i] = " " substr(file_out[i], 1, col-36) " "
	if (downloader_out[i] == "cURL") {
	    if (check_pid(pid_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BGreen downloader_out[i] ": " file_out_chunk[i] " " length_saved[i] " B (" length_H ") " BBlue speed_out[i] speed_out_type[i] Color_Off
	    } else if (exists(file_out[i])) {
		length_H = human_length(length_saved[i])
		code = code BGreen downloader_out[i] ": " file_out_chunk[i] " " length_saved[i] " B (" length_H ") terminato" Color_Off
	    } else {
		code = code BRed downloader_out[i] ": " file_out_chunk[i] " Download non attivo" Color_Off
	    }
	} else {
	    progress_bar = make_progress()
	    if (downloader_out[i] == "RTMPDump")
		downloader = "RTMP"
	    else
		downloader = downloader_out[i]
	    code = code diff_bar_color downloader ": " progress_bar "\n"
	}
    }
    return code "\n"
}


function make_progress (size_bar, progress_bar, progress) {
    if (! percent_out[i])
	percent_out[i] = 0
    size_bar = 0
    if (! check_pid(pid_out[i])) {
	if (percent_out[i] == 100) {
	    diff_bar_color = BGreen 
	    bar_color = On_Green
	    info = sprintf("%-5s%-9s", percent_out[i] "%", "completato" Color_Off)	
	} else {	    
	    diff_bar_color = BRed 
	    bar_color = On_Red
	    # if (downloader_out[i] == "Wget")
	    # 	percent_out[i] = 0
	    info = sprintf("%-5s%-9s", percent_out[i] "%", "non attivo" Color_Off)	
	}
    } else {
	if (speed_out[i] > 0) {
	    diff_bar_color = BGreen
	    bar_color = On_Green 
	    speed = int(speed_out[i]) speed_out_type[i]
	    eta = eta_out[i]
	    if (length_out[i] == "unspecified") {
		info = sprintf("%-5s", speed)	
		progress = BBlue "dimensione file non specificata, finora scaricati "  BGreen human_length(length_saved[i])  " ("  length_saved[i] " B) " speed Color_Off
	    }
	} else {
	    diff_bar_color = BYellow
	    bar_color = On_Yellow
	    info = sprintf("%-5s%-9s", percent_out[i] "%", "attendi" Color_Off)	
	}		    
    }

    if (! int(percent_out[i])) percent_out[i] = 0
    size_bar = int((col-info_space) * percent_out[i]/100)
    diff_size_bar = (col-info_space) - size_bar

    bar = ""
    diff_bar = ""
    if (zdl_mode == "lite") {
	for (k=0; k<size_bar; k++) {
	    if (substr(file_out_chunk[i], k+1, 1)) {
		bar = bar substr(file_out_chunk[i], k+1, 1)
	    } else {
		bar = bar " "
	    }
	}

	for (h=0; h<diff_size_bar; h++) {
	    if (substr(file_out_chunk[i], h+k+1, 1))
		diff_bar = diff_bar substr(file_out_chunk[i], h+k+1, 1)
	    else
		diff_bar = diff_bar " "
	}
	
	if (tty() ~ /pts/) on_diff_color = On_Gray2
	if ((tty() ~ /tty/) || ENVIRON["WINDIR"]) on_diff_color = On_Gray1
	progress_bar = Black bar_color bar Color_Off on_diff_color diff_bar #_color diff_bar
    } else {
	for (k=0; k<size_bar; k++) bar = bar " "
	for (k=0; k<diff_size_bar; k++) diff_bar = diff_bar "│"
	progress_bar = Black bar_color bar Color_Off diff_bar_color diff_bar
    }
    
    if (! progress) {
	if (! info)
	    info = sprintf("%-5s" Color_Off BBlue "%-9s" Color_Off "%-12s", percent_out[i] "%", speed, eta)	
	progress = progress_bar Color_Off diff_bar_color " " info
	info = ""
    }
    return progress
}

function display () {
    info_space = 34
    init_colors()
    blue_line = separator()
    if (zdl_mode == "extended") {
	result = show_downloads_extended()
    } else if (zdl_mode == "lite") {
	result = "\033c" White On_Black "\033[J" header("ZigzagDownLoader in "ENVIRON["PWD"], " ", White, On_Blue)
	result = result "\n\n" show_downloads_lite()
    } else {
	result = "\n" header("Downloading in "ENVIRON["PWD"], " ", White, On_Blue)
	result = result show_downloads()
    }
    printf("%s", result)
}
