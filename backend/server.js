const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const admin = require('firebase-admin');

dotenv.config();

// Initialize Firebase Admin
if (!admin.apps.length) {
    try {
        let serviceAccount;
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            console.log('Firebase Admin: Initializing with service account from env var');
            serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        } else {
            console.log('Firebase Admin: Initializing with service account from file');
            serviceAccount = require('./serviceAccountKey.json');
        }
        
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin Initialized');
    } catch (error) {
        console.warn('WARNING: Firebase Admin failed to initialize:', error.message);
        console.warn('Push notifications and Phone Login will NOT work until initialized.');
    }
}

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));

app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// Routes
const authRoutes = require('./routes/auth');
const labourerRoutes = require('./routes/labourers');
const profileRoutes = require('./routes/profile');
const bookingRoutes = require('./routes/bookings');
const paymentRoutes = require('./routes/payments');

const adminRoutes = require('./routes/admin');
const categoriesRoutes = require('./routes/categories');
const settingsRoutes = require('./routes/settings');

app.use('/api/auth', authRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/labourers', labourerRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/settings', settingsRoutes);

// Database Connection
mongoose.connect(process.env.MONGO_URI)
    .then(() => console.log('MongoDB Connected'))
    .catch(err => console.log(err));

app.get('/', (req, res) => {
    res.send('Labour Market Backend is running');
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
