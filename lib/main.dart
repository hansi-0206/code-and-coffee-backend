import 'dart:async'; // 🔥 ADD

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';

// 🔥 PROVIDERS
import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/canteen_provider.dart';

// 🔥 SCREENS
import 'screens/login_screen.dart';
import 'screens/canteen/select_canteen_screen.dart';
import 'screens/kitchen/kitchen_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

// 🔥 COMMON
import 'widgets/app_background.dart';
import 'services/notification_service.dart';

// 🔥 GLOBAL NAVIGATOR
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Timer? _orderPollingTimer; // 🔥 ADD GLOBAL POLLING

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize notifications
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 🔥 GLOBAL ORDER AUTO SYNC
  void _startGlobalPolling(BuildContext context) {
    _orderPollingTimer?.cancel();

    _orderPollingTimer =
        Timer.periodic(const Duration(seconds: 8), (_) async {
      final auth =
          Provider.of<AuthProvider>(context, listen: false);
      final orders =
          Provider.of<OrderProvider>(context, listen: false);

      if (auth.isAuthenticated &&
          (auth.user?.role == 'student' ||
              auth.user?.role == 'staff')) {
        await orders.loadUserOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CanteenProvider()),
      ],
      child: Builder(
        builder: (context) {
          _startGlobalPolling(context); // 🔥 START POLLING

          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Code & Coffee',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AppBackground(
                child: child ?? const SizedBox(),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔥 When app resumes → refresh orders automatically
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth =
          Provider.of<AuthProvider>(context, listen: false);
      final orders =
          Provider.of<OrderProvider>(context, listen: false);

      if (auth.isAuthenticated &&
          (auth.user?.role == 'student' ||
           auth.user?.role == 'staff')) {
        orders.loadUserOrders();
      }
    }
  }

  Future<void> _checkAuth() async {
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);

    await authProvider.loadUser();

    if (!mounted) return;

    orderProvider.clearOrders();

    if (!authProvider.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final role = authProvider.user!.role;

    if (role == 'student' || role == 'staff') {
      await orderProvider.loadUserOrders();
    }

    if (role == 'student' || role == 'staff') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SelectCanteenScreen(),
        ),
      );
    } else if (role == 'kitchen') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const KitchenDashboard(),
        ),
      );
    } else if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Code & Coffee',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
