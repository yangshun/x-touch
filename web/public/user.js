$(function () {
  var currentUser;
  var connected = false;
  var socket = io();

  socket.emit('user join');
  socket.on('user joined', function (payload) {
    if (!connected) {
      currentUser = payload.newUserId;
      console.log('You are', currentUser);
      connected = true;
    }
  });

  $('.js-update').click(function () {
    if (connected) {
      socket.emit('user input', {
        userId: currentUser,
        x: 3,
        y: 4,
      });
    }
  });

  var drawing = false;

  $(document).on('mousedown', function (event) {
    drawing = true;
    socket.emit('user input touchdown', {
      userId: currentUser,
      x: event.pageX,
      y: event.pageY
    });
  });

  $(document).on('mouseup', function (event) {
    drawing = false;
    socket.emit('user input touchup', {
      userId: currentUser
    });
  });

  $(document).on('mousemove', function (event) {
    if (drawing) {
      socket.emit('user input touchmove', {
        userId: currentUser,
        x: event.pageX,
        y: event.pageY,
      });
    }
  });
});
