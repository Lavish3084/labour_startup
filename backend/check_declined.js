
const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const Booking = require('./models/Booking');
const Labourer = require('./models/Labourer');

mongoose.connect(process.env.MONGO_URI)
    .then(async () => {
        console.log('Connected to MongoDB');
        
        const workerId = '69c6577496dcc3d3c635bf2b'; // Lavish Kamboj
        const worker = await Labourer.findById(workerId);
        
        if (!worker) {
            console.log('Worker not found');
            process.exit(1);
        }
        
        console.log('Worker found:', worker.name);
        console.log('Category:', worker.category);
        console.log('isOnline:', worker.isOnline);
        console.log('Declined Bookings count:', worker.declinedBookings ? worker.declinedBookings.length : 0);
        
        const pendingBroadcasts = await Booking.find({
            status: 'pending',
            labourer: null,
            category: worker.category
        }).sort({ createdAt: -1 }).limit(10);
        
        console.log('Pending Broadcasts for this category (last 10):', pendingBroadcasts.length);
        
        pendingBroadcasts.forEach(b => {
            const isDeclined = worker.declinedBookings && worker.declinedBookings.includes(b._id);
            console.log(`Booking ${b._id}: Status=${b.status}, isDeclined=${isDeclined}, Date=${b.date}`);
        });

        process.exit(0);
    })
    .catch(err => {
        console.error('Connection error:', err);
        process.exit(1);
    });
