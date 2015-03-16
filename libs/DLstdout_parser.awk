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
   code=code type"["i"]=\""value"\"; "
}

function seconds_to_human (seconds,         minutes, hours) {
    minutes = int(seconds/60)
    hours = int(minutes/60)
    minutes = minutes - (hours * 60)
    seconds = seconds - (minutes * 60) - (hours * 60 * 60)
    return hours "h" minutes "m" seconds "s"
}

function progress_out (value) {
    ## eta, %, speed, speed type, length-saved (length-out)

    if (dler == "Axel") {
	for (y=n; y>0; y--) {
	    if (chunk[y] ~ /[\%]+/) {
		progress_line = chunk[y]
		split(progress_line, progress_elems, /[\ ]*[\%]*[K]*/)
		percent_out[i] = progress_elems[2]
		if (speed_out[i]) break
	    } 
	    if (chunk[y] ~ /[K]+/) {
		progress_line = chunk[y]
		split(progress_line, progress_elems, /[\ ]*[\%]*[K]*/)
		speed_out[i] = progress_elems[length(progress_elems)-1]
		if (percent_out[i]) break
	    }
	}

	if (progress_line) {
	    speed_out_type[i] = "KB/s"
	    ## mancano ancora (secondi):
	    if (speed_out[i] > 0) {
		eta_out[i] = int(((length_out[i] / 1024) * (100 - percent_out[i]) / 100) / speed_out[i])
		eta_out[i] = seconds_to_human(eta_out[i])
	    }
	    length_saved[i] = int((length_out[i] * percent_out[i]) / 100)
	    system("cp .zdl_tmp/"file_out[i]"_stdout.tmp .zdl_tmp/"file_out[i]"_stdout.tmp.z")
	} else {
	    ## giallo: sostituire ciò che segue con un sistema di recupero dati precedenti (barra di colore giallo)
	    percent_out[i] = 0
	    speed_out[i] = 0
	    speed_out_type[i] = "KB/s"
	    ## mancano ancora (secondi):
	    eta_out[i] = ""
	    length_saved[i] = 0
	}
    } else if (dler == "Wget") {
	for (y=n; y>0; y--) {
	    if (chunk[y] ~ /[%]+.+(K|M|B)/) {
		progress_line = chunk[y]
		break
	    }
	}

	if (progress_line) {
	    split(progress_line, progress_elems, /[\ ]*[\%]*/)
	    percent_out[i] = progress_elems[8]
	    speed_out[i] = progress_elems[10]
	    eta_out[i] = progress_elems[11]
	    if (speed_out[i] ~ /B/) speed_out_type[i]="B/s"
	    if (speed_out[i] ~ /K/) speed_out_type[i]="KB/s"
	    if (speed_out[i] ~ /M/) speed_out_type[i]="MB/s"
	    sub(/[BKM]/, "", speed_out[i])
	    length_saved[i] = size_file(file_out[i])
	    if (! length_saved[i]) length_saved[i] = 0
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
	    if (chunk[y] ~ /\([0-9]+/) {
		progress_line = chunk[y]
		break
	    }
	}

	if (progress_line) {
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
	}
    } else if (dler == "cURL") {
	for (y=n; y>0; y--) {
	    if (chunk[y] ~ /[0-9]+/) {
		progress_line = chunk[y]
		break
	    }
	}
        if (progress_line) {
	    split(progress_line, progress_elems, /[\ ]*/)
	    speed_out[i] = int(progress_elems[length(progress_elems)])
	    speed_out_type[i] = "KB/s"
	    length_saved[i] = size_file(file_out[i])
	    length_out[i] = 0

	}
    }
    array_out(speed_out[i], "speed_out")
    array_out(speed_out_type[i], "speed_out_type")
    array_out(eta_out[i], "eta_out")
    array_out(length_saved[i], "length_saved")
    array_out(percent_out[i], "percent_out")
}

function progress () {
    ## estrae le ultime n righe e le processa con progress_out()
    for(k=0;k<n;k++) {
	chunk[k] = progress_data[++j%n]
	delete progress_data[j%n]
    }
    progress_out(chunk)
    delete chunk
    j=0
}

BEGIN {
    i=0
    j=0
    n=20
}

{
    if (FNR == 1) {
	if (j>n) {
	    ## progress_out
	    progress()
	    i++
	}
	array_out($0, "pid_out")
    }

    progress_data[++j%n] = $0

    if (FNR == 2) array_out($0, "url_out")
    if (FNR == 3) {
	dler = $0
	array_out(dler, "downloader_out")
    }
    if (FNR == 4) array_out($0, "pid_prog_out")
    if (FNR == 5) {
	file_out[i] = $0
	array_out(file_out[i], "file_out")
    }
    if (FNR == 6) {
	if (dler ~ /Axel|Wget/) array_out($0, "url_out_file")
	if (dler ~ /RTMPDump|cURL/) array_out($0, "streamer_out")
    }
    if (FNR == 7) {
	if (dler ~ /RTMPDump|cURL/) array_out($0, "playpath_out")
	if (dler == "Axel") array_out($0, "axel_parts_out")
    }
    if (FNR == 8) start_time = $0

    if ($0 ~ /Content-Length:/ && dler == "Wget") {
	length_out[i] = $2
	code = code "length_out["i"]=\"" length_out[i] "\"; "
    }
    if ($0 ~ /File\ size:/ && dler == "Axel") {
	length_out[i] = $3
	code = code "length_out["i"]=\"" length_out[i] "\"; "
    }
} 

END {
    progress()
    print code
}
