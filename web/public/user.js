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
});
