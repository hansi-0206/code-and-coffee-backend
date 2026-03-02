const express = require('express');
const router = express.Router();
const Canteen = require('../models/Canteen');

router.get('/', async (req, res) => {
  try {
    const canteens = await Canteen.find();
    res.json(canteens);
  } catch (err) {
    res.status(500).json({ message: 'Error loading canteens' });
  }
});

module.exports = router;
