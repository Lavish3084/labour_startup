const socketIO = require('socket.io');

let io;

module.exports = {
  init: (server) => {
    io = socketIO(server, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST']
      }
    });

    io.on('connection', (socket) => {
      console.log(`[Socket] New connection: ${socket.id}`);

      // Users/Workers join a room specific to a booking
      socket.on('join_booking', (bookingId) => {
        socket.join(`booking_${bookingId}`);
        console.log(`[Socket] Socket ${socket.id} joined room: booking_${bookingId}`);
      });

      socket.on('leave_booking', (bookingId) => {
        socket.leave(`booking_${bookingId}`);
        console.log(`[Socket] Socket ${socket.id} left room: booking_${bookingId}`);
      });

      socket.on('disconnect', () => {
        console.log(`[Socket] User disconnected: ${socket.id}`);
      });
    });

    return io;
  },
  getIO: () => {
    if (!io) {
      throw new Error('Socket.io not initialized!');
    }
    return io;
  }
};
