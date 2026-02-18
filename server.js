const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const axios = require('axios'); // 🔥 Cashfree
require('dotenv').config();

// ================= ROUTES =================
const authRoutes = require('./routes/auth');
const menuRoutes = require('./routes/menu');
const orderRoutes = require('./routes/orders');
const paymentRoutes = require('./routes/payments');
const canteenRoutes = require('./routes/canteen'); // 🔥 NEW


const app = express();

// ================= MIDDLEWARE =================
app.use(cors());
app.use(express.json());
app.use('/api/menu', require('./routes/menu'));


// ================= MONGO URI =================
const MONGO_URI =
  process.env.MONGODB_URI ||
  'mongodb+srv://Hansika:hansika0206@cluster0.legp3mn.mongodb.net/code_and_coffee?retryWrites=true&w=majority';

// ================= MONGO CONNECTION =================
mongoose
  .connect(MONGO_URI, {
    maxPoolSize: 10,
  })
  .then(() => console.log('✅ MongoDB connected'))
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1);
  });

// ================= API ROUTES =================
// ⚠️ ALL routes prefixed with /api
app.use('/api/auth', authRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/orders', orderRoutes); // 🔥 ADMIN TODAY = /api/orders/admin/today
app.use('/api/payments', paymentRoutes);
app.use('/api/canteens', canteenRoutes); // 🔥 NEW (IMPORTANT)

// ================= HEALTH CHECK =================
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Code & Coffee backend running',
    timestamp: new Date(),
  });
});

// ================= SERVER =================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});

module.exports = app;
