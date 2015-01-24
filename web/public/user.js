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

  $('#imgLoader').on('change', function (e) {
    var imageFile = $(this)[0].files[0];
    var reader = new FileReader();
    reader.onload = function (e) {
      if (connected) {
        socket.emit('user input image', {
          imageDataURL: e.target.result
        });
      }
    };
    reader.readAsDataURL(imageFile);
  });

  $('#clearer').click(function(e) {
    if (connected) {
      socket.emit('user input clear', {});
    }
  });

  var drawing = false;

  $(document).on('mousedown', function (event) {
    if (connected) {
      drawing = true;
      socket.emit('user input touchdown', {
        userId: currentUser,
        x: event.pageX,
        y: event.pageY
      });
    };
  });

  $(document).on('mouseup', function (event) {
    if (connected) {
      drawing = false;
      socket.emit('user input touchup', {
        userId: currentUser
      });
    }
  });

  $(document).on('mousemove', function (event) {
    if (drawing && connected) {
      socket.emit('user input touchmove', {
        userId: currentUser,
        x: event.pageX,
        y: event.pageY,
      });
    }
  });
});
