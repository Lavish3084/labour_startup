const express = require('express');
const router = express.Router();
const Faq = require('../models/Faq');

// @route   GET /api/faqs
// @desc    Get all active FAQs or filtered by category name
// @access  Public
router.get('/', async (req, res) => {
    try {
        const { category } = req.query;
        let query = {};
        if (category) {
            query.categories = category;
        }
        const faqs = await Faq.find(query).sort({ createdAt: -1 });
        res.json(faqs);
    } catch (err) {
        console.error('Fetch FAQs Error:', err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
