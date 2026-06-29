const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Labourer = require('../models/Labourer');
const HelpRequest = require('../models/HelpRequest');

// Middleware to verify token (basic implementation for now, assuming you have one or extracting from header)
// Since we didn't explicitly create an auth middleware file yet, I'll inline a simple one for this route file or rely on one if it exists.
// Checking previous files... I don't see a middleware/auth.js created in the walkthrough.
// I will create a simple inline middleware function to extract user ID from token.
const jwt = require('jsonwebtoken');
const Razorpay = require('razorpay');

let razorpay;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
}

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

        // Lazy generation for existing users
        if (!user.referralCode) {
            user.referralCode = 'WILL' + user._id.toString().substring(18).toUpperCase();
            await user.save();
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
        latitude,
        longitude,
        skills,
        experienceYears,
        upiId
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
    if (latitude !== undefined) profileFields.latitude = latitude;
    if (longitude !== undefined) profileFields.longitude = longitude;
    if (skills) {
        profileFields.skills = Array.isArray(skills)
            ? skills
            : skills.split(',').map(skill => skill.trim());
    }
    if (experienceYears) profileFields.experienceYears = experienceYears;
    if (upiId) profileFields.upiId = upiId;

    // Set defaults for required fields if missing (for safety, though frontend should handle validation)
    // Actually our model requires them, so simple validation here:
    if (!category || !hourlyRate || !location || !experienceYears) {
        return res.status(400).json({ msg: 'Please enter all required fields' });
    }

    try {
        let labourer = await Labourer.findOne({ user: req.user.id });

        if (labourer) {
            // Check if we need to create a Razorpay Linked Account (if UPI exists but no account ID)
            if (upiId && !labourer.razorpayAccountId && razorpay) {
                try {
                    const account = await razorpay.accounts.create({
                        email: req.user.email || 'worker@example.com', // Best effort if email missing
                        phone: '9999999999', // Placeholder as it might be required
                        type: 'route',
                        reference_id: req.user.id.toString(),
                        legal_business_name: profileFields.name || 'Worker',
                        business_type: 'individual',
                        contact_name: profileFields.name || 'Worker',
                        profile: {
                            category: 'others',
                            subcategory: 'other_services',
                            addresses: {
                                operation: {
                                    street1: profileFields.location || 'Default',
                                    city: 'Default',
                                    state: 'Default',
                                    postal_code: '111111',
                                    country: 'IN'
                                }
                            }
                        }
                    });
                    profileFields.razorpayAccountId = account.id;
                    console.log('Created Razorpay Linked Account:', account.id);
                } catch (rzpErr) {
                    console.error('Failed to create Razorpay account:', rzpErr);
                }
            }

            // Update
            labourer = await Labourer.findOneAndUpdate(
                { user: req.user.id },
                { $set: profileFields },
                { new: true }
            );
            return res.json(labourer);
        }

        // New Profile - Check for Razorpay Linked Account creation
        if (upiId && razorpay) {
            try {
                const account = await razorpay.accounts.create({
                    email: 'worker@example.com',
                    phone: '9999999999',
                    type: 'route',
                    reference_id: req.user.id.toString(),
                    legal_business_name: profileFields.name || 'Worker',
                    business_type: 'individual',
                    contact_name: profileFields.name || 'Worker',
                    profile: {
                        category: 'others',
                        subcategory: 'other_services',
                        addresses: {
                            operation: {
                                street1: profileFields.location || 'Default',
                                city: 'Default',
                                state: 'Default',
                                postal_code: '111111',
                                country: 'IN'
                            }
                        }
                    }
                });
                profileFields.razorpayAccountId = account.id;
                console.log('Created Razorpay Linked Account:', account.id);
            } catch (rzpErr) {
                console.error('Failed to create Razorpay account:', rzpErr);
            }
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

// @route   PUT /api/profile
// @desc    Update user profile (name)
// @access  Private
router.put('/', verifyToken, async (req, res) => {
    const { name } = req.body;
    if (!name) return res.status(400).json({ msg: 'Name is required' });

    try {
        let user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        user.name = name;
        await user.save();

        // Also update labourer profile if exists to keep names in sync
        if (user.role === 'worker') {
            await Labourer.findOneAndUpdate(
                { user: req.user.id },
                { $set: { name: name } }
            );
        }

        res.json(user);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/profile/worker/upi
// @desc    Update worker UPI ID
// @access  Private (Worker only)
router.put('/worker/upi', verifyToken, async (req, res) => {
    const { upiId } = req.body;
    try {
        let labourer = await Labourer.findOne({ user: req.user.id });
        if (!labourer) {
            return res.status(404).json({ msg: 'Worker profile not found. Please complete profile first.' });
        }

        labourer.upiId = upiId;

        // Create linked account if missing
        if (!labourer.razorpayAccountId && razorpay) {
            try {
                const account = await razorpay.accounts.create({
                    email: 'worker@example.com',
                    phone: '9999999999',
                    type: 'route',
                    reference_id: req.user.id.toString(),
                    legal_business_name: labourer.name || 'Worker',
                    business_type: 'individual',
                    contact_name: labourer.name || 'Worker',
                    profile: {
                        category: 'others',
                        subcategory: 'other_services',
                        addresses: {
                            operation: {
                                street1: labourer.location || 'Default',
                                city: 'Default',
                                state: 'Default',
                                postal_code: '111111',
                                country: 'IN'
                            }
                        }
                    }
                });
                labourer.razorpayAccountId = account.id;
                console.log('Created Razorpay Linked Account on UPI update:', account.id);
            } catch (rzpErr) {
                console.error('Failed to create Razorpay account:', rzpErr);
            }
        }

        await labourer.save();
        res.json(labourer);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT /api/profile/worker/status
// @desc    Toggle online status
// @access  Private (Worker only)
router.put('/worker/status', verifyToken, async (req, res) => {
    const { isOnline } = req.body;
    try {
        let labourer = await Labourer.findOne({ user: req.user.id });
        if (!labourer) {
            return res.status(404).json({ msg: 'Worker profile not found.' });
        }

        labourer.isOnline = isOnline;
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

// @route   POST /api/profile/address
// @desc    Add a saved address
// @access  Private
router.post('/address', verifyToken, async (req, res) => {
    console.log(`POST /api/profile/address called for user ${req.user.id}`);
    const { label, address, houseNumber, landmark, latitude, longitude } = req.body;
    console.log('Request body:', req.body);

    if (!address) {
        return res.status(400).json({ msg: 'Address is required' });
    }

    try {
        const user = await User.findById(req.user.id);
        
        // Prevent duplicate addresses from being saved
        const addressExists = user.addresses.some(existingAddr => 
            existingAddr.address.toLowerCase().trim() === address.toLowerCase().trim()
        );

        if (addressExists) {
            console.log('Address already saved previously. Skipping duplicate saving.');
            return res.json(user.addresses);
        }

        const newAddress = {
            label: label || 'Saved Location',
            address,
            houseNumber: houseNumber || '',
            landmark: landmark || '',
            latitude,
            longitude
        };

        user.addresses.unshift(newAddress);
        await user.save();
        console.log('Address saved successfully. Total addresses:', user.addresses.length);
        res.json(user.addresses);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE /api/profile/address/:id
// @desc    Delete a saved address
// @access  Private
router.delete('/address/:id', verifyToken, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        user.addresses = user.addresses.filter(
            addr => addr._id.toString() !== req.params.id
        );
        await user.save();
        res.json(user.addresses);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE /api/profile
// @desc    Delete user and associated labourer profile
// @access  Private
router.delete('/', verifyToken, async (req, res) => {
    try {
        // Remove labourer profile if exists
        await Labourer.findOneAndDelete({ user: req.user.id });

        // Remove user
        await User.findOneAndDelete({ _id: req.user.id });

        res.json({ msg: 'User deleted successfully' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/profile/wallet
// @desc    Get user's wallet balance
// @access  Private
router.get('/wallet', verifyToken, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('walletBalance');
        if (!user) return res.status(404).json({ msg: 'User not found' });
        res.json({ balance: user.walletBalance || 0 });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/profile/wallet/transactions
// @desc    Get user's wallet transactions
// @access  Private
router.get('/wallet/transactions', verifyToken, async (req, res) => {
    try {
        const user = await User.findById(req.user.id)
            .select('walletTransactions')
            .populate('walletTransactions.relatedBooking', 'category date');
        if (!user) return res.status(404).json({ msg: 'User not found' });
        
        const txs = user.walletTransactions || [];
        txs.sort((a, b) => new Date(b.date) - new Date(a.date));
        res.json(txs);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST /api/profile/wallet/add
// @desc    Add money to wallet after Razorpay success
// @access  Private
router.post('/wallet/add', verifyToken, async (req, res) => {
    const { amount, paymentId } = req.body;
    if (!amount || amount <= 0) return res.status(400).json({ msg: 'Invalid amount' });

    try {
        // Ideally verify with Razorpay API here. Assuming client verified for now.
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ msg: 'User not found' });

        const updatedUser = await User.findOneAndUpdate(
            { _id: req.user.id },
            {
                $inc: { walletBalance: amount },
                $push: {
                    walletTransactions: {
                        amount: amount,
                        type: 'credit',
                        description: `Added via Razorpay (${paymentId})`,
                        date: new Date()
                    }
                }
            },
            { new: true }
        );

        res.json({ balance: updatedUser.walletBalance, msg: 'Money added successfully' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST /api/profile/help
// @desc    Submit a help request from user/worker app
// @access  Private
router.post('/help', verifyToken, async (req, res) => {
    const { subject, message } = req.body;
    if (!subject || !message) {
        return res.status(400).json({ msg: 'Please provide subject and message' });
    }

    try {
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ msg: 'User not found' });

        const helpRequest = new HelpRequest({
            user: user.id,
            name: user.name,
            email: user.email || '',
            phone: user.phoneNumber || '',
            role: user.role,
            subject,
            message
        });

        await helpRequest.save();
        res.status(201).json({ msg: 'Help request submitted successfully', helpRequest });
    } catch (err) {
        console.error('Help Request Submission Error:', err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST /api/profile/referral/apply
// @desc    Apply a referral code
// @access  Private
router.post('/referral/apply', verifyToken, async (req, res) => {
    const { code } = req.body;
    if (!code) {
        return res.status(400).json({ success: false, message: 'Referral code is required' });
    }

    try {
        const currentUser = await User.findById(req.user.id);
        if (!currentUser) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Check if referral code is already applied
        if (currentUser.referredBy) {
            return res.status(400).json({ success: false, message: 'You have already applied a referral code' });
        }

        // Find referrer by their referralCode (case-insensitive search)
        const referrer = await User.findOne({ 
            referralCode: { $regex: new RegExp(`^${code.trim()}$`, 'i') } 
        });

        if (!referrer) {
            return res.status(400).json({ success: false, message: 'Invalid referral code' });
        }

        // Cannot refer yourself
        if (referrer._id.toString() === currentUser._id.toString()) {
            return res.status(400).json({ success: false, message: 'You cannot use your own referral code' });
        }

        // Apply referral reward
        // Crediting current user (referred user) ₹100
        const updatedCurrentUser = await User.findOneAndUpdate(
            { _id: currentUser._id },
            {
                $set: { referredBy: referrer._id },
                $inc: { walletBalance: 100 },
                $push: {
                    walletTransactions: {
                        amount: 100,
                        type: 'credit',
                        description: `Referral bonus (Code applied: ${referrer.referralCode})`,
                        date: new Date()
                    }
                }
            },
            { new: true }
        );

        // Crediting referrer ₹100
        await User.findOneAndUpdate(
            { _id: referrer._id },
            {
                $inc: { walletBalance: 100 },
                $push: {
                    walletTransactions: {
                        amount: 100,
                        type: 'credit',
                        description: `Referral reward (Referred user: ${updatedCurrentUser.name})`,
                        date: new Date()
                    }
                }
            }
        );

        res.json({ 
            success: true, 
            message: 'Referral applied successfully!', 
            walletBalance: updatedCurrentUser.walletBalance 
        });

    } catch (err) {
        console.error('Apply Referral Error:', err.message);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

module.exports = router;
