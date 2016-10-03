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
    'visible': [],
    'downloader': '',
    'max_downloads': ''
};

var getUriParam = function (name, url) {
    if (!url) url = location.href;
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regexS = "[\\?&]"+name+"=([^&#]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( url );
    return results == null ? null : results[1];
};

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
};


var isJsonString = function (str) {
    try {
	JSON.parse(str);
    } catch (e) {
	return false;
    }
    return true;
};

var getData = function () {
    load ('GET', '?cmd=get-data', false);
    if (isJsonString(ZDL.data))
	return JSON.parse(ZDL.data);
    else
	return false;
};

var showInfoLink = function (id, path, link) {
    document.getElementById(id).setAttribute('class', 'visible');
    ZDL.visible[path + ' ' + link] = true;
};

var hideInfoLink = function (id, path, link) {
    document.getElementById(id).setAttribute('class', 'hidden');
    ZDL.visible[path + ' ' + link] = false;
};


var displayLinks = function () {
    return load ('GET', '?cmd=get-data', true, function (str) {
	if (isJsonString(str)) {
	    var data = JSON.parse(str);
	    var output = '';
	    var visibility = 'hidden';
	    var color;
	    
	    if (typeof data === 'object') {
		for (var i=0; i<data.length; i++) {
		    if (ZDL.visible[data[i].path + ' ' + data[i].link])
			visibility = 'visible';
		    else
			visibility = 'hidden';
		    
		    output += '<div' +
			" onclick=\"showInfoLink('info-" + i + "','" + data[i].path + "','" + data[i].link + "');\">" +
			"<div id=\"progress-bar\">" +
			"<div id=\"progress-label-file\">" + data[i].file + "</div>" +
			"<div id=\"progress-status\" style=\"width:" + data[i].percent + "%; background-color:" + data[i].color + "\"></div>" +
			"</div>" +
			"<div id=\"progress-label-status\">" +
			data[i].percent + '% ' +
			data[i].speed + data[i].speed_measure + ' ' +
			data[i].eta +
			"</div>" +
			"</div>";

		    output += "<div style=\"float: left; width: 100%;\" class=\"" + visibility + "\" id=\"info-" + i + "\"" +
			" onclick=\"hideInfoLink('info-" + i + "','" + data[i].path + "','" + data[i].link + "');\">";

		    output += "<div class=\"info-label\"> Downloader: </div><div class=\"info-data\"> " + data[i].downloader + "</div>";
		    output += "<div class=\"info-label\"> Link: </div><div class=\"info-data\"> " + data[i].link + "</div>";
		    output += "<div class=\"info-label\"> Path: </div><div class=\"info-data\"> " + data[i].path + "</div>";
		    output += "<div class=\"info-label\"> File: </div><div class=\"info-data\"> " + data[i].file + "</div>";

		    if (data[i].downloader.match(/^(RTMPDump|cURL)$/)) {
			output += "<div class=\"info-label\"> Streamer: </div><div class=\"info-data\"> " + data[i].streamer + "</div>";
			output += "<div class=\"info-label\"> Playpath: </div><div class=\"info-data\"> " + data[i].playpath + "</div>";
		    } else {
			output += "<div class=\"info-label\"> Url: </div><div class=\"info-data\"> " + data[i].url.toHtmlEntities() + "</div>";
		    }

		    output += addButtonsLink();
		    output += '</div>';
		}
		
		document.getElementById('output-links').innerHTML = output;
	    }
	    return displayLinks();
	}
	
	document.getElementById('output-links').innerHTML = '';
	return displayLinks();
    });
};

var addButtonsLink = function () {
    return "<button>Varie funzioni da implementare</button>";
};

var addLink = function (id) {
    var query = "?cmd=add-link&path=" + ZDL.path + "&link=" + document.getElementById(id).value;
    document.getElementById(id).value = '';
    return load ('GET', query, true);
};

var delLink = function (id) {
    var query = "?cmd=del-link&path=" + ZDL.path + "&link=" + document.getElementById(id).value;
    return load ('GET', query, true);
};

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
    var that = {};
    var data = {};

    var getByAttr = function (attr) {
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

    that.getDownloader = function (recursive) {
	return load ('GET',
		     '?cmd=get-downloader&path=' + path,
		     true,
		     function (dler){
			 dler = dler.replace(/(\r\n|\n|\r)/gm, "");
			 ZDL.downloader = dler;
			 var selector = '<select id="sel-downloader" onchange="singlePath(ZDL.path).setDownloader();">';

			 ["Aria2", "Axel", "Wget"].forEach(function (item) {
			     if (String(dler) === String(item)) {
				 selector += "<option selected>";

			     } else {
				 selector += "<option>"
			     }
			     selector += item + "</option>";
			 });
			 
			 selector += "</select>";
			 document.getElementById('downloader').innerHTML = selector;

			 if (typeof recursive === 'function')
			     return recursive(recursive);
		     });
    };

    that.setDownloader = function () {
	return load ('GET',
		     '?cmd=set-downloader&path=' + path + '&dowloader=' + document.getElementById('sel-downloader').value,
		     true,
		     function (){
			 that.getDownloader();
		     });
    };

    that.setMaxDownloads = function (spec) {
	var max_dl = document.getElementById('input-max-downloads').value;
	if (spec === 'no-limits')
	    max_dl = '';

	if (spec === 'no-limits' || !isNaN(parseInt(max_dl))) {
	    load ('GET',
		  '?cmd=set-max-downloads&path=' + path + '&number=' + max_dl,
		  true,
		  function (){
		      that.getMaxDownloads();
		  });
	} else {
	    alert("Immissione dati non valida: il limite massimo di downloads deve essere un numero");
	    that.getMaxDownloads();
	}
    };

    that.inputMaxDownloads = function (max_dl) {
	if (isNaN(max_dl))
	    max_dl = '';
	    
	var output = "<input id=\"input-max-downloads\" type=\"text\" value=\"" + max_dl + "\">" +
		"<button onclick=\"singlePath(ZDL.path).setMaxDownloads();\">Invia</button>" +
		"<button onclick=\"singlePath(ZDL.path).setMaxDownloads('no-limits');\">Nessun limite</button>";
	return document.getElementById('max-downloads').innerHTML = output;
    };
	
    that.getMaxDownloads = function (recursive) {
	return load ('GET',
		     '?cmd=get-max-downloads&path=' + path,
		     true,
		     function (max_dl_str){
			 var output;
			 var max_dl = parseInt(max_dl_str);

			 if (isNaN(max_dl)) {
			     max_dl_str = "illimitati";
			     max_dl = '';
			 }
			 ZDL.max_downloads = max_dl; 			 

			 output = " <button onclick=\"singlePath(ZDL.path).inputMaxDownloads(" + max_dl + ");\">Cambia MAX</button>";
			 document.getElementById('max-downloads').innerHTML =  max_dl_str + output;

			 if (typeof recursive === 'function')
			     return recursive(recursive);
		     });
    };

    that.getLinks = function () {
	return load ('GET',
		     '?cmd=get-links&path=' + path,
		     true,
		     function (str){
			 document.getElementById('editor-links').innerHTML = "<textarea id=\"list-links\">" + str + "</textarea>" +
			     "<button onclick=\"singlePath(ZDL.path).setLinks();\">Salva</button>" +
			     "<button onclick=\"displayEditButton();\">Annulla</button>";
		     });
    };
    
    that.setLinks = function () {
	return load ('GET',
		     '?cmd=set-links&path=' + path + '&links=' + document.getElementById('list-links').value,
		     true,
		     displayEditButton());
    };

    return that;
};

var displayEditButton = function () {
    document.getElementById('editor-links').innerHTML = "<button onclick=\"singlePath(ZDL.path).getLinks();\">Editor dei link</button>";
};

var browse = function (path) {
    document.getElementById('run-path').setAttribute('class', 'hidden');
    path = path.replace(/[^/]+\/\.\.$/,'');

    var callback = function (dirs) {
	document.getElementById('sel-path').innerHTML = "<button onclick=\"selectDir('" + path + "');\">Seleziona:</button> " + path;
	document.getElementById('browse').innerHTML = dirs;
    };

    return load ('GET', '?cmd=get-dirs&path=' + path, true, callback);
};

var changeSection = function (section) {
    ['links', 'path', 'config', 'info', 'server'].forEach(function(item) {
	if (item === section) {
	    document.getElementById(item).style.display = 'block';
	    document.getElementById(item + '-menu').setAttribute('class', 'active');
	} else {
	    document.getElementById(item).style.display = 'none';
	    document.getElementById(item + '-menu').setAttribute('class', 'not-active');
	}
    });
};

var selectDir = function (path) {
    document.getElementById('run-path').setAttribute('class', 'visible');
    ZDL.path = path;
    document.getElementById('sel-path').innerHTML = '<div class="label-element">Agisci in:</div> ' + path +
	" <button onClick=\"browse('" + path + "');\">Cambia</button><br>";
    document.getElementById('browse').innerHTML = '';
};

var killServer = function () {
    return load ('GET', '?cmd=kill-server', true);
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

var checkData = function () {
    load ('GET', '?cmd=get-downloader&path=' + ZDL.path, true, function (dler) {
	dler = dler.replace(/(\r\n|\n|\r)/gm, "");
	if (dler !== ZDL.downloader)
	    singlePath(ZDL.path).getDownloader();
    });

    load ('GET', '?cmd=get-max-downloads&path=' + ZDL.path, true, function (str) {
	var max_dl = parseInt(str);
	if (isNaN(max_dl))	
	    max_dl = '';
	
	if (max_dl !== ZDL.max_downloads)
	    singlePath(ZDL.path).getMaxDownloads();
    });
};

var display = function () {
    selectDir(ZDL.path);
    changeSection('links');
    displayEditButton();
    displayLinks();
    singlePath(ZDL.path).getMaxDownloads(singlePath(ZDL.path).getMaxDownloads);
    singlePath(ZDL.path).getDownloader(singlePath(ZDL.path).getDownloader);
};

var init = function (path) {
    ZDL.path = path;
    load ('GET', '?cmd=init-client', true);
    display();
};

