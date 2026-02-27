const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ['user', 'worker'],
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
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('User', UserSchema);
