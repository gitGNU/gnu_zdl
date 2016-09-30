var net = require('net');

var port = process.argv[2];

var portInUse = function(port, callback) {
    var server = net.createServer(function(socket) {
	socket.write('Echo server\r\n');
	socket.pipe(socket);
    });

    server.listen(port, '127.0.0.1');
    server.on('error', function (e) {
	callback(true);
    });
    server.on('listening', function (e) {
	server.close();
	callback(false);
    });
};

portInUse(port, function(returnValue) {
    process.exit(1 - returnValue);
});
