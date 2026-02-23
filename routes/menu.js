const express = require('express');
const router = express.Router();

const { auth, authorize } = require('../middleware/auth');
const controller = require('../controllers/menucontroller');

/**
 * ================================
 * GET MENU ITEMS
 * Student / Staff → by canteen
 * Admin → all or by canteen
 * GET /api/menu?canteenId=XXXX
 * ================================
 */
router.get('/', auth, controller.getMenuItems);

/**
 * ================================
 * CREATE MENU ITEM (ADMIN ONLY)
 * POST /api/menu
 * ================================
 */
router.post('/', auth, authorize('admin'), controller.createMenuItem);

/**
 * ================================
 * UPDATE MENU ITEM (ADMIN ONLY)
 * PUT /api/menu/:id
 * ================================
 */
router.put('/:id', auth, authorize('admin'), controller.updateMenuItem);

/**
 * ================================
 * DELETE MENU ITEM (ADMIN ONLY)
 * DELETE /api/menu/:id
 * ================================
 */
router.delete('/:id', auth, authorize('admin'), controller.deleteMenuItem);

module.exports = router;
