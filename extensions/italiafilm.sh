#!/bin/bash -i


if [ "$url_in" != "${url_in//'italiafilm.tv'}" ]; then
    redir=$( wget "$url_in" -O - -q |grep dle-content ) #> 
    links_loop - "$url_in"

    url_in="${redir##*href=\"}"
    url_in="${url_in%%\"*}"
    links_loop + "$url_in"

fi
