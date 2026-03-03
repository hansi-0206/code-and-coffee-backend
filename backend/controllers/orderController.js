const Order = require('../models/Order');
const MenuItem = require('../models/MenuItem');

// ================================
// CREATE ORDER
// POST /api/orders
// ================================
exports.createOrder = async (req, res) => {
  try {
    const { canteenId, items, subtotal, tax, total, paymentMode } = req.body;

    const userId = req.user.id;
    const userName = req.user.name;

    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'Cart is empty' });
    }

    if (!total || total <= 0) {
      return res.status(400).json({ message: 'Invalid order total' });
    }

    const orderItems = [];

    for (const item of items) {

      const menuItemId = item.menuItem;
      const quantity = Number(item.quantity);

      if (!menuItemId || !quantity || quantity <= 0) {
        return res.status(400).json({ message: 'Invalid item data' });
      }

      const updatedItem = await MenuItem.findOneAndUpdate(
        { _id: menuItemId, stock: { $gte: quantity } },
        { $inc: { stock: -quantity } },
        { new: true }
      );

      if (!updatedItem) {
        return res.status(400).json({
          message: 'Item out of stock'
        });
      }

      // 🔥 Build full order item from DB
      orderItems.push({
        menuItem: updatedItem._id,
        name: updatedItem.name,
        price: updatedItem.price,
        quantity
      });

      if (global.io) {
        global.io.emit("stockUpdated", {
          menuItemId,
          newStock: updatedItem.stock
        });
      }
    }

    const order = await Order.create({
      canteenId,
      userId,
      userName,
      items: orderItems,  // 🔥 use backend-built items
      subtotal,
      tax,
      total,
      paymentMode,
    });

    return res.status(201).json(order);

  } catch (error) {
    console.error('Create order error:', error);
    return res.status(500).json({ message: 'Failed to create order' });
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

    return res.status(200).json(orders);

  } catch (error) {
    console.error('Fetch user orders error:', error);
    return res.status(500).json({ message: 'Failed to fetch orders' });
  }
};
