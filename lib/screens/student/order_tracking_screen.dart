import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/canteen_provider.dart';   // NEW
import '../../models/order.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with WidgetsBindingObserver {

  Timer? _refreshTimer;
  Timer? _countdownTimer;

  Duration? _remainingTime;
  Duration? _totalDuration;
  double _etaProgress = 0.0;

  String? _lastStatus;
  DateTime? _previousEstimatedTime;
  bool _hideTimeline = false;

  /* =========================================================
     START COUNTDOWN
  ========================================================= */
  void _startCountdown(DateTime estimatedTime, DateTime createdAt) {
    _countdownTimer?.cancel();

    _totalDuration = estimatedTime.difference(createdAt);

    void update() {
      final now = DateTime.now();
      final remaining = estimatedTime.difference(now);

      if (remaining.isNegative) {
        _remainingTime = Duration.zero;
        _etaProgress = 1.0;
        _countdownTimer?.cancel();
      } else {
        _remainingTime = remaining;
        final elapsed = now.difference(createdAt).inSeconds.toDouble();
        final total = _totalDuration!.inSeconds.toDouble();
        _etaProgress = min(1.0, elapsed / total);
      }

      if (mounted) setState(() {});
    }

    update();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  /* =========================================================
     RELOAD ORDERS
  ========================================================= */
  Future<void> _reloadOrders() async {
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();
    final canteen = context.read<CanteenProvider>();

    if (auth.user != null) {
      await orders.loadUserOrders();

      final String? canteenId = canteen.selectedCanteen?.id;

      final Order? current =
          canteenId == null
              ? null
              : orders.currentOrderByCanteen(canteenId);

      if (current == null) {
        _countdownTimer?.cancel();
        _remainingTime = null;
        _etaProgress = 0.0;
        _previousEstimatedTime = null;
        if (mounted) setState(() {});
        return;
      }

      if (current.status == OrderStatus.completed) {
        _countdownTimer?.cancel();
      }

      if (current.estimatedTime != null &&
          current.status != OrderStatus.completed) {

        _lastStatus = current.status;

        if (_previousEstimatedTime == null ||
            !_previousEstimatedTime!
                .isAtSameMomentAs(current.estimatedTime!)) {

          _previousEstimatedTime = current.estimatedTime;
          _startCountdown(current.estimatedTime!, current.createdAt);
        }
      }
    }
  }

  /* ========================================================= */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<OrderProvider>().loadUserOrders();
      await _reloadOrders();

      _refreshTimer =
          Timer.periodic(const Duration(seconds: 15), (_) => _reloadOrders());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadOrders();
    }
  }

  /* ========================================================= */
  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final canteenProvider = context.watch<CanteenProvider>();

    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final String? canteenId = canteenProvider.selectedCanteen?.id;

    final Order? currentOrder =
        canteenId == null
            ? null
            : orderProvider.currentOrderByCanteen(canteenId);

    final List<Order> history =
        canteenId == null
            ? []
            : orderProvider.orderHistoryByCanteen(canteenId);

    final bool hasActiveOrder = currentOrder != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Order Tracking'),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadOrders,
        child: orderProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (hasActiveOrder)
                      _buildActiveOrderCard(currentOrder!, currency),

                    const SizedBox(height: 24),

                    const Text(
                      "Past Orders",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),

                    Column(
                      children: history.map((o) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(_shortId(o.id)),
                            subtitle: Text(currency.format(o.total)),
                            trailing: _statusChip(o.status),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),
                    _extra(),_extra(),_extra(),_extra(),_extra(),_extra(),
                    _extra(),_extra(),_extra(),_extra(),_extra(),_extra(),
                    _extra(),_extra(),_extra(),_extra(),_extra(),_extra(),
                    _extra(),_extra(),_extra(),_extra(),_extra(),_extra(),
                    _extra(),_extra(),_extra(),_extra(),_extra(),_extra(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _extra() => const SizedBox(height: 1);

  /* =========================================================
     ACTIVE ORDER CARD
  ========================================================= */
  Widget _buildActiveOrderCard(Order order, NumberFormat currency) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Card(
      color: const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _shortId(order.id),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _statusChip(order.status),
              ],
            ),

            const SizedBox(height: 16),

            if (!_hideTimeline)
              _buildOrderTimeline(order.status),

            const SizedBox(height: 16),

            _buildEtaSection(),

            const Divider(height: 24),

            ...order.items.map(
              (item) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantity}× ${item.name}'),
                  Text(currency.format(item.total)),
                ],
              ),
            ),

            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(currency.format(order.total),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange)),
              ],
            ),

            if (order.status == OrderStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: () {
                    orderProvider.completeOrder(order.id);
                  },
                  child: const Text("Done"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtaSection() {
    if (_remainingTime == null) return const SizedBox();

    final minutes = _remainingTime!.inMinutes;
    final seconds = _remainingTime!.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Time Remaining: ${minutes}m ${seconds}s',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: _etaProgress),
      ],
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  Widget _statusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildOrderTimeline(String currentStatus) {
    final statuses = [
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.completed,
    ];

    int currentIndex = statuses.indexOf(currentStatus);
    if (currentIndex < 0) currentIndex = 0;

    return Row(
      children: List.generate(statuses.length * 2 - 1, (index) {
        if (index.isEven) {
          return _buildStep(
            active: index ~/ 2 <= currentIndex,
            icon: _getStatusIcon(statuses[index ~/ 2]),
          );
        } else {
          return _buildLine(index ~/ 2 < currentIndex);
        }
      }),
    );
  }

  Widget _buildStep({required bool active, required IconData icon}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: active ? AppTheme.accentOrange : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        color: active ? AppTheme.accentOrange : Colors.grey[300],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.completed:
        return Icons.check_circle_outline;
      default:
        return Icons.circle;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Placed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.accentOrange;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
