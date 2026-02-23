import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';

class OrderPollingService {
  static Timer? _timer;

  static void start(context) {
    stop();

    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final auth = context.read<AuthProvider>();

      if (auth.user != null) {
        await context.read<OrderProvider>().loadUserOrders();
      }
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
