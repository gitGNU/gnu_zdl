:: ZigzagDownLoader (ZDL)
:: 
:: This program is free software: you can redistribute it and/or modify it 
:: under the terms of the GNU General Public License as published 
:: by the Free Software Foundation; either version 3 of the License, 
:: or (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful, 
:: but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
:: or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License 
:: along with this program. If not, see http://www.gnu.org/licenses/. 
:: 
:: Copyright (C) 2012
:: Free Software Foundation, Inc.
:: 
:: For information or to collaborate on the project:
:: https://savannah.nongnu.org/projects/zdl
:: 
:: Gianluca Zoni
:: http://inventati.org/zoninoz
:: zoninoz@inventati.org


@echo off
set url=%2
set fname="%3"
set folder="%4"
set cfile="%5"
set cookie=%6
set referer=%7

start \cygwin\bin\mintty.exe -t ZigzagDownLoader -s 140,50 -e \cygwin\bin\bash.exe --login -i -c 'zdl --stream %url% %fname% %folder% %cfile% %cookie% %referer%'

exit
