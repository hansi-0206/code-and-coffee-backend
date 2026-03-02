const mongoose = require('mongoose');

const canteenSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
    },
    code: {
      type: String,
      required: true,
      unique: true, // EAST, NAMMA, CORE, KS, MUNCH
    },
    active: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Canteen', canteenSchema);
