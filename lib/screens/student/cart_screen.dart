import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/canteen_provider.dart';
import '../../services/api_service.dart';
import 'order_tracking_screen.dart';

enum PaymentMethod { upi, cod }

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final canteenProvider = Provider.of<CanteenProvider>(context);

    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final selectedCanteen = canteenProvider.selectedCanteen;

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),

      body: cartProvider.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [

                /* ================= CART ITEMS ================= */
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartProvider.items[index];
                      final item = cartItem.menuItem;

                      final bool outOfStock =
                          (item.available != true) || item.stock == 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Opacity(
                          opacity: outOfStock ? 0.5 : 1, // ✅ Grey effect
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightCream,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.coffee,
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        '${currencyFormat.format(item.price)} each',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // ✅ STOCK / WARNING
                                      if (outOfStock)
                                        const Text(
                                          "Out of Stock ❌",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else if (item.stock == 1)
                                        const Text(
                                          "Only 1 left 🔥",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else
                                        Text(
                                          "Stock: ${item.stock}",
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                /* ================= QUANTITY ================= */
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightCream,
                                    borderRadius: BorderRadius.circular(8),
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
                                          '${cartItem.quantity}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        icon: const Icon(Icons.add),

                                        // ✅ Disable if stock exceeded
                                        onPressed: outOfStock ||
                                                cartItem.quantity >= item.stock
                                            ? null
                                            : () {
                                                cartProvider.addItem(item);
                                              },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () {
                                    cartProvider.updateQuantity(item, 0);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /* ================= BILLING ================= */
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      RadioListTile<PaymentMethod>(
                        value: PaymentMethod.upi,
                        groupValue: _paymentMethod,
                        title: const Text('UPI / Online Payment'),
                        onChanged: (value) {
                          setState(() => _paymentMethod = value!);
                        },
                      ),

                      RadioListTile<PaymentMethod>(
                        value: PaymentMethod.cod,
                        groupValue: _paymentMethod,
                        title: const Text('Cash on Delivery'),
                        onChanged: (value) {
                          setState(() => _paymentMethod = value!);
                        },
                      ),

                      const Divider(height: 24),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(currencyFormat.format(cartProvider.subtotal)),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (10%)'),
                          Text(currencyFormat.format(cartProvider.tax)),
                        ],
                      ),

                      const Divider(height: 24),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currencyFormat.format(cartProvider.total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: orderProvider.isLoading ||
                                  authProvider.user == null ||
                                  selectedCanteen == null
                              ? null
                              : () async {
                                  try {
                                    if (_paymentMethod ==
                                        PaymentMethod.upi) {
                                      await _apiService.createCashfreeOrder(
                                        cartProvider.total,
                                      );
                                    }

                                    final payload =
                                        cartProvider.buildOrderPayload(
                                      userId: authProvider.user!.id,
                                      userName: authProvider.user!.name,
                                      canteenId: selectedCanteen.id,
                                    );

                                    payload['paymentMode'] =
                                        _paymentMethod == PaymentMethod.upi
                                            ? 'UPI'
                                            : 'COD';

                                    await orderProvider.createOrder(payload);

                                    await orderProvider.loadUserOrders();
                                    cartProvider.clear();

                                    if (context.mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const OrderTrackingScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Order failed: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: orderProvider.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Place Order'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: cartProvider.clear,
                        child: const Text('Clear Cart'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}