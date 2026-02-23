import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final String nextStatus;
  final String buttonText;
  final VoidCallback onStatusUpdate;

  // 🔥 NEW — SWIGGY STYLE UPDATE TIME
  final VoidCallback? onUpdateTime;

  // 🔥 NEW — allow hiding button (history tab)
  final bool showButton;

  const OrderCard({
    super.key,
    required this.order,
    required this.nextStatus,
    required this.buttonText,
    required this.onStatusUpdate,
    this.onUpdateTime,
    this.showButton = true, // default true
  });

  bool get isStaffPriority => order.priority == 'high';

  String _shortId(String id) {
    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(order.createdAt);
    final statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isStaffPriority ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isStaffPriority
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shortId(order.id),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.userName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (isStaffPriority) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'STAFF PRIORITY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// TIME
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (onUpdateTime != null) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onUpdateTime,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update time'),
                  ),
                ],
              ],
            ),

            const Divider(height: 24),

            /// ITEMS
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${item.quantity}× ${item.name}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ACTION BUTTON (🔥 hide when history)
            if (showButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStatusUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStaffPriority
                        ? Colors.red
                        : _getButtonColor(nextStatus),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getButtonIcon(nextStatus)),
                      const SizedBox(width: 8),
                      Text(buttonText),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return DateFormat('MMM dd, HH:mm').format(dateTime);
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

  String _getStatusText(String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
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

  Color _getButtonColor(String nextStatus) {
    switch (nextStatus) {
      case OrderStatus.preparing:
        return AppTheme.accentOrange;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.blue;
      default:
        return AppTheme.primaryBrown;
    }
  }

  IconData _getButtonIcon(String nextStatus) {
    switch (nextStatus) {
      case OrderStatus.preparing:
        return Icons.play_arrow;
      case OrderStatus.ready:
        return Icons.check;
      case OrderStatus.completed:
        return Icons.check_circle;
      default:
        return Icons.arrow_forward;
    }
  }
}
