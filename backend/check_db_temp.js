const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env
dotenv.config();

const Labourer = require('./models/Labourer');
const Booking = require('./models/Booking');
const User = require('./models/User');

async function checkDb() {
    try {
        console.log('Connecting to MongoDB...');
        if (!process.env.MONGO_URI) {
            console.error('MONGO_URI not found in .env');
            return;
        }
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected.');

        console.log('\n--- LABOURERS ---');
        const labourers = await Labourer.find().populate('user', 'name fcmToken');
        labourers.forEach(l => {
            console.log(`ID: ${l._id}`);
            console.log(`Name: ${l.name}`);
            console.log(`Category: "${l.category}"`);
            console.log(`IsOnline: ${l.isOnline}`);
            console.log(`User ID: ${l.user ? l.user._id : 'null'}`);
            console.log(`FCM Token: ${l.user && l.user.fcmToken ? (l.user.fcmToken.substring(0, 10) + '...') : 'No'}`);
            console.log('-----------------');
        });

        console.log('\n--- PENDING BROADCAST BOOKINGS ---');
        const bookings = await Booking.find({ status: 'pending', labourer: null });
        console.log(`Total Pending Broadcasts: ${bookings.length}`);
        bookings.forEach(b => {
            console.log(`ID: ${b._id}`);
            console.log(`Category: "${b.category}"`);
            console.log(`Date: ${b.date}`);
            console.log(`Created At: ${b.createdAt}`);
            console.log('-----------------');
        });

        console.log('\n--- ACTIVE COMMITMENTS (Hiding others) ---');
        const active = await Booking.find({
            status: { $in: ['confirmed', 'arrived'] }
        });
        console.log(`Total Active: ${active.length}`);
        active.forEach(a => {
            console.log(`ID: ${a._id}`);
            console.log(`Worker ID: ${a.labourer}`);
            console.log(`Status: ${a.status}`);
            console.log(`Date: ${a.date}`);
            console.log('-----------------');
        });

    } catch (err) {
        console.error('Error:', err);
    } finally {
        await mongoose.disconnect();
        console.log('\nDisconnected.');
    }
}

checkDb();
