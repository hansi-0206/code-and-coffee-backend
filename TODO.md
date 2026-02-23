# TODO: Fix Order Tracking and Status Transitions

## 1. Update OrderTrackingScreen
- [x] Change `hasActiveOrder` to only include orders with status 'pending', 'preparing', or 'ready'
- [x] Add "View Previous Orders" button when no active order, opening bottom sheet with orderHistory
- [x] Remove "Done" button for completed orders since they won't display
- [x] Ensure countdown timer only starts for active orders

## 2. Update OrderProvider
- [x] In `updateOrderStatus`, ensure orders move correctly between _activeOrders and _orderHistory
- [x] Remove incorrect `loadUserOrders` call in kitchen_dashboard.dart after status update
- [x] Ensure notifications trigger on status changes via polling

## 3. Verify 
Backend
- [x] Confirm PATCH /orders/:id/status accepts `estimatedTime` (already implemented)
- [x] Ensure estimatedTime updates reflect in frontend via polling

## 4. Testing
- [x] Test order completion moves to history immediately
- [x] Test timer updates when estimatedTime changes
- [x] Test "View Previous Orders" functionality
