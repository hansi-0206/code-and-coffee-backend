const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../models/User');
const Canteen = require('../models/Canteen');

const router = express.Router();

/**
 * =====================
 * SIGNUP
 * =====================
 */
router.post('/signup', async (req, res) => {
  try {
    const { name, email, password, role, canteenId } = req.body;

    // ✅ Validate role
    const allowedRoles = ['student', 'staff', 'admin', 'kitchen'];
    if (!allowedRoles.includes(role)) {
      return res.status(400).json({ message: 'Invalid role' });
    }

    // 🔐 Kitchen must have canteenId
    if (role === 'kitchen') {
      if (!canteenId || !mongoose.Types.ObjectId.isValid(canteenId)) {
        return res.status(400).json({
          message: 'canteenId is required for kitchen users',
        });
      }

      const canteen = await Canteen.findById(canteenId);
      if (!canteen || !canteen.active) {
        return res.status(400).json({ message: 'Invalid canteen' });
      }
    }

    // 🔐 Non-kitchen users must NOT send canteenId
    if (role !== 'kitchen' && canteenId) {
      return res.status(400).json({
        message: 'canteenId is only allowed for kitchen users',
      });
    }

    // ✅ Check existing user
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    // ✅ Create user
    const user = await User.create({
      name,
      email,
      password,
      role,
      canteenId: role === 'kitchen' ? canteenId : null,
    });

    // ✅ Generate token
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        canteenId: user.canteenId,
      },
      token,
    });
  } catch (error) {
    console.error('SIGNUP ERROR:', error);
    res.status(500).json({ message: 'Signup failed', error: error.message });
  }
});

/**
 * =====================
 * LOGIN
 * =====================
 */
router.post('/login', async (req, res) => {
  console.time('LOGIN_TOTAL');

  try {
    const { email, password, role } = req.body;

    const user = await User.findOne({ email });

    if (!user) {
      console.timeEnd('LOGIN_TOTAL');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      console.timeEnd('LOGIN_TOTAL');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (user.role !== role) {
      console.timeEnd('LOGIN_TOTAL');
      return res.status(403).json({ message: 'Invalid role' });
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    console.timeEnd('LOGIN_TOTAL');

    res.json({
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        canteenId: user.canteenId,
      },
      token,
    });
  } catch (error) {
    console.timeEnd('LOGIN_TOTAL');
    console.error('LOGIN ERROR:', error);
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
});

module.exports = router;
