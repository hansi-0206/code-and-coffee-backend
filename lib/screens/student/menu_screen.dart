import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/canteen_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/menu_item.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import '../canteen/select_canteen_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenu();
      _loadOrders();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMenu();
      _loadOrders();
    }
  }

  void _loadMenu() {
    final canteenProvider =
        Provider.of<CanteenProvider>(context, listen: false);
    final menuProvider =
        Provider.of<MenuProvider>(context, listen: false);

    final selectedCanteen = canteenProvider.selectedCanteen;

    if (selectedCanteen != null) {
      menuProvider.loadMenuItemsByCanteen(selectedCanteen.id);
    }
  }

  void _loadOrders() {
    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);
    orderProvider.loadUserOrders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final canteenProvider = Provider.of<CanteenProvider>(context);

    final canteenName =
        canteenProvider.selectedCanteen?.name ?? 'Menu';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SelectCanteenScreen(),
              ),
            );
          },
        ),
        title: Text(canteenName),
        actions: [

          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Track Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderTrackingScreen(),
                ),
              );
            },
          ),

          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CartScreen(),
                    ),
                  );
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentOrange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: menuProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : menuProvider.items.isEmpty
              ? const Center(child: Text('No menu items available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: menuProvider.items.length,
                  itemBuilder: (context, index) {
                    final MenuItem item = menuProvider.items[index];
                    final int quantity =
                        cartProvider.getQuantity(item);

                    final bool outOfStock =
                        (item.available != true) || (item.stock ?? 0) == 0;
                     

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.lightCream,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.coffee,
                                size: 40,
                                color: AppTheme.primaryBrown,
                              ),
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    item.category,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentOrange,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // ✅ STOCK DISPLAY
                                  if (outOfStock)
                                    const Text(
                                      "Unavailable ❌",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else ...[
                                    Text(
                                      "Stock: ${item.stock}",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                    ),

                                    // ✅ LOW STOCK BADGE 🔥
                                    if (item.stock == 1)
                                      const Text(
                                        "Only 1 left 🔥",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ]
                                ],
                              ),
                            ),

                            if (quantity == 0)
                              ElevatedButton(
                                onPressed: outOfStock
                                    ? null
                                    : () {
                                        cartProvider.addItem(item);
                                      },
                                child: const Text('Add'),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.lightCream,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        cartProvider.removeItem(item);
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: outOfStock
                                          ? null
                                          : () {
                                              cartProvider.addItem(item);
                                            },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
