const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from the parent directory
dotenv.config({ path: path.join(__dirname, '.env') });

const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
    console.error('Error: MONGO_URI is not defined in .env');
    process.exit(1);
}

async function fixIndexes() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(MONGO_URI);
        console.log('Connected.');

        const db = mongoose.connection.db;
        const collection = db.collection('users');

        console.log('Fetching current indexes...');
        const indexes = await collection.listIndexes().toArray();
        console.log('Current indexes:', JSON.stringify(indexes, null, 2));

        // Indexes to drop if they exist
        const indexesToDrop = ['email_1', 'phoneNumber_1'];

        for (const indexName of indexesToDrop) {
            const exists = indexes.some(idx => idx.name === indexName);
            if (exists) {
                console.log(`Dropping index: ${indexName}...`);
                await collection.dropIndex(indexName);
                console.log(`Successfully dropped ${indexName}.`);
            } else {
                console.log(`Index ${indexName} does not exist (skipping).`);
            }
        }

        console.log('Finished fixing indexes.');
        process.exit(0);
    } catch (error) {
        console.error('Error fixing indexes:', error);
        process.exit(1);
    }
}

fixIndexes();
