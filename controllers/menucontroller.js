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
    const { canteenId, name, category, price, description, image } = req.body;

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

    const menuItem = await MenuItem.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!menuItem) {
      return res.status(404).json({ message: 'Menu item not found' });
    }

    res.status(200).json(menuItem);
  } catch (error) {
    console.error('Update menu error:', error.message);
    res.status(500).json({ message: 'Failed to update menu item' });
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
