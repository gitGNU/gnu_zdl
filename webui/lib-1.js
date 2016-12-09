var displayLinks = function (op) {
    var query = "cmd=get-data";

    if (op === "force")
        query += "&op=force";

    ajax({
        query: query,
        callback: function (str) {
            if (isJsonString(str)) {
                var data = JSON.parse(str);
                var output = "";
                var visibility = "hidden";
                var color;

                for (var i = 0; i < data.length; i++) {
                    if (ZDL.visible[data[i].path + "-" + data[i].link])
                        visibility = "visible";
                    else
                        visibility = "hidden";

                    output += "<div id='info-" + i + "-bar'>";

                    output += "<div id='progress-bar'>" +
                        "<div id='progress-label-file'>" + data[i].file + "</div>" +
                        "<div id='progress-status' style='width:" + data[i].percent + "%; background-color:" + data[i].color + "'></div>" +
                        "</div>";

                    output += "<div id='progress-label-status'>" +
                        data[i].percent + "% " +
                        parseFloat(data[i].speed).toFixed(2) + data[i].speed_measure + " " +
                        data[i].eta +
                        "</div>" +
                        "</div>";

                    output += "<div class='download-info " + visibility + "' id='info-" + i + "'>";

                    output += "<div class='label-element'>Downloader:</div>" +
			"<div class='element'><p>" + data[i].downloader + "</p></div>";

                    output += "<div class='label-element'>Link:</div>" +
			"<div class='element'><p>" + data[i].link + "</p></div>";

                    output += "<div class='label-element'>Path:</div>" +
			"<div class='element'><p>" + data[i].path + "</p>" +
			"<button class='btn' id='link-to-path-" + i + "'>Gestisci</button></div>";

                    output += "<div class='label-element'>File:</div>" +
			"<div class='element'><p>" + data[i].file + "</p><button class='btn' id='link-add-playlist-" + i + "'>Aggiungi alla playlist</button></div>";
		    
                    output += "<div class='label-element'>Length:</div>" +
			"<div class='element'><p>" + (data[i].length / 1024 / 1024).toFixed(2) +  "M</p></div>";

                    if (data[i].downloader.match(/^(RTMPDump|cURL)$/)) {
                        output += "<div class='label-element'>Streamer:</div>" +
                            "<div class='element'><p>" + data[i].streamer + "</p></div>";
                        output += "<div class='label-element'>Playpath:</div>" +
                            "<div class='element'><p>" + data[i].playpath + "</p></div>";
                    } else {
                        output += "<div class='label-element'>Url:</div>" +
                            "<div class='element'><p>" + toHtmlEntities(data[i].url) + "</p></div>";
                    }

                    output += "<div class='background-element align-center'>" + displayLinkButtons(i);
                    output += "</div></div>";
                }

                document.getElementById("output-links").innerHTML = output;

                for (var i = 0; i < data.length; i++) {
                    onClick({
                        id: "link-add-playlist-" + i,
                        callback: function (file) {
                            addPlaylist(file);
                        },
                        params: data[i].path + "/" + data[i].file
                    });

                    onClick({
                        id: "play-" + i,
                        callback: function (data) {
                            singleLink(data).play();
                        },
                        params: data[i]
                    });

                    onClick({
                        id: "del-" + i,
                        callback: function (data) {
                            if (confirm("Vuoi davvero cancellare il download del file " + data.file + " ?")) {
                                singleLink(data).del();
                            }
                        },
                        params: data[i]
                    });

                    onClick({
                        id: "stop-" + i,
                        callback: function (data) {
                            singleLink(data).stop();
                        },
                        params: data[i]
                    });

                    onClick({
                        id: "link-to-path-" + i,
                        callback: sectionPath,
                        params: data[i].path
                    });

                    onClick({
                        id: "info-" + i + "-bar",
                        callback: showInfoLink,
                        params: {
                            id: "info-" + i,
                            key: data[i].path + "-" + data[i].link
                        }
                    });

                    onClick({
                        id: "info-" + i,
                        callback: hideInfoLink,
                        params: {
                            id: "info-" + i,
                            key: data[i].path + "-" + data[i].link
                        }
                    });
                }

                return displayLinks();
            }

            document.getElementById("output-links").innerHTML = "";
            return displayLinks();
        }
    });
};
