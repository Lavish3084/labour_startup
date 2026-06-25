const express = require('express');
const router = express.Router();
const Category = require('../models/Category');
const Labourer = require('../models/Labourer');

// @route   GET /api/categories
// @desc    Get all active categories
// @access  Public
router.get('/', async (req, res) => {
    try {
        const categories = await Category.find({ isActive: true }).sort({ name: 1 }).lean();
        
        // Aggregate average rating per category
        const ratings = await Labourer.aggregate([
            { $group: { _id: "$category", avgRating: { $avg: "$rating" } } }
        ]);
        
        const ratingMap = {};
        ratings.forEach(r => {
            ratingMap[r._id] = r.avgRating;
        });

        const categoriesWithRating = categories.map(cat => ({
            ...cat,
            // If no labourers or 0 rating, default to 4.5 so it doesn't look bad initially, 
            // but use actual rating if it exists and is > 0
            rating: (ratingMap[cat.name] && ratingMap[cat.name] > 0) ? ratingMap[cat.name] : 4.5
        }));

        res.json(categoriesWithRating);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
