const mongoose = require('mongoose');

const LabourerSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        unique: true
    },
    name: { type: String, required: true },
    category: { type: String, required: true },
    rating: { type: Number, default: 0 },
    jobsCompleted: { type: Number, default: 0 },
    hourlyRate: { type: Number, required: true },
    description: { type: String, default: '' },
    imageUrl: { type: String, default: '' }, // We will sync this with user.profilePicture or keep independent
    location: { type: String, required: true },
    skills: { type: [String], default: [] },
    experienceYears: { type: Number, required: true }
});

module.exports = mongoose.model('Labourer', LabourerSchema);
