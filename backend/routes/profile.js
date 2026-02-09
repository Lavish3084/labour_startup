const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Labourer = require('../models/Labourer');

// Middleware to verify token (basic implementation for now, assuming you have one or extracting from header)
// Since we didn't explicitly create an auth middleware file yet, I'll inline a simple one for this route file or rely on one if it exists.
// Checking previous files... I don't see a middleware/auth.js created in the walkthrough.
// I will create a simple inline middleware function to extract user ID from token.
const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
    const token = req.header('x-auth-token');
    if (!token) {
        console.log('No token provided');
        return res.status(401).json({ msg: 'No token, authorization denied' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded.user;
        next();
    } catch (err) {
        console.log('Token verification failed:', err.message);
        res.status(401).json({ msg: 'Token is not valid' });
    }
};

// @route   GET /api/profile/me
// @desc    Get current user profile
// @access  Private
router.get('/me', verifyToken, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        let profileData = { user };

        if (user.role === 'worker') {
            const labourer = await Labourer.findOne({ user: req.user.id });
            if (labourer) {
                profileData.labourer = labourer;
            } else {
                profileData.labourer = null; // Profile not completed yet
            }
        }

        res.json(profileData);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST /api/profile/worker
// @desc    Create or Update worker profile
// @access  Private (Worker only)
router.post('/worker', verifyToken, async (req, res) => {
    const {
        category,
        hourlyRate,
        description,
        location,
        skills,
        experienceYears
    } = req.body;

    // specialized build object
    const profileFields = {};
    profileFields.user = req.user.id;
    // Fetch user name to populate basic labourer name (as they are linked)
    // In a real app, you might want separate display names, but for now we sync them or pass them.
    // Let's fetch the user to get the name.
    try {
        const user = await User.findById(req.user.id);
        if (user.role !== 'worker') {
            return res.status(403).json({ msg: 'Access denied: Not a worker' });
        }
        profileFields.name = user.name;
    } catch (err) {
        return res.status(500).send('Server Error');
    }

    if (category) profileFields.category = category;
    if (hourlyRate) profileFields.hourlyRate = hourlyRate;
    if (description) profileFields.description = description;
    if (location) profileFields.location = location;
    if (skills) {
        profileFields.skills = Array.isArray(skills)
            ? skills
            : skills.split(',').map(skill => skill.trim());
    }
    if (experienceYears) profileFields.experienceYears = experienceYears;

    // Set defaults for required fields if missing (for safety, though frontend should handle validation)
    // Actually our model requires them, so simple validation here:
    if (!category || !hourlyRate || !location || !experienceYears) {
        return res.status(400).json({ msg: 'Please enter all required fields' });
    }

    try {
        let labourer = await Labourer.findOne({ user: req.user.id });

        if (labourer) {
            // Update
            labourer = await Labourer.findOneAndUpdate(
                { user: req.user.id },
                { $set: profileFields },
                { new: true }
            );
            return res.json(labourer);
        }

        // Create
        labourer = new Labourer(profileFields);
        await labourer.save();
        res.json(labourer);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/profile/fcm-token
// @desc    Update FCM Token
// @access  Private
router.put('/fcm-token', verifyToken, async (req, res) => {
    const { fcmToken } = req.body;
    console.log(`Received FCM Token update for user ${req.user.id}: ${fcmToken ? fcmToken.substring(0, 10) + '...' : 'null'}`);
    try {
        await User.findByIdAndUpdate(req.user.id, { fcmToken });
        res.json({ msg: 'FCM Token updated' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/profile/image
// @desc    Update profile picture
// @access  Private
router.put('/image', verifyToken, async (req, res) => {
    console.log('PUT /api/profile/image called');
    const { profilePicture } = req.body;

    if (!profilePicture) {
        console.log('No profilePicture provided in body');
        return res.status(400).json({ msg: 'No image data provided' });
    }

    console.log(`Received profilePicture length: ${profilePicture.length}`);

    try {
        let user = await User.findById(req.user.id);
        if (!user) {
            console.log('User not found');
            return res.status(404).json({ msg: 'User not found' });
        }

        user.profilePicture = profilePicture;
        await user.save();
        console.log('User profile picture updated');

        if (user.role === 'worker') {
            await Labourer.findOneAndUpdate(
                { user: req.user.id },
                { $set: { imageUrl: profilePicture } }
            );
            console.log('Worker imageUrl updated');
        }

        res.json(user);
    } catch (err) {
        console.error('Error updating profile picture:', err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
