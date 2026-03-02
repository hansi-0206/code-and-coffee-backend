const MenuItem = require('../models/MenuItem');
const Canteen = require('../models/Canteen');

// ================================
// GET MENU ITEMS
// Student/Staff → available only
// Admin → all items
// GET /api/menu?canteenId=xxx
// ================================
exports.getMenuItems = async (req, res) => {
  try {
    const { canteenId } = req.query;
    const filter = {};

    if (canteenId) {
      filter.canteenId = canteenId;

      // 🔐 Students & staff see only available items
      if (req.user.role !== 'admin') {
        filter.available = true;
      }
    }

    const items = await MenuItem.find(filter).sort({
      category: 1,
      createdAt: -1,
    });

    res.status(200).json(items);
  } catch (error) {
    console.error('Fetch menu error:', error.message);
    res.status(500).json({ message: 'Failed to load menu items' });
  }
};

// ================================
// CREATE MENU ITEM (ADMIN ONLY)
// POST /api/menu
// ================================
exports.createMenuItem = async (req, res) => {
  try {
    const { canteenId, name, category, price, description, image, stock } = req.body;

    if (!canteenId || !name || !category || !price) {
      return res.status(400).json({
        message: 'canteenId, name, category and price are required',
      });
    }

    const allowedCategories = ['Beverages', 'Snacks', 'Meals'];
    if (!allowedCategories.includes(category)) {
      return res.status(400).json({ message: 'Invalid category' });
    }

    const canteen = await Canteen.findById(canteenId);
    if (!canteen || !canteen.active) {
      return res.status(400).json({ message: 'Invalid canteen' });
    }

    const menuItem = await MenuItem.create({
      canteenId,
      name,
      category,
      price,
      description,
      image,
      stock: stock || 0,
      available: stock > 0,
    });

    res.status(201).json(menuItem);
  } catch (error) {
    console.error('Create menu error:', error.message);
    res.status(500).json({ message: 'Failed to create menu item' });
  }
};

// ================================
// UPDATE MENU ITEM (ADMIN ONLY)
// PUT /api/menu/:id
// ================================
exports.updateMenuItem = async (req, res) => {
  try {
    const allowedCategories = ['Beverages', 'Snacks', 'Meals'];

    if (req.body.category && !allowedCategories.includes(req.body.category)) {
      return res.status(400).json({ message: 'Invalid category' });
    }

    const menuItem = await MenuItem.findById(req.params.id);

    if (!menuItem) {
      return res.status(404).json({ message: 'Menu item not found' });
    }

    Object.assign(menuItem, req.body);

    // 🔥 Sync availability with stock
    if (req.body.stock !== undefined) {
      menuItem.available = req.body.stock > 0;
    }

    await menuItem.save();

    res.status(200).json(menuItem);
  } catch (error) {
    console.error('Update menu error:', error.message);
    res.status(500).json({ message: 'Failed to update menu item' });
  }
};

// ================================
// UPDATE STOCK (ADMIN ONLY)
// PATCH /api/menu/:id/stock
// ================================
exports.updateStock = async (req, res) => {
  try {
    console.log("🔥 STOCK UPDATE ROUTE HIT");
    console.log("ID:", req.params.id);
    console.log("Body:", req.body);
    console.log("User:", req.user);

    const { stock } = req.body;

    if (stock === undefined || stock < 0) {
      return res.status(400).json({ message: 'Invalid stock value' });
    }

    const menuItem = await MenuItem.findById(req.params.id);

    if (!menuItem) {
      return res.status(404).json({ message: 'Menu item not found' });
    }

    menuItem.stock = stock;
    menuItem.available = stock > 0;

    await menuItem.save();

    console.log("✅ STOCK UPDATED IN DB");

    if (global.io) {
      global.io.emit("stockUpdated", {
        menuItemId: menuItem._id.toString(),
        newStock: menuItem.stock
      });
    }

    res.status(200).json(menuItem);

  } catch (error) {
    console.error('❌ Stock update error:', error);
    res.status(500).json({ message: 'Failed to update stock' });
  }
};

// ================================
// DELETE MENU ITEM (ADMIN ONLY)
// DELETE /api/menu/:id
// ================================
exports.deleteMenuItem = async (req, res) => {
  try {
    const menuItem = await MenuItem.findByIdAndDelete(req.params.id);

    if (!menuItem) {
      return res.status(404).json({ message: 'Menu item not found' });
    }

    res.status(200).json({ message: 'Menu item deleted successfully' });
  } catch (error) {
    console.error('Delete menu error:', error.message);
    res.status(500).json({ message: 'Failed to delete menu item' });
  }
};