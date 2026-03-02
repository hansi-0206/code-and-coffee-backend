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

    // ✅ NEW: STOCK VALIDATION + ATOMIC DECREMENT
    for (const item of items) {

      const result = await MenuItem.updateOne(
        { _id: item.menuItemId, stock: { $gt: 0 } },  // Only if stock > 0
        { $inc: { stock: -item.quantity } }           // Decrease stock
      );

      // 🔥 If stock not available → STOP ORDER
      if (result.modifiedCount === 0) {
        return res.status(400).json({
          message: `${item.name} just went out of stock`
        });
      }

      // ✅ NEW: Fetch updated stock
      const updatedItem = await MenuItem.findById(item.menuItemId);

      // ✅ NEW: REALTIME STOCK UPDATE
      io.emit("stockUpdated", {
        menuItemId: item.menuItemId,
        newStock: updatedItem.stock
      });
    }

    // ✅ Order creation (UNCHANGED)
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
