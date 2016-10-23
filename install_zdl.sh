#!/bin/bash -i

DIR="$PWD"
path_usr="/usr/local/share/zdl"
path_tmp=".zdl_tmp"

PROG=ZigzagDownLoader
prog=zdl
BIN="/usr/local/bin"
SHARE="/usr/local/share/zdl"
URL_ROOT="http://download.savannah.gnu.org/releases/zdl/"

## from: http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
cygaxel_url="http://www.inventati.org/zoninoz/html/upload/files/axel-2.4-1.tar.bz2" 
success="Installazione completata"
failure="Installazione non riuscita"
path_conf="$HOME/.$prog"
file_conf="$path_conf/$prog.conf"
installer_zdl="true"

if [[ -z "$(grep 'shopt -s checkwinsize' $HOME/.bashrc)" ]]
then
    echo "shopt -s checkwinsize" >> ~/.bashrc 
fi

mkdir -p "$path_conf/extensions"

if [ ! -f "$file_conf" ]
then
    echo "# ZigzagDownLoader configuration file" > "$file_conf"
fi

if [ -e /cygdrive ]
then
    win_home=$(cygpath -u "$HOMEDRIVE$HOMEPATH")
    win_progfiles=$(cygpath -u "$PROGRAMFILES")
fi
cygdrive=$(realpath /cygdrive/?/cygwin 2>/dev/null)
[ -z "$cygdrive" ] && cygdrive=$(realpath /cygdrive/?/Cygwin 2>/dev/null)
cygdrive="${cygdrive#*cygdrive\/}"
cygdrive="${cygdrive%%\/*}"
[ -z "$cygdrive" ] && cygdrive="C"



## funzioni per Cygwin
function get-mirror {
    mirror=$(grep 'last-mirror' /etc/setup/setup.rc -A 1 | tail -n1)
}

function pkt-download {
    cscript /nologo downloader_tmp.js $1 $2 2>/dev/null
}

function last-pkt {
    path_pkt=$(grep "\@ $1$" -A 15 <<< "$setup"| grep install |head -n1 | awk '{print $2}')
    echo ${path_pkt##*\/}
}

function init {
    get-mirror
    pkt-download $mirror/x86/setup.bz2 setup.bz2
    setup=$(bzcat setup.bz2)
    unset pkts
}

function cygwinports {
    mirror=ftp://ftp.cygwinports.org/pub/cygwinports
    wget $mirror/x86/setup.bz2
    setup=$(bzcat setup.bz2)
    unset pkts
}

function required-pkt {
    if [[ ! "${pkts[*]}" =~ $1 ]]
    then 
	pkts[${#pkts[*]}]="$1"
    fi

    dep_pkt=$(grep "\@ $1$" -A 15 <<< "$setup"| grep requires |head -n1)
    for p in ${dep_pkt#* }
    do
	if [ ! -f /etc/setup/$p.lst.gz ]
	then
	    required-pkt $p
	fi
    done
}

## Axel - Cygwin
function install_axel-cygwin {
    if ! command -v axel &>/dev/null
    then
	cd /
	wget "$cygaxel_url"
	tar -xvjf "${cygaxel_url##*'/'}"
	cd -
    fi
}
################


function bold {
    echo -e "\e[1m$1\e[0m"
}



##############################################
echo "Installazione di ZigzagDownLoader (ZDL)"
##############################################

mkdir -p "$path_conf/src"
cd "$path_conf/src"
rm *.tar.gz* $prog -rf

echo "Download in corso: attendere..."

if [ -e /cygdrive ]
then
    cd /tmp

    echo -e 'var WinHttpReq = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
WinHttpReq.Open("GET", WScript.Arguments(0), /*async=*/false);
WinHttpReq.Send();
//WScript.Echo(WinHttpReq.ResponseText);

BinStream = new ActiveXObject("ADODB.Stream");
BinStream.Type = 1;
BinStream.Open();
BinStream.Write(WinHttpReq.ResponseBody);
BinStream.SaveToFile(WScript.Arguments(1));' > downloader_tmp.js 

    if ! command -v wget &>/dev/null
    then
	echo -e "
Installazione di Wget
...attendi...

"
	init
	required-pkt wget

	for p in ${pkts[*]}
	do
	    echo "Installing $p..."
	    last-pkt $p
	    tarball=${path_pkt##*\/}
	    pkt-download $mirror/$path_pkt $tarball

	    cd /
	    [ "$tarball" != "${tarball%.xz}" ] && tar -xvJf /tmp/$tarball
	    [ "$tarball" != "${tarball%.bz2}" ] && tar -xvjf /tmp/$tarball
	    cd /tmp
	done

	cd /tmp
	rm -f downloader_tmp.js setup.bz2 *.tar.*
    fi

fi

#wget "$URL_ROOT" -r -l 1 -A sig,txt -np -nd -q
#wget -q "http://download-mirror.savannah.gnu.org/releases/zdl/zdl-2.0.tar.gz"
#wget -q "http://download-mirror.savannah.gnu.org/releases/zdl/zdl-2.0.tar.gz.sig"

rm -f zdl-2.0.tar.gz.sig zdl-2.0.tar.gz
while [ ! -f zdl-2.0.tar.gz ]
do
    wget -q "http://download-mirror.savannah.gnu.org/releases/zdl/zdl-2.0.tar.gz" -O zdl-2.0.tar.gz 
    
    if [ ! -f zdl-2.0.tar.gz ]
    then
	echo "Problemi di connessione: se non dovesse risolversi, chiudi il programma con <Control+c>"
	sleep 1
    fi
done

package="zdl-2.0.tar.gz"

#cp *.sig "$path_conf/"

date +%s >"$path_conf/version"

#package=$(ls *.tar.gz)
tar -xzf "$package"

rm -fr "$prog"
mv "${package%.tar.gz}" $prog
cd $prog

chmod +rx -R .

## UPDATER ########
background=black
source libs/core.sh
source ui/widgets.sh
source ui/ui.sh
source updater.sh

update
###################

## Axel
if [ -e "/cygdrive" ]
then
    install_axel-cygwin
fi

cd "$DIR"
rm -fr "$path_conf/src"

print_c 4 "Per informazioni su ZigzagDownLoader (zdl):"
print_c 0 "\tzdl --help
\tman zdl
\tpinfo zdl
\tinfo zdl
"
print_c 4 "http://nongnu.org/zdl"

exit
