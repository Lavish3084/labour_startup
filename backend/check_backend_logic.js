
const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const Booking = require('./models/Booking');
const Labourer = require('./models/Labourer');
const User = require('./models/User');

async function testRouteLogic() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        const workerId = '69c6577496dcc3d3c635bf2b'; // Lavish Kamboj
        const labourer = await Labourer.findById(workerId);
        
        if (!labourer) {
            console.log('Labourer not found');
            process.exit(1);
        }

        console.log(`\nTesting logic for: ${labourer.name} (ID: ${workerId})`);
        console.log(`Category: ${labourer.category}, isOnline: ${labourer.isOnline}`);

        const bookings = await Booking.find({
            status: 'pending',
            $or: [
                { labourer: workerId },
                { labourer: null, category: labourer.category }
            ]
        }).populate('user', 'name phone profilePicture');

        console.log(`Initial query returned ${bookings.length} bookings`);

        if (!labourer.isOnline) {
            console.log('Worker is OFFLINE. Filtering for assigned only.');
            const assignedOnly = bookings.filter(b => b.labourer && b.labourer.toString() === workerId.toString());
            console.log(`Result: ${assignedOnly.length} bookings`);
            return;
        }

        const activeCommitments = await Booking.find({
            labourer: workerId,
            status: { $in: ['confirmed', 'arrived'] }
        });

        console.log(`Active commitments count: ${activeCommitments.length}`);

        const filteredBookings = bookings.filter(b => {
            // Decline check
            if (labourer.declinedBookings && labourer.declinedBookings.some(id => id.toString() === b._id.toString())) {
                console.log(`Booking ${b._id} rejected: DECLINED`);
                return false;
            }

            // Overlap check
            const bookingDate = new Date(b.date);
            const bookingDuration = parseInt(b.numberOfHours) || 2;
            const bookingEnd = new Date(bookingDate.getTime() + bookingDuration * 60 * 60 * 1000);

            const hasOverlap = activeCommitments.some(commitment => {
                const start = new Date(commitment.date);
                const duration = parseInt(commitment.numberOfHours) || 2;
                const end = new Date(start.getTime() + duration * 60 * 60 * 1000);
                return (bookingDate < end && bookingEnd > start);
            });

            if (hasOverlap) {
                console.log(`Booking ${b._id} rejected: OVERLAP`);
                return false;
            }

            // Category/Assignment check
            if (b.labourer) {
                const isAssigned = b.labourer.toString() === workerId.toString();
                if (!isAssigned) console.log(`Booking ${b._id} rejected: ASSIGNED TO OTHER`);
                return isAssigned;
            }
            
            const catMatch = b.category === labourer.category;
            if (!catMatch) console.log(`Booking ${b._id} rejected: CATEGORY MISMATCH ("${b.category}" vs "${labourer.category}")`);
            return catMatch;
        });

        console.log(`\nFinal result: ${filteredBookings.length} bookings`);
        filteredBookings.forEach(fb => {
            console.log(`- Booking ID: ${fb._id}, Date: ${fb.date}, Cat: ${fb.category}`);
        });

    } catch (err) {
        console.error('Error:', err);
    } finally {
        await mongoose.disconnect();
    }
}

testRouteLogic();
