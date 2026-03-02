const Order = require('../models/Order');
const MenuItem = require('../models/MenuItem');

// ================================
// CREATE ORDER
// POST /api/orders
// ================================
exports.createOrder = async (req, res) => {
  try {
    const {
      canteenId,
      userId,
      userName,
      items,
      subtotal,
      tax,
      total,
      paymentMode,
    } = req.body;

    // 🔥 BLOCK EMPTY ORDERS (CRITICAL FIX)
    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'Cart is empty' });
    }

    if (!total || total <= 0) {
      return res.status(400).json({ message: 'Invalid order total' });
    }

    const order = await Order.create({
      canteenId,
      userId,
      userName,
      items,
      subtotal,
      tax,
      total,
      paymentMode,
    });

    res.status(201).json(order);
  } catch (error) {
    console.error('Create order error:', error.message);
    res.status(500).json({ message: 'Failed to create order' });
  }
};

// ================================
// GET USER ORDERS
// GET /api/orders/my
// ================================
exports.getUserOrders = async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.user.id })
      .sort({ createdAt: -1 });

    res.status(200).json(orders);
  } catch (error) {
    console.error('Fetch user orders error:', error.message);
    res.status(500).json({ message: 'Failed to fetch orders' });
  }
};
