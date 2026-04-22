const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const Booking = require('../models/Booking');
const Setting = require('../models/Setting');
const Category = require('../models/Category');
const Labourer = require('../models/Labourer');
const User = require('../models/User');
const { sendNotification } = require('../utils/notification');

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

// Initialize Razorpay
let razorpay;
try {
    if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
        razorpay = new Razorpay({
            key_id: process.env.RAZORPAY_KEY_ID,
            key_secret: process.env.RAZORPAY_KEY_SECRET
        });
    } else {
        console.warn("WARNING: RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET is missing in environment variables. Payment routes will fail.");
    }
} catch (err) {
    console.warn("WARNING: Failed to initialize Razorpay:", err.message);
}

/**
 * Helper to handle post-payment logic (marking as paid, notifying worker, launching broadcast)
 */
async function completePaymentLogic(bookingId, paymentId) {
    // 1) Mark as paid
    await Booking.findByIdAndUpdate(bookingId, {
        paymentStatus: 'paid',
        paymentId: paymentId
    });

    // 2) Process notifications and assignments
    try {
        const booking = await Booking.findById(bookingId).populate('labourer');
        if (!booking) return;

        if (booking.labourer) {
            // Direct Booking: Notify worker and clear overlaps
            const labourerId = booking.labourer._id;
            const bStart = new Date(booking.date).getTime();
            const bEnd = bStart + (booking.numberOfHours || 2) * 60 * 60 * 1000;

            const pendingBookings = await Booking.find({
                status: 'pending',
                applicants: labourerId
            });

            for (let pBooking of pendingBookings) {
                if (pBooking._id.toString() === bookingId.toString()) continue;
                
                const pStart = new Date(pBooking.date).getTime();
                const pEnd = pStart + (pBooking.numberOfHours || 2) * 60 * 60 * 1000;
                
                if (bStart < pEnd && bEnd > pStart) {
                    pBooking.applicants = pBooking.applicants.filter(
                        id => id.toString() !== labourerId.toString()
                    );
                    await pBooking.save();
                }
            }

            const labourer = await Labourer.findById(labourerId).populate('user');
            if (labourer && labourer.user && labourer.user.fcmToken) {
                await sendNotification(
                    labourer.user.fcmToken,
                    'Payment Received',
                    'The platform fee for your current job has been paid.',
                    { 
                        type: 'booking',
                        bookingId: bookingId.toString(),
                        status: booking.status
                    }
                );
            }
        } else {
            // Broadcast Booking: Trigger broadcast
            console.log(`[Payment] Success for broadcast booking ${bookingId}. Launching broadcast...`);
            const bookingsRouter = require('./bookings');
            if (bookingsRouter.broadcastBooking) {
                await bookingsRouter.broadcastBooking(booking);
            }
        }
    } catch (err) {
        console.error("Failed to process post-payment logic:", err);
        throw err;
    }
}

// @route   POST /api/payments/create-order
// @desc    Create a Razorpay order
// @access  Private
router.post('/create-order', verifyToken, async (req, res) => {
    const { bookingId } = req.body;

    if (!razorpay) {
        return res.status(500).json({ msg: "Payment service configuration error." });
    }

    try {
        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ msg: "Booking not found" });

        if (booking.paymentStatus === 'paid') {
            return res.status(400).json({ msg: "Already paid", code: "ALREADY_PAID" });
        }

        // Calculate fee
        let feeAmount = 0; 
        try {
            const categoryObj = await Category.findOne({ name: booking.category });
            if (categoryObj) {
                const commission = categoryObj.commissionPercentage || 0;
                const referenceAmount = booking.amount || booking.minAmount || 0;

                if (referenceAmount > 0) {
                    feeAmount = (referenceAmount * commission) / 100;
                } else {
                    // Fallback to percentage as flat fee if no amount set, min 20 if commission > 0
                    feeAmount = commission > 0 ? Math.max(commission, 20) : 0;
                }
            }
        } catch (err) {
            console.error("Error calculating fee:", err);
        }

        // Safety: If fee is 0, we shouldn't be here (frontend should use confirm-free-booking)
        // but if we are, enforce minimum 1 INR for Razorpay if it's supposed to be paid
        if (feeAmount < 1) {
            return res.status(400).json({ msg: "Booking fee is 0. Please use confirm-free-booking route." });
        }

        const options = {
            amount: Math.round(feeAmount * 100), // paise
            currency: "INR",
            receipt: `receipt_booking_${bookingId}`,
            notes: { bookingId: bookingId, userId: req.user.id }
        };

        const order = await razorpay.orders.create(options);
        await Booking.findByIdAndUpdate(bookingId, { orderId: order.id });

        res.json(order);
    } catch (err) {
        console.error("Razorpay Error:", err);
        res.status(500).json({ msg: "Error creating order" });
    }
});

// @route   POST /api/payments/verify-payment
// @desc    Verify Razorpay payment signature
// @access  Private
router.post('/verify-payment', verifyToken, async (req, res) => {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, bookingId } = req.body;

    const body = razorpay_order_id + "|" + razorpay_payment_id;
    const expectedSignature = crypto
        .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
        .update(body.toString())
        .digest('hex');

    if (expectedSignature === razorpay_signature) {
        try {
            await completePaymentLogic(bookingId, razorpay_payment_id);
            res.json({ success: true, msg: "Payment verified successfully" });
        } catch (err) {
            res.status(500).json({ success: false, msg: "Error processing payment logic" });
        }
    } else {
        res.status(400).json({ success: false, msg: "Invalid signature" });
    }
});

// @route   POST /api/payments/confirm-free-booking
// @desc    Confirm a booking with 0 platform fee
// @access  Private
router.post('/confirm-free-booking', verifyToken, async (req, res) => {
    const { bookingId } = req.body;

    try {
        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ msg: "Booking not found" });

        if (booking.paymentStatus === 'paid') {
            return res.status(200).json({ msg: "Already confirmed" });
        }

        // Verify if it's actually free
        const categoryObj = await Category.findOne({ name: booking.category });
        const commission = categoryObj ? (categoryObj.commissionPercentage || 0) : 0;
        
        if (commission > 0) {
            return res.status(400).json({ msg: "This booking requires a platform fee." });
        }

        await completePaymentLogic(bookingId, 'FREE_BOOKING');
        res.json({ success: true, msg: "Booking confirmed successfully" });
    } catch (err) {
        console.error("Confirm Free Booking Error:", err);
        res.status(500).json({ msg: "Server error" });
    }
});

module.exports = router;
