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
//  Gianluca Zoni
//  http://inventati.org/zoninoz
//  zoninoz@inventati.org

var ZDL = {
    "path": "",
    "pathDesktop": "",
    "visible": [],
    "webUI": ["1","1_flat","2","2_lite"]
};

var toHtmlEntities = function (str) {
    return str.replace(/./gm, function (s) {
        return "&#" + s.charCodeAt(0) + ";";
    });
};

var fromHtmlEntities = function (str) {
    return (str + "").replace(/&#\d+;/gm, function (s) {
        return String.fromCharCode(s.match(/\d+/gm)[0]);
    });
};

var objectToString = function (obj) {
    return JSON.stringify(obj);
};

var cleanInput = function (str) {
    return str.replace(/(\r\n|\n|\r)/gm, "");
};

var getUriParam = function (name, url) {
    if (!url) url = document.location.href;
    name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
    var regexS = "[\\?&]" + name + "=([^&#]*)";
    var regex = new RegExp(regexS);
    var results = regex.exec(url);
    return (results === null) ? null : results[1];
};

var isJsonString = function (str) {
    try {
        JSON.parse(str);
    } catch (e) {
        return false;
    }
    return true;
};

var ajax = function (spec) {
    // spec: {method,url,query,async,callback,params}

    if (!spec.method)
        spec.method = "GET";

    if (!spec.url)
        spec.url = "index.html";

    if (!spec.async)
        spec.async = true;

    if (spec.method === "GET" && spec.query) {
        spec.url += "?" + spec.query;
        spec.query = "";
    }

    var req = new XMLHttpRequest();

    req.open(spec.method,
        encodeURI(spec.url),
        spec.async);

    req.onload = function () {
        if (req.status === 200) {
            if (typeof spec.callback === "function") {
                spec.callback(req.responseText,
                    spec.params);
                return true;
            }

            if (getUriParam("cmd", spec.url) === "get-data") {
                ZDL.data = req.responseText;
            }

        } else if (req.status === 302) {
            window.location.replace("login.html");
        }
    };
    req.send(spec.query);
};

var getData = function () {
    ajax({
        query: "cmd=get-data",
        async: false
    });

    if (isJsonString(ZDL.data))
        return JSON.parse(ZDL.data);
    else
        return false;
};


var showInfoLink = function (spec) {
    document.getElementById(spec.id).setAttribute("class", "download-info visible");
    ZDL.visible[spec.key] = true;
};


var hideInfoLink = function (spec) {
    document.getElementById(spec.id).setAttribute("class", "hidden");
    ZDL.visible[spec.key] = false;
};


var cleanComplete = function () {
    ajax({
        query: "cmd=clean-complete&path=" + ZDL.path
    });
};

var singleLink = function (spec) {
    var that = spec;

    that.stop = function () {
        ajax({
            query: "cmd=stop-link&path=" + that.path + "&link=" + encodeURIComponent(that.link)
        });
    };

    that.del = function () {
        ajax({
            query: "cmd=del-link&path=" + that.path + "&link=" + encodeURIComponent(that.link)
        });
    };

    that.play = function () {
        ajax({
            query: "cmd=play-link&path=" + that.path + "&file=" + that.file,
            callback: function (res) {
                if (cleanInput(res) !== "running")
                    alert(res);
                else if (cleanInput(res) === "running" && document.location.hostname !== "localhost")
                    alert("Player avviato in " + document.location.hostname);
            }
        });
    };

    return that;
};


var singlePath = function (path) {
    var that = {};
    var data = {};

    var getByAttr = function (attr) {
        for (var i = 0; i < data.length; i += 1) {
            if (data[i].path === path) {
                return data[i][attr];
            }
        }
    };

    that.getFreeSpace = function () {
        ajax({
            query: "cmd=get-free-space&path=" + path,
            callback: function (res) {
                if (cleanInput(res))
                    document.getElementById("path-free-space").innerHTML = res;
            }
        });
    };

    that.reconnect = function (str) {
        var query = "cmd=reconnect&path=" + path;
        if (str)
            query += "&loop=" + str;

        ajax({
            query: query,
            callback: function (res) {
                alert(res);
            }
        });
    };

    that.setReconnecter = function (spec) {
        var value = document.getElementById("input-" + spec.key).value;

        if (value === "Mai")
            value = "false";
        else
            value = "true";

        ajax({
            query: "cmd=reconnect&path=" + path + "&set=" + value,
            callback: function (res) {
                if (cleanInput(res)) {
                    alert(res);
                    document.getElementById("input-reconnect").value = "Mai";
                }
            }
        });
    };

    that.getIP = function () {
        ajax({
            query: "cmd=get-ip",
            callback: function (res) {
                alert(res);
            }
        });
    };

    that.kill = function () {
        ajax({
            query: "cmd=kill-zdl&path=" + path
        });
    };

    that.quit = function () {
        ajax({
            query: "cmd=quit-zdl&path=" + path
        });
    };

    that.run = function () {
        ajax({
            query: "cmd=run-zdl&path=" + path
        });
    };

    that.setDownloader = function () {
        ajax({
            query: "cmd=set-downloader&path=" + path + "&dowloader=" + document.getElementById("sel-downloader").value
        });
    };

    that.getDownloader = function (repeat, op) {
        var query = "cmd=get-downloader&path=" + path;

        if (op === "force")
            query += "&op=" + op;

        ajax({
            query: query,
            callback: function (dler) {
                displayDownloader(dler);

                if (repeat)
                    singlePath(ZDL.path).getDownloader(true);
            }
        });
    };

    that.setMaxDownloads = function (spec) {
        var max_dl = document.getElementById("input-max-downloads").value;
        if (spec === "no-limits")
            max_dl = "";

        if (spec === "no-limits" || !isNaN(parseInt(max_dl))) {
            ajax({
                query: "cmd=set-max-downloads&path=" + path + "&number=" + max_dl
            });
        } else {
            alert("Immissione dati non valida: il limite massimo di downloads deve essere un numero");
        }
    };

    that.inputMaxDownloads = function (max_dl) {
        if (isNaN(max_dl))
            max_dl = "";

        var output = "<input id='input-max-downloads' type='number' value='" + max_dl + "' min='0' max='100'>" +
		"<button class='btn' onclick='singlePath(ZDL.path).setMaxDownloads();'>Invia</button>" +
        "<button class='btn' onclick='singlePath(ZDL.path).setMaxDownloads('no-limits');'>Nessun limite</button>" +
        "<button class='btn' onclick='initClient(ZDL.path);'>Annulla</button>";
        return document.getElementById("max-downloads").innerHTML = output;
    };

    that.getMaxDownloads = function (repeat, op) {
        var query = "cmd=get-max-downloads&path=" + path;

        if (op === "force")
            query += "&op=" + op;

        ajax({
            query: query,
            callback: function (max_dl_str) {
                displayMaxDownloads(max_dl_str);

                if (repeat)
                    singlePath(ZDL.path).getMaxDownloads(true);
            }
        });
    };

    that.getLinks = function () {
        ajax({
            query: "cmd=get-links&path=" + path,
            callback: function (str) {
                document.getElementById("editor-links").innerHTML = "<textarea class='edit-links' id='list-links'>" +
		    str +
		    "</textarea><div class='edit-links-buttons'>" +
                    "<button class='btn' onclick='singlePath(ZDL.path).setLinks();'>Salva</button>" +
                    "<button class='btn' onclick='displayEditButton();'>Annulla</button></div>";
            }
        });
    };

    that.setLinks = function () {
        ajax({
            query: "cmd=set-links&path=" + path + "&links=" + encodeURIComponent(document.getElementById("list-links").value),
            callback: function (res) {
                if (cleanInput(res)) {
                    alert("I seguenti link non sono stati accettati perché non validi o già presenti:\n" + res);
                }
                displayEditButton();
            }
        });
    };

    that.getRunStatus = function (repeat, op) {
        var query = "cmd=get-status-run&path=" + path;

        if (op === "force")
            query += "&op=" + op;

        ajax({
            query: query,
            callback: function (response) {
                response = cleanInput(response);

                if (response.match(/RELOAD/g)) {
                    singlePath(ZDL.path).getRunStatus(true, "force");
                }

                if (response.match(/not-running/g)) {
                    displayStatus("not-running");
                } else if (response.match(/running/g)) {
                    displayStatus("running");
                }

                if (repeat)
                    singlePath(ZDL.path).getRunStatus(true);
            }
        });
    };

    that.addLink = function (id, link) {
        if (link) {
            displayTorrentButton(id);
        } else {
            link = encodeURIComponent(document.getElementById(id).value.trim());
            document.getElementById(id).value = "";
        }

        ajax({
            query: "cmd=add-link&path=" + ZDL.path + "&link=" + link,
            callback: function (res) {
                if (cleanInput(res)) {
                    alert("Il seguente link non è stato accettato perché non valido o già presente:\n" + res);
                }
            }
        });
    };

    that.addXDCC = function (id) {
        // id: {host:,chan:,ctcp:}
        var host = encodeURIComponent(document.getElementById(id.host).value.trim());
        var chan = encodeURIComponent(document.getElementById(id.chan).value.trim());
        var ctcp = encodeURIComponent(document.getElementById(id.ctcp).value.trim());
        var errMsg = "";

        if (!host)
            errMsg += "\nIRC host";
        if (!chan)
            errMsg += "\nIRC channel";
        if (!ctcp)
            errMsg += "\nIRC msg/ctcp";

        if (errMsg) {
            return alert("Mancano le seguenti informazioni:\n" + errMsg);
        } else {
            ajax({
                query: "cmd=add-xdcc&path=" + path + "&host=" + host + "&chan=" + chan + "&ctcp=" + ctcp,
                callback: function (res) {
                    if (cleanInput(res)) {
                        alert("Il link xdcc non è stato aggiunto perché non valido o già presente, controlla i dati inviati:\n" + res);
                    } else {
                        document.getElementById(id.host).value = "";
                        document.getElementById(id.chan).value = "";
                        document.getElementById(id.ctcp).value = "";
                    }
                }
            });
        }
    };

    return that;
};


var changeSection = function (section) {
    ["path", "config", "info", "server", "playlist", "links"].forEach(function (item) {
        if (item === section) {
            document.getElementById(item).style.display = "block";
            document.getElementById(item + "-menu").setAttribute("class", "active");
        } else {
            document.getElementById(item).style.display = "none";
            document.getElementById(item + "-menu").setAttribute("class", "not-active");
        }
    });
};

var sectionPath = function (path) {
    setPath({
        path: path,
        idSel: "path-sel",
        idBrowser: "path-browser",
        callback: "setPath"
    });
    changeSection("path");
};

var initClient = function (path) {
    displayTorrentButton("path-torrent");
    displayPlaylistButton("playlist-browse");

    ajax({
        query: "cmd=init-client&path=" + path
    });
};

var runServer = function (port) {
    port = parseInt(port);

    if (isNaN(port) || port < 1025 || port > 65535)
        alert("Porta non valida: deve essere un numero compreso tra 1025 e 65535");

    ajax({
        query: "cmd=run-server&port=" + port,
        callback: function (res) {
            if (res.match(/already-in-use/g))
                alert("Porta non valida: " + port + " è utilizzata da un'altra applicazione");
            else
                alert("Nuovo socket disponibile alla porta: " + port);
        }
    });
};

var killServer = function (ports) {
    if (typeof ports !== "object") {
        ports = [];
        ports.push(document.location.port);
    }

    var query = "cmd=kill-server";

    ports.forEach(function (port) {
        port = parseInt(port);
        query += "&port=" + port;
    });

    ajax({
        query: query
    });

};

var killAll = function () {
    ajax({
        query: "cmd=kill-all"
    });
};

var exitAll = function () {
    if (confirm("Vuoi davvero terminare i download e le istanze di ZDL in tutti i path e chiudere tutti i socket?")) {
        killAll();

        ajax({
            query: "cmd=get-sockets",
            callback: function (res) {
                if (isJsonString(res)) {
                    var sockets = JSON.parse(res);
                    killServer(sockets);
                    window.setTimeout(reloadPage, 2000);
                }
            }
        });
    }
};

var getConf = function (repeat, op) {
    var query = "cmd=get-conf";

    if (op === "force")
        query += "&op=" + op;

    ajax({
        query: query,
        callback: function (res) {
            if (isJsonString(res)) {
                displayConf(JSON.parse(res));

                if (repeat)
                    getConf(true);
            }
        }
    });
};

var setConf = function (spec, value) {
    if (!value)
        value = document.getElementById("input-" + spec.key).value;

    if (spec.key.match(/^(axel_parts|aria2_connections|max_dl|tcp_port|udp_port|socket_port)$/)) {
        value = parseInt(value);
        if (isNaN(value) || value < spec.min || value > spec.max) {
            return alert("È richiesto un valore numerico compreso fra " + spec.min + " e " + spec.max);
        }
    }

    if (spec.key === 'web_ui' ) {
	var callback = function () {
	    reloadPage();
	}
    }
    
    ajax({
        query: "cmd=set-conf&key=" + spec.key + "&value=" + value,
	callback: callback
    });
};

var getStatus = function (repeat, op) {
    var query = "cmd=get-status&path=" + ZDL.path;

    if (op === "loop")
        query += "&op=" + op;

    ajax({
        query: query,
        callback: function (res) {
            if (isJsonString(res)) {
                var data = JSON.parse(res);

                displayStatus(data.status);
                displayDownloader(data.downloader);
                displayMaxDownloads(data.maxDownloads);
                displayReconnecter(data.reconnect, "path-reconnecter");
                displayConf(data.conf);
                displaySockets(data.sockets);
            }

            singlePath(ZDL.path).getFreeSpace();

            if (repeat)
                getStatus(true);
        }
    });
};

var displayStatus = function (status) {
    if (status === "not-running") {
        document.getElementById("path-status").innerHTML = "<button class='btn' onclick='singlePath(ZDL.path).run();'>Avvia ZDL</button>";

    } else if (status === "running") {
        document.getElementById("path-status").innerHTML = "<button class='btn' onclick='singlePath(ZDL.path).quit();'>Termina ZDL</button>" +
        "<button class='btn m-left' onclick='singlePath(ZDL.path).kill();'>Termina ZDL e download</button>";
    }
};

var displayReconnecter = function (value, id) {
    if (value === "enabled")
        value = "Ogni nuovo link";
    else
        value = "Mai";

    var spec = {
        "key": "reconnect",
        "value": value,
        "options": ["Ogni nuovo link", "Mai"]
    };

    displayInputSelect(spec, id, "singlePath(ZDL.path).setReconnecter");
};

var displayInputSelect = function (spec, id, callback) {
    // spec = {key: options: value:}
    var output = "<div class='btn-select'><select id='input-" + spec.key + "' onchange='" + callback + "(" + objectToString(spec) + ");'></div>";

    spec.options.forEach(function (item) {
        if (String(spec.value) === String(item))
            output += "<option selected>";
        else
            output += "<option>";
        output += item + "</option>";
    });

    document.getElementById(id).innerHTML = output;
};

var displayInputNumber = function (spec, id) {
    // spec = {key: value: min: max:}
    var output = "<input id='input-" + spec.key + "' type='number' value='" + spec.value + "' min='" + spec.min + "' max='" + spec.max + "'>" +
    "<button class='btn' onclick='setConf(" + objectToString(spec) + ");'>Invia</button>" +
    "<button class='btn' onclick='initClient(ZDL.path)'>Annulla</button>";

    document.getElementById(id).innerHTML = output;
};

var displayInputText = function (spec) {
    // spec = {idInput, idDiv, key, value, min, max, callback}
    var output = "<input id='" + spec.idInput + "' type='text' value='" + spec.value + "'>" +
        "<button class='btn' id='enter-" + spec.key + "'>Invia</button>" +
        "<button class='btn' onclick='initClient(ZDL.path)'>Annulla</button>";

    document.getElementById(spec.idDiv).innerHTML = output;
    onClick({
        id: "enter-" + spec.key,
        callback: spec.callback,
        params: spec
    });
};

var browseFile = function (spec) {
    // spec: {path,key,id,type,callback}
    spec.path = cleanPath(spec.path);

    var query = "cmd=browse&path=" + spec.path + "&id=" + spec.id + "&type=" + spec.type;
    if (spec.key)
        query += "&key=" + spec.key;

    ajax({
        query: query,
        callback: function (res) {
            var output = "<div class='open'>" +
                "<div class='value'><b>Sfoglia:</b> " + spec.path + "</div>" +
                "<button class='btn' onclick='initClient(ZDL.path)'>Chiudi</button>" +
                "<div class='value open'>" + res + "</div>" +
                "</div>";

            document.getElementById(spec.id).innerHTML = output;
            document.body.scrollTop = document.getElementById(spec.id).scrollHeight;
        }
    });
};

var browseDir = function (spec) {
    // spec:{path,idSel,idBrowser,callback}
    spec.path = cleanPath(spec.path);

    if (spec.callback === 'setPath')
	document.getElementById('run-path').setAttribute('class', 'hidden');

    ajax({
        query: "cmd=browse-dirs&path=" + spec.path + "&idsel=" + spec.idSel + "&idbrowser=" + spec.idBrowser + "&callback=" + spec.callback,
        callback: function (dirs) {
            var sel = document.getElementById(spec.idSel);

            if (!document.getElementById("path-prefix-" + spec.idSel)) {
                var newItem = document.createElement("DIV");
                newItem.id = "path-prefix-" + spec.idSel;
                newItem.setAttribute("class", "value path");
                newItem.innerHTML = "<b>Path:</b>";
                sel.parentElement.insertBefore(newItem, document.getElementById(spec.idSel));
            }

            sel.innerHTML = spec.path;

            var output = "<div class='browse-buttons'><button class='btn' id='button-select-" + spec.idSel + "'>Seleziona</button>" +
            "<button class='btn m-left' id='button-cancel-" + spec.idSel + "'>Annulla</button></div>";

            var browser = document.getElementById(spec.idBrowser);
            browser.innerHTML = output + "<div class='value browse'>" + dirs + "</div>";
	    browser.style.clear = 'both';
            document.body.scrollTop = document.getElementById(spec.idBrowser).scrollHeight;

            onClick({
                id: "button-select-" + spec.idSel,
                callback: function () {
                    document.getElementById(spec.idBrowser).innerHTML = "";
                    document.getElementById("path-prefix-" + spec.idSel).remove();
                    window[spec.callback](spec);
                }
            });

            onClick({
                id: "button-cancel-" + spec.idSel,
                callback: function () {
                    if (spec.callback === "setPath")
                        spec.path = ZDL.path;
                    else if (spec.callback === "setDesktopPath")
                        spec.path = ZDL.pathDesktop;

                    document.getElementById(spec.idBrowser).innerHTML = "";
                    document.getElementById("path-prefix-" + spec.idSel).remove();
                    window[spec.callback](spec);
                }
            });
        }
    });
};

var editDir = function (spec) {
    //alert(objectToString(spec));

    if (spec.callback === 'setPath')
	document.getElementById('run-path').setAttribute('class', 'hidden');

    var inputDiv = document.getElementById(spec.idSel);
    var buttonsDiv = document.getElementById(spec.idBrowser);

    inputDiv.innerHTML = "<input type='text' id='input-" + spec.idSel + "' value='" + inputDiv.textContent + "'/>";
    buttonsDiv.innerHTML = "<button class='btn' id='enter-" + spec.idSel + "'>Invia</button>" +
        "<button class='btn m-left' id='cancel-" + spec.idSel + "'>Annulla</button> ";

    inputDiv.setAttribute("class", "");

    onClick({
        id: "enter-" + spec.idSel,
        callback: function (params) {
            var path = cleanInput(document.getElementById("input-" + params.idSel).value);

            if (path) {
                ajax({
                    query: "cmd=check-dir&path=" + path,
                    callback: function (res, params) {
                        params.path = path;

                        if (cleanInput(res)) {
                            window[params.callback](params);
                        } else {
                            alert("Directory inesistente:\n" + params.path);
                        }
                    },
                    params: params
                });
            } else
                alert("Non è stata inserita alcuna directory");
        },
        params: spec
    });

    onClick({
        id: "cancel-" + spec.idSel,
        callback: function (params) {
            if (spec.callback === "setPath")
                params.path = ZDL.path;
            else if (spec.callback === "setDesktopPath")
                params.path = ZDL.pathDesktop;

            window[params.callback](params);
        },
        params: spec
    });
};

var displayDesktopPath = function (spec) {
    ajax({
        query: "cmd=get-desktop-path",
        callback: function (res) {
            if (res)
                spec.path = cleanInput(res);

            document.getElementById(spec.idSel).innerHTML = cleanPath(spec.path);

            document.getElementById(spec.idBrowser).innerHTML = "<button class='btn' id='button-browse-desktop'>Sfoglia</button>" +
                "<button class='btn m-left' id='button-edit-desktop'>Scrivi</button>";

	    document.getElementById(spec.idBrowser).style.clear = 'right';
            document.getElementById(spec.idSel).setAttribute("class", "value");

            onClick({
                id: "button-browse-desktop",
                callback: function () {
                    ZDL.pathDesktop = document.getElementById(spec.idSel).value;
                    browseDir(spec);
                }
            });

            onClick({
                id: "button-edit-desktop",
                callback: function () {
                    ZDL.pathDesktop = document.getElementById(spec.idSel).value;
                    editDir(spec);
                }
            });
        }
    });
};

var setDesktopPath = function (spec) {
    ajax({
        query: "cmd=set-desktop-path&path=" + spec.path,
        callback: function (res) {
            displayDesktopPath(spec);
        }
    });
};

var onClick = function (spec) {
    // spec: {id,callback,params:{}}
    if (!spec.params)
        spec.params = "";

    document.getElementById(spec.id).addEventListener("click",
        function (e) {
            spec.callback(spec.params);
            e.stopPropagation();
        },
        false);
};

var setPath = function (spec) {
    // spec:{path,idSel,idBrowser,callback}

    ZDL.path = spec.path;
    document.getElementById('run-path').setAttribute('class', 'visible');

    document.getElementById(spec.idSel).innerHTML = cleanPath(spec.path);
    document.getElementById(spec.idBrowser).innerHTML = "<button class='btn' id='button-browse-" + spec.idSel + "'>Sfoglia</button>" +
        "<button class='btn m-left' id='button-edit-" + spec.idSel + "'>Scrivi</button>";
    
    document.getElementById(spec.idBrowser).style.clear = 'right';
    document.getElementById(spec.idSel).setAttribute("class", "value");

    onClick({
        id: "button-browse-" + spec.idSel,
        callback: function () {
            browseDir(spec);
        }
    });

    onClick({
        id: "button-edit-" + spec.idSel,
        callback: function () {
            editDir(spec);
        }
    });

    return initClient(spec.path);
};

var cleanPath = function (path) {
    path = path.replace(/\/[^/]+\/\.\.$/, "");
    path = "/" + path.replace(/^\/+/, "");
    return path.replace(/^([/]{2}|\/[.]{2})/g, "/");
};

var displayConf = function (conf) {
    Object.keys(conf).forEach(function (item) {
        var spec = {
            "key": item,
            "value": cleanInput(conf[item])
        };

        switch (item) {
            case "web_ui":
                if (!spec.options)
                    spec.options = ZDL.webUI;
            case "conf_downloader":
                if (!spec.options)
                    spec.options = ["Aria2", "Axel", "Wget"];
            case "background":
                if (!spec.options)
                    spec.options = ["transparent", "black"];
            case "language":
                if (!spec.options)
                    spec.options = ["it_IT.UTF-8"];
            case "resume":
            case "autoupdate":
                if (!spec.options) {
                    spec.options = ["enabled", "disabled"];
                    if (spec.value !== "enabled")
                        spec.value = "disabled";
                }
            case "zdl_mode":
                if (!spec.options)
                    spec.options = ["stdout", "lite", "daemon"];

                displayInputSelect(spec, "conf-" + spec.key, "setConf");
                break;

            case "axel_parts":
                if (isNaN(spec.min) || isNaN(spec.max)) {
                    spec.min = 1;
                    spec.max = 32;
                }
            case "aria2_connections":
                if (isNaN(spec.min) || isNaN(spec.max)) {
                    spec.min = 1;
                    spec.max = 16;
                }
            case "max_dl":
                if (isNaN(spec.min) || isNaN(spec.max)) {
                    spec.min = 0;
                    spec.max = 100;
                }
            case "tcp_port":
            case "udp_port":
            case "socket_port":
                if (isNaN(spec.min) || isNaN(spec.max)) {
                    spec.min = 1025;
                    spec.max = 65535;
                }

                var output = "<button class='btn' onclick='displayInputNumber(" + objectToString(spec) + ", \"conf-" + spec.key + "\");'>Cambia</button>";

                document.getElementById("conf-" + spec.key).innerHTML = "<div class='value-number'>" + spec.value + "</div>" + output;
                break;

            case "reconnecter":
            case "player":
            case "editor":
            case "browser":
                var id_inputFile = "conf-input-file-" + spec.key;
                var inputFile = document.getElementById(id_inputFile);

                var id_inputText = "conf-" + spec.key + "-text";
                var inputText = document.getElementById(id_inputText);

                inputFile.innerHTML = "<div class='value'>" + spec.value + "</div>" +
                    "<button class='btn' id='conf-browse-file-" + spec.key + "'>Sfoglia</button>";

                inputFile.style.display = "initial";

                spec.id = id_inputFile;
                spec.callback = browseFile;
                spec.type = "executable";
                spec.path = ZDL.path;

                onClick({
                    id: "conf-browse-file-" + spec.key,
                    callback: function (params) {
                        document.getElementById(id_inputText).style.display = "none";
                        browseFile(params);
                    },
                    params: spec
                });

                inputText.innerHTML = "<button class='btn' id='conf-text-file-" + spec.key + "'>Scrivi</button>";
                inputText.style.display = "initial";

                spec.idDiv = id_inputText;
                spec.idHide = id_inputFile;
                spec.idInput = "input-" + spec.key;
                spec.callback = setConf;

                onClick({
                    id: "conf-text-file-" + spec.key,
                    callback: function (params) {
                        document.getElementById(params.idHide).style.display = "none";
                        displayInputText(params);
                    },
                    params: spec
                });
        };
    });
};

var reloadPage = function (page) {
    if (!page)
        page = window.location.pathname;
    window.location.href = page;
};

var displaySockets = function (sockets) {
    var output_kill = "";
    var output_open = "";

    sockets.forEach(function (port) {
        port = parseInt(port);

        if (!isNaN(port)) {
            output_open += "<button class='btn' onclick='window.open(\"" +
                document.location.protocol + "//" +
                document.location.hostname + ":" + port + "\");'>" + port + "</button>";

            output_kill += "<button class='btn' onclick='killServer([" + port + "]);";
            if (parseInt(port) === parseInt(document.location.port))
                output_kill += "setTimeout(reloadPage, 2000);"

            output_kill += "'>" + port + "</button>";
        }
    });
    document.getElementById("list-sockets-open").innerHTML = output_open;
    document.getElementById("list-sockets-kill").innerHTML = output_kill;
};

var displayDownloader = function (dler) {
    dler = dler.replace(/(\r\n|\n|\r)/gm, "");
    var selector = "<div class='btn-select'><select id='sel-downloader' onchange='singlePath(ZDL.path).setDownloader();'></div>";

    ["Aria2", "Axel", "Wget"].forEach(function (item) {
        if (String(dler) === String(item)) {
            selector += "<option selected>";

        } else {
            selector += "<option>"
        }
        selector += item + "</option>";
    });

    selector += "</select>";
    document.getElementById("downloader").innerHTML = selector;
};

var displayMaxDownloads = function (max_dl_str) {
    var output;
    var max_dl = parseInt(max_dl_str);

    if (isNaN(max_dl)) {
        max_dl_str = "illimitati";
        max_dl = "";
    }
    output = "<button class='btn' onclick='singlePath(ZDL.path).inputMaxDownloads(" + max_dl + ");'>Cambia</button>";
    document.getElementById("max-downloads").innerHTML = "<div class='value-number'>" + max_dl_str + "</div>" + output;
};

var displayEditButton = function () {
    document.getElementById("editor-links").innerHTML = "<button class='btn' onclick='singlePath(ZDL.path).getLinks();'>Apri</button>";
};


var displayLinkButtons = function (id) {
    if (document.location.hostname !== "localhost")
        var host = " in " + document.location.hostname;
    else
        var host = "";

    var output = "<button class='btn' id='stop-" + id + "'>Ferma</button>" +
            "<button class='btn' id='del-" + id + "'>Elimina</button>" +
            "<button class='btn' id='play-" + id + "'>Play" + host + "</button>";

    return output;
};

var displayTorrentButton = function (id) {
    document.getElementById(id).innerHTML = "<button class='btn' id='path-torrent-button'>Sfoglia</button>";

    onClick({
        id: "path-torrent-button",
        callback: function (params) {
            browseFile(params);
        },
        params: {
            id: id,
            path: ZDL.path,
            type: "torrent"
        }
    });
};

var displayPlaylistButton = function (id) {
    document.getElementById(id).innerHTML = "<button class='btn' id='playlist-browse-button'>Sfoglia</button>";

    onClick({
        id: "playlist-browse-button",
        callback: function (params) {
            browseFile(params);
        },
        params: {
            id: id,
            path: ZDL.path,
            type: "media"
        }
    });
};

var addPlaylist = function (file) {
    if (confirm("Vuoi aggiungere " + file + " alla playlist?")) {
        ajax({
            query: "cmd=add-playlist&file=" + file,
            callback: function (data) {
                //displayPlaylistButton("playlist-browse");
                if (cleanInput(data) === "Non è un file audio/video") {
                    alert(data);
                    getPlaylist("playlist-list");
                } else {
                    // data = [...]
                    displayPlaylist("playlist-list", data);
                }
            }
        });
    }
};

var delPlaylist = function (file) {
    if (confirm("Vuoi togliere " + file + " dalla playlist?")) {
        ajax({
            query: "cmd=del-playlist&file=" + file,
            callback: function (data) {
                displayPlaylist("playlist-list", data);
            }
        });
    }
};

var playMedia = function (media) {
    ajax({
        query: "cmd=play-playlist&file=" + media,
        callback: function (res) {
            if (cleanInput(res) !== "running")
                alert(res);
            else if (cleanInput(res) === "running" && document.location.hostname !== "localhost")
                alert("Player avviato in " + document.location.hostname);
        }
    });
};

var getPlaylist = function (id) {
    ajax({
        query: "cmd=get-playlist",
        callback: function (data) {
            displayPlaylist(id, data);
        }
    });
};

var displayPlaylist = function (id, data) {
    var output = "";
    if (isJsonString(data)) {
        var json = JSON.parse(data);

        json.forEach(function (file) {
            output += "<div class='background-element'><div class='label-element'>File:</div><div class='value'>" + file + "</div>";
            output += "<button class='btn pull-right m-left' onclick=\"delPlaylist('" + file + "')\">Togli</button>" +
		"<button class='btn pull-right' onclick=\"playMedia('" + file + "');\">Play</button></div>";
        });

    } else {
        output = "";
    }

    document.getElementById(id).innerHTML = output;
};

var displayFileButton = function (spec) {
    // spec: {id,file}
    var output = "<button class='btn' onclick='displayFileText(" + objectToString(spec) + ");'>" +
        "Leggi " + spec.file + "</button>";

    document.getElementById(spec.id).innerHTML = output;
};

var deleteFile = function (spec) {
    if (confirm("Vuoi davvero cancellare il file " + ZDL.path + "/" + spec.file + " ?")) {
        ajax({
            query: "cmd=del-file&path=" + ZDL.path + "&file=" + spec.file,
            callback: function (res) {
                displayFileButton(spec);
            }
        });
    }
};

var displayFileText = function (spec) {
    ajax({
        query: "cmd=get-file&path=" + ZDL.path + "&file=" + ZDL.path + "/" + spec.file,
        callback: function (res) {
            if (cleanInput(res)) {
                var id = "file-text-" + spec.file.replace(/\./g, "");

                var output = "<div class='file-text-name'>" +
                spec.file +
                "</div><div class='file-text' id='" +
                id +
                "'><p>" +
                res +
                "</p></div>";
                output += "<div class='file-text-buttons'><button class='btn' onclick='deleteFile(" + objectToString(spec) + ");'>Elimina</button>";
                output += "<button class='btn' onclick='displayFileText(" + objectToString(spec) + ")'>Aggiorna</button>";
                output += "<button class='btn' onclick='displayFileButton(" + objectToString(spec) + ");'>Chiudi</button></div>";


                var elemOuter = document.getElementById(spec.id);
                elemOuter.innerHTML = output;

                var elemInner = document.getElementById(id);
                elemInner.scrollTop = elemInner.scrollHeight;

            } else {
                alert("File " + spec.file + " non disponibile");
            }
        }
    });
};

var checkAccount = function () {
    ajax({
        url: "login.html",
        query: "cmd=check-account",
        callback: function (res) {
            if (cleanInput(res) === "exists") {
                var output = "<form action='/' method='POST'>" +
                    "<input type='hidden' name='cmd' value='login'>" +
                    "<table class='login'>" +
                    "<tr><td>Utente:</td>" +
                    "<td><input type='text' name='user' class='login'></td></tr>" +
                    "<tr><td>Password:</td>" +
                    "<td><input type='password' name='pass' class='login'></td></tr>" +
                    "<tr><td></td><td><input type='submit' value='Login'></td></tr></table>" +
                    "</form>";
            } else {
                var output = "<table class='login'>" +
                    "<tr><td>Utente:</td>" +
                    "<td><input id='user' type='text' name='user' class='login'></td></tr>" +
                    "<tr><td>Password:</td>" +
                    "<td><input id='pass1' type='password' name='pass1' class='login'></td></tr>" +
                    "<tr><td>Ripeti password:</td>" +
                    "<td><input id='pass2' type='password' name='pass2' class='login'></td></tr>" +
                    "<tr><td></td><td><button class='btn' onclick='createAccount();'>Crea un nuovo account</button></td></tr></table>";
            }

            document.getElementById("login").innerHTML = output;
            if (getUriParam("op") === "retry")
                alert("Login errato: riprova");
        }
    });
};

var createAccount = function () {
    var user = document.getElementById("user").value;
    var pass1 = document.getElementById("pass1").value;
    var pass2 = document.getElementById("pass2").value;

    if (!(user && pass1 && pass2)) {
        alert("Devi completare tutti i campi del form per eseguire l'operazione");
        return 0;
    } else if (pass1 !== pass2) {
        alert("L'immissione della password deve essere ripetuta identica");
        return 0;
    }

    ajax({
        method: "POST",
        url: "login.html",
        query: "cmd=create-account&user=" + user + "&pass=" + pass1,
        callback: function (res) {
            checkAccount();
        }
    });
};

var resetAccount = function () {
    ajax({
        query: "cmd=reset-account",
        callback: function () {
            reloadPage("login.html");
        }
    });
};

var init = function (path) {
    setPath({
        path: path,
        idSel: "path-sel",
        idBrowser: "path-browser",
        callback: "setPath"
    });
    changeSection("links");
    displayEditButton();
    displayTorrentButton("path-torrent");
    displayFileButton({
        id: "path-file-log",
        file: "zdl_log.txt"
    });
    displayFileButton({
        id: "path-file-links",
        file: "links.txt"
    });
    displayLinks("force");
    getStatus(true, "loop");

    document.getElementById("conf-account-socket").innerHTML = "<button class='btn' onclick='resetAccount();'>Reset account</button>";

    displayDesktopPath({
        idSel: "conf-sel-path",
        idBrowser: "conf-browser-path",
        callback: "setDesktopPath"
    });

    displayPlaylistButton("playlist-browse");
    getPlaylist("playlist-list");
};

window.onbeforeunload = function () {
    ajax({
        query: "cmd=reset-requests&path=" + ZDL.path
    });
};
