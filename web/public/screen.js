$(function () {

  var socket = io();
  var users = [];
  // Socket events
  socket.emit('screen');

  // Whenever the server emits 'user joined', log it in the chat body
  socket.on('user joined', function (userId) {
    console.log('New user joined: ', userId.newUserId);
    users.push(userId);
  });

  socket.on('user input', function (data) {
    console.log(data);
  });
});
