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
        
        // 1) Try using the pre-calculated amount from the booking record
        if (booking.commissionAmount !== undefined && booking.commissionAmount !== null) {
            feeAmount = booking.commissionAmount;
        } 
        
        // 2) Fallback to recalculation if not found (legacy support)
        if (feeAmount === 0) {
            try {
                const categoryObj = await Category.findOne({ name: booking.category });
                if (categoryObj) {
                    const commission = categoryObj.commissionPercentage || 0;
                    const referenceAmount = booking.amount || booking.minAmount || 0;
    
                    if (referenceAmount > 0) {
                        let calculatedFee = (referenceAmount * commission) / 100;
                        calculatedFee = Math.max(49, Math.min(calculatedFee, 999));
                        feeAmount = Math.ceil(calculatedFee);
                    } else {
                        // Fallback to percentage as flat fee if no amount set, min 20 if commission > 0
                        feeAmount = commission > 0 ? Math.max(commission, 20) : 0;
                    }
                }
            } catch (err) {
                console.error("Error calculating fee fallback:", err);
            }
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

// @route   POST /api/payments/pay-with-wallet
// @desc    Pay the booking fee using wallet balance
// @access  Private
router.post('/pay-with-wallet', verifyToken, async (req, res) => {
    const { bookingId } = req.body;

    try {
        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ msg: "Booking not found" });

        if (booking.paymentStatus === 'paid') {
            return res.status(400).json({ msg: "Already paid", code: "ALREADY_PAID" });
        }

        let feeAmount = 0; 
        if (booking.commissionAmount !== undefined && booking.commissionAmount !== null) {
            feeAmount = booking.commissionAmount;
        } 
        
        if (feeAmount === 0) {
            try {
                const categoryObj = await Category.findOne({ name: booking.category });
                if (categoryObj) {
                    const commission = categoryObj.commissionPercentage || 0;
                    const referenceAmount = booking.amount || booking.minAmount || 0;
                    if (referenceAmount > 0) {
                        let calculatedFee = (referenceAmount * commission) / 100;
                        calculatedFee = Math.max(49, Math.min(calculatedFee, 999));
                        feeAmount = Math.ceil(calculatedFee);
                    } else {
                        feeAmount = commission > 0 ? Math.max(commission, 20) : 0;
                    }
                }
            } catch (err) {
                console.error("Error calculating fee fallback:", err);
            }
        }

        if (feeAmount < 1) {
            return res.status(400).json({ msg: "Booking fee is 0. Please use confirm-free-booking route." });
        }

        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ msg: "User not found" });

        if ((user.walletBalance || 0) < feeAmount) {
            return res.status(400).json({ msg: "Insufficient wallet balance" });
        }

        // Use atomic findOneAndUpdate to prevent race conditions
        const updatedUser = await User.findOneAndUpdate(
            { _id: req.user.id, walletBalance: { $gte: feeAmount } },
            {
                $inc: { walletBalance: -feeAmount },
                $push: {
                    walletTransactions: {
                        amount: feeAmount,
                        type: 'debit',
                        description: `Payment for Booking: ${booking.category}`,
                        relatedBooking: booking._id,
                        date: new Date()
                    }
                }
            },
            { new: true }
        );

        if (!updatedUser) {
            return res.status(400).json({ msg: "Insufficient wallet balance or user not found during deduction" });
        }

        // Complete logic
        await completePaymentLogic(bookingId, 'WALLET_PAYMENT');
        res.json({ success: true, msg: "Payment completed successfully using wallet" });
    } catch (err) {
        console.error("Wallet Payment Error:", err);
        res.status(500).json({ msg: "Error processing wallet payment" });
    }
});

// @route   POST /api/payments/pay-cart-with-wallet
// @desc    Pay the booking fees for multiple bookings using wallet balance
// @access  Private
router.post('/pay-cart-with-wallet', verifyToken, async (req, res) => {
    const { bookingIds } = req.body;

    if (!bookingIds || !Array.isArray(bookingIds) || bookingIds.length === 0) {
        return res.status(400).json({ msg: "Invalid or missing booking IDs" });
    }

    try {
        const bookings = await Booking.find({ _id: { $in: bookingIds } });
        if (bookings.length === 0) {
            return res.status(404).json({ msg: "No valid bookings found" });
        }

        let totalFeeAmount = 0;
        const validBookings = [];

        for (let booking of bookings) {
            if (booking.paymentStatus === 'paid') continue; // Skip already paid
            
            let feeAmount = 0;
            if (booking.commissionAmount !== undefined && booking.commissionAmount !== null) {
                feeAmount = booking.commissionAmount;
            }
            
            if (feeAmount === 0) {
                try {
                    const categoryObj = await Category.findOne({ name: booking.category });
                    if (categoryObj) {
                        const commission = categoryObj.commissionPercentage || 0;
                        const referenceAmount = booking.amount || booking.minAmount || 0;
        
                        if (referenceAmount > 0) {
                            let calculatedFee = (referenceAmount * commission) / 100;
                            calculatedFee = Math.max(49, Math.min(calculatedFee, 999));
                            feeAmount = Math.ceil(calculatedFee);
                        } else {
                            feeAmount = commission > 0 ? Math.max(commission, 20) : 0;
                        }
                    }
                } catch (err) {
                    console.error("Error calculating fee fallback:", err);
                }
            }
            totalFeeAmount += feeAmount;
            validBookings.push(booking);
        }

        if (totalFeeAmount < 1) {
            return res.status(400).json({ msg: "Total booking fee is 0. Please use confirm-free-booking route." });
        }

        // Use atomic findOneAndUpdate to prevent race conditions
        const updatedUser = await User.findOneAndUpdate(
            { _id: req.user.id, walletBalance: { $gte: totalFeeAmount } },
            {
                $inc: { walletBalance: -totalFeeAmount },
                $push: {
                    walletTransactions: {
                        amount: totalFeeAmount,
                        type: 'debit',
                        description: `Payment for ${validBookings.length} Booking(s)`,
                        date: new Date()
                    }
                }
            },
            { new: true }
        );

        if (!updatedUser) {
            return res.status(400).json({ msg: "Insufficient wallet balance or user not found during deduction" });
        }

        // Complete logic for all
        for (let booking of validBookings) {
            await completePaymentLogic(booking._id, 'WALLET_PAYMENT_CART');
        }

        res.json({ success: true, msg: "Cart Payment completed successfully using wallet" });
    } catch (err) {
        console.error("Wallet Cart Payment Error:", err);
        res.status(500).json({ msg: "Error processing wallet cart payment" });
    }
});

// @route   POST /api/payments/create-cart-order
// @desc    Create a Razorpay order for multiple bookings (cart)
// @access  Private
router.post('/create-cart-order', verifyToken, async (req, res) => {
    const { bookingIds } = req.body;

    if (!razorpay) {
        return res.status(500).json({ msg: "Payment service configuration error." });
    }

    if (!Array.isArray(bookingIds) || bookingIds.length === 0) {
        return res.status(400).json({ msg: "No bookings provided" });
    }

    try {
        let totalFeeAmount = 0;
        const validBookings = [];

        for (const bookingId of bookingIds) {
            const booking = await Booking.findById(bookingId);
            if (!booking) continue;

            if (booking.paymentStatus === 'paid') {
                continue; // Skip already paid
            }

            validBookings.push(booking);

            let feeAmount = 0;
            if (booking.commissionAmount !== undefined && booking.commissionAmount !== null) {
                feeAmount = booking.commissionAmount;
            } 
            
            if (feeAmount === 0) {
                try {
                    const categoryObj = await Category.findOne({ name: booking.category });
                    if (categoryObj) {
                        const commission = categoryObj.commissionPercentage || 0;
                        const referenceAmount = booking.amount || booking.minAmount || 0;
        
                        if (referenceAmount > 0) {
                            let calculatedFee = (referenceAmount * commission) / 100;
                            calculatedFee = Math.max(49, Math.min(calculatedFee, 999));
                            feeAmount = Math.ceil(calculatedFee);
                        } else {
                            feeAmount = commission > 0 ? Math.max(commission, 20) : 0;
                        }
                    }
                } catch (err) {
                    console.error("Error calculating fee fallback:", err);
                }
            }
            totalFeeAmount += feeAmount;
        }

        if (validBookings.length === 0) {
             return res.status(400).json({ msg: "All bookings are already paid or invalid." });
        }

        if (totalFeeAmount < 1) {
            return res.status(400).json({ msg: "Total booking fee is 0. Please use confirm-free-booking route." });
        }

        const options = {
            amount: Math.round(totalFeeAmount * 100), // paise
            currency: "INR",
            receipt: `receipt_cart_${validBookings[0]._id.toString().substring(0,8)}`,
            notes: { cart: true, count: validBookings.length, userId: req.user.id }
        };

        const order = await razorpay.orders.create(options);
        
        // Update all valid bookings with the same orderId
        for (const booking of validBookings) {
            await Booking.findByIdAndUpdate(booking._id, { orderId: order.id });
        }

        res.json(order);
    } catch (err) {
        console.error("Razorpay Error:", err);
        res.status(500).json({ msg: "Error creating cart order" });
    }
});

// @route   POST /api/payments/verify-cart-payment
// @desc    Verify Razorpay payment signature for multiple bookings
// @access  Private
router.post('/verify-cart-payment', verifyToken, async (req, res) => {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, bookingIds } = req.body;

    const body = razorpay_order_id + "|" + razorpay_payment_id;
    const expectedSignature = crypto
        .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
        .update(body.toString())
        .digest('hex');

    if (expectedSignature === razorpay_signature) {
        try {
            for (const bookingId of bookingIds) {
                await completePaymentLogic(bookingId, razorpay_payment_id);
            }
            res.json({ success: true, msg: "Cart Payment verified successfully" });
        } catch (err) {
            console.error("Cart payment verification error:", err);
            res.status(500).json({ success: false, msg: "Error processing payment logic" });
        }
    } else {
        res.status(400).json({ success: false, msg: "Invalid signature" });
    }
});

module.exports = router;
