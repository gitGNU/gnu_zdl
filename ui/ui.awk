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
	return sprintf("%.2f", length_M) " MB"
    } else if (length_K > 0) {
	return sprintf("%.2f", length_K) " KB"
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
    return header("", "─", BBlue, Background)
}

function show_downloads_extended () {
    for (i=0; i<length(pid_out); i++) {
	length_H = human_length(length_out[i])
	speed = int(speed_out[i]) speed_out_type[i]
	
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
		code = code BGreen downloader_out[i] ": " progress_unspecified("downloading") "\n\n"
	    } else if (exists(file_out[i])) {
		code = code BGreen downloader_out[i] ": " progress_unspecified("complete") "\n\n"
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
	speed = int(speed_out[i]) speed_out_type[i]
	if (exists(file_out[i]))
	    length_saved[i] = size_file(file_out[i])
	    
	progress_bar = make_progress()
	    	
	if (downloader_out[i] == "RTMPDump")
	    downloader = "RTMP"
	else if (downloader_out[i] == "DCC_Xfer")
	    downloader = "xdcc"
	else
	    downloader = downloader_out[i]

	if (length(downloader)<5)
	    downloader = downloader ":" 

	code = code diff_bar_color downloader " " progress_bar "\n" blue_line
    }
    return code "\n\n\n\n\n"
}

function show_downloads_lite () {
    for (i=0; i<length(pid_out); i++) {
	file_out_chunk[i] = " " substr(file_out[i], 1, col-36) " "

	progress_bar = make_progress()

	if (downloader_out[i] == "RTMPDump")
	    downloader = "RTMP"
	else if (downloader_out[i] == "DCC_Xfer")
	    downloader = "xdcc"
	else
	    downloader = downloader_out[i]

	if (length(downloader)<5)
	    downloader = downloader ":"
	
	code = code diff_bar_color downloader " " progress_bar "\n"
    }
    return code "\n"
}


function progress_unspecified (status) {
    progress_text = BBlue "(grandezza del file non specificata dal server) "  BGreen human_length(length_saved[i])
    if (status == "downloading")
	return progress_text " " BBlue speed Color_Off

    if (status == "complete")
	return progress_text " terminato" Color_Off
}

function bar_colors (content, I) {
    if ((length_out[i] == "unspecified") && (check_pid(pid_out[i]))) {
	if (odd_run) {
	    if (! (I%2)) {
		bg_color = On_Green
		fg_color = Black
	    } else {
		bg_color = on_diff_color
		fg_color = Black #White
	    }
	} else {
	    if (! (I%2)) {
		bg_color = on_diff_color
		fg_color = Black #White
	    } else {
		bg_color = On_Green
		fg_color = Black
	    }
	}
	return fg_color bg_color content
    } else {
	return content
    }
}

function check_irc_pid () {
    c = "grep '" url_out[i] "$' .zdl_tmp/irc-pids 2>/dev/null"
    while (c | getline line) {
	split(line, irc_pid, " ")
	if (check_pid(irc_pid[1])) return 1
    }
    close(c)
    return 0
}

function make_progress (size_bar, progress_bar, progress) {
    if (downloader_out[i] == "cURL") {
	length_out[i] = "unspecified"
	# if ((! check_pid(pid_out[i])) && (exists(file_out[i]))) {
	#     percent_out[i] = 100
	# }
    }

    if (! percent_out[i])
	percent_out[i] = 0

    size_bar = 0

    if (! check_pid(pid_out[i])) {
	if (percent_out[i] == 100) {
	    diff_bar_color = BGreen 
	    bar_color = On_Green
	    info = sprintf("%-5s%-9s", percent_out[i] "%", "completato  " Color_Off)	
	}
	else if (check_irc_pid()) {
	    diff_bar_color = BYellow
	    bar_color = On_Yellow
	    info = sprintf("%-5s%-9s", percent_out[i] "%", "attendi     " Color_Off)	
	}    
	else {	    
	    diff_bar_color = BRed 
	    bar_color = On_Red
	    # if (downloader_out[i] == "Wget")
	    # 	percent_out[i] = 0
	    info = sprintf("%-5s%-9s", percent_out[i] "%", "non attivo  " Color_Off)	
	}
    } else {
	if (speed_out[i] > 0) {

	    diff_bar_color = BGreen
	    bar_color = On_Green 
	    speed = int(speed_out[i]) speed_out_type[i]
	    if (eta_out[i])
		eta = eta_out[i]
	    if ((length_out[i] == "unspecified") && (this_mode != "lite")) {
		progress = progress_unspecified("downloading")

	    }
	} else {
	    diff_bar_color = BYellow
	    bar_color = On_Yellow
	    info = sprintf("%-5s%-9s", percent_out[i] "%", "attendi     " Color_Off)	
	}		    
    }

    if (! int(percent_out[i])) percent_out[i] = 0
    size_bar = int((col-info_space) * percent_out[i]/100)
    diff_size_bar = (col-info_space) - size_bar

    bar = ""
    diff_bar = ""
    if (this_mode == "lite") {
	if (tty() ~ /pts/) on_diff_color = On_Gray2
	if ((tty() ~ /tty/) || ENVIRON["WINDIR"]) on_diff_color = On_Gray1

	for (k=0; k<size_bar; k++) {
	    if (substr(file_out_chunk[i], k+1, 1)) {
		bar = bar bar_colors(substr(file_out_chunk[i], k+1, 1), k)
	    } else {
		bar = bar bar_colors(" ", k)
	    }
	}

	for (h=0; h<diff_size_bar; h++) {
	    if (substr(file_out_chunk[i], h+k+1, 1))
		diff_bar = diff_bar bar_colors(substr(file_out_chunk[i], h+k+1, 1), k+h)
	    else
		diff_bar = diff_bar bar_colors(" ", k+h)
	}

	if (length_out[i] == "unspecified" && (check_pid(pid_out[i]))) {
	    info = sprintf("%-11s" Color_Off BBlue "%s", human_length(length_saved[i]), speed Color_Off)	
	    progress_bar = bar diff_bar Color_Off BGreen
	} else {
	    progress_bar = Black bar_color bar Color_Off on_diff_color diff_bar #_color diff_bar
	}
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
    }
    else if (this_mode == "lite") {
	# result = "\033c" White Background "\033[J" header("ZigzagDownLoader in "ENVIRON["PWD"], " ", White, On_Blue)
	# result = result "\n\n" show_downloads_lite()
	result = show_downloads_lite()
    }
    else {
	result = "\n" header("Downloading in "ENVIRON["PWD"], " ", White, On_Blue)
	result = result show_downloads()
    }
    printf("%s", result)
}
