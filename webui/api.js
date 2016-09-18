//  ZigzagDownLoader (ZDL)
//  
//  This program is free software: you can redistribute it and/or modify it 
//  under the terms of the GNU General Public License as published 
//  by the Free Software Foundation; either version 3 of the License, 
//  or (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful, 
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License 
//  along with this program. If not, see http://www.gnu.org/licenses/. 
//  
//  Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
//  
//  For information or to collaborate on the project:
//  https://savannah.nongnu.org/projects/zdl
//  
//  Gianluca Zoni (author)
//  http://inventati.org/zoninoz
//  zoninoz@inventati.org
// 

var ZDL = {};

var load = function (method, url, async = true) {
    var data;
    var req = new XMLHttpRequest();
    req.open(method, url, async);
    req.onload = function() {
    	if (req.status === 200) {
	    if (async === false)
		ZDL.data = req.responseText;

    	} else {
    	    alert("Error " + req.status);
    	}
    };
    req.send();
}

var isJsonString = function (str) {
    try {
	JSON.parse(str);
    } catch (e) {
	return false;
    }
    return true;
}

var getData = function () {
    load ('GET', '?cmd=get-data', false);
    if (isJsonString(ZDL.data))
	return JSON.parse(ZDL.data);
    else
	return ZDL.data;
}

var printDeleteLink = function (id) {
    var data = getData();
    
    var output = "<form action=\"\" method=\"get\">";
    output += "<input type=\"hidden\" name=\"cmd\" value=\"del-link\">";
    
    for (var i=0; i<data.length; i++) {
	output += "<input type=\"hidden\" name=\"path\" value=\"" + data[i]["path"] + "\">";
	output += "<br><hr><br><input type=\"checkbox\" name=\"link\" value=\"" + data[i]["link"] + "\">";
	
	for (var j in data[i]) {
    	    output += j + ": " + data[i][j] + "<br>----<br>";
	}
    }
    output += "<input type=\"submit\" name=\"submit\" value=\"Elimina\">";
    output += "</form>";
    
    document.getElementById(id).innerHTML = output;
}

var printAddLink = function (id) {
    var output;
    document.getElementById(id).innerHTML = output;
}

var addLink = function (spec) {
    // spec = {path: ..., link: ...}
    return load ('?cmd=add-link&path=' + spec.path + '&link=' + spec.link);
}

var singleLink = function (spec) {
    // spec = {path: ..., link: ...}
    var data = getData();
    var that = {};
    
    for (var i = 0; i<data.length; i += 1) {
	if (data[i].path === spec.path && data[i].link === spec.link ) {
	    that = data[i];
	    break;
	}
    }

    var cmd_to_link = function (cmd) {
	return load ('GET', "?cmd=" + cmd + "&path=" + data.path + "&link=" + data.link);
    }
    
    that.delLink = function () {
	return cmd_to_link('del-link');
    }
    that.stopLink = function () {
	return cmd_to_link ('stop-link');
    }

    return that;
}

var singlePath = function (path) {
    var data = getData();
    var pid, downloader, max_downloads;
    var that = {}
    
    for (var i = 0; i<data.length; i += 1) {
	if (data[i].path === path) {
	    pid = data[i].pid_instance;
	    downloader = data[i].downloader;
	    max_downloads = data[i].max_downloads;
	    break;
	}
    }

    that.getPid = function () {
	return pid;
    }

    that.getDownloader = function () {
	return downloader;
    }

    that.setDownloader = function (dler) {
	return load ('GET', '?cmd=set-downloader&dowloader=' + dler);
    }

    that.getMaxDownloads = function () {
	return max_downloads;
    }

    that.setMaxDownloads = function (num) {
	return load ('GET', '?cmd=set-max-downloads&number=' + num);
    }

    return that;
}

