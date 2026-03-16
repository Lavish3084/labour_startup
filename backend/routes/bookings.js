const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const Labourer = require('../models/Labourer');
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');

let razorpay;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
}

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

const { sendNotification, sendBroadcastNotification } = require('../utils/notification');

// @route   POST /api/bookings
// @desc    Create a new booking
// @access  Private (User)
router.post('/', verifyToken, async (req, res) => {
    const { labourerId, category, date, notes, address, houseNumber, landmark, latitude, longitude, bookingMode, numberOfHours, amount, minAmount, maxAmount } = req.body;

    try {
        let bookingData = {
            user: req.user.id,
            date,
            notes,
            category,
            address,
            houseNumber,
            landmark,
            latitude,
            longitude,
            bookingMode,
            numberOfHours,
            amount,
            minAmount,
            maxAmount
        };

        const priceDisplay = (minAmount && maxAmount)
            ? `₹${minAmount}-₹${maxAmount}`
            : `₹${amount || 'Negotiable'}`;

        // If specific labourer is requested (direct booking)
        if (labourerId) {
            const labourer = await Labourer.findById(labourerId).populate('user');
            if (!labourer) {
                return res.status(404).json({ msg: 'Labourer not found' });
            }
            bookingData.labourer = labourerId;
            if (!bookingData.category) bookingData.category = labourer.category;

            const newBooking = new Booking(bookingData);
            const booking = await newBooking.save();

            // Notify the specific worker
            if (labourer.user && labourer.user.fcmToken) {
                console.log(`Sending direct notification to worker: ${labourer.user._id}`);
                await sendNotification(
                    labourer.user.fcmToken,
                    'New Job Request',
                    `You have a new booking request for ${date}! Price: ${priceDisplay}`,
                    { bookingId: booking._id.toString() }
                );
            } else {
                console.log(`Worker ${labourerId} (User: ${labourer.user ? labourer.user._id : 'null'}) has no FCM token.`);
            }

            res.json(booking);
        } else if (!category) {
            return res.status(400).json({ msg: 'Category is required for broadcast requests' });
        } else {
            // Broadcast Request
            const newBooking = new Booking(bookingData);
            const booking = await newBooking.save();

            // Find all workers in this category
            const workers = await Labourer.find({ category: category }).populate('user');
            console.log(`Found ${workers.length} workers in category: ${category}`);

            const tokens = workers
                .map(w => {
                    if (w.user && w.user.fcmToken) {
                        return w.user.fcmToken;
                    }
                    if (w.user) {
                        console.log(`Worker User ${w.user._id} (${w.user.name}) has no FCM token.`);
                    } else {
                        console.log(`Labourer ${w._id} has no associated user.`);
                    }
                    return null;
                })
                .filter(t => t); // Filter out nulls/empty

            if (tokens.length > 0) {
                console.log(`Sending broadcast to ${tokens.length} workers: ${tokens.map(t => t.substring(0, 10) + '...').join(', ')}`);
                await sendBroadcastNotification(
                    tokens,
                    'New Job Opportunity',
                    `A new ${category} job is available nearby! Price: ${priceDisplay}`,
                    { bookingId: booking._id.toString() }
                );
            } else {
                console.log(`No valid FCM tokens found for category: ${category}. Category count: ${workers.length}`);
            }

            res.json(booking);
        }
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

        // Notify the user who created the booking
        try {
            // Need to fetch user document to get fcmToken (populate only gives select fields)
            const userToNotify = await User.findById(booking.user._id);
            // Also get worker name for the message
            const workerUser = await User.findById(req.user.id);

            if (userToNotify && userToNotify.fcmToken) {
                console.log(`Sending confirmation notification to user: ${userToNotify._id}`);
                await sendNotification(
                    userToNotify.fcmToken,
                    'Booking Confirmed!',
                    `${workerUser.name} has accepted your request for ${labourer.category}.`,
                    { bookingId: booking._id.toString(), status: 'confirmed' }
                );
            }
        } catch (notifyErr) {
            console.error("Failed to send confirmation notification:", notifyErr);
            // Don't fail the request if notification fails
        }

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
        const isUserOwner = booking.user.toString() === req.user.id;
        let isWorkerOwner = false;

        if (booking.labourer) {
            const labourer = await Labourer.findById(booking.labourer);
            if (labourer && labourer.user.toString() === req.user.id) {
                isWorkerOwner = true;
            }
        }

        if (!isUserOwner && !isWorkerOwner) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        booking.status = status;
        await booking.save();

        // Notify the counterparty about the status change
        // If Worker changed it -> Notify User
        // If User changed it -> Notify Worker
        let targetUserId;
        if (isWorkerOwner) {
            targetUserId = booking.user;
        } else if (isUserOwner && booking.labourer) {
            const l = await Labourer.findById(booking.labourer);
            targetUserId = l.user;
        }

        if (targetUserId) {
            const userToNotify = await User.findById(targetUserId);
            if (userToNotify && userToNotify.fcmToken) {
                await sendNotification(
                    userToNotify.fcmToken,
                    'Booking Update',
                    `Your booking status has been updated to ${status.toUpperCase()}`,
                    { bookingId: booking._id.toString() }
                );
            }
        }

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

const Setting = require('../models/Setting');

// @route   PUT /api/bookings/:id/confirm-work
// @desc    User confirms the work is done and we calculate commission
// @access  Private (User)
router.put('/:id/confirm-work', verifyToken, async (req, res) => {
    try {
        let booking = await Booking.findById(req.params.id);
        if (!booking) {
            return res.status(404).json({ msg: 'Booking not found' });
        }

        // Must be the user who booked it
        if (booking.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized to confirm this work' });
        }

        if (booking.isWorkConfirmed) {
            return res.status(400).json({ msg: 'Work is already confirmed' });
        }

        // Fetch global commission setting
        let adminCommissionPercentage = 0; // Default if not found
        const commissionSetting = await Setting.findOne({ key: 'adminCommissionPercentage' });
        if (commissionSetting && commissionSetting.value) {
            adminCommissionPercentage = Number(commissionSetting.value);
        }

        const totalAmount = booking.amount || 0;
        const commission = (totalAmount * adminCommissionPercentage) / 100;
        const payout = totalAmount - commission;

        booking.isWorkConfirmed = true;
        booking.commissionAmount = commission;
        booking.workerPayoutAmount = payout;
        booking.status = 'completed'; // Also mark as completed
        
        // Automated Razorpay Route Payout Release
        if (razorpay && booking.paymentId) {
            try {
                const transfersRes = await razorpay.transfers.all({ payment_id: booking.paymentId });
                if (transfersRes && transfersRes.items && transfersRes.items.length > 0) {
                    const transfer = transfersRes.items[0]; // The worker's split transfer
                    if (transfer.on_hold) {
                        await razorpay.transfers.edit(transfer.id, { on_hold: false });
                        booking.paymentStatus = 'released'; // Automatically mark as released
                        console.log(`Successfully released hold on transfer ${transfer.id} for booking ${booking._id}`);
                    }
                }
            } catch (rzpErr) {
                console.error('Razorpay Error releasing transfer:', rzpErr);
                // Keep moving, the admin can intervene if the API call fails
            }
        }

        await booking.save();

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/bookings/:id/payout
// @desc    Admin manually marks a worker payout as released
// @access  Private (Admin)
router.put('/:id/payout', verifyToken, async (req, res) => {
    // In a full implementation, enforce admin role here
    if (req.user.role !== 'admin') {
        return res.status(403).json({ msg: 'Access denied' });
    }

    try {
        let booking = await Booking.findById(req.params.id);
        if (!booking) {
            return res.status(404).json({ msg: 'Booking not found' });
        }

        if (!booking.isWorkConfirmed) {
            return res.status(400).json({ msg: 'Work has not been confirmed by user yet' });
        }

        // Automated Razorpay Route Payout Release (Manual Retry by Admin)
        if (razorpay && booking.paymentId) {
            try {
                const transfersRes = await razorpay.transfers.all({ payment_id: booking.paymentId });
                if (transfersRes && transfersRes.items && transfersRes.items.length > 0) {
                    const transfer = transfersRes.items[0]; 
                    if (transfer.on_hold) {
                        await razorpay.transfers.edit(transfer.id, { on_hold: false });
                        console.log(`Successfully manual-released hold on transfer ${transfer.id} for booking ${booking._id}`);
                    }
                }
            } catch (rzpErr) {
                console.error('Razorpay Error on manual retry:', rzpErr);
                return res.status(500).json({ msg: 'Failed to release payout via Razorpay. Check API logs.' });
            }
        }

        booking.paymentStatus = 'released';
        await booking.save();

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
