const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const User = require('./models/User'); // Register User schema
const Labourer = require('./models/Labourer');
const Booking = require('./models/Booking');

async function checkDb() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        
        console.log('\n--- LABOURERS ---');
        const labourers = await Labourer.find();
        labourers.forEach(l => {
            console.log(`L_ID: ${l._id} | Name: ${l.name} | Cat: "${l.category}" | Online: ${l.isOnline}`);
        });

        console.log('\n--- RECENT PENDING BROADCASTS ---');
        const bookings = await Booking.find({ status: 'pending', labourer: null }).sort({ createdAt: -1 }).limit(10);
        bookings.forEach(b => {
            console.log(`B_ID: ${b._id} | Cat: "${b.category}" | Date: ${b.date}`);
        });

    } catch (err) {
        console.error('Error:', err);
    } finally {
        await mongoose.disconnect();
    }
}

checkDb();
