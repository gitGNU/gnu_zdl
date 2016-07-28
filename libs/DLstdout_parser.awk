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

function array_out (value, type) {
    code = code bash_array(type, i, value) 
}

function downloaded_part () {
    if ((downloader_out[i] == "Axel") && (percent_out[i] < 100)) {
    	tot = int((percent_out[i] * (length_out[i] / axel_parts_out[i])) / 100)
    	return tot
    } else {
	return length_saved[i]
    }
}

function check_stdout () {
    delete pid_alive[i]
    if (check_pid(pid_out[i])) {
	pid_alive[i] = pid_out[i]
	array_out(pid_alive[i], "pid_alive")
    }

    if ((percent_out[i] == 0) && (! check_pid(pid_out[i]))) {
	system("rm -f .zdl_tmp/"file_out[i]"_stdout.tmp")
	if (error_code[i] == 8) {
	    system("rm -f " file_out[i] " " file_out[i] ".aria2")
	    delete error_code[i]
	}
    }


    if ((downloader_out[i] !~ /RTMPDump|cUrl/) &&
	(pid_alive[i]) &&
	(num_check > 10)){
	code = code bash_var("num_check", "0")
	test_stdout["old"] = cat(".zdl_tmp/" file_out[i] "_stdout.old")
	if (test_stdout["new"] == test_stdout["old"] && 
	    downloader_out[i] == "Axel" &&		
	    exists(file_out[i] ".st")) {
	    system("kill -9 " pid_out[i] " 2>/dev/null")
	}
    }

    if (check_pid(pid_out[i])) {
	if (url_in == url_out[i])
	    code = code bash_var("url_in", "")
	if (file_in == file_out[i]) {
	    code = code bash_var("file_in", "")
	    code = code bash_var("url_in", "")
	}	    

	# if (percent_out[i] == 100) {
	#     system("kill -9 " pid_out[i] " 2>/dev/null")
	#     system("rm -f " file_out[i] ".st")
	# }
    }

    if (! check_pid(pid_out[i])) {
	# if ((! length_saved[i]) ||				
	#     (length_out[i] > 0 &&				
	#      length_saved[i] < length_out[i] &&
	#     downloader_out[i] == "Wget"))
	#     system("rm -f .zdl_tmp/"file_out[i]"_stdout.tmp " file_out[i] " " file_out[i] ".st .zdl_tmp/"file_out[i]"_stdout.yellow")
	
	if (length_saved[i] == length_out[i] &&
	    length_out[i] > 0 &&
	    ! exists(file_out[i] ".st") &&
	    ! exists(file_out[i] ".aria2"))
	    rm_line(url_out[i], ".zdl_tmp/links_loop.txt")

		
	##############################################################################################
	## cancella i file temporanei se il link non è in coda e il file non esiste
	## (potrebbe essere stato spostato o decompresso).
	## Codice lasciato commentato perché potrebbe essere un'alternativa valida (funziona).
	## Consuma qualche risorsa in più e non è un'operazione necessaria: è un lusso :)
	##############################################################################################
	# if (! exists(file_out[i])) {
	#     while (getline url_loop < ".zdl_tmp/links_loop.txt") {
	# 	if (url_loop == url_out[i]) {
	# 	    url_exists = 1
	# 	    break
	# 	}
	#     }
	#     if (url_exists) {
	# 	url_exists = 0
	#     } else {
	# 	system("rm -f .zdl_tmp/"file_out[i]"_stdout.tmp")
	#     }
	# }
		
	# check_in_file
	if (file_in == file_out[i] &&
	    url_in == url_out[i])
	    code = code bash_var("no_bis", "true")

	if (no_complete == "true") {
	    if ((exists(file_out[i]) &&
		 ! exists(file_out[i]".st") &&
		 ! exists(file_out[i]".aria2") &&
		 length_saved[i] == length_out[i]) ||
		(downloader_out[i] == "cURL" &&
		 ! length_saved[i] &&
		 length_saved[i]>0 ) ||
		progress_end[i]) {
		system("rm -f .zdl_tmp/" file_out[i] "_stdout.*")
	    }
	}
    }
    downloaded_length = downloaded_part()
    if ((percent_out[i] == 100) ||
	(downloaded_length > 4000000)) {
	add_line(file_out[i], ".zdl_tmp/pipe_files.txt")
    } else if (exists(".zdl_tmp/pipe_files.txt")) {
    	rm_line(file_out[i], ".zdl_tmp/pipe_files.txt")
    }

    ## check_in_file
    if (file_in == file_out[i]) {
	code = code bash_var("length_in", length_out[i])
	code = code bash_var("length_saved_in", length_saved[i])
    }

}

function yellow_progress () {
    if (exists(".zdl_tmp/"file_out[i]"_stdout.yellow")) {
	## giallo: sostituire ciò che segue con un sistema di recupero dati precedenti (barra di colore giallo)

	c = "head -n5 .zdl_tmp/"file_out[i]"_stdout.yellow 2>/dev/null"
	nr = 0
	while (c | getline line) {
	    nr++
	    if (nr == 1) percent_out[i] = line
	    if (nr == 2) speed_out[i] = 0
	    if (nr == 3) speed_out_type[i] = line
	    if (nr == 4) eta_out[i] = line
	    if (nr == 5) length_saved[i] = line
	}
	array_out(percent_out[i], "percent_out")
	close(c)
    } else {
	percent_out[i] = 0
	speed_out[i] = 0
	speed_out_type[i] = "KB/s"
	## mancano ancora (secondi):
	eta_out[i] = ""
	length_saved[i] = 0
    }
}

function progress_out (chunk,           progress_line) {
    ## eta, %, speed, speed type, length-saved (length-out)

    if (dler == "Axel") {
	for (y=n; y>0; y--) {
	    if (chunk[y] ~ /(Too many redirects)/) {
	    	code = code "wget_links[" wget_links_index "]=\"" url_out[i] "\"; "
	    	break
	    } 
	    if (chunk[y] ~ /(Could not parse URL|404 Not Found)/) {
	    	progress_abort[i] = chunk[y]
	    	break
	    } 
	    if ((chunk[y] ~ "Downloaded") && (! exists(file_out[i]".st"))) {
	    	progress_end[i] = chunk[y]
	    	break
	    } 
	    if (chunk[y] ~ /\%.+KB\/s.+/) {
		progress_line = chunk[y]
		split(progress_line, progress_elems, /[\ ]*[\%]*[K]*/)
		percent_out[i] = progress_elems[2]
		if (percent_out[i] == "]") percent_out[i] = 100
		speed_out[i] = int(progress_elems[length(progress_elems)-1])
		break
	    }

	}

	if (progress_end[i]) {
	    rm_line(url_out[i], ".zdl_tmp/links_loop.txt")
	    if (url_in == url_out[i]) bash_var("url_in", "")
	    length_saved[i] = size_file(file_out[i])
	    percent_out[i] = 100
	} else if (progress_abort[i]) {
	    bash_var("url_in", "")
	    percent_out[i] = 0
	    code = code "_log 3 \"" url_out[i] "\"; "
	    system("rm -f .zdl_tmp/"file_out[i]"_stdout.tmp " file_out[i] " " file_out[i] ".st " file_out[i] ".aria2")
	} else if ((speed_out[i] > 0) && (speed_out[i] ~ /^[0-9]+$/)) {
	    speed_out_type[i] = "KB/s"
	    ## mancano ancora (secondi):
	    if (int(speed_out[i]) != 0 && int(speed_out[i]) > 0) {
		eta_out[i] = int(((length_out[i] / 1024) * (100 - percent_out[i]) / 100) / int(speed_out[i]))
		eta_out[i] = seconds_to_human(eta_out[i])
	    }
	    length_saved[i] = int((length_out[i] * percent_out[i]) / 100)
	    if ((! no_check) && (percent_out[i] ~ /^[0-9]+$/) && (percent_out[i] > 0))
		print percent_out[i] "\n" speed_out[i] "\n" speed_out_type[i] "\n" eta_out[i] "\n" length_saved[i] > ".zdl_tmp/"file_out[i]"_stdout.yellow"
	}
	
    } else if (dler == "Aria2") {
	for (y=n; y>0; y--) {
	    if (chunk[y] ~ /(404 Not Found)/) {
	    	progress_abort[i] = chunk[y]
	    	break
	    }
	    if ((chunk[y] ~ "download completed") && (! exists(file_out[i]".aria2"))) {
	    	progress_end[i] = chunk[y]
	    } 
	    if (chunk[y] ~ /\%/) {
		progress_line = chunk[y]

		if (! progress_end[i]) {
		    split(progress_line, progress_elems, /[(]*[\%]*[:]*[K]*[\]]*/)
		    percent_out[i] = int(progress_elems[2])
		
		    match(progress_line, /DL:([0-9]+)/, matched)
		    speed_out[i] = matched[1]/1024

		    match(progress_line, /ETA:(.+)\]/, matched)
		    eta_out[i] = matched[1]
		}
		
		match(progress_line, /\/([0-9]+)B/, matched)
		length_out[i] = matched[1]
		
		break
	    }

	}

	if (progress_end[i]) {
	    rm_line(url_out[i], ".zdl_tmp/links_loop.txt")

	    if (url_in == url_out[i]) bash_var("url_in", "")

	    length_saved[i] = length_out[i]
	    percent_out[i] = 100
	}
	else if (progress_abort[i]) {
	    bash_var("url_in", "")
	    percent_out[i] = 0
	    code = code "_log 3 \"" url_out[i] "\"; "
	    system("rm -f .zdl_tmp/"file_out[i]"_stdout.tmp " file_out[i] " " file_out[i] ".aria2 " file_out[i] ".st")
	}
	else if ((speed_out[i] > 0) && (speed_out[i] ~ /^[0-9]+$/)) {
	    speed_out_type[i] = "KB/s"
	    length_saved[i] = int((length_out[i] * percent_out[i]) / 100)
	    if ((! no_check) && (percent_out[i] ~ /^[0-9]+$/) && (percent_out[i] > 0))
		print percent_out[i] "\n" speed_out[i] "\n" speed_out_type[i] "\n" eta_out[i] "\n" length_saved[i] > ".zdl_tmp/"file_out[i]"_stdout.yellow"
	}
	
    } else if (dler == "Wget") {
	for (y=n; y>0; y--) {
	    if (chunk[y] ~ /(saved|100%)/) {
		progress_end[i] = chunk[y]
		break
	    }
	    if (chunk[y] ~ /(404: Not Found)/) {
	    	progress_abort[i] = chunk[y]
	    	break
	    } 
	    if (chunk[y] ~ /[%]+ .+(K|M|B)/) {
		progress_line = chunk[y]
		break
	    }
	    if (chunk[y] ~ /.+K.+ ([0-9]+)[MK]+/) {
		    progress_chunked = chunk[y]
		    nolength = ""
		break
	    }
	}

	if (progress_end[i]) {
	    if (! no_check)
		rm_line(url_out[i], ".zdl_tmp/links_loop.txt")
	    if (url_in == url_out[i]) bash_var("url_in", "")
	    length_saved[i] = size_file(file_out[i])
	    percent_out[i] = 100
	} else if (progress_abort[i]) {
	    bash_var("url_in", "")
	    percent_out[i] = 0
	    code = code "_log 3 \"" url_out[i] "\"; "
	    system("rm -f .zdl_tmp/"file_out[i]"_stdout.* " file_out[i] " " file_out[i] ".st")
	} else if (progress_line) {
	    split(progress_line, progress_elems, /[\ ]*[\%]*/)
	    percent_out[i] = progress_elems[length(progress_elems)-3]
	    speed_out[i] = progress_elems[length(progress_elems)-1]
	    eta_out[i] = progress_elems[length(progress_elems)]
	    if (speed_out[i] ~ /B/) speed_out_type[i]="B/s"
	    if (speed_out[i] ~ /K/) speed_out_type[i]="KB/s"
	    if (speed_out[i] ~ /M/) speed_out_type[i]="MB/s"
	    sub(/[BKM]/, "", speed_out[i])
	    length_saved[i] = size_file(file_out[i])
	    if (! length_saved[i]) length_saved[i] = 0
	} else if (progress_chunked) {
	    match(progress_chunked, /.+ ([0-9]+)[MK]/, matched)
	    speed_out[i] = matched[1]
	    length_saved[i] = size_file(file_out[i])
	} else {
	    ## giallo: sostituire ciò che segue con un sistema di recupero dati precedenti (barra di colore giallo)
	    percent_out[i] = 0
	    speed_out[i] = 0
	    speed_out_type[i] = "KB/s"
            ## mancano ancora (secondi):
	    eta_out[i] = ""
	    length_saved[i] = 0
	}
    } else if (dler == "RTMPDump") {
	for (y=n; y>0; y--) {
	    if (chunk[y] ~ "Download complete") {
		progress_end[i] = chunk[y]
		break
	    }

	    if (chunk[y] ~ /\([0-9]+/) {
		progress_line = chunk[y]
		break
	    }
	}

	if (progress_end[i]) {
	    if (! no_check)
		rm_line(url_out[i], ".zdl_tmp/links_loop.txt")
	    if (url_in == url_out[i]) bash_var("url_in", "")
	    length_saved[i] = size_file(file_out[i])
	    percent_out[i] = 100
	} else if (progress_line) {
	    cmd = "date +%s"
	    cmd | getline this_time
	    close(cmd)
	    elapsed_time = this_time - start_time
	    split(progress_line, progress_elems, /[\ ]*[\%]*[\(]*/)
	    percent_out[i] = int(progress_elems[length(progress_elems)-1])
	    if (percent_out[i] > 0) {
		eta_out[i] = int((elapsed_time * 100 / percent_out[i]) - elapsed_time)
		eta_out[i] = seconds_to_human(eta_out[i])
		length_saved[i] = size_file(file_out[i])
		if (! length_saved[i]) length_saved[i] = 0
		speed_out[i] = (length_saved[i] / 1024) / elapsed_time
		speed_out_type[i] = "KB/s"
	    }
	    if (! pid_alive[i] && length_saved[i] < length_out[i])
		system("rm -f " file_out[i])
	}
    } else if (dler == "cURL") {
	for (y=n; y>0; y--) {

	    if (chunk[y] ~ /[\ ]+[0-9]+[k]*k$/) {
	    	progress_line = chunk[y]
	    	break
	    }
	}
        if (progress_line) {
	    split(progress_line, progress_elems, /[\ ]+/)
	    speed_out[i] = progress_elems[length(progress_elems)]
	    if (speed_out[i] ~ /k$/) {
		speed_out_type[i] = "KB/s"
		sub(/k$/, "", speed_out[i])
	    } else {
		speed_out_type[i] = "B/s"
	    }
	    
	    if (!speed_out[i])
		speed_out[i] = 0
	    
	} else {
	    speed_out[i] = 0
	    speed_out_type[i] = "KB/s"
	}
	length_saved[i] = size_file(file_out[i])
	if (!length_out[i])
	    length_out[i] = "unspecified"
    } else if (dler == "FFMpeg") {
	for (y=n; y>0; y--) {

	    if (chunk[y] ~ /kbits/) {
	    	progress_line = chunk[y]
	    	break
	    }
	}
	
        if (progress_line) {
	    split(progress_line, progress_elems, /[\ ]+/)
	    speed_out[i] = progress_elems[length(progress_elems)]
	    if (speed_out[i] ~ /k$/) {
		speed_out_type[i] = "KB/s"
		sub(/k$/, "", speed_out[i])
	    } else {
		speed_out_type[i] = "B/s"
	    }
	    
	    if (!speed_out[i])
		speed_out[i] = 0
	    
	} else {
	    speed_out[i] = 0
	    speed_out_type[i] = "KB/s"
	}
	length_saved[i] = size_file(file_out[i])
	if (!length_out[i])
	    length_out[i] = "unspecified"
    }

    
    if (! speed_out[i]) speed_out[i] = 0
    if (! speed_out_type[i]) speed_out_type[i] = "KB/s"
    if (! length_saved[i]) length_saved[i] = 0
    if (! percent_out[i]) percent_out[i] = 0
    
    array_out(speed_out[i], "speed_out")
    array_out(speed_out_type[i], "speed_out_type")
    array_out(eta_out[i], "eta_out")
    array_out(length_saved[i], "length_saved")
    array_out(percent_out[i], "percent_out")
    array_out(length_out[i], "length_out")

    if (! no_check)
	check_stdout()
}

function progress () {
    ## estrae le ultime n righe e le processa con progress_out()
    delete test_stdout["new"]
    
    for (k=0;k<n;k++) {
	chunk[k] = progress_data[++j%n]
	if (! no_check)
	    test_stdout["new"] = test_stdout["new"] chunk[k]
	delete progress_data[j%n]
    }
    
    if ((num_check < 2) && (! no_check))
	print test_stdout["new"] > ".zdl_tmp/" file_out[i] "_stdout.old"
    progress_out(chunk)
    delete chunk
}

BEGIN {
    i = -1
    j = 0
    ## numero righe coda del chunk:
    n = 20
    delete pid_alive
}

{
 #   		code = code "test+=\" RIGA " $0 "\"; "
    if (FNR == 1) {
	if (j > 1) {
	    ## progress_out
	    progress()
	    j = 0
	} 
	i++
	pid_out[i] = $0
	array_out(pid_out[i], "pid_out")

	if (check_pid(pid_out[i])) {
	    array_out(pid_out[i], "pid_alive")
	    pid_alive[i] = pid_out[i]
	}
    }

    progress_data[++j%n] = $0

    if (FNR == 2) {
	url_out[i] = $0
	array_out(url_out[i], "url_out")
    }
    if (FNR == 3) {
	dler = $0
	downloader_out[i] = dler
	array_out(dler, "downloader_out")
    }
    if (FNR == 4) array_out($0, "pid_prog_out")
    if (FNR == 5) {
	file_out[i] = $0
	array_out(file_out[i], "file_out")
	if (dler ~ /Aria2|Axel/) yellow_progress()
    }
    if (FNR == 6) {
	if (dler ~ /Aria2|Axel|Wget|youtube-dl/) {
	    url_out_file[i] = $0
	    array_out(url_out_file[i], "url_out_file")
	} else if (dler ~ /RTMPDump|cURL/) {
	    streamer_out[i] = $0
	    array_out(streamer_out[i], "streamer_out")
	}
    }
    if (FNR == 7) {
	if (dler ~ /RTMPDump|cURL/) {
	    playpath_out[i] = $0
	    array_out(playpath_out[i], "playpath_out")
	} else if (dler ~ /Aria2|Axel/) {
	    axel_parts_out[i] = $0
	    aria2_parts_out[i] = $0
	    array_out(axel_parts_out[i], "axel_parts_out")
	    array_out(aria2_parts_out[i], "aria2_parts_out") 
	}
    }
    if (FNR == 8) start_time = $0


    if ($0 ~ /Length:/ && dler == "Wget") {
	length_out[i] = $2
    }
    if ($0 ~ /File\ size:/ && dler == "Axel") {
	length_out[i] = $3
    }
    if ($0 ~ /errorCode=8/ && dler == "Aria2") {
	error_code[i] = 8
    }
} 

END {
    progress()

    for (I=0; I<length(file_out); I++) {
	for (J=0; J<length(file_out); J++) {
	    ## cancella download di file con nome diverso per uno stesso link/url
	    if ((url_out[I] == url_out[J]) &&
		(file_out[I] != file_out[J]) &&
		(check_pid(pid_out[I]))) {
		system("rm -f .zdl_tmp/"file_out[J]"_stdout.tmp " file_out[J] " " file_out[J] ".st " file_out[J] ".aria2")
	    }
	}
    }

    print code
}
