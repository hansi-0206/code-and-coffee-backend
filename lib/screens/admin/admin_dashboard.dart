// FULL FILE — COPY PASTE (OVERFLOW FIXED + RESPONSIVE METRICS)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/canteen_provider.dart';
import '../../models/order.dart';
import '../../models/menu_item.dart';
import '../../widgets/app_background.dart';
import '../login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final orderProvider =
          Provider.of<OrderProvider>(context, listen: false);
      final canteenProvider =
          Provider.of<CanteenProvider>(context, listen: false);
      final menuProvider =
          Provider.of<MenuProvider>(context, listen: false);

      await canteenProvider.fetchCanteens();
      await menuProvider.loadMenuItems();
      await orderProvider.loadTodayOrders();
      await orderProvider.fetchAdminStats();

      _refreshTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) async {
          final selected = canteenProvider.selectedCanteen;

          if (selected != null) {
            await orderProvider.loadTodayOrdersByCanteen(selected.id);
            await orderProvider.fetchAdminStatsByCanteen(selected.id);
          } else {
            await orderProvider.loadTodayOrders();
            await orderProvider.fetchAdminStats();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final authProvider = context.watch<AuthProvider>();
    final canteenProvider = context.watch<CanteenProvider>();

    final orders = List<Order>.from(orderProvider.todayOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange,
          onPressed: canteenProvider.selectedCanteen == null
              ? null
              : () => _openMenuDialog(context),
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.person),
              onSelected: (value) async {
                if (value == 'logout') {
                  await authProvider.logout(context);
                  orderProvider.clearOrders();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (_) => false,
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(authProvider.user?.name ?? 'Admin'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            final selected = canteenProvider.selectedCanteen;

            if (selected != null) {
              await orderProvider.loadTodayOrdersByCanteen(selected.id);
              await orderProvider.fetchAdminStatsByCanteen(selected.id);
            } else {
              await orderProvider.loadTodayOrders();
              await orderProvider.fetchAdminStats();
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _canteenSelector(canteenProvider, menuProvider),
              const SizedBox(height: 16),
              _metrics(menuProvider, orderProvider),
              const SizedBox(height: 28),
              _menuSection(menuProvider),
              const SizedBox(height: 28),
              _ordersSection(orders),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canteenSelector(
      CanteenProvider canteenProvider, MenuProvider menuProvider) {
    return DropdownButtonFormField<String>(
      value: canteenProvider.selectedCanteen?.id,
      decoration: const InputDecoration(
        labelText: 'Select Canteen',
        filled: true,
      ),
      items: canteenProvider.canteens
          .map(
            (c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.name),
            ),
          )
          .toList(),
      onChanged: (canteenId) async {
        if (canteenId == null) return;

        final canteen = canteenProvider.canteens
            .firstWhere((c) => c.id == canteenId);

        canteenProvider.selectCanteen(canteen);
        await menuProvider.loadMenuItemsByCanteen(canteen.id);

        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);

        await orderProvider.loadTodayOrdersByCanteen(canteen.id);
        await orderProvider.fetchAdminStatsByCanteen(canteen.id);
      },
    );
  }

  // 🔥 RESPONSIVE METRICS (NO OVERFLOW)
  Widget _metrics(MenuProvider menu, OrderProvider order) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _metric('Total Items',
                      menu.items.length.toString(),
                      Icons.restaurant_menu, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _metric("Today's Orders",
                      order.todayOrdersCount.toString(),
                      Icons.receipt_long, Colors.green)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _metric('Revenue',
                      '₹${order.totalRevenue.toStringAsFixed(0)}',
                      Icons.attach_money, Colors.blue)),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _metric('Total Items',
                menu.items.length.toString(),
                Icons.restaurant_menu, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _metric("Today's Orders",
                order.todayOrdersCount.toString(),
                Icons.receipt_long, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _metric('Revenue',
                '₹${order.totalRevenue.toStringAsFixed(0)}',
                Icons.attach_money, Colors.blue)),
          ],
        );
      },
    );
  }

  Widget _menuSection(MenuProvider menuProvider) {
    return Card(
      color: const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              columnSpacing: 30,
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Stock')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: menuProvider.items.map((item) {
                return DataRow(cells: [
                  DataCell(SizedBox(
                    width: 120,
                    child: Text(item.name,
                        overflow: TextOverflow.ellipsis),
                  )),
                  DataCell(Text(item.category)),
                  DataCell(Text('₹${item.price.toStringAsFixed(0)}')),
                  DataCell(Text(item.stock.toString())),
                  DataCell(Text(item.available ? 'Available' : 'Unavailable')),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _openMenuDialog(context, item: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.inventory),
                        onPressed: () => _showStockDialog(item),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showStockDialog(MenuItem item) {
    final controller =
        TextEditingController(text: item.stock.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Stock"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: "Stock Quantity"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () async {
              final newStock =
                  int.tryParse(controller.text) ?? 0;

              if (newStock < 0) return;

              await Provider.of<MenuProvider>(
                context,
                listen: false,
              ).updateStock(item.id, newStock);

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _ordersSection(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders today',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: orders.map(_orderCard).toList(),
    );
  }

  Widget _orderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Order #${_shortId(order.id)}'),
        subtitle:
            Text('${order.userName} • ${order.items.length} items'),
        trailing:
            Text('₹${order.total.toStringAsFixed(0)}'),
      ),
    );
  }

  void _openMenuDialog(BuildContext context,
      {MenuItem? item}) {}

  Widget _metric(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}