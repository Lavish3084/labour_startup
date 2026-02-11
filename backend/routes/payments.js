const express = require('express');
const router = express.Router();
const Razorpay = require('razorpay');
const crypto = require('crypto');
const Booking = require('../models/Booking');
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
const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
});

// @route   POST /api/payments/create-order
// @desc    Create a Razorpay order
// @access  Private
router.post('/create-order', verifyToken, async (req, res) => {
    const { bookingId, amount } = req.body; // amount in INR (e.g., 500)

    try {
        const options = {
            amount: amount * 100, // amount in the smallest currency unit (paise)
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
