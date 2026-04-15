const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const Booking = require('./models/Booking');

async function checkOverlap() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        const workerId = '69c6577496dcc3d3c635bf2b'; // Lavish Kamboj
        
        console.log(`\n--- ACTIVE JOBS FOR ${workerId} ---`);
        const active = await Booking.find({
            labourer: workerId,
            $or: [
                { status: 'confirmed', paymentStatus: 'paid' },
                { status: 'arrived' },
                { status: 'confirmed' } // Let's check all confirmed just in case
            ]
        });
        
        active.forEach(a => {
            console.log(`ID: ${a._id} | Status: ${a.status} | Pay: ${a.paymentStatus} | Date: ${a.date}`);
            const bStart = new Date(a.date).getTime();
            const bEnd = bStart + (a.numberOfHours || 2) * 60 * 60 * 1000;
            console.log(`   Time Range: ${new Date(bStart).toLocaleString()} to ${new Date(bEnd).toLocaleString()}`);
            console.log(`   Is currently "active"? ${Date.now() < bEnd ? 'YES' : 'NO'}`);
        });

    } catch (err) {
        console.error('Error:', err);
    } finally {
        await mongoose.disconnect();
    }
}

checkOverlap();
