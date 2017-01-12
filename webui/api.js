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

"use strict";

function ZDL(options) {
    this.path = options.path;
    this.file = options.file;

    function serve(query) {
        var promise = new Promise(function(resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", ZDL.file + query, true);
            xhr.send();
            xhr.onload = function() {
                if (this.status === 200) {
                    resolve(this.responseText);
                } else {
                    reject("Bad status");
                }
            };
            xhr.onerror = function() {
                reject("Server failure");
            };
        });
        return promise;
    }

    this.initClient = function() {
        return serve("?cmd=init-client&path=" + this.path);
    };

    this.getStatus = function(start) {
        var query = "?cmd=get-status&path=" + this.path;
        if (start) query += "&op=loop";
        return serve(query);
    };

    this.getData = function(start) {
        var query = "?cmd=get-data";
        if (start) query += "&op=force";
        return serve(query);
    };

    this.getFile = function(file) {
        return serve("?cmd=get-file&path=" + this.path + "&file=" + file);
    };

    this.getFreeSpace = function() {
        return serve("?cmd=get-free-space&path=" + this.path);
    };

    this.getHomePath = function() {
        return serve("?cmd=get-desktop-path");
    };

    this.getIP = function() {
        return serve("?cmd=get-ip");
    };

    this.addLink = function(link) {
        return serve("?cmd=add-link&path=" + this.path + "&link=" + link);
    };

    this.deleteFile = function(file) {
        return serve("?cmd=del-file&path=" + this.path + "&file=" + file);
    };

    this.cleanCompleted = function() {
        return serve("?cmd=clean-complete&path=" + this.path);
    };

    this.play = function(file) {
        return serve("?cmd=play-link&path=" + this.path + "&file=" + file);
    };

    this.setGlobal = function(key, value) {
        return serve("?cmd=set-conf&key=" + key + "&value=" + value);
    };

    this.setLocal = function(cmd, arg) {
        return serve("?cmd=" + cmd + "&path=" + this.path + "&" + arg);
    };

    this.startSocket = function(port) {
        return serve("?cmd=run-server&port=" + port);
    };

    this.killSocket = function(port) {
        return serve("?cmd=kill-server&port=" + port);
    };

    this.run = function() {
        return serve("?cmd=run-zdl&path=" + this.path);
    };

    this.quit = function() {
        return serve("?cmd=quit-zdl&path=" + this.path);
    };

    this.killServer = function(ports) {
        var args = "";
        ports.forEach(function(port) {
            args += "&port=" + port;
        });
        return serve("?cmd=kill-server" + args);
    };

    this.killAll = function() {
        return serve("?cmd=kill-all");
    };

    this.exitAll = function() {
        var that = this;
        return serve("?cmd=kill-all").then(function() {
            serve("?cmd=get-sockets").then(function(res) {
                that.killServer(JSON.parse(res));
            });
        });
    };

    this.reset = function() {
        serve("?cmd=reset-requests&path=" + this.path);
    };

    this.resetAccount = function() {
        serve("?cmd=reset-account");
    };
}

window.onbeforeunload = function () {
    ZDL.reset;
};
