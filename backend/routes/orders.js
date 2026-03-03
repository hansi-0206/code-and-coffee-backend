const express = require('express');
const mongoose = require('mongoose');
const Order = require('../models/Order');
const MenuItem = require('../models/MenuItem');
const Canteen = require('../models/Canteen');
const { auth, authorize } = require('../middleware/auth');
const orderController = require('../controllers/orderController');

const router = express.Router();

/**
 * =====================
 * CREATE ORDER (STUDENT / STAFF)
 * =====================
 */
router.post(
  '/',
  auth,
  authorize('student', 'staff'),
  orderController.createOrder
);

/**
 * =====================
 * GET MY ORDERS
 * =====================
 */
router.get('/my', auth, async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .populate('items.menuItem');

    res.status(200).json(orders);
  } catch (error) {
    console.error('GET MY ORDERS ERROR:', error);
    res.status(500).json({ message: 'Failed to fetch orders' });
  }
});

/**
 * =====================
 * KITCHEN QUEUE
 * =====================
 */
router.get(
  '/kitchen/queue',
  auth,
  authorize('kitchen'),
  async (req, res) => {
    try {
      const orders = await Order.find({
        canteenId: req.user.canteenId,
        status: { $in: ['pending', 'preparing', 'ready'] },
      })
        .sort({ priority: -1, createdAt: 1, updatedAt: 1 })
        .populate('items.menuItem');

      res.status(200).json(orders);
    } catch (error) {
      console.error('KITCHEN QUEUE ERROR:', error);
      res.status(500).json({ message: 'Failed to fetch kitchen orders' });
    }
  }
);

/**
 * =====================
 * KITCHEN HISTORY
 * =====================
 */
router.get(
  '/kitchen/history',
  auth,
  authorize('kitchen', 'admin'),
  async (req, res) => {
    try {
      const canteenId =
        req.user.role === 'kitchen'
          ? req.user.canteenId
          : req.query.canteenId;

      const orders = await Order.find({
        canteenId,
        status: 'completed',
      })
        .sort({ updatedAt: -1 })
        .populate('items.menuItem');

      res.status(200).json(orders);
    } catch (error) {
      console.error('KITCHEN HISTORY ERROR:', error);
      res.status(500).json({ message: 'Failed to fetch kitchen history' });
    }
  }
);

/**
 * =====================
 * UPDATE ORDER STATUS
 * =====================
 */
router.patch(
  '/:id/status',
  auth,
  authorize('admin', 'kitchen'),
  async (req, res) => {
    try {
      const { status, estimatedTime } = req.body;

      const transitions = {
        pending: ['preparing'],
        preparing: ['ready'],
        ready: ['completed'],
      };

      if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
        return res.status(400).json({ message: 'Invalid order id' });
      }

      const order = await Order.findById(req.params.id);
      if (!order) {
        return res.status(404).json({ message: 'Order not found' });
      }

      if (
        req.user.role === 'kitchen' &&
        order.canteenId.toString() !== req.user.canteenId.toString()
      ) {
        return res.status(403).json({ message: 'Access denied' });
      }

      if (
        order.status !== status &&
        !transitions[order.status]?.includes(status)
      ) {
        return res.status(400).json({
          message: `Invalid transition from ${order.status} to ${status}`,
        });
      }

      order.status = status;

      if (status === 'completed' && order.paymentMode === 'COD') {
        order.paymentStatus = 'paid';
      }

      if (estimatedTime) {
        order.estimatedTime = new Date(estimatedTime);
      }

      await order.save();

      const updatedOrder = await Order.findById(order._id)
        .populate('items.menuItem');

      res.status(200).json(updatedOrder);
    } catch (error) {
      console.error('UPDATE STATUS ERROR:', error);
      res.status(500).json({ message: 'Failed to update order status' });
    }
  }
);

/**
 * =====================
 * ADMIN TODAY
 * =====================
 */
router.get(
  '/admin/today',
  auth,
  authorize('admin'),
  async (req, res) => {
    try {
      const { canteenId } = req.query;

      const start = new Date();
      start.setHours(0, 0, 0, 0);

      const end = new Date();
      end.setHours(23, 59, 59, 999);

      const filter = {
        createdAt: { $gte: start, $lte: end },
      };

      if (canteenId) filter.canteenId = canteenId;

      const orders = await Order.find(filter)
        .sort({ createdAt: -1 })
        .populate('items.menuItem');

      res.status(200).json(orders);
    } catch (error) {
      console.error('ADMIN TODAY ORDERS ERROR:', error);
      res.status(500).json({ message: 'Failed to fetch today orders' });
    }
  }
);

/**
 * =====================
 * ADMIN STATS
 * =====================
 */
router.get(
  '/admin/stats',
  auth,
  authorize('admin'),
  async (req, res) => {
    try {
      const { canteenId } = req.query;

      const start = new Date();
      start.setHours(0, 0, 0, 0);

      const end = new Date();
      end.setHours(23, 59, 59, 999);

      const match = {
        createdAt: { $gte: start, $lte: end },
      };

      if (canteenId) {
        match.canteenId = new mongoose.Types.ObjectId(canteenId);
      }

      const todayOrders = await Order.countDocuments(match);

      const revenueAgg = await Order.aggregate([
        { $match: match },
        {
          $group: {
            _id: null,
            totalRevenue: { $sum: '$total' },
          },
        },
      ]);

      res.status(200).json({
        todayOrders,
        totalRevenue:
          revenueAgg.length > 0 ? revenueAgg[0].totalRevenue : 0,
      });
    } catch (error) {
      console.error('ADMIN STATS ERROR:', error);
      res.status(500).json({ message: 'Failed to fetch admin stats' });
    }
  }
);

module.exports = router;
