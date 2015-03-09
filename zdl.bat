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
:: Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
:: 
:: For information or to collaborate on the project:
:: https://savannah.nongnu.org/projects/zdl
:: 
:: Gianluca Zoni (author)
:: http://inventati.org/zoninoz
:: zoninoz@inventati.org


@echo off

if "%~1" == "--stream" (
	start /high {{{CYGDRIVE}}}:\cygwin\bin\mintty.exe -t ZigzagDownLoader -s 160,50 -e {{{CYGDRIVE}}}:\cygwin\bin\bash.exe --login -i -c 'zdl --stream "%~2" "%~3" "%~4" "%~5" "%~6" "%~7"'
) else (
	start /high {{{CYGDRIVE}}}:\cygwin\bin\mintty.exe -t ZigzagDownLoader -s 160,50 -e {{{CYGDRIVE}}}:\cygwin\bin\bash.exe --login -i -c 'zdl "%~1"'
)



