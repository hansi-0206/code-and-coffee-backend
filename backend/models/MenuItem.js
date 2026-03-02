const mongoose = require('mongoose');

const menuItemSchema = new mongoose.Schema(
  {
    canteenId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Canteen',
      required: true,
      index: true,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },

    category: {
      type: String,
      required: true,
      enum: ['Beverages', 'Snacks', 'Meals'],
    },

    price: {
      type: Number,
      required: true,
      min: 0,
    },

    description: {
      type: String,
      trim: true,
    },

    // ✅ STOCK FIELD (CRITICAL FOR REALTIME)
    stock: {
      type: Number,
      default: 0,
      min: 0,
    },

    image: {
      type: String,
    },

    // ✅ Availability always derived from stock
    available: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// 🔥 AUTO-SYNC availability with stock (Bulletproof Fix)
menuItemSchema.pre('save', function () {
  this.available = this.stock > 0;
});
// 🔥 Optimized index for canteen-based menu loading
menuItemSchema.index({ canteenId: 1, category: 1, available: 1 });

module.exports = mongoose.model('MenuItem', menuItemSchema);