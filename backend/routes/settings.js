const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Setting = require('../models/Setting');
const { isPointInAnyZone } = require('../utils/geoUtils');

// Middleware to verify admin role (consistent with admin.js)
const verifyAdmin = async (req, res, next) => {
    try {
        const token = req.header('x-auth-token');
        if (!token) return res.status(401).json({ msg: 'No token, authorization denied' });

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.user.id);

        if (!user || user.role !== 'admin') {
            return res.status(403).json({ msg: 'Access denied. Admin only.' });
        }

        req.user = user;
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
        console.log("Fetching global settings - Start");
        if (!Setting) {
            console.error("Setting model is NOT defined!");
            return res.status(500).json({ msg: 'Model Error', error: 'Setting model is not defined' });
        }
        const settings = await Setting.find();
        console.log(`Found ${settings.length} settings`);
        const config = {};
        settings.forEach(s => {
            if (s && s.key) {
                config[s.key] = s.value;
            }
        });
        res.json(config);
    } catch (err) {
        console.error("Error in GET /api/settings:", err);
        res.status(500).json({ 
            msg: 'Server Error', 
            error: err.message,
            stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
        });
    }
});

// GET check if a coordinate is in an active service zone
// Usage: GET /settings/check-location?lat=30.7046&lng=76.7179
router.get('/check-location', async (req, res) => {
    try {
        const lat = parseFloat(req.query.lat);
        const lng = parseFloat(req.query.lng);

        if (isNaN(lat) || isNaN(lng)) {
            return res.status(400).json({ msg: 'Invalid coordinates. Provide lat and lng as query params.' });
        }

        // Fetch serviceZones from settings
        const zonesSetting = await Setting.findOne({ key: 'serviceZones' });
        let zones = [];

        if (zonesSetting && zonesSetting.value) {
            // value could be a JSON string or already parsed array
            if (typeof zonesSetting.value === 'string') {
                try {
                    zones = JSON.parse(zonesSetting.value);
                } catch (e) {
                    zones = [];
                }
            } else if (Array.isArray(zonesSetting.value)) {
                zones = zonesSetting.value;
            }
        }

        // If no zones configured, fall back to legacy text-based check
        if (zones.length === 0) {
            const citiesSetting = await Setting.findOne({ key: 'enabledCities' });
            if (!citiesSetting || !citiesSetting.value || citiesSetting.value.toString().trim() === '') {
                // No restrictions at all
                return res.json({ active: true, nearestZone: null, method: 'no_restrictions' });
            }
            // Can't do text-based check with coordinates alone, return unknown
            return res.json({ active: null, nearestZone: null, method: 'legacy_text_only' });
        }

        const result = isPointInAnyZone(lat, lng, zones);
        res.json({ ...result, method: 'geofence' });
    } catch (err) {
        console.error("Error in GET /settings/check-location:", err);
        res.status(500).json({ msg: 'Server Error', error: err.message });
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
router.put('/', verifyAdmin, async (req, res) => {
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

