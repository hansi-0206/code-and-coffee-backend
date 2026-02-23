import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/action_card.dart';
import '../../widgets/app_background.dart';

import '../../models/order.dart'; // ADDED (fix OrderStatus reference)

import '../login_screen.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {

  static const Color headingBrown = Color(0xFF2D1B0D);
  static const Color secondaryBrown = Color(0xFF5D4037);

  final int orderNumber = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().restoreActiveOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final user = authProvider.user;

    // MODIFIED: use provider-level getter (safer)
    final bool showTrackButton = orderProvider.hasActiveOrder;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.coffee,
                  color: AppTheme.primaryBrown,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Code & Coffee',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.person, color: Colors.white),
              onSelected: (value) async {
                if (value == 'logout') {

                  await authProvider.logout(context);

                  context.read<OrderProvider>().clearOrders();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'user',
                  enabled: false,
                  child: Text(
                    user?.name ?? 'User',
                    style: const TextStyle(color: headingBrown),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.coffee, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Welcome back',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Hello, ${user?.name ?? 'John'}!',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('☕', style: TextStyle(fontSize: 28)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ready to order? Your favorite café is just a tap away',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Order',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          ActionCard(
                            icon: Icons.restaurant_menu,
                            title: 'View Menu',
                            subtitle: 'Browse food',
                            color: AppTheme.accentOrange,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MenuScreen(),
                                ),
                              );
                            },
                          ),

                          if (showTrackButton)
                            ActionCard(
                              icon: Icons.receipt_long,
                              title: 'Track Orders',
                              subtitle: 'Check status',
                              color: Colors.green,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const OrderTrackingScreen(),
                                  ),
                                );
                              },
                            ),

                          ActionCard(
                            icon: Icons.shopping_cart,
                            title: 'Cart',
                            subtitle: cartProvider.itemCount > 0
                                ? '${cartProvider.itemCount} items'
                                : 'Empty',
                            color: AppTheme.primaryBrown,
                            badge: cartProvider.itemCount > 0
                                ? cartProvider.itemCount.toString()
                                : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                          ),

                          ActionCard(
                            icon: Icons.history,
                            title: 'Order History',
                            subtitle: 'Past orders',
                            color: Colors.blueGrey,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const OrderTrackingScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
