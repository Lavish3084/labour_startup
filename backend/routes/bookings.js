const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const Labourer = require('../models/Labourer');
const User = require('../models/User');
const Setting = require('../models/Setting');
const Category = require('../models/Category');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const socketUtils = require('../utils/socket');

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
const crypto = require('crypto');

// Helper to generate a 4-digit OTP
const generateOTP = () => {
    return Math.floor(1000 + Math.random() * 9000).toString();
};

// Helper function to calculate time overlaps for a worker
async function checkOverlap(labourerId, targetBooking) {
    const activeCommitments = await Booking.find({
        labourer: labourerId,
        $or: [
            { status: 'confirmed', paymentStatus: 'paid' },
            { status: 'arrived' }
        ]
    });

    const bStart = new Date(targetBooking.date).getTime();
    const bEnd = bStart + (targetBooking.numberOfHours || 2) * 60 * 60 * 1000;

    for (let active of activeCommitments) {
        if (active._id.toString() === targetBooking._id.toString()) continue;
        const aStart = new Date(active.date).getTime();
        const aEnd = aStart + (active.numberOfHours || 2) * 60 * 60 * 1000;
        if (bStart < aEnd && bEnd > aStart) {
            return true; // Overlaps
        }
    }
    return false;
}

// Helper to broadcast a booking to all workers in category
const broadcastBooking = async (booking) => {
    try {
        const category = booking.category;
        const minAmount = booking.minAmount;
        const maxAmount = booking.maxAmount;
        const amount = booking.amount;
        
        const priceDisplay = (minAmount && maxAmount)
            ? `₹${minAmount}-₹${maxAmount}`
            : `₹${amount || 'Negotiable'}`;

        // Find all workers in this category
        const workers = await Labourer.find({ category: category }).populate('user');
        console.log(`[Broadcast] Found ${workers.length} workers in category: ${category}`);

        const tokens = workers
            .map(w => (w.user && w.user.fcmToken) ? w.user.fcmToken : null)
            .filter(t => t);

        if (tokens.length > 0) {
            console.log(`[Broadcast] Sending to ${tokens.length} workers for Booking: ${booking._id}`);
            await sendBroadcastNotification(
                tokens,
                'New Job Opportunity',
                `A new ${category} job is available nearby! Price: ${priceDisplay}`,
                { 
                    type: 'booking',
                    bookingId: booking._id.toString(),
                    status: 'pending'
                }
            );
            return true;
        } else {
            console.log(`[Broadcast] No valid FCM tokens found for category: ${category}`);
            return false;
        }
    } catch (err) {
        console.error('[Broadcast] Error:', err.message);
        return false;
    }
};

// @route   POST /api/bookings
// @desc    Create a new booking
// @access  Private (User)
router.post('/', verifyToken, async (req, res) => {
    const { labourerId, category, date, notes, problemTitle, address, houseNumber, landmark, latitude, longitude, bookingMode, numberOfHours, amount, minAmount, maxAmount, numberOfWorkers, workType, taskImages, taskAudio } = req.body;
    
    // Check if the booking date is less than 1 hour away or in the past
    const bookingDate = new Date(date);
    const minBookingTime = new Date(Date.now() + 3600000); // Current time + 1 hour

    if (bookingDate < minBookingTime) {
        return res.status(400).json({ msg: 'Booking must be scheduled at least 1 hour in advance.' });
    }

    try {
        let bookingData = {
            user: req.user.id,
            date,
            problemTitle,
            taskImages,
            taskAudio,
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
            maxAmount,
            numberOfWorkers: numberOfWorkers || 1,
            workType,
            commissionAmount: 0 // Default
        };

        // Calculate platform commission fee from backend configuration
        try {
            const categoryObj = await Category.findOne({ name: category });
            if (categoryObj) {
                const commission = categoryObj.commissionPercentage || 0;
                const referenceAmount = amount || minAmount || 0;
                
                if (referenceAmount > 0) {
                    bookingData.commissionAmount = Math.ceil((referenceAmount * commission) / 100);
                } else if (commission > 0) {
                    // Fallback to percentage as flat fee if no amount set, min 20 if commission > 0
                    bookingData.commissionAmount = Math.max(commission, 20);
                }
            }
        } catch (err) {
            console.error('Error calculating commission:', err);
        }

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
                    { 
                        type: 'booking',
                        bookingId: booking._id.toString(),
                        status: 'pending' 
                    }
                );
            } else {
                console.log(`Worker ${labourerId} (User: ${labourer.user ? labourer.user._id : 'null'}) has no FCM token.`);
            }

            res.json(booking);
        } else if (!category) {
            return res.status(400).json({ msg: 'Category is required for broadcast requests' });
        } else {
            // Broadcast Request
            const num = bookingData.numberOfWorkers || 1;
            let firstBooking = null;

            for (let i = 0; i < num; i++) {
                const newBooking = new Booking(bookingData);
                const savedBooking = await newBooking.save();
                if (i === 0) firstBooking = savedBooking;
            }

            const booking = firstBooking; 

            // GATE: Only broadcast immediately if labourerId was provided (direct booking)
            // For broadcast requests, we wait until payment is verified in payments.js
            if (labourerId) {
                // Already handled above for direct booking
            } else {
                console.log(`[Booking] Created broadcast booking ${booking._id}. Awaiting payment before broadcast.`);
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
            .populate('labourer', 'name category imageUrl hourlyRate location rating jobsCompleted reviews') // Populate full labourer details
            .populate('applicants', 'name category imageUrl hourlyRate location rating jobsCompleted reviews') // Populate applicants for customer view
            .sort({ date: -1 });
        res.json(bookings);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/bookings/worker
// @desc    Get all bookings relevant to the logged-in worker
// @access  Private (Worker)
router.get('/worker', verifyToken, async (req, res) => {
    try {
        // First find the labourer profile associated with this user
        const labourer = await Labourer.findOne({ user: req.user.id });
        if (!labourer) {
            console.log(`GET /worker: Labourer profile not found for user ${req.user.id}`);
            return res.status(404).json({ msg: 'Labourer profile not found' });
        }

        console.log(`GET /worker: Token user ${req.user.id} matched labourer ${labourer._id} (${labourer.name}), category: ${labourer.category}, isOnline: ${labourer.isOnline}`);

        // Fetch bookings:
        // 1. Assigned to this labourer
        // 2. Unassigned (labourer: null) AND matching category (and status pending)
        //    AND not declined by this labourer AND start date is not completely expired (>3 hours ago)
        
        const expirationTime = new Date(Date.now() - 3 * 60 * 60 * 1000); // 3 hours ago

        // If worker is online, get their own bookings PLUS broadcast bookings
        // If offline, ONLY get their own applied/assigned bookings
        const queryOr = [{ labourer: labourer._id }];
        
        if (labourer.isOnline !== false) {
            queryOr.push({ 
                labourer: null, 
                category: labourer.category, 
                status: 'pending',
                paymentStatus: 'paid', // GATE: Only show paid broadcast jobs
                declinedBy: { $ne: labourer._id },
                date: { $gt: expirationTime }
            });
        }

        console.log(`GET /worker: Querying with $or: ${JSON.stringify(queryOr)}`);

        const bookings = await Booking.find({ $or: queryOr })
            .populate('user', 'name email phone') // Populate user details who booked
            .sort({ date: -1 });

        console.log(`GET /worker: Found ${bookings.length} potential bookings before filtering.`);

        const activeCommitments = await Booking.find({
            labourer: labourer._id,
            $or: [
                { status: 'confirmed', paymentStatus: 'paid' },
                { status: 'arrived' }
            ]
        });

        const filteredBookings = bookings.filter(b => {
            // Keep if already assigned to this worker or if they already applied
            if (b.labourer && b.labourer.toString() === labourer._id.toString()) return true;
            if (b.applicants && b.applicants.includes(labourer._id)) return true;

            // Otherwise check overlap
            const bStart = new Date(b.date).getTime();
            const bEnd = bStart + (b.numberOfHours || 2) * 60 * 60 * 1000;

            for (let active of activeCommitments) {
                if (active._id.toString() === b._id.toString()) continue;
                const aStart = new Date(active.date).getTime();
                const aEnd = aStart + (active.numberOfHours || 2) * 60 * 60 * 1000;
                if (bStart < aEnd && bEnd > aStart) {
                    console.log(`GET /worker: Hiding booking ${b._id} due to overlap with active job ${active._id}`);
                    return false; // Hide overlapping pending job
                }
            }
            return true;
        });

        console.log(`GET /worker: Returning ${filteredBookings.length} filtered bookings.`);
        res.json(filteredBookings);
    } catch (err) {
        console.error('GET /worker Error:', err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/bookings/:id
// @desc    Get a single booking by ID
// @access  Private
router.get('/:id', verifyToken, async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id)
            .populate({
                path: 'labourer',
                select: 'name category imageUrl hourlyRate location rating jobsCompleted reviews',
                populate: { path: 'user', select: 'phoneNumber' }
            })
            .populate('applicants', 'name category imageUrl hourlyRate location rating jobsCompleted reviews');
        
        if (!booking) {
            return res.status(404).json({ msg: 'Booking not found' });
        }

        // Check if user has access to this booking
        const isOwner = booking.user.toString() === req.user.id;
        
        // If it's a worker, they should only see it if they are the assigned labourer 
        // OR if it's a broadcast unassigned job
        const labourer = await Labourer.findOne({ user: req.user.id });
        const isLabourer = labourer && (
            (booking.labourer && booking.labourer.toString() === labourer._id.toString()) ||
            (!booking.labourer && booking.status === 'pending' && booking.paymentStatus === 'paid' && booking.category === labourer.category)
        );

        if (!isOwner && !isLabourer) {
             return res.status(401).json({ msg: 'Unauthorized to view this booking' });
        }

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Booking not found' });
        }
        res.status(500).send('Server Error');
    }
});


// @route   PUT /api/bookings/:id/decline
// @desc    Worker declines an open job request
// @access  Private (Worker)
router.put('/:id/decline', verifyToken, async (req, res) => {
    try {
        const labourer = await Labourer.findOne({ user: req.user.id });
        if (!labourer) {
            return res.status(404).json({ msg: 'Labourer profile not found' });
        }

        let booking = await Booking.findById(req.params.id);
        if (!booking) {
            return res.status(404).json({ msg: 'Booking not found' });
        }

        // Only matters for unassigned pending requests
        if (booking.labourer || booking.status !== 'pending') {
            return res.status(400).json({ msg: 'Cannot decline this booking at this stage' });
        }

        // Add labourer to declinedBy if not already present
        if (!booking.declinedBy.includes(labourer._id)) {
            booking.declinedBy.push(labourer._id);
            await booking.save();
        }

        res.json({ msg: 'Booking declined successfully' });
    } catch (err) {
        console.error('Error declining booking:', err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/bookings/:id/claim
// @desc    Worker applies for an open job request
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

        // Directly assign worker and confirm booking
        booking.labourer = labourer._id;
        booking.status = 'confirmed';
        booking.arrivalOTP = generateOTP();
        booking.completionOTP = generateOTP();
        
        // Final sanity check for overlapping paid bookings
        const overlaps = await checkOverlap(labourer._id, booking);
        if (overlaps) {
            return res.status(400).json({ msg: 'You have a conflicting paid booking at this time' });
        }

        await booking.save();

        // Socket update
        try {
            socketUtils.getIO().to(`booking_${booking._id}`).emit('booking_update', booking);
        } catch (sErr) {
            console.error('Socket error:', sErr.message);
        }

        // Populate user for the response card
        await booking.populate('user', 'name email');

        // Notify the user who created the booking
        try {
            const userToNotify = await User.findById(booking.user._id);
            const workerUser = await User.findById(req.user.id);

            if (userToNotify && userToNotify.fcmToken) {
                console.log(`Sending confirmation notification to user: ${userToNotify._id}`);
                await sendNotification(
                    userToNotify.fcmToken,
                    'Worker Found!',
                    `${workerUser.name} has accepted your ${labourer.category} request. Job is confirmed!`,
                    { 
                        type: 'booking',
                        bookingId: booking._id.toString(), 
                        status: 'confirmed' 
                    }
                );
            }
        } catch (notifyErr) {
            console.error("Failed to send confirmation notification:", notifyErr);
        }

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/bookings/:id/accept-worker
// @desc    User accepts a worker from applicants
// @access  Private
router.put('/:id/accept-worker', verifyToken, async (req, res) => {
    try {
        const { labourerId } = req.body;
        if (!labourerId) {
            return res.status(400).json({ msg: 'Labourer ID is required' });
        }

        let booking = await Booking.findById(req.params.id);
        if (!booking) {
            return res.status(404).json({ msg: 'Booking not found' });
        }

        // Only the user who created the booking can accept a worker
        if (booking.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        if (booking.labourer) {
            return res.status(400).json({ msg: 'Worker already assigned to this booking' });
        }

        if (!booking.applicants.includes(labourerId)) {
            return res.status(400).json({ msg: 'Worker has not applied for this booking' });
        }

        const overlaps = await checkOverlap(labourerId, booking);
        if (overlaps) {
            return res.status(400).json({ msg: 'This worker has a conflicting paid booking at this time' });
        }

        booking.labourer = labourerId;
        booking.status = 'confirmed';
        booking.arrivalOTP = generateOTP();
        booking.completionOTP = generateOTP();
        await booking.save();

        // Notify the accepted worker
        try {
            const acceptedWorker = await Labourer.findById(labourerId).populate('user');
            if (acceptedWorker && acceptedWorker.user && acceptedWorker.user.fcmToken) {
                await sendNotification(
                    acceptedWorker.user.fcmToken,
                    'Application Accepted!',
                    `Your application for ${booking.category} has been accepted. Job is confirmed!`,
                    { 
                        type: 'booking',
                        bookingId: booking._id.toString(), 
                        status: 'confirmed' 
                    }
                );
            }
        } catch (notifyErr) {
            console.error("Failed to send acceptance notification:", notifyErr);
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
    const validStatuses = ['pending', 'confirmed', 'arrived', 'completed', 'cancelled'];
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

        if (status === 'confirmed' && (!booking.arrivalOTP || !booking.completionOTP)) {
            booking.arrivalOTP = generateOTP();
            booking.completionOTP = generateOTP();
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
            if (l) {
                targetUserId = l.user;
            }
        }

        if (targetUserId) {
            const userToNotify = await User.findById(targetUserId);
            if (userToNotify && userToNotify.fcmToken) {
                await sendNotification(
                    userToNotify.fcmToken,
                    'Booking Update',
                    `Your booking status has been updated to ${status.toUpperCase()}`,
                    { 
                        type: 'booking',
                        bookingId: booking._id.toString(),
                        status: status
                    }
                );
            }
        }

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/bookings/:id/confirm-work
// @desc    DEPRECATED: User confirms work completion. Replaced by OTP verification.
// @access  Private
router.put('/:id/confirm-work', verifyToken, async (req, res) => {
    return res.status(410).json({ 
        msg: 'The manual confirmation method is no longer supported. Please provide the Completion OTP to the worker instead.' 
    });
});

// @route   PUT /api/bookings/:id/payout
// @desc    Admin manually marks a worker payout as released
// @access  Private (Admin)
router.put('/:id/payout', verifyToken, async (req, res) => {
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

        booking.paymentStatus = 'released';
        await booking.save();

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/bookings/:id/verify-arrival
// @desc    Worker verifies arrival with OTP
// @access  Private (Worker)
router.put('/:id/verify-arrival', verifyToken, async (req, res) => {
    const { otp } = req.body;
    try {
        let booking = await Booking.findById(req.params.id);
        if (!booking) return res.status(404).json({ msg: 'Booking not found' });

        const labourer = await Labourer.findOne({ user: req.user.id });
        if (!labourer || booking.labourer.toString() !== labourer._id.toString()) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        const now = new Date();
        const scheduled = new Date(booking.date);
        const start = new Date(scheduled.getTime() - 3600000); // 1 hour before
        const end = new Date(scheduled.getTime() + 1800000);   // 30 mins after

        if (now < start || now > end) {
            return res.status(400).json({ msg: 'Arrival verification window expired (Allowed: 1h before to 30m after).' });
        }

        if (booking.arrivalOTP !== otp) {
            return res.status(400).json({ msg: 'Invalid Arrival OTP' });
        }

        booking.status = 'arrived';
        await booking.save();

        // Socket update
        try {
            socketUtils.getIO().to(`booking_${booking._id}`).emit('booking_update', booking);
        } catch (sErr) {
            console.error('Socket error:', sErr.message);
        }

        // Notify user
        const user = await User.findById(booking.user);
        if (user && user.fcmToken) {
            await sendNotification(
                user.fcmToken, 
                'Worker Arrived', 
                'The worker has arrived and starting the job!',
                { type: 'booking_update', bookingId: booking._id.toString() }
            );
        }

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/bookings/:id/verify-completion
// @desc    Worker verifies completion with OTP
// @access  Private (Worker)
router.put('/:id/verify-completion', verifyToken, async (req, res) => {
    const { otp } = req.body;
    try {
        let booking = await Booking.findById(req.params.id);
        if (!booking) return res.status(404).json({ msg: 'Booking not found' });

        const labourer = await Labourer.findOne({ user: req.user.id });
        if (!labourer || booking.labourer.toString() !== labourer._id.toString()) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        if (booking.completionOTP !== otp) {
            return res.status(400).json({ msg: 'Invalid Completion OTP' });
        }

        // Logic from confirm-work (commission calculation, status update)
        let commissionAmount = 0;
        try {
            const Category = require('../models/Category');
            const categoryObj = await Category.findOne({ name: booking.category });
            if (categoryObj && categoryObj.commissionPercentage) {
                if (booking.amount) {
                    commissionAmount = (booking.amount * categoryObj.commissionPercentage) / 100;
                } else {
                    commissionAmount = categoryObj.commissionPercentage;
                }
            }
        } catch (err) {
            console.error("Error fetching category commission:", err);
        }

        booking.status = 'completed';
        booking.isWorkConfirmed = true;
        booking.commissionAmount = commissionAmount;
        booking.workerPayoutAmount = 0; // Settled directly via cash
        booking.paymentStatus = 'released';

        await booking.save();

        // Socket update
        try {
            socketUtils.getIO().to(`booking_${booking._id}`).emit('booking_update', booking);
        } catch (sErr) {
            console.error('Socket error:', sErr.message);
        }

        // Increment worker's jobsCompleted
        if (booking.labourer) {
            await Labourer.findByIdAndUpdate(booking.labourer, { $inc: { jobsCompleted: 1 } });
        }

        // Notify user
        const user = await User.findById(booking.user);
        if (user && user.fcmToken) {
            await sendNotification(
                user.fcmToken, 
                'Work Completed', 
                'Job completed successfully! Thank you for using Will.',
                { type: 'booking_update', bookingId: booking._id.toString() }
            );
        }

        res.json(booking);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST /api/bookings/:id/rate
// @desc    Rate a completed booking and the worker
// @access  Private
router.post('/:id/rate', verifyToken, async (req, res) => {
    const { rating, comment } = req.body;

    if (!rating || rating < 1 || rating > 5) {
        return res.status(400).json({ msg: 'Please provide a valid rating between 1 and 5' });
    }

    try {
        let booking = await Booking.findById(req.params.id);
        if (!booking) return res.status(404).json({ msg: 'Booking not found' });

        // Ensure user owns booking
        if (booking.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        // Must be completed
        if (booking.status !== 'completed') {
            return res.status(400).json({ msg: 'Can only rate completed jobs' });
        }

        // Check if already rated
        if (booking.isRated) {
            return res.status(400).json({ msg: 'Already rated this booking' });
        }

        // Grab worker
        if (!booking.labourer) {
            return res.status(400).json({ msg: 'No worker assigned to rate' });
        }

        let labourer = await Labourer.findById(booking.labourer);
        if (!labourer) {
            return res.status(404).json({ msg: 'Worker profile no longer exists' });
        }

        // Grab user name
        const user = await User.findById(req.user.id);

        const newReview = {
            user: req.user.id,
            userName: user ? user.name : 'Customer',
            rating: Number(rating),
            comment: comment || ''
        };

        labourer.reviews.unshift(newReview); // add to top

        // Recalculate average rating
        const totalRating = labourer.reviews.reduce((acc, curr) => acc + curr.rating, 0);
        labourer.rating = totalRating / labourer.reviews.length;

        await labourer.save();

        booking.isRated = true;
        await booking.save();

        res.json({ msg: 'Review submitted successfully!', booking });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

router.broadcastBooking = broadcastBooking;
module.exports = router;
