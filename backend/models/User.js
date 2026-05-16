const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: false
    },
    phoneNumber: {
        type: String,
        required: false
    },
    password: {
        type: String,
        required: false
    },
    role: {
        type: String,
        enum: ['user', 'worker', 'admin'],
        default: 'user'
    },
    profilePicture: {
        type: String,
        default: ''
    },
    fcmToken: {
        type: String,
        default: ''
    },
    addresses: [{
        label: String,
        address: String,
        houseNumber: String,
        landmark: String,
        latitude: Number,
        longitude: Number,
        createdAt: {
            type: Date,
            default: Date.now
        }
    }],
    walletBalance: {
        type: Number,
        default: 0
    },
    walletTransactions: [{
        amount: Number,
        type: { type: String, enum: ['credit', 'debit'] },
        description: String,
        date: { type: Date, default: Date.now },
        relatedBooking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' }
    }],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

UserSchema.index({ email: 1, role: 1 }, { unique: true, sparse: true });
UserSchema.index({ phoneNumber: 1, role: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('User', UserSchema);
