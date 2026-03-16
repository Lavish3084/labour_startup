const express = require('express');
const router = express.Router();
const Razorpay = require('razorpay');
const crypto = require('crypto');
const Booking = require('../models/Booking');
const Setting = require('../models/Setting');
const Labourer = require('../models/Labourer');
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

        const settings = await Setting.findOne();
        const commissionPercentage = settings ? settings.adminCommissionPercentage : 0;
        
        const commissionAmount = (amount * commissionPercentage) / 100;
        const workerPayoutAmount = amount - commissionAmount;

        const options = {
            amount: amount * 100, // amount in the smallest currency unit (paise)
            currency: "INR",
            receipt: `receipt_booking_${bookingId}`,
            notes: {
                bookingId: bookingId,
                userId: req.user.id
            }
        };

        // If worker has a linked Razorpay account, set up the split in escrow
        if (booking.labourer && booking.labourer.razorpayAccountId) {
            options.transfers = [
                {
                    account: booking.labourer.razorpayAccountId,
                    amount: Math.round(workerPayoutAmount * 100), // Transfer amount must be in paise
                    currency: "INR",
                    notes: {
                        booking: bookingId,
                        rollout: "automated"
                    },
                    linked_account_notes: ["rollout"],
                    on_hold: true, // Crucial: holds the money until the job is confirmed
                    on_hold_until: undefined // Holds indefinitely until we explicitly release it
                }
            ];
        }

        const order = await razorpay.orders.create(options);

        // Update booking with orderId
        await Booking.findByIdAndUpdate(bookingId, {
            orderId: order.id,
            amount: amount
        });

        res.json(order);
    } catch (err) {
        console.error("Razorpay Error:", err);
        res.status(500).send("Error creating order");
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
