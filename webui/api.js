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
    'conf_items': [
	'downloader',
	'axel_parts',
	'aria2_connections',
	'max_dl',
	'background',
	'language',
	'reconnecter',
	'autoupdate',
	'player',
	'editor',
	'resume',
	'zdl_mode',
	'tcp_port',
	'udp_port',
	'socket_port',
	'browser'
    ]
};

String.prototype.toHtmlEntities = function() {
    return this.replace(/./gm, function(s) {
	return "&#" + s.charCodeAt(0) + ";";
    });
};

String.prototype.fromHtmlEntities = function(string) {
    return (string+"").replace(/&#\d+;/gm,function(s) {
	return String.fromCharCode(s.match(/\d+/gm)[0]);
    });
};

var cleanInput = function (str) {
    return str.replace(/(\r\n|\n|\r)/gm, "");
};

var getUriParam = function (name, url) {
    if (!url) url = location.href;
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regexS = "[\\?&]"+name+"=([^&#]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( url );
    return results == null ? null : results[1];
};

var isJsonString = function (str) {
    try {
	JSON.parse(str);
    } catch (e) {
	return false;
    }
    return true;
};

var load = function (method, url, async, callback, params) {
    var data;
    var req = new XMLHttpRequest();
    req.open(method, encodeURI(url), async);     // .replace("#", "%23")
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


var addLink = function (id) {
    var query = "?cmd=add-link&path=" + ZDL.path + "&link=" + encodeURIComponent(document.getElementById(id).value);
    document.getElementById(id).value = '';
    return load ('GET',
		 query,
		 true);
};

var cleanComplete = function () {
    var query = "?cmd=clean-complete&path=" + ZDL.path;
    return load ('GET',
		 query,
		 true);
		 // function () {
		 //     load ('GET', '?cmd=init-client&path=' + ZDL.path, true);
		 // });
};

var singleLink = function (spec) {
    var that = spec;

    var cmd_to_link = function (cmd) {
	return load ('GET',
		     "?cmd=" + cmd + "&path=" + that.path + "&link=" + that.link,
		     true);
    };
    
    that.stop = function () {
	return cmd_to_link('stop-link');
    };
    
    that.del = function () {
	return cmd_to_link ('del-link');
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

    that.setDownloader = function () {
	return load ('GET',
		     '?cmd=set-downloader&path=' + path + '&dowloader=' + document.getElementById('sel-downloader').value,
		     true);
    };


    that.getDownloader = function (repeat, op) {
	var query = '?cmd=get-downloader&path=' + path;

	if (op === 'force')
	    query += '&op=' + op;
	
	return load ('GET',
		     query,
		     true,
		     function (dler){
			 displayDownloader(dler);
			 
			 if (repeat)
			     singlePath(ZDL.path).getDownloader(true);
		     });
    };

    that.setMaxDownloads = function (spec) {
	var max_dl = document.getElementById('input-max-downloads').value;
	if (spec === 'no-limits')
	    max_dl = '';

	if (spec === 'no-limits' || !isNaN(parseInt(max_dl))) {
	    load ('GET',
		  '?cmd=set-max-downloads&path=' + path + '&number=' + max_dl,
		  true);
	} else {
	    alert("Immissione dati non valida: il limite massimo di downloads deve essere un numero");
	}
    };

    that.inputMaxDownloads = function (max_dl) {
	if (isNaN(max_dl))
	    max_dl = '';
	    
	var output = '<input id="input-max-downloads" type="number" value="' + max_dl + '" min="0" max="100">' +
		"<button onclick=\"singlePath(ZDL.path).setMaxDownloads();\">Invia</button>" +
		"<button onclick=\"singlePath(ZDL.path).setMaxDownloads('no-limits');\">Nessun limite</button>";
	return document.getElementById('max-downloads').innerHTML = output;
    };
	
    that.getMaxDownloads = function (repeat, op) {
	var query = '?cmd=get-max-downloads&path=' + path;

	if (op === 'force')
	    query += '&op=' + op;
	
	return load ('GET',
		     query,
		     true,
		     function (max_dl_str){
			 displayMaxDownloads (max_dl_str);
			 
			 if (repeat)
			     singlePath(ZDL.path).getMaxDownloads(true);
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
		     '?cmd=set-links&path=' + path + '&links=' + encodeURIComponent(document.getElementById('list-links').value),
		     true,
		     displayEditButton());
    };

    that.getRunStatus = function (repeat, op) {
	var query = '?cmd=get-status-run&path=' + path;

	if (op === 'force')
	    query += '&op=' + op;
	
	return load ('GET',
		     query,
		     true,
		     function (response) {
			 response = cleanInput(response);

			 if (response.match(/RELOAD/g)) {
			     singlePath(ZDL.path).getRunStatus(true, 'force');
			 }

			 if (response.match(/not-running/g)) {
			     displayStatus('not-running');
			 } else if (response.match(/running/g)) {
			     displayStatus('running');
			 }
			 
			 if (repeat)
			     singlePath(ZDL.path).getRunStatus(true);
		     });
    };
    
    return that;
};


var browseDir = function (path) {
    document.getElementById('run-path').setAttribute('class', 'hidden');
    path = path.replace(/[^/]+\/\.\.$/,'');

    var callback = function (dirs) {
	document.getElementById('sel-path').innerHTML = "<button onclick=\"selectDir('" + path + "');\">Seleziona:</button><div class=\"value\">" + path + "</div>";
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

var initClient = function (path) {
    load ('GET', '?cmd=init-client&path=' + path, true);
}

var selectDir = function (path) {
    ZDL.path = path;
    document.getElementById('run-path').setAttribute('class', 'visible');
    document.getElementById('sel-path').innerHTML = '<div class="label-element">Agisci in:</div><div class="value">' + path + '</div>' +
 	" <button onClick=\"browseDir('" + path + "');\">Cambia</button><br>";
    document.getElementById('browse').innerHTML = '';
    return initClient(path);
};

var runServer = function (port) {
    port = parseInt(port);

    if (isNaN(port) || port < 1024 || port > 65535 )
	alert('Porta non valida: deve essere un numero compreso tra 1024 e 65535');

    return load ('GET',
		 '?cmd=run-server&port=' + port,
		 true,
		 function (res) {
		     if (res.match(/already-in-use/g))
			 alert("Porta non valida: " + port + " è utilizzata da un'altra applicazione");
		     else
			 alert("Nuovo socket disponibile alla porta: " + port);
		 });
};

var getSockets = function (repeat, op) {
    var query = '?cmd=get-sockets';

    if (op === 'force')
	query += '&op=' + op;
    
    return load ('GET',
		 query,
		 true,
		 function (sockets){
		     if (sockets !== '') {			 
			 displaySockets(sockets.split('\n'));
			 	
			 if (repeat)
			     getSockets(true);
		     } else {
			 document.getElementById('list-sockets-open').innerHTML = '';
			 document.getElementById('list-sockets-kill').innerHTML = '';
		     }
		 });
};

var killServer = function (port) {
    port = parseInt(port);
    if (isNaN(port))
	port = document.location.port;

    port = parseInt(port);
    return load ('GET',
		 '?cmd=kill-server&port=' + port,
		 true);
};

var killAll = function () {
    return load ('GET', '?cmd=kill-all', true);
};


window.onbeforeunload = function () {
    load ('GET', '?cmd=reset-requests&path=' + ZDL.path, true);
};

// window.onfocus = function () {
//     initClient (ZDL.path);
// };


var getConf = function (repeat, op) {
    var query = '?cmd=get-conf';

    if (op === 'force')
	query += '&op=' + op;
    
    return load ('GET',
		 query,
		 true,
		 function (res) {
		     if (isJsonString(res)) {
			 displayConf(JSON.parse(res));
			 
			 if (repeat)
			     getConf(true);
		     }
		 });
};

var setConf = function (spec, value) {
    if (!value)
	value = document.getElementById('input-' + spec.id).value;
    
    if (spec.id.match(/^(axel_parts|aria2_connections|max_dl|tcp_port|udp_port|socket_port)$/)) {
	value = parseInt(value);
	if (isNaN(value) || value < spec.min || value > spec.max) {
	    return alert ('È richiesto un valore numerico compreso fra ' + spec.min + ' e ' + spec.max);
	}
    }

    load ('GET', "?cmd=set-conf&key=" + spec.id + '&value=' + value, true);	
};

var getStatus = function (repeat, op) {
    var query = '?cmd=get-status&path=' + ZDL.path;

    if (op === 'force')
	query += '&op=' + op;
    
    return load ('GET',
		 query,
		 true,
		 function (res) {
		     if (isJsonString(res)) {
			 var data = JSON.parse(res);

			 // data.status:
			 displayStatus(data.status);
			 
			 // data.downloader:
			 displayDownloader(data.downloader);
		
			 //data.maxDownloads;
			 displayMaxDownloads(data.maxDownloads);
			 
			 //data.conf:
			 displayConf(data.conf);
			 
			 //data.sockets:
			 displaySockets(data.sockets);
		     }

		     if (repeat)
			 getStatus(true);
		 });
};

var displayStatus = function (status) {
    if (status === 'not-running') {
	document.getElementById('path-status').innerHTML = '<button onclick="singlePath(ZDL.path).run();">Avvia ZDL</button>';
	
    } else if (status === 'running') {
	document.getElementById('path-status').innerHTML = '<button onclick="singlePath(ZDL.path).quit();">Termina ZDL</button>' +
	    '<button onclick="singlePath(ZDL.path).kill();">Termina ZDL e download</button>';			     
    }
};

var displayInputSelect = function (spec, id) {
    // spec = {id: options: value:}
    var output = '<select id="input-' + spec.id + "\" onchange=\"setConf(" + JSON.stringify(spec).replace(/\"/g, "'") + ");\">";

    spec.options.forEach(function(item){
	if (String(spec.value) === String(item))
	    output += "<option selected>";
	else
	    output += "<option>";
	output += item + "</option>";
    });

    document.getElementById(id).innerHTML = output;
};

var displayInputNumber = function (spec, id) {
    // spec = {id: value: min: max:}
    var output = '<input id="input-' + spec.id + '" type="number" value="' + spec.value + '" min="' + spec.min + '" max="' + spec.max + '">' +
		"<button onclick=\"setConf(" + JSON.stringify(spec).replace(/\"/g, "'") + ");\">Invia</button>" +
		"<button onclick=\"initClient(ZDL.path)\">Annulla</button>";

    document.getElementById(id).innerHTML = output;
};

var displayInputText = function (spec, id) {
    // spec = {id: value: min: max:}
    var output = '<input id="input-' + spec.id + '" type="text" value="' + spec.value + '">' +
		"<button onclick=\"setConf(" + JSON.stringify(spec).replace(/\"/g, "'") + ");\">Invia</button>" +
		"<button onclick=\"initClient(ZDL.path)\">Annulla</button>";

    document.getElementById(id).innerHTML = output;
};

var selectFile = function (id, path) {
    setConf({id: id}, path);
};

var browseFile = function (id, path) {
    // spec = {id: value:}
    
    return load ('GET',
		 '?cmd=get-file&path=' + path + '&id=' + id,
		 true,
		 function (res) {
		     var output = "<div class=\"value\"><b>Sfoglia da:</b> " + path + "</div>" +
			     "<button onclick=\"initClient(ZDL.path)\">Annulla</button><br>" +
			     res +
			     "<button onclick=\"initClient(ZDL.path)\">Annulla</button>";

		     document.getElementById('conf-' + id + '-file').style.width = '100%';
		     document.getElementById('conf-' + id + '-file').innerHTML = output;
		 });
};

var displayConf = function (conf) {
    Object.keys(conf).forEach(function(item){
	var spec = {
	    "id": item,
	    "value": cleanInput(conf[item])
	};	 

	switch(item) {
	case 'downloader':
	    if (!spec.options)
		spec.options = ['Aria2','Axel','Wget'];
	case 'background':
	    if (!spec.options)
		spec.options = ['transparent','black'];
	case 'language':
	    if (!spec.options)
		spec.options = ['it_IT.UTF-8'];
	case 'resume':
	case 'autoupdate':
	    if (!spec.options) {
		spec.options = ['enabled','disabled'];
		if (spec.value !== 'enabled')
		    spec.value = 'disabled';
	    }
	case 'zdl_mode':
	    if (!spec.options)
		spec.options = ['stdout','lite','daemon'];
	    
	    displayInputSelect (spec, 'conf-' + spec.id);
	    break;
	    
	case 'axel_parts':
	    if (isNaN(spec.min) || isNaN(spec.max)) {
		spec.min = 1;
		spec.max = 32;
	    }
	case 'aria2_connections':
	    if (isNaN(spec.min) || isNaN(spec.max)) {
		spec.min = 1;
		spec.max = 16;
	    }
	case 'max_dl':
	    if (isNaN(spec.min) || isNaN(spec.max)) {
		spec.min = 0;
		spec.max = 100;
	    }
	case 'tcp_port':
	case 'udp_port':
	case 'socket_port':
	    if (isNaN(spec.min) || isNaN(spec.max)) {
		spec.min = 1024;
		spec.max = 65535;
	    }

 	    var output = "<button onclick=\"displayInputNumber(" + JSON.stringify(spec).replace(/\"/g, "'") + ",'conf-" + spec.id + "');\">Cambia</button>";
	    document.getElementById('conf-' + spec.id).innerHTML = '<div class="value">' + spec.value + '</div>' + output;
	    break;

	case 'reconnecter':
	case 'player':
	case 'editor':
	case 'browser':
	    document.getElementById('conf-' + spec.id + '-file').innerHTML = '<div class="value">' + spec.value + '</div>' +
		"<button onclick=\"document.getElementById('conf-" + spec.id + "-text').style.display = 'none'; browseFile('" + spec.id +"', '" + ZDL.path + "');\">Sfoglia</button>";

	    document.getElementById('conf-' + spec.id + '-text').innerHTML = "<button onclick=\"" +
		"document.getElementById('conf-" + spec.id + "-file').style.display = 'none';" +		
		"displayInputText (" +
		JSON.stringify(spec).replace(/\"/g, "'") +
		", 'conf-" + spec.id + "-text');" +
		"\">Scrivi</button>";

	    document.getElementById('conf-' + spec.id + '-file').style.width = 'initial';
	    document.getElementById('conf-' + spec.id + '-file').style.display = 'initial';
	    document.getElementById('conf-' + spec.id + '-text').style.display = 'initial';
	};
    });    
}

var displaySockets = function (sockets) {
    var output_kill = '';
    var output_open = '';

    sockets.forEach(function (port) {
	port = parseInt(port);
	
	if(!isNaN(port)) {
	    output_open += "<button onclick=\"window.open('" +
		document.location.protocol + '//' + 
		document.location.hostname +
		':' + port +
		"');";
	    output_kill += '<button onclick="killServer(' + port + ');';
	    if(parseInt(port) === parseInt(document.location.port))
		output_kill += "setTimeout('document.location.reload(true)', 2000);"
	    output_open += '">' + port + '</button>';
	    output_kill += '">' + port + '</button>';
	}
    });
    document.getElementById('list-sockets-open').innerHTML = output_open;
    document.getElementById('list-sockets-kill').innerHTML = output_kill;
};

var displayDownloader = function (dler) {
    dler = dler.replace(/(\r\n|\n|\r)/gm, "");
    var selector = '<select id="sel-downloader" onchange="singlePath(ZDL.path).setDownloader();">';
    var label = '<div class="label-element">Downloader: </div>';
    
    ["Aria2", "Axel", "Wget"].forEach(function (item) {
	if (String(dler) === String(item)) {
	    selector += "<option selected>";
	    
	} else {
	    selector += "<option>"
	}
			     selector += item + "</option>";
    });
    
    selector += "</select>";
    document.getElementById('downloader').innerHTML = label + selector;    
};

var displayMaxDownloads = function (max_dl_str) {
    var output;
    var max_dl = parseInt(max_dl_str);
    
    if (isNaN(max_dl)) {
	max_dl_str = "illimitati";
	max_dl = '';
    }
    output = "<button onclick=\"singlePath(ZDL.path).inputMaxDownloads(" + max_dl + ");\">Cambia</button>";
    document.getElementById('max-downloads').innerHTML = '<div class="value">' + max_dl_str + '</div>' + output;
};

var displayEditButton = function () {
    document.getElementById('editor-links').innerHTML = '<button onclick="singlePath(ZDL.path).getLinks();">Editor dei link</button>';
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

		    output += "<div style=\"float: left; width: 100%;\" class=\"" + visibility + "\" id=\"info-" + i + "\"" + '</div><div ' +
			" onclick=\"hideInfoLink('info-" + i + "','" + data[i].path + "','" + data[i].link + "');\">";

		    output += '<div class="background-data"><div class="label-element">Downloader:</div><div class="value">' + data[i].downloader + "</div></div>";
		    output += '<div class="background-data"><div class="label-element">Link:</div><div class="value">' + data[i].link + "</div></div>";
		    output += '<div class="background-data"><div class="label-element">Path:</div><div class="value">' + data[i].path + "</div>";
		    output += "<button onclick=\"selectDir('" + data[i].path + "'); changeSection('path');\" style=\"float: left;\">Gestisci</button></div>";
		    output += '<div class="background-data"><div class="label-element">File: </div><div class="value">' + data[i].file + "</div></div>";

		    if (data[i].downloader.match(/^(RTMPDump|cURL)$/)) {
			output += '<div class="background-data"><div class="label-element">Streamer:</div><div class="value">' + data[i].streamer + "</div></div>";
			output += '<div class="background-data"><div class="label-element">Playpath:</div><div class="value">' + data[i].playpath + "</div></div>";
		    } else {
			output += '<div class="background-data"><div class="label-element">Url:</div><div class="value">' + data[i].url.toHtmlEntities() + "</div></div>";
		    }
		    output += '</div>';
		    output += displayButtonsLink(data[i]);
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

var displayButtonsLink = function (spec) {
    var output = "<button onclick=\"singleLink({path:'" + spec.path + "', link:'" + spec.link + "'}).stop();\">Ferma il download</button>" +
	    "<button onclick=\"singleLink({path:'" + spec.path + "', link:'" + spec.link + "'}).del();\">Cancella il download</button>";
    return output;
};


var init = function (path) {
    selectDir(path);
    changeSection('links');
    displayEditButton();
    displayLinks();
    // singlePath(ZDL.path).getMaxDownloads(true, 'force');
    // singlePath(ZDL.path).getDownloader(true, 'force');
    // singlePath(ZDL.path).getStatus(true, 'force');
    // getSockets(true, 'force');

    // getConf(true, 'force');
    getStatus(true, 'force');
};

