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
# Copyright (C) 2012
# Free Software Foundation, Inc.
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (project administrator and first inventor)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#


function restore_ffprefs {
    if [ -d "$path_conf/firefox" ]; then
	print_c 2 "Flashgot è stato disabilitato nella configurazione di $PROG: avvio del ripristino della configurazione di Flashgot."
	if [ -e "/cygdrive" ]; then
	    test_ff_alive=`ps -efW |grep firefox`
	else
	    test_ff_alive=`ps u -N -C grep |grep firefox` #ps aux |grep "firefox-bin"`
	fi
	if [ ! -z "$test_ff_alive" ]; then
	    echo
	    print_c 3 "Rilevata un'istanza attiva di Firefox: per procedere con il ripristino di Flashgot è necessario chiudere Firefox. Se non vuoi ripristinare la configurazione di Flashgot e lasciarlo abilitato per $PROG, puoi attivare Flashgot nella configurazione di $PROG, con il seguente comando: $prog --configure (oppure: $prog -c)"
	    echo
	    print_c 2 "Premi <invio> per continuare (se Firefox è ancora attivo, $PROG rimanderà il ripristino di Flashgot a un'altra volta)"
	    read
	fi
	
	if [ -e "/cygdrive" ]; then
	    test_ff_alive=`ps -efW |grep firefox`
	else
	    test_ff_alive=`ps u -N -C grep |grep firefox` #ps aux |grep "firefox-bin"`
	fi
	if [ -z "$test_ff_alive" ]; then
	    if [ -e "/cygdrive" ]; then
		print_c 2 "Attendere: ricerca dei file delle preferenze di Firefox in corso..."
		cygprefs=`find /cygdrive 2>/dev/null |grep Firefox |grep default/prefs.js |grep "/$USER/"`
	    fi
	    ls  "$path_conf"/firefox/ | while read file1; do
		file="${file1#${path_conf}\/firefox\/}"
		if [ -e "/cygdrive" ]; then
		    prepath=( $cygprefs )
		    prepath=( ${prepath%/*} )
		    prepath=( ${prepath%/*} )
		    file="${prepath[0]}/${file}"
		else
		    file="$HOME/.mozilla/firefox/${file}"
		fi
		file=${file//default_prefs.js/default\/prefs.js}
		cp "$path_conf"/firefox/"$file1" "$file" && echo "Ripristino di $file da \"$path_conf\"/firefox/$file1"
	    done
	    echo
	    print_c 1 "Le preferenze di Firefox sono state ripristinate da \"$path_conf\"/firefox/"
	    echo
	    rm -r "$path_conf/firefox" || print_c 3 "Impossibile il ripristino delle preferenze di Firefox: la directory \"$path_conf\"/firefox/ è inesistente"
	fi
    fi
}

function flashgot_autoconf {
    ## elenco preferenze di firefox:
    ##
    # user_pref("flashgot.custom", "ZigzagDownLoader,axel");
    # user_pref("flashgot.custom.ZigzagDownLoader.args", "--stream [URL] [FOLDER] [FNAME]");
    # user_pref("flashgot.custom.ZigzagDownLoader.exe", "/usr/local/bin/zdl");
    # user_pref("flashgot.defaultDM", "ZigzagDownLoader");
    # user_pref("flashgot.detect.cache", "(Incorporato nel browser),axel,ZigzagDownLoader");
    # user_pref("flashgot.media.dm", "ZigzagDownLoader");
    ##
    if [ -e "/cygdrive" ]; then	
	if [ ! -f "$path_conf"/ffprefs_path ]; then
	    print_c 2 "Attendere: ricerca dei file delle preferenze di Firefox in corso (può richiedere molti minuti)..."
			#cygprefs=`find /cygdrive 2>/dev/null |grep Firefox |grep default/prefs.js|grep "/$USER/"`
	    find /cygdrive 2>/dev/null |grep Firefox |grep default/prefs.js|grep "/$USER/" > "$path_conf"/ffprefs_path
	fi
	cygprefs=`cat "$path_conf"/ffprefs_path`
	test_flashgot=`cat "$cygprefs" | grep flashgot`
    else
	test_flashgot=`cat "$HOME"/.mozilla/firefox/*.default/prefs.js |grep flashgot`
    fi
    test_ZDL=`echo "$test_flashgot" | grep 'flashgot.custom"' |grep ZigzagDownLoader`
    ## test updates
    test_update_ZDL=`echo "$test_flashgot" | grep ZigzagDownLoader |grep '[REFERER]'`
    test_update1_ZDL=`echo "$test_flashgot" | grep ZigzagDownLoader |grep 'CFILE\]'`
    test_update2_ZDL=`echo "$test_flashgot" | grep ZigzagDownLoader |grep 'CFILE]\ '`

    if [ ! -z "$test_flashgot" ] && ( [ -z "$test_ZDL" ] || [ "$test_ZDL" != "${test_ZDL//'",ZigzagDownLoader"'}" ] || [ -z "$test_update_ZDL" ] || [ ! -z "$test_update1_ZDL" ] || [ ! -z "$test_update2_ZDL" ] ); then
	print_c 1 "Rilevata la presenza di Flashgot: configurazione automatica per l'uso di $PROG, attendi..."
	if [ -e "/cygdrive" ]; then
	    test_ff_alive=`ps -efW |grep firefox`
	else
	    test_ff_alive=`ps u -N -C grep |grep firefox` #ps aux |grep "firefox-bin"`
	fi
	if [ ! -z "$test_ff_alive" ]; then
	    echo
	    print_c 3 "Rilevata un'istanza attiva di Firefox: per procedere con la configurazione automatica di Flashgot per l'uso di $PROG è necessario chiudere Firefox. Se non vuoi configurare Flashgot per $PROG, puoi disattivare Flashgot nella configurazione di $PROG, con il seguente comando: $prog --configure (oppure: $prog -c)"
	    echo
	    print_c 2 "Premi <invio> per continuare (se Firefox è ancora attivo, $PROG rimanderà la configurazione automatica di Flashgot a un'altra volta)"
	    read
	fi
	
	if [ -e "/cygdrive" ]; then
	    test_ff_alive=`ps -efW |grep firefox`
	    path_ffprefs="$cygprefs"
	else
	    test_ff_alive=`ps u -N -C grep |grep firefox` #ps aux |grep "firefox-bin"`
	    path_ffprefs=`ls "$HOME"/.mozilla/firefox/*.default/prefs.js`
	fi
	
	if [ -z "$test_ff_alive" ]; then
	## save old prefs
	    if [ ! -d "$path_conf/firefox/" ];then
		mkdir "$path_conf/firefox/"
		
		echo -e "$path_ffprefs" | while read file1; do
		    file="${file1//default\/prefs.js/default_prefs.js}"
		    file="${file##*\/}"
		    cp "$file1" "$path_conf/firefox/$file"
		    echo "Copia di $file1: \"$path_conf\"/firefox/$file"
		done
		echo
		print_c 1 "Configurazione automatica di Flashgot: le precedenti preferenze di Firefox sono state salvate in \"$path_conf\"/firefox/ per un eventuale ripristino."
		echo
	    fi
	    
	## set flashgot config
	    echo -e "$path_ffprefs" | while read file; do
		for key in 'flashgot.custom\"' 'flashgot.custom.ZigzagDownLoader.args' 'flashgot.custom.ZigzagDownLoader.exe' 'flashgot.defaultDM' 'flashgot.detect.cache' 'flashgot.media.dm'; do
		    
		    firefox_pref=`cat "$file" |grep $key`
		    case $key in
			'flashgot.custom\"')
			    values="${firefox_pref#'user_pref(\"flashgot.custom\", \"'}"
		    values="${values%'\");'}"
			    values="${values//,ZigzagDownLoader}"
			    if [ ! -z "${values}" ]; then
				values="${values},"
			    fi
			    new_pref="user_pref(\"flashgot.custom\", \"${values}ZigzagDownLoader\");"
			    ;;
			'flashgot.custom.ZigzagDownLoader.args')
			    new_pref="user_pref(\"flashgot.custom.ZigzagDownLoader.args\", \"--stream [URL] [FNAME] [FOLDER] [CFILE] [COOKIE] [REFERER]\");"
			    ;; 
			'flashgot.custom.ZigzagDownLoader.exe')
			    path_zdl=`which $prog`
			    new_pref="user_pref(\"flashgot.custom.ZigzagDownLoader.exe\", \"$path_zdl\");"
			    if [ -e "/cygdrive" ]; then
				new_pref="user_pref(\"flashgot.custom.ZigzagDownLoader.exe\", \"$(cygpath -m /)\\\zdl.bat\");"
			    fi
			    ;; 
			'flashgot.defaultDM')
			    new_pref="user_pref(\"flashgot.defaultDM\", \"ZigzagDownLoader\");"
			    ;; 
			'flashgot.detect.cache')
			    values="${firefox_pref#'user_pref(\"flashgot.detect.cache\", "'}"
		    values="${values%'");'}"
			    values="${values//,ZigzagDownLoader}"
			    new_pref="user_pref(\"flashgot.detect.cache\", \"${values},ZigzagDownLoader\");"
			    ;; 
			'flashgot.media.dm')
			    new_pref="user_pref(\"flashgot.media.dm\", \"ZigzagDownLoader\");"
			    ;;
		    esac
		    
		    if [ -z "${firefox_pref}" ]; then
			echo "${new_pref}" >> "$file"
		    else
			firefox_pref="${firefox_pref//[/\[}"
			firefox_pref="${firefox_pref//]/\]}"
			sed -i "s@${firefox_pref}@${new_pref}@g" $file
		    fi
		done
	    done
	fi
    fi

}
