const express = require('express');
const router = express.Router();
const verifyToken = require('../utils/verifyToken');
const Message = require('../models/Message');
const Booking = require('../models/Booking');

// @route   GET api/chat/:bookingId
// @desc    Get all messages for a booking
// @access  Private
router.get('/:bookingId', verifyToken, async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.bookingId);
        if (!booking) return res.status(404).json({ msg: 'Booking not found' });

        // Security: Only allow user or assigned worker to see messages
        // Add logic here if needed. For now, assuming if they have the ID they can see it
        // Or check if req.user.id is booking.user or linked to booking.labourer

        const messages = await Message.find({ booking: req.params.bookingId })
            .sort({ createdAt: 1 })
            .populate('sender', 'name profilePicture');
        
        res.json(messages);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/chat
// @desc    Send a message
// @access  Private
router.post('/', verifyToken, async (req, res) => {
    const { bookingId, text } = req.body;

    try {
        const newMessage = new Message({
            booking: bookingId,
            sender: req.user.id,
            text
        });

        const message = await newMessage.save();
        
        // Populate sender before returning
        const populatedMessage = await Message.findById(message._id).populate('sender', 'name profilePicture');

        res.json(populatedMessage);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
