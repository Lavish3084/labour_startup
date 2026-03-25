const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Labourer = require('../models/Labourer');
const { OAuth2Client } = require('google-auth-library');

// We use the empty client to verify tokens just from their issuer and audience.
// In a real production app, pass your specific CLIENT_ID to prevent confused deputy attacks.
const client = new OAuth2Client();

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

        let user = await User.findOne({ email });

        if (!user) {
            // If action is login, don't auto-create the account
            if (action === 'login') {
                return res.status(404).json({ msg: 'Account does not exist. Please sign up first.', code: 'USER_NOT_FOUND' });
            }

            // Create user with a secure random unguessable password so the DB schema validation passes
            const randomDummyPassword = await bcrypt.hash(Math.random().toString(36).slice(-10), 10);
            
            user = new User({
                name: name,
                email: email,
                password: randomDummyPassword,
                role: role || 'user',
                profilePicture: picture || ''
            });
            await user.save();

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
        let user = await User.findOne({ email });
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
    const { email, password } = req.body;
    try {
        const user = await User.findOne({ email });
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

module.exports = router;
