
var load = function (method, url) {
    var req = new XMLHttpRequest();
    req.open(method, url, true);
    req.onload = function() {
    	if (req.status == 200) {
    	    return req.responseText;
		
    	} else {
    	    alert("Error " + req.status);
    	}
    };
    req.send();
}

var getData = function () {
    var json = load ('GET', '?cmd=get-data');
    return JSON.parse(json);
}

var printDeleteLink = function (id) {
    var data = getData();
    
    var output = "<form action=\"\" method=\"get\">";
    
    for (var i=0; i<data.length; i++) {
	output += "<input type=\"hidden\" name=\"cmd\" value=\"del-link\">";
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
