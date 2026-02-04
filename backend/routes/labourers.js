const express = require('express');
const router = express.Router();
const Labourer = require('../models/Labourer');

// GET /api/labourers
router.get('/', async (req, res) => {
    try {
        const labourers = await Labourer.find();
        res.json(labourers);
    } catch (err) {
        res.status(500).json({ msg: 'Server Error' });
    }
});

// POST /api/labourers (For seeding/adding)
router.post('/', async (req, res) => {
    try {
        const newLabourer = new Labourer(req.body);
        const labourer = await newLabourer.save();
        res.json(labourer);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// GET /api/labourers/:id
router.get('/:id', async (req, res) => {
    try {
        const labourer = await Labourer.findById(req.params.id);
        if (!labourer) {
            return res.status(404).json({ msg: 'Labourer not found' });
        }
        res.json(labourer);
    } catch (err) {
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Labourer not found' });
        }
        res.status(500).send('Server Error');
    }
});

module.exports = router;
