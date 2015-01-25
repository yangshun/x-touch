$(function () {
  var currentUser;
  var connected = false;
  var socket = io();
  var mode = 'drag';

  socket.emit('user join');
  socket.on('user joined', function (payload) {
    if (!connected) {
      currentUser = payload.newUserId;
      console.log('You are', currentUser);
      connected = true;
    }
  });

  $('#toggle').click(function (e) {
    socket.emit('show image', {});
  });

  $('#imgLoader').on('change', function (e) {
    var imageFile = $(this)[0].files[0];
    var reader = new FileReader();
    reader.onload = function (e) {
      if (connected) {
        socket.emit('add image', {
          imageDataURL: e.target.result
        });
      }
    };
    reader.readAsDataURL(imageFile);
  });

  $('#clearer').click(function(e) {
    if (connected) {
      socket.emit('canvas clear', {});
    }
  });

  var drawing = false;

  $(document).on('mousedown', function (event) {
    if (connected) {
      drawing = true;
      socket.emit(mode + ' touchdown', {
        userId: currentUser,
        x: event.pageX / window.innerWidth,
        y: event.pageY / window.innerHeight
      });
    };
  });

  $(document).on('mouseup', function (event) {
    if (connected) {
      drawing = false;
      socket.emit(mode + ' touchup', {
        userId: currentUser
      });
    }
  });

  $(document).on('mousemove', function (event) {
    if (drawing && connected) {
      socket.emit(mode + ' touchmove', {
        userId: currentUser,
        x: event.pageX / window.innerWidth,
        y: event.pageY / window.innerHeight
      });
    }
  });
});
