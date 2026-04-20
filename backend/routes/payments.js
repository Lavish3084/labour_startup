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

// @route   POST /api/payments/create-order
// @desc    Create a Razorpay order
// @access  Private
router.post('/create-order', verifyToken, async (req, res) => {
    const { bookingId, amount } = req.body; // amount in INR (e.g., 500)

    if (!razorpay) {
        console.error("Razorpay instance not initialized");
        return res.status(500).json({ msg: "Payment service configuration error. Please contact support." });
    }

    try {
        const booking = await Booking.findById(bookingId).populate('labourer');
        if (!booking) {
            return res.status(404).json({ msg: "Booking not found" });
        }

        // PREVENTION: Don't create a new order if already paid
        if (booking.paymentStatus === 'paid') {
            return res.status(400).json({ 
                msg: "This booking is already paid.",
                code: "ALREADY_PAID"
            });
        }

        // Fetch the platform fee from the specific Category
        let feeAmount = 20; // Default fallback
        try {
            const categoryObj = await Category.findOne({ name: booking.category });
            if (categoryObj && categoryObj.commissionPercentage) {
                // If it's a percentage, we might need the job amount to calculate the fee.
                // However, the user said "make it clear how much commission we want to take".
                // If it's a fixed amount entered as "percentage" in admin panel, or a real percentage?
                // The user said "enter percentage of commision".
                // Usually commission is a percentage of the total amount.
                // But if amount is negotiable or not yet finalized, 
                // we might want to take a fixed fee or calculate it if amount exists.
                
                if (booking.amount) {
                    feeAmount = (booking.amount * categoryObj.commissionPercentage) / 100;
                } else if (categoryObj.commissionPercentage > 0) {
                    // Fallback to a minimum or the percentage of some base rate
                    feeAmount = categoryObj.commissionPercentage; // Or keep it simple if it's meant to be a fixed amount for now
                }
            }
        } catch (err) {
            console.error("Error fetching category commission:", err);
        }

        const options = {
            amount: feeAmount * 100, // amount in the smallest currency unit (paise)
            currency: "INR",
            receipt: `receipt_booking_${bookingId}`,
            notes: {
                bookingId: bookingId,
                userId: req.user.id
            }
        };

        const order = await razorpay.orders.create(options);

        // Update booking with orderId
        await Booking.findByIdAndUpdate(bookingId, {
            orderId: order.id
            // Removed amount: amount so that the original service cost isn't overwritten by the 20rs fee
        });

        res.json(order);
    } catch (err) {
        console.error("Razorpay Error:", err);
        res.status(500).json({ 
            msg: "Error creating order", 
            detail: err.description || err.message || "Server error"
        });
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

    const isAuthentic = expectedSignature === razorpay_signature;

    if (isAuthentic) {
        // Payment successful
        await Booking.findByIdAndUpdate(bookingId, {
            paymentStatus: 'paid',
            paymentId: razorpay_payment_id
        });

        // Notify the worker and remove them from overlapping pending jobs
        try {
            const booking = await Booking.findById(bookingId).populate('labourer');
            if (booking) {
                if (booking.labourer) {
                    // 1) Remove worker from applicants of other overlapping pending bookings
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
                        
                        // If times overlap, remove worker from this pending job's applicants
                        if (bStart < pEnd && bEnd > pStart) {
                            pBooking.applicants = pBooking.applicants.filter(
                                id => id.toString() !== labourerId.toString()
                            );
                            await pBooking.save();
                        }
                    }

                    // 2) Send Notification
                    const Labourer = require('../models/Labourer');
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
                    // This is a broadcast booking (no specific labourer yet)
                    // Trigger the broadcast now that it's paid
                    console.log(`[Payment] Verification success for broadcast booking ${bookingId}. Launching broadcast...`);
                    const bookingsRouter = require('./bookings');
                    if (bookingsRouter.broadcastBooking) {
                        await bookingsRouter.broadcastBooking(booking);
                    }
                }
            }
        } catch (notifyErr) {
            console.error("Failed to process post-payment logic:", notifyErr);
        }

        res.json({
            success: true,
            msg: "Payment verified successfully"
        });
    } else {
        res.status(400).json({
            success: false,
            msg: "Invalid signature"
        });
    }
});

module.exports = router;
