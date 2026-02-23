import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import '../../models/order.dart';
import '../../widgets/app_background.dart';
import '../login_screen.dart';

class KitchenDashboard extends StatefulWidget {
  const KitchenDashboard({super.key});

  @override
  State<KitchenDashboard> createState() => _KitchenDashboardState();
}

class _KitchenDashboardState extends State<KitchenDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  String? _canteenId;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final orders = Provider.of<OrderProvider>(context, listen: false);

      _canteenId = auth.user?.canteenId;

      if (_canteenId == null) return;

      await orders.loadKitchenOrdersByCanteen(_canteenId!);

      _refreshTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) async {
          await orders.loadKitchenOrdersByCanteen(_canteenId!);
        },
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final authProvider = context.watch<AuthProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Kitchen Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                if (_canteenId != null) {
                  await orderProvider.loadKitchenOrdersByCanteen(_canteenId!);
                }
              },
            ),
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
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(authProvider.user?.name ?? 'Kitchen'),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                tabs: [
                  Tab(text: 'New (${orderProvider.newOrders.length})'),
                  Tab(text: 'Preparing (${orderProvider.preparingOrders.length})'),
                  Tab(text: 'Ready (${orderProvider.readyOrders.length})'),
                  Tab(text: 'History (${orderProvider.kitchenHistory.length})'),
                ],
              ),
            ),
          ),
        ),
        body: orderProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(
                    context,
                    orderProvider.newOrders,
                    OrderStatus.preparing,
                    'Start Preparing',
                    askTime: true,
                  ),
                  _buildOrderList(
                    context,
                    orderProvider.preparingOrders,
                    OrderStatus.ready,
                    'Mark Ready',
                    allowTimeUpdate: true,
                  ),
                  _buildOrderList(
                    context,
                    orderProvider.readyOrders,
                    OrderStatus.completed,
                    'Complete',
                  ),
                  _buildHistoryList(orderProvider.kitchenHistory),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryList(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No completed orders',
          style: TextStyle(color: Color(0xFFFFF3E0)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return OrderCard(
          order: orders[index],
          nextStatus: OrderStatus.completed,
          buttonText: 'Completed',
          onStatusUpdate: () {},
          showButton: false,
        );
      },
    );
  }

  Widget _buildOrderList(
    BuildContext context,
    List<Order> orders,
    String nextStatus,
    String buttonText, {
    bool askTime = false,
    bool allowTimeUpdate = false,
  }) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders available',
          style: TextStyle(
            color: Color(0xFFFFF3E0),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        return OrderCard(
          order: order,
          nextStatus: nextStatus,
          buttonText: buttonText,
          onStatusUpdate: () async {
            final provider =
                Provider.of<OrderProvider>(context, listen: false);

            DateTime? estimatedTime;

            if (askTime) {
              final minutes = await _askPrepTime(context);
              if (minutes == null) return;

              estimatedTime =
                  DateTime.now().add(Duration(minutes: minutes));
            }

            if (nextStatus == OrderStatus.completed) {
              await provider.completeOrder(order.id);   // 🔥 added
            } else {
              await provider.updateOrderStatus(
                order.id,
                nextStatus,
                estimatedTime: estimatedTime,
              );
            }

            if (_canteenId != null) {
              await provider.loadKitchenOrdersByCanteen(_canteenId!);
            }
          },
          onUpdateTime: allowTimeUpdate
              ? () async {
                  final minutes = await _askPrepTime(context);
                  if (minutes == null) return;

                  final newTime =
                      DateTime.now().add(Duration(minutes: minutes));

                  final provider =
                      Provider.of<OrderProvider>(context, listen: false);

                  await provider.updateOrderStatus(
                    order.id,
                    order.status,
                    estimatedTime: newTime,
                  );

                  if (_canteenId != null) {
                    await provider.loadKitchenOrdersByCanteen(_canteenId!);
                  }
                }
              : null,
        );
      },
    );
  }

  Future<int?> _askPrepTime(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Preparation Time'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: 'Minutes (e.g. 10)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
