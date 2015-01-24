$(function () {

  var canvas = new fabric.Canvas('drawing_board', {
    backgroundColor: 'rgb(255,255,224)',
    height: window.innerWidth * 0.75,
    width: window.innerWidth
  });
  var socket = io();
  var users = [];
  // Socket events
  socket.emit('screen');

  // Whenever the server emits 'user joined', log it in the chat body
  socket.on('user joined', function (userId) {
    console.log('New user joined: ', userId.newUserId);
    users.push({ key: userId.newUserId, value: null });
  });

  var circle = new fabric.Circle({
    radius: 100,
    left: 100,
    top: 100,
    fill: 'red'
  });
  canvas.add(circle);

  fabric.Object.prototype.containsPoint = function(point) {
    var horiz_in = point.x >= this.getLeft() && point.x <= this.getLeft() + this.getWidth();
    var vert_in = point.y >= this.getTop() && point.y <= this.getTop() + this.getHeight();
    return horiz_in && vert_in;
  };

  socket.on('user input touchdown', function (data) {
    var point = new fabric.Point(data.x, data.y);
    canvas.getObjects().forEach(function (obj) {
      if (obj.containsPoint(point)) {
        users[data.userId] = obj;
      }
    });
  });

  socket.on('user input touchmove', function (data) {
    var target = users[data.userId];
    if (target) {
      target.set({
        left: data.x - target.getWidth() / 2,
        top: data.y - target.getHeight() / 2
      });
      canvas.renderAll();
    }
  });

  socket.on('user input touchup', function (data) {
    users[data.userId] = null;
  })

});
