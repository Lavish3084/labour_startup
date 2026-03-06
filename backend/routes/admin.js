const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Category = require('../models/Category');
const Booking = require('../models/Booking');
const Labourer = require('../models/Labourer');

// Middleware to verify admin role
const verifyAdmin = async (req, res, next) => {
    try {
        const token = req.header('x-auth-token');
        if (!token) return res.status(401).json({ msg: 'No token, authorization denied' });

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.user.id);

        if (!user || user.role !== 'admin') {
            return res.status(403).json({ msg: 'Access denied. Admin only.' });
        }

        req.user = decoded;
        next();
    } catch (err) {
        res.status(401).json({ msg: 'Token is not valid' });
    }
};

// @route   GET /api/admin/stats
// @desc    Get dashboard statistics
router.get('/stats', verifyAdmin, async (req, res) => {
    try {
        const totalUsers = await User.countDocuments({ role: 'user' });
        const totalWorkers = await User.countDocuments({ role: 'worker' });
        const totalBookings = await Booking.countDocuments();
        const completedBookings = await Booking.countDocuments({ status: 'completed' });

        // Active users (booked in last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const activeUsersList = await Booking.distinct('user', {
            createdAt: { $gte: thirtyDaysAgo }
        });
        const activeUsers = activeUsersList.length;

        // Revenue calculation
        const revenueData = await Booking.aggregate([
            { $match: { paymentStatus: 'paid' } },
            { $group: { _id: null, total: { $sum: "$amount" } } }
        ]);
        const totalRevenue = revenueData.length > 0 ? revenueData[0].total : 0;

        // Recent bookings
        const recentBookings = await Booking.find()
            .populate('user', 'name')
            .sort({ createdAt: -1 })
            .limit(5);

        res.json({
            stats: {
                totalUsers,
                totalWorkers,
                totalBookings,
                completedBookings,
                totalRevenue,
                activeUsers
            },
            recentBookings
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/admin/categories
// @desc    Get all categories
router.get('/categories', verifyAdmin, async (req, res) => {
    try {
        const categories = await Category.find().sort({ name: 1 });
        res.json(categories);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST /api/admin/categories
// @desc    Create a category
router.post('/categories', verifyAdmin, async (req, res) => {
    const { name, iconName, description, supportedModes, hourlyRate, dailyRate } = req.body;
    try {
        let category = new Category({
            name,
            iconName,
            description,
            supportedModes,
            hourlyRate,
            dailyRate
        });
        await category.save();
        res.json(category);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/admin/categories/:id
// @desc    Update a category
router.put('/categories/:id', verifyAdmin, async (req, res) => {
    try {
        const category = await Category.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true }
        );
        res.json(category);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/admin/users
// @desc    Get all users and workers
router.get('/users', verifyAdmin, async (req, res) => {
    try {
        const users = await User.find().select('-password').sort({ createdAt: -1 });
        res.json(users);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/admin/bookings
// @desc    Get all bookings
router.get('/bookings', verifyAdmin, async (req, res) => {
    try {
        const bookings = await Booking.find()
            .populate('user', 'name email')
            .populate({
                path: 'labourer',
                select: 'name'
            })
            .sort({ createdAt: -1 });
        res.json(bookings);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

module.exports = router;
