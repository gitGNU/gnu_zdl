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
