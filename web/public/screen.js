$(function () {

  var canvas = new fabric.Canvas('drawing_board', {
    backgroundColor: 'rgb(255,255,224)',
    height: window.innerHeight,
    width: window.innerWidth
  });
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
    var point = new fabric.Circle({
      radius: 20,
      fill: 'blue',
      left: data.x,
      top: data.y
    });
    canvas.add(point);
  });

});
