// Setup basic express server
var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io')(server);
var port = process.env.PORT || 3000;

server.listen(port, function () {
  console.log('Server listening at port %d', port);
});

// Routing
app.use(express.static(__dirname + '/public'));

// Chatroom

// usernames which are currently connected to the chat
var usernames = {};
var currentUserId = 0;
var screen;

io.on('connection', function (socket) {
  socket.on('screen', function () {
    screen = socket;
    console.log('Screen has joined');
  });

  // when the client emits 'add user', this listens and executes
  socket.on('user join', function () {
    // add the client's username to the global list
    usernames[currentUserId] = currentUserId;
    socket.currentUserId = currentUserId;
    console.log('user join', currentUserId)
    io.sockets.emit('user joined', {
      newUserId: currentUserId
    });
    ++currentUserId;
  });

  socket.on('user input touchdown', function (data) {
    screen.emit('user input', data);
  });

  socket.on('user input touchup', function (data) {
    screen.emit('user input', data);
  });

  socket.on('user input touchmove', function (data) {
    screen.emit('user input', data);
  });

  socket.on('disconnect', function () {
    // remove the username from global usernames list
    delete usernames[socket.currentUserId];
  });
});
