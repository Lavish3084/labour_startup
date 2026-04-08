const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    labourer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Labourer'
        // required: false // Now optional for broadcast requests
    },
    category: {
        type: String,
        required: true // Required to know which workers to broadcast to
    },
    date: {
        type: Date,
        required: true
    },
    bookingMode: {
        type: String,
        required: true,
        enum: ['Hourly', 'Daily', 'Task-based']
    },
    numberOfHours: {
        type: Number,
        required: false
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'arrived', 'completed', 'cancelled'],
        default: 'pending'
    },
    arrivalOTP: { type: String },
    completionOTP: { type: String },
    paymentStatus: {
        type: String,
        enum: ['pending', 'paid', 'released', 'refunded'],
        default: 'pending'
    },
    paymentId: { type: String },
    orderId: { type: String },
    amount: { type: Number },
    commissionAmount: { type: Number, default: 0 },
    workerPayoutAmount: { type: Number, default: 0 },
    isWorkConfirmed: { type: Boolean, default: false },
    minAmount: { type: Number },
    maxAmount: { type: Number },
    notes: {
        type: String
    },
    address: {
        type: String
    },
    declinedBy: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Labourer'
    }],
    applicants: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Labourer'
    }],
    houseNumber: {
        type: String
    },
    landmark: {
        type: String
    },
    latitude: {
        type: Number
    },
    longitude: {
        type: Number
    },
    isRated: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Booking', BookingSchema);
