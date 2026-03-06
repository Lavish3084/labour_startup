const mongoose = require('mongoose');

const CategorySchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true
    },
    iconName: {
        type: String,
        required: true
    },
    description: {
        type: String,
        default: ''
    },
    supportedModes: {
        type: [String],
        enum: ['Hourly', 'Daily', 'Task-based'],
        default: ['Hourly', 'Daily']
    },
    hourlyRate: {
        type: Number,
        required: true
    },
    minHourlyRate: {
        type: Number,
        required: true,
        default: 0
    },
    maxHourlyRate: {
        type: Number,
        required: true,
        default: 1000
    },
    dailyRate: {
        type: Number,
        required: true
    },
    isActive: {
        type: Boolean,
        default: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Category', CategorySchema);
