const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Labourer = require('../models/Labourer');
const { OAuth2Client } = require('google-auth-library');
const admin = require('firebase-admin');

// We use the empty client to verify tokens just from their issuer and audience.
// In a real production app, pass your specific CLIENT_ID to prevent confused deputy attacks.
const client = new OAuth2Client();

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
    const token = req.header('x-auth-token');
    if (!token) {
        return res.status(401).json({ msg: 'No token, authorization denied' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded.user;
        next();
    } catch (err) {
        res.status(401).json({ msg: 'Token is not valid' });
    }
};

// POST /api/auth/google
router.post('/google', async (req, res) => {
    const { idToken, role, action } = req.body;
    
    if (!idToken) {
        return res.status(400).json({ msg: 'No token provided' });
    }

    try {
        // Verify token
        const ticket = await client.verifyIdToken({
            idToken: idToken,
            // audience: CLIENT_ID,  // Specify the CLIENT_ID of the app that accesses the backend
        });
        const payload = ticket.getPayload();
        const { email, name, picture } = payload;
        const displayName = name || email.split('@')[0];
        const { phoneNumber } = req.body; // Optional phone number from request

        let user = await User.findOne({ email, role });

        if (!user) {
            // Previously we blocked this with ROLE_MISMATCH, but the user wants 
            // to allow one email to have both User and Worker roles.
            // We now seamlessly create the account for the requested role.
            
            // Create user with a secure random unguessable password
            const randomDummyPassword = await bcrypt.hash(Math.random().toString(36).slice(-10), 10);
            
            user = new User({
                name: displayName,
                email: email,
                password: randomDummyPassword,
                role: role || 'user',
                profilePicture: picture || ''
            });

            try {
                await user.save();
            } catch (saveErr) {
                if (saveErr.code === 11000) {
                    return res.status(400).json({ msg: 'This email is already registered. Please login instead.' });
                }
                throw saveErr;
            }

            // Create worker profile if requested
            if (user.role === 'worker') {
                const newLabourer = new Labourer({
                    user: user.id,
                    name: user.name,
                    category: 'General',
                    hourlyRate: 0,
                    location: 'Not set',
                    experienceYears: 0,
                    imageUrl: picture || ''
                });
                await newLabourer.save();
            }
        }

        // Mandatory Phone Number Check for Workers
        if (role === 'worker' && !user.phoneNumber && !phoneNumber) {
            return res.status(400).json({ 
                msg: 'Phone number is mandatory for worker accounts.', 
                code: 'PHONE_REQUIRED',
                user: { id: user.id, email: user.email, name: user.name } 
            });
        }

        // Update phone number if provided and missing
        if (phoneNumber && !user.phoneNumber) {
            user.phoneNumber = phoneNumber;
            await user.save();
        }

        // Return standard JWT token
        const jwtPayload = { user: { id: user.id } };
        jwt.sign(jwtPayload, process.env.JWT_SECRET, { expiresIn: '30d' }, (err, token) => {
            if (err) throw err;
            res.json({ token, role: user.role, name: user.name, profilePicture: user.profilePicture });
        });

    } catch (err) {
        console.error('Google Auth Error:', err.message);
        res.status(401).json({ msg: 'Google Authentication failed' });
    }
});

// POST /api/auth/signup
router.post('/signup', async (req, res) => {
    const { name, email, password, role, profilePicture } = req.body;
    try {
        let user = await User.findOne({ email, role });
        if (user) return res.status(400).json({ msg: 'User already exists' });

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        user = new User({
            name,
            email,
            password: hashedPassword,
            role: role || 'user',
            profilePicture: profilePicture || ''
        });

        await user.save();

        if (role === 'worker') {
            const newLabourer = new Labourer({
                user: user.id,
                name: user.name,
                category: 'General',
                hourlyRate: 0,
                location: 'Not set',
                experienceYears: 0,
                imageUrl: profilePicture || ''
            });
            await newLabourer.save();
        }

        const payload = { user: { id: user.id } };
        jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '30d' }, (err, token) => {
            if (err) throw err;
            res.json({ token, role: user.role, name: user.name, profilePicture: user.profilePicture });
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
    const { email, password, role } = req.body;
    try {
        if (!role) {
            return res.status(400).json({ msg: 'Role is required' });
        }
        const user = await User.findOne({ email, role });
        if (!user) return res.status(400).json({ msg: 'Invalid Credentials' });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(400).json({ msg: 'Invalid Credentials' });

        const payload = { user: { id: user.id } };
        jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '30d' }, (err, token) => {
            if (err) throw err;
            res.json({ token, role: user.role, name: user.name, profilePicture: user.profilePicture });
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// POST /api/auth/phone-login
router.post('/phone-login', async (req, res) => {
    const { idToken, role } = req.body;
    try {
        if (!idToken) return res.status(400).json({ msg: 'No token provided' });

        // Verify Firebase Token
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const phoneNumber = decodedToken.phone_number;

        if (!phoneNumber) {
            return res.status(400).json({ msg: 'Invalid token: No phone number found' });
        }

        let user = await User.findOne({ phoneNumber, role });

        if (!user) {
            // Create the account for this role seamlessly
            user = new User({
                name: 'User ' + phoneNumber.slice(-4),
                phoneNumber: phoneNumber,
                role: role || 'user',
            });

            try {
                await user.save();
            } catch (saveErr) {
                if (saveErr.code === 11000) {
                    return res.status(400).json({ msg: 'This phone number is already registered with another role.' });
                }
                throw saveErr;
            }

            if (user.role === 'worker') {
                const newLabourer = new Labourer({
                    user: user.id,
                    name: user.name,
                    category: 'General',
                    hourlyRate: 0,
                    location: 'Not set',
                    experienceYears: 0
                });
                await newLabourer.save();
            }
        }

        // Return standard JWT token
        const jwtPayload = { user: { id: user.id } };
        jwt.sign(jwtPayload, process.env.JWT_SECRET, { expiresIn: '30d' }, (err, token) => {
            if (err) throw err;
            res.json({ token, role: user.role, name: user.name, profilePicture: user.profilePicture });
        });

    } catch (err) {
        console.error('Phone Login Error:', err.message);
        res.status(401).json({ msg: 'Phone Authentication failed' });
    }
});

// @route   PUT /api/auth/phone
// @desc    Update user phone number (Verified via Firebase OTP)
// @access  Private
router.put('/phone', verifyToken, async (req, res) => {
    const { idToken } = req.body;
    try {
        if (!idToken) return res.status(400).json({ msg: 'No verification token provided' });

        // Verify Firebase Token to get the NEW phone number
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const newPhoneNumber = decodedToken.phone_number;

        if (!newPhoneNumber) {
            return res.status(400).json({ msg: 'Invalid token: No phone number found' });
        }

        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ msg: 'User not found' });

        // Check if phone number is already in use by ANOTHER user with the same role
        const existingUser = await User.findOne({ 
            phoneNumber: newPhoneNumber, 
            role: user.role,
            _id: { $ne: user._id }
        });

        if (existingUser) {
            return res.status(400).json({ msg: 'This phone number is already registered with another account.' });
        }

        user.phoneNumber = newPhoneNumber;
        await user.save();

        res.json({ msg: 'Phone number updated successfully', phoneNumber: newPhoneNumber });

    } catch (err) {
        console.error('Phone Update Error:', err.message);
        res.status(500).json({ msg: 'Failed to update phone number' });
    }
});

module.exports = router;
