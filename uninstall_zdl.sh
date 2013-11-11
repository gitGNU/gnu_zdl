#!/bin/bash -i

function usage {
    Uso: /usr/local/share/zdl/uninstall_zdl.sh [--purge] [-h|--help]
}

option=$1
if [ "$option" == "--help" ] || [ "$option" == "-h" ]; then
    usage
    exit
else
    read -p "Vuoi davvero disinstallare ZigzagDownLoader? [sì|*]" result
    if [ "$result" == "sì" ]; then
	if [ "$option" == "--purge" ]; then
	    rm -rf $HOME/.zdl
	fi
	rm -rf /usr/local/bin/zdl /usr/local/share/zdl /zdl.bat && echo "ZigzagDownLoader disinstallato" || echo "ZigzagDownLoader NON è stato disinstallato"
    fi
fi
