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
    referralCode: {
        type: String,
        unique: true,
        sparse: true
    },
    referredBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

UserSchema.pre('save', function(next) {
    if (!this.referralCode) {
        this.referralCode = 'WILL' + this._id.toString().substring(0, 5).toUpperCase();
    }
    next();
});

UserSchema.index({ email: 1, role: 1 }, { unique: true, sparse: true });
UserSchema.index({ phoneNumber: 1, role: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('User', UserSchema);
