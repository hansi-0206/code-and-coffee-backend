const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    menuItem: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MenuItem',
      required: true,
    },

    name: {
      type: String,
      trim: true,
      required: true,
    },

    price: {
      type: Number,
      min: 0,
      required: true,
    },

    quantity: {
      type: Number,
      required: true,
      min: 1,
    },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    // 🔥 STEP 4 ADDITION — CANTEEN LINK (MOST IMPORTANT)
    canteenId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Canteen',
      required: true,
      index: true,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    userName: {
      type: String,
      required: true,
      trim: true,
    },

    items: {
      type: [orderItemSchema],
      required: true,

      // 🔥 NEW — prevent empty orders
      validate: {
        validator: function(v) {
          return v && v.length > 0;
        },
        message: 'Order must contain at least one item'
      }
    },

    subtotal: {
      type: Number,
      required: true,
      min: 0,
    },

    tax: {
      type: Number,
      required: true,
      min: 0,
    },

    total: {
      type: Number,
      required: true,
      min: 0,

      // 🔥 NEW — block ₹0 orders
      validate: {
        validator: function(v) {
          return v > 0;
        },
        message: 'Order total must be greater than 0'
      }
    },

    paymentMode: {
      type: String,
      enum: ['UPI', 'COD'],
      default: 'COD',
    },

    paymentStatus: {
      type: String,
      enum: ['pending', 'paid'],
      default: 'pending',
    },

    paymentOrderId: {
      type: String,
      default: null,
    },

    status: {
      type: String,
      enum: ['pending', 'preparing', 'ready', 'completed'],
      default: 'pending',
    },

    priority: {
      type: String,
      enum: ['normal', 'high'],
      default: 'normal',
    },

    estimatedTime: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

orderSchema.index({ canteenId: 1, createdAt: -1 });
orderSchema.index({ userId: 1, createdAt: -1 });
orderSchema.index({ status: 1 });
orderSchema.index({ priority: 1 });

module.exports = mongoose.model('Order', orderSchema);
