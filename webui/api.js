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

var load = function (method, url, async, callback, params) {
    var data;
    var req = new XMLHttpRequest();
    req.open(method, encodeURI(url), async);
    req.onload = function () {
    	if (req.status === 200) {
	    if (typeof callback === 'function') {
		callback(req.responseText, params);
		return true;
	    }
	    
	    switch (getUriParam('cmd', url)) {
	    case 'get-data':
		ZDL.data = req.responseText;
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


var display = function () {
    var that = {};
    
    var links = function (str) {
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
			"<div id=\"progress-bar\">" +
			"<div id=\"progress-label\">" + data[i].file.replace(/_/gm, ' ') + "</div>" +
			"<div id=\"progress-status\" style=\"width:" + data[i].percent + "%\"></div>" +
			"</div>" +
			"<div id=\"progress-label2\">" +
			data[i].percent + '% ' +
			data[i].speed + data[i].speed_measure + ' ' +
			data[i].eta +
			"</div>" +
			"</div>";

		    output += "<div class=\"" + visibility + "\" id=\"info-" + i + "\"" +
			" onclick=\"hideInfoLink('info-" + i + "','" + data[i].path + "','" + data[i].link + "');\">";

		    output += "Downloader: " + data[i].downloader + "<br>";
		    output += "Path: " + data[i].path + "<br>";
		    output += "Link: " + data[i].link + "<br>";

		    if (data[i].downloader.match(/^(RTMPDump|cURL)$/)) {
			output += "Streamer: " + data[i].streamer + "<br>";
			output += "Playpath: " + data[i].playpath + "<br>";
		    } else {
			output += "Url: " + data[i].url + "<br>";
		    }
		    
		    output += '</div>';
		}
		
		document.getElementById('out').innerHTML = output;
	    }
	    return true;
	}
	
	document.getElementById('out').innerHTML = '';
	return false;
    };

    that.links = function () {
	return load ('GET', '?cmd=get-data', true, links);
    };

    return that;
}

var displayLinks = function () {
    setInterval (display().links, 1000);
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
    var that = {};
    
    var cmd_to_link = function (cmd) {
	return load ('GET', "?cmd=" + cmd + "&path=" + spec.path + "&link=" + spec.link, true);
    };
    
    that.del = function () {
	return cmd_to_link('del-link');
    };
    
    that.stop = function () {
	return cmd_to_link ('stop-link');
    };

    return that;
};

var singlePath = function (path) {
    var that = {}

    var get = function (attr) {
	for (var i = 0; i<data.length; i += 1) {
	    if (data[i].path === path) {
		return data[i][attr];
	    }
	}
    };

    that.kill = function () {
	return load ('GET', '?cmd=kill-zdl&path=' + path, true);
    };

    that.quit = function () {
	return load ('GET', '?cmd=quit-zdl&path=' + path, true);
    };

    that.run = function () {
	return load ('GET', '?cmd=run-zdl&path=' + path, true);
    };

    that.getDownloader = function () {
	return load ('GET', '?cmd=get-downloader', false, get, 'downloader');
    };

    that.setDownloader = function (dler) {
	return load ('GET', '?cmd=set-downloader&dowloader=' + dler, true);
    };

    that.getMaxDownloads = function () {
	return load ('GET', '?cmd=max-downloads', false, get, 'max_downloads');
    };

    that.setMaxDownloads = function (num) {
	return load ('GET', '?cmd=set-max-downloads&number=' + num, true);
    };

    return that;
};

var browse = function (path) {
    document.getElementById('run-downloads').setAttribute('class', 'hidden');
    path = path.replace(/[^/]+\/\.\.$/,'');

    var callback = function (dirs) {
	document.getElementById('path').innerHTML = "<button onclick=\"selectDir('" + path + "');\">Seleziona:</button> " + path;
	document.getElementById('browse').innerHTML = dirs;
    };

    return load ('GET', '?cmd=get-dirs&path=' + path, true, callback);
};

var selectDir = function (path) {
    document.getElementById('run-downloads').setAttribute('class', 'visible');
    ZDL.path = path;
    document.getElementById('path').innerHTML = 'Agisci in: ' + path + " <button onClick=\"browse('" + path + "');\">Cambia</button><br>";
    document.getElementById('browse').innerHTML = '';
};

var killServer = function () {
    load ('GET', '?cmd=kill-server', true);
};

/**
 * Convert a string to HTML entities
 */
String.prototype.toHtmlEntities = function() {
    return this.replace(/./gm, function(s) {
	return "&#" + s.charCodeAt(0) + ";";
    });
};

/**
 * Create string from HTML entities
 */
String.fromHtmlEntities = function(string) {
    return (string+"").replace(/&#\d+;/gm,function(s) {
	return String.fromCharCode(s.match(/\d+/gm)[0]);
    });
};
