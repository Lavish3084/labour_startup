const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Labourer = require('./models/Labourer');

dotenv.config();

const labourers = [
    {
        name: 'Ramesh Kumar',
        category: 'Plumber',
        rating: 4.8,
        jobsCompleted: 154,
        hourlyRate: 250.0,
        description:
            'Expert plumber with over 10 years of experience in fixing leaks, pipe installation, and bathroom fittings. Reliable and quick service.',
        imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        location: 'Andheri East, Mumbai',
        skills: ['Pipe Fitting', 'Leakage Repair', 'Basin Installation'],
        experienceYears: 12,
    },
    {
        name: 'Suresh Patel',
        category: 'Electrician',
        rating: 4.6,
        jobsCompleted: 98,
        hourlyRate: 300.0,
        description:
            'Certified electrician specializing in home wiring, switchboard repairs, and appliance installation. Safety is my priority.',
        imageUrl: 'https://randomuser.me/api/portraits/men/45.jpg',
        location: 'Borivali, Mumbai',
        skills: ['Wiring', 'Switchboard Repair', 'Fan Installation'],
        experienceYears: 8,
    },
    {
        name: 'Anita Devi',
        category: 'Cleaner',
        rating: 4.9,
        jobsCompleted: 210,
        hourlyRate: 150.0,
        description:
            'Professional home cleaner offering deep cleaning services. Punctual and thorough work guaranteed.',
        imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
        location: 'Juhu, Mumbai',
        skills: ['Deep Cleaning', 'Kitchen Cleaning', 'Floor Polishing'],
        experienceYears: 5,
    },
    {
        name: 'Mohammad Khan',
        category: 'Carpenter',
        rating: 4.7,
        jobsCompleted: 130,
        hourlyRate: 350.0,
        description:
            'Skilled carpenter for furniture repair, custom cabinets, and door installation. Quality woodwork at affordable rates.',
        imageUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
        location: 'Bandra, Mumbai',
        skills: ['Furniture Repair', 'Door Installation', 'Polishing'],
        experienceYears: 15,
    },
    {
        name: 'Vikram Singh',
        category: 'Painter',
        rating: 4.5,
        jobsCompleted: 85,
        hourlyRate: 200.0,
        description:
            'House painter experienced in interior and exterior painting. Wall putty, texture painting, and clean finish.',
        imageUrl: 'https://randomuser.me/api/portraits/men/12.jpg',
        location: 'Dadar, Mumbai',
        skills: ['Wall Painting', 'Texture Design', 'Waterproofing'],
        experienceYears: 7,
    },
    {
        name: 'Sunita Sharma',
        category: 'Cook',
        rating: 4.8,
        jobsCompleted: 300,
        hourlyRate: 400.0,
        description:
            'Experienced cook specializing in North Indian and Gujarati cuisine. Hygiene and taste are assured.',
        imageUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
        location: 'Ghatkopar, Mumbai',
        skills: ['North Indian', 'Gujarati', 'Jain Food'],
        experienceYears: 10,
    },
];

const seedDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected');

        await Labourer.deleteMany({}); // Clear existing data
        console.log('Data cleared');

        await Labourer.insertMany(labourers);
        console.log('Data seeded');

        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

seedDB();
