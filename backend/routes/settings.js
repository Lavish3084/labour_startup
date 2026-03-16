const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

// Middleware to verify token
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

// GET settings (can be accessed by admin or regular users if needed, maybe only adminCommissionPercentage)
// Actually, public access is fine for generic config, but maybe we only need it for admin and internally.
// Let's make a generic endpoint for generic configs.
router.get('/', async (req, res) => {
    try {
        const settings = await Setting.find();
        const config = {};
        settings.forEach(s => config[s.key] = s.value);
        res.json(config);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// GET specific setting by key
router.get('/:key', async (req, res) => {
    try {
        const setting = await Setting.findOne({ key: req.params.key });
        if (!setting) {
            return res.status(404).json({ msg: 'Setting not found' });
        }
        res.json(setting.value);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// POST/PUT global settings (Admin Only)
router.put('/', verifyToken, async (req, res) => {
    // Add simple role check
    if (req.user.role !== 'admin') {
        return res.status(403).json({ msg: 'Access denied. Admins only.' });
    }

    try {
        const updates = req.body; // e.g., { adminCommissionPercentage: 10 }
        
        for (const [key, value] of Object.entries(updates)) {
            await Setting.findOneAndUpdate(
                { key },
                { value, updatedAt: Date.now() },
                { new: true, upsert: true } // Create if doesn't exist
            );
        }

        const settings = await Setting.find();
        const config = {};
        settings.forEach(s => config[s.key] = s.value);
        res.json(config);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
