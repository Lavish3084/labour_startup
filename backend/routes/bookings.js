const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const Labourer = require('../models/Labourer');
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// Middleware
const verifyToken = (req, res, next) => {
    const token = req.header('x-auth-token');
    if (!token) return res.status(401).json({ msg: 'No token, authorization denied' });

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded.user;
        next();
    } catch (err) {
        res.status(401).json({ msg: 'Token is not valid' });
    }
};

// @route   POST /api/bookings
// @desc    Create a new booking
// @access  Private (User)
router.post('/', verifyToken, async (req, res) => {
    const { labourerId, category, date, notes } = req.body;

    try {
        let bookingData = {
            user: req.user.id,
            date,
            notes,
            category
        };

        // If specific labourer is requested (direct booking)
        if (labourerId) {
            const labourer = await Labourer.findById(labourerId);
            if (!labourer) {
                return res.status(404).json({ msg: 'Labourer not found' });
            }
            bookingData.labourer = labourerId;
            // Also ensure category matches labourer if not provided, or validate it
            if (!bookingData.category) bookingData.category = labourer.category;
        } else if (!category) {
            return res.status(400).json({ msg: 'Category is required for broadcast requests' });
        }

        const newBooking = new Booking(bookingData);
        const booking = await newBooking.save();
        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/bookings/user
// @desc    Get all bookings for current user
// @access  Private
router.get('/user', verifyToken, async (req, res) => {
    try {
        const bookings = await Booking.find({ user: req.user.id })
            .populate('labourer', 'name category imageUrl hourlyRate location') // Populate labourer details
            .sort({ date: -1 });
        res.json(bookings);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/bookings/worker
// @desc    Get all bookings received by current worker
// @access  Private (Worker)
router.get('/worker', verifyToken, async (req, res) => {
    try {
        // First find the labourer profile associated with this user
        const labourer = await Labourer.findOne({ user: req.user.id });
        if (!labourer) {
            return res.status(404).json({ msg: 'Labourer profile not found' });
        }

        // Fetch bookings:
        // 1. Assigned to this labourer
        // 2. Unassigned (labourer: null) AND matching category (and maybe status pending)
        const bookings = await Booking.find({
            $or: [
                { labourer: labourer._id },
                { labourer: null, category: labourer.category, status: 'pending' }
            ]
        })
            .populate('user', 'name email') // Populate user details who booked
            .sort({ date: -1 });

        res.json(bookings);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/bookings/:id/claim
// @desc    Worker claims an open job request
// @access  Private (Worker)
router.put('/:id/claim', verifyToken, async (req, res) => {
    try {
        const labourer = await Labourer.findOne({ user: req.user.id });
        if (!labourer) {
            return res.status(404).json({ msg: 'Labourer profile not found' });
        }

        let booking = await Booking.findById(req.params.id);
        if (!booking) {
            return res.status(404).json({ msg: 'Booking not found' });
        }

        if (booking.labourer) {
            return res.status(400).json({ msg: 'Booking already claimed' });
        }

        if (booking.category !== labourer.category) {
            return res.status(403).json({ msg: 'Category mismatch' });
        }

        booking.labourer = labourer._id;
        booking.status = 'confirmed'; // Auto confirm when claimed
        await booking.save();

        // Populate user for the response card
        await booking.populate('user', 'name email');

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/bookings/:id/status
// @desc    Update booking status (Accept/Reject/Complete)
// @access  Private (Worker/User)
router.put('/:id/status', verifyToken, async (req, res) => {
    const { status } = req.body;

    // Validate status
    const validStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ msg: 'Invalid status' });
    }

    try {
        let booking = await Booking.findById(req.params.id);
        if (!booking) {
            return res.status(404).json({ msg: 'Booking not found' });
        }

        // Verify ownership (either the user who booked or the worker assigned)
        // Note: For 'confirmed' (accept) / 'cancelled' (reject), usually the worker does it.
        // But user can also cancel.
        // We need to check if req.user.id is either booking.user or booking.labourer.user

        // However, booking.labourer is an ID of Labourer model, not User model.
        // We need to fetch the associated Labourer to check the user ID.
        const labourer = await Labourer.findById(booking.labourer);

        if (booking.user.toString() !== req.user.id && labourer.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        booking.status = status;
        await booking.save();
        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
