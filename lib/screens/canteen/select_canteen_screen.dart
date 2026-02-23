import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/canteen.dart';
import '../../providers/canteen_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart'; // 🔥 ADD
import '../student/menu_screen.dart';
import '../login_screen.dart';

class SelectCanteenScreen extends StatefulWidget {
  const SelectCanteenScreen({super.key});

  @override
  State<SelectCanteenScreen> createState() => _SelectCanteenScreenState();
}

class _SelectCanteenScreenState extends State<SelectCanteenScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<CanteenProvider>(context, listen: false).fetchCanteens();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canteenProvider = context.watch<CanteenProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Canteen'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) async {
              if (value == 'logout') {
                Provider.of<CartProvider>(context, listen: false).clear();
                Provider.of<MenuProvider>(context, listen: false).clear();
                Provider.of<CanteenProvider>(context, listen: false).clear();

                await authProvider.logout(context);

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(authProvider.user?.name ?? 'Student'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
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
      body: _buildBody(canteenProvider),
    );
  }

  Widget _buildBody(CanteenProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Text(
          provider.error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (provider.canteens.isEmpty) {
      return const Center(
        child: Text('No canteens available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.canteens.length,
      itemBuilder: (context, index) {
        final canteen = provider.canteens[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              canteen.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Code: ${canteen.code}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _onCanteenSelected(context, canteen),
          ),
        );
      },
    );
  }

  // ================= CANTEEN SELECT =================
  void _onCanteenSelected(BuildContext context, Canteen canteen) async {
    Provider.of<CanteenProvider>(context, listen: false)
        .selectCanteen(canteen);

    Provider.of<CartProvider>(context, listen: false).clear();
    Provider.of<MenuProvider>(context, listen: false).clear();

    // 🔥 IMPORTANT FIX — reload orders so tracking appears
    await Provider.of<OrderProvider>(context, listen: false)
        .loadUserOrders();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MenuScreen(),
      ),
    );
  }
}
