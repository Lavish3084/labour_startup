const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Category = require('./models/Category');

const path = require('path');
dotenv.config({ path: path.join(__dirname, '.env') });

const categories = [
    {
        name: 'Masonry',
        iconName: 'foundation',
        description: 'Construction and repair.',
        supportedModes: ['Hourly', 'Daily'],
        hourlyRate: 350.0,
        dailyRate: 2500.0,
    },
    {
        name: 'Garden',
        iconName: 'yard',
        description: 'Gardening and landscaping.',
        supportedModes: ['Hourly', 'Daily'],
        hourlyRate: 200.0,
        dailyRate: 1500.0,
    },
    {
        name: 'Moving',
        iconName: 'local_shipping',
        description: 'Moving services.',
        supportedModes: ['Hourly', 'Daily'],
        hourlyRate: 300.0,
        dailyRate: 2000.0,
    },
    {
        name: 'Loading',
        iconName: 'inventory_2',
        description: 'Loading and unloading.',
        supportedModes: ['Hourly', 'Daily'],
        hourlyRate: 250.0,
        dailyRate: 1800.0,
    },
    {
        name: 'General',
        iconName: 'engineering',
        description: 'General labor tasks.',
        supportedModes: ['Hourly', 'Daily'],
        hourlyRate: 150.0,
        dailyRate: 1000.0,
    },
    {
        name: 'Cleanup',
        iconName: 'cleaning_services',
        description: 'Cleanup services.',
        supportedModes: ['Hourly', 'Daily'],
        hourlyRate: 150.0,
        dailyRate: 1000.0,
    },
    {
        name: 'Plumbing',
        iconName: 'plumbing',
        description: 'Pipe installation and repairs.',
        supportedModes: ['Hourly', 'Task-based'],
        hourlyRate: 250.0,
        dailyRate: 2000.0,
    },
    {
        name: 'Electric',
        iconName: 'electrical_services',
        description: 'Electrical work.',
        supportedModes: ['Hourly', 'Task-based'],
        hourlyRate: 300.0,
        dailyRate: 2500.0,
    },
    {
        name: 'Painting',
        iconName: 'format_paint',
        description: 'Painting services.',
        supportedModes: ['Hourly', 'Daily'],
        hourlyRate: 200.0,
        dailyRate: 1600.0,
    },
];

const seedDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        await Category.deleteMany({});
        console.log('Cleared existing categories');

        await Category.insertMany(categories);
        console.log('Seeded categories successfully');

        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

seedDB();
