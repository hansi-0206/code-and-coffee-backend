import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../login_screen.dart';
import '../student/student_dashboard.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // ✅ SAFETY CHECK: ensure only staff enters
    if (authProvider.user?.role != 'staff') {
      return const LoginScreen();
    }

    return WillPopScope(
      onWillPop: () async => false, // prevent back navigation
      child: const StudentDashboard(), // reuse UI safely
    );
  }
}
