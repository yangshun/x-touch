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

  socket.on('drag touchdown', function (data) {
    var point = new fabric.Point(data.x * canvas.width, data.y * canvas.height);
    objs = canvas.getObjects();
    for (var i = objs.length - 1; i >= 0; i--) {
      if (objs[i].containsPoint(point)) {
        users[data.userId] = objs[i];
        objs[i].bringToFront();
        break;
      }
    };
  });

  socket.on('drag touchmove', function (data) {
    var target = users[data.userId];
    if (target) {
      target.set({
        left: data.x * canvas.width - target.getWidth() / 2,
        top: data.y * canvas.height - target.getHeight() / 2
      });
      canvas.renderAll();
    } else {
      var point = new fabric.Circle({
        radius: 20,
        fill: 'green',
        left: data.x * canvas.width,
        top: data.y * canvas.height
      });
      canvas.add(point);
    }
  });

  socket.on('drag touchup', function (data) {
    users[data.userId] = null;
  });

  socket.on('add image', function (data) {
    fabric.Image.fromURL(data.imageDataURL, function(img) {
      img.left = 200;
      img.top = 1000;
      img.scale(600 / img.getHeight());
      canvas.add(img);
      img.bringToFront();
      img.animate('top', '-=800', {
        onChange: canvas.renderAll.bind(canvas),
        duration: 600,
        easing: fabric.util.ease.easeOutExpo
      });
      var angle = Math.floor(Math.random() * 10) - 5;
      img.animate('angle', angle, {
        onChange: canvas.renderAll.bind(canvas),
        duration: 200,
        easing: fabric.util.ease.easeOutExpo
      });
    });
  });

  socket.on('canvas clear', function (data) {
    canvas.clear();
  });

  // socket.on('draw touchmove', function (data) {
  //   var point = new fabric.Circle({
  //     radius: 20,
  //     fill: 'green',
  //     left: data.x * canvas.width,
  //     top: data.y * canvas.height
  //   });
  //   canvas.add(point);
  //   console.log(data);
  // });

});
