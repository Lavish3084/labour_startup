const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

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

app.use('/api/auth', authRoutes);
app.use('/api/labourers', labourerRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);

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
