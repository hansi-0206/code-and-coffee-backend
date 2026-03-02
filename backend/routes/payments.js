const express = require('express');
const axios = require('axios');
const { auth } = require('../middleware/auth');

const router = express.Router();

/**
 * ===============================
 * CREATE CASHFREE PAYMENT ORDER
 * ===============================
 * TEST MODE (Sandbox)
 */
router.post('/create-order', auth, async (req, res) => {
  try {
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid amount' });
    }

    const orderId = `CC_${Date.now()}`;

    const response = await axios.post(
      'https://sandbox.cashfree.com/pg/orders',
      {
        order_id: orderId,
        order_amount: amount,
        order_currency: 'INR',
        order_note: 'Code & Coffee Order',

        customer_details: {
          customer_id: req.user._id.toString(),
          customer_name: req.user.name,
          customer_email: req.user.email,
          customer_phone: '9999999999',
        },

        order_meta: {
          // For mobile apps, this can be any valid URL
          return_url: 'https://example.com/payment-success',
        },
      },
      {
        headers: {
          'x-client-id': process.env.CASHFREE_CLIENT_ID,
          'x-client-secret': process.env.CASHFREE_CLIENT_SECRET,
          'x-api-version': '2022-09-01',
          'Content-Type': 'application/json',
        },
      }
    );

    res.status(200).json(response.data);
  } catch (error) {
    console.error(
      '❌ CASHFREE ERROR:',
      error.response?.data || error.message
    );

    res.status(500).json({
      message: 'Cashfree order creation failed',
    });
  }
});

module.exports = router;
