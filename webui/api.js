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

var ZDL = {
    'path': '',
    'visible': []
};

var setPath = function (path) {
    ZDL.path = path;
}

var getUriParam = function (name, url) {
    if (!url) url = location.href;
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regexS = "[\\?&]"+name+"=([^&#]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( url );
    return results == null ? null : results[1];
}

var load = function (method, url, async, callback) {
    var data;
    var req = new XMLHttpRequest();
    req.open(method, encodeURI(url), async);
    req.onload = function () {
    	if (req.status === 200) {
	    if (typeof callback === 'function') {
		callback(req.responseText);
		return true;
	    }
	    
	    switch (getUriParam('cmd', url)) {
	    case 'get-data':
		ZDL.data = req.responseText;
		break;
	    case 'get-dirs':
		ZDL.browse = req.responseText;
		break;
	    }

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
	return false;
}


var showInfoLink = function (id, path, link) {
    document.getElementById(id).setAttribute('class', 'visible');
    ZDL.visible[path + ' ' + link] = true;
}

var hideInfoLink = function (id, path, link) {
    document.getElementById(id).setAttribute('class', 'hidden');
    ZDL.visible[path + ' ' + link] = false;
}

var selectSingleLink = function (path, link) {
    var link = singleLink({'path': path, 'link': link});
    
}

var displayLinks = function (str) {
    //var data = getData();
    if (isJsonString(str)) {
	var data = JSON.parse(str);
	var output = '';
	var visibility = 'hidden';

	if (typeof data === 'object') {
	    for (var i=0; i<data.length; i++) {
		if (ZDL.visible[data[i].path + ' ' + data[i].link])
		    visibility = 'visible';
		else
		    visibility = 'hidden';
		
		output += '<div' +
		    " onblclick=\"selectSingleLink('" + data[i].path + "','" + data[i].link + "');\"" +
		    " onclick=\"showInfoLink('info-" + i + "','" + data[i].path + "','" + data[i].link + "');\">" +
		    data[i].file + ': ' + data[i].percent + '% ' + data[i].speed + data[i].speed_measure + ' ' + data[i].eta +
		    "</div>";

		output += "<div class=\"" + visibility + "\" id=\"info-" + i + "\"" +
		    " onclick=\"hideInfoLink('info-" + i + "','" + data[i].path + "','" + data[i].link + "');\">";

		for (var j in data[i]) {
     		    output += j + ": " + data[i][j] + "<br>";
 		}
		output += '</div>';
	    }
	    
	    document.getElementById('out').innerHTML = output;
	}
	return true;
    }
    
    document.getElementById('out').innerHTML = '';
    return false;
}

var display = function () {
    load ('GET', '?cmd=get-data', true, displayLinks);
}

var addLink = function (id) {
    var query = "?cmd=add-link&path=" + ZDL.path + "&link=" + document.getElementById(id).value;
    document.getElementById(id).value = '';
    return load ('GET', query, true);
}

var delLink = function (id) {
    var query = "?cmd=del-link&path=" + ZDL.path + "&link=" + document.getElementById(id).value;
    return load ('GET', query, true);
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
	return load ('GET', "?cmd=" + cmd + "&path=" + data.path + "&link=" + data.link, true);
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
	return load ('GET', '?cmd=set-downloader&dowloader=' + dler, true);
    }

    that.getMaxDownloads = function () {
	return max_downloads;
    }

    that.setMaxDownloads = function (num) {
	return load ('GET', '?cmd=set-max-downloads&number=' + num, true);
    }

    return that;
}

var browse = function (path) {
    document.getElementById('browse').innerHTML = 'Attendi...';
    load ('GET', '?cmd=get-dirs&path=' + path, false);
    path = path.replace(/[^/]+\/\.\.$/,'');
    document.getElementById('path').innerHTML = "<button onclick=\"selectDir('" + path + "');\">Seleziona:</button> " + path;
    document.getElementById('browse').innerHTML = ZDL.browse;
}

var selectDir = function (path) {
    // var script = '<script>start_path = "' + path + '";</script>';
    //document.getElementById('input-path').value = path;
    ZDL.path = path;
    document.getElementById('path').innerHTML = 'Scarica in: ' + path + " <button onClick=\"browse('" + path + "');\">Cambia</button><br>";
    document.getElementById('browse').innerHTML = '';
}

