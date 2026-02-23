import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/role_card.dart';

import 'canteen/select_canteen_screen.dart';
import 'admin/admin_dashboard.dart';
import 'kitchen/kitchen_dashboard.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'student';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus(); // 🔥 ADD: close keyboard

    final authProvider = context.read<AuthProvider>();

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email & password')),
      );
      return;
    }

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _selectedRole,
    );

    if (!mounted) return;

    // ❌ LOGIN FAILED
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? 'Login failed. Please try again.',
          ),
        ),
      );
      return;
    }

    // ✅ ROLE BASED ROUTING
    Widget nextScreen;

    if (_selectedRole == 'student' || _selectedRole == 'staff') {
      nextScreen = const SelectCanteenScreen();
    } else if (_selectedRole == 'admin') {
      nextScreen = const AdminDashboard();
    } else if (_selectedRole == 'kitchen') {
      nextScreen = const KitchenDashboard();
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 🔥 ADD
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/cafe_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'I am a...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 104,
                      ),
                      itemBuilder: (context, index) {
                        final roles = [
                          ('Student', Icons.school,
                              'Order & track food', 'student'),
                          ('Staff', Icons.badge,
                              'Quick faculty orders', 'staff'),
                          ('Admin', Icons.admin_panel_settings,
                              'Manage cafeteria', 'admin'),
                          ('Kitchen', Icons.restaurant,
                              'Prepare orders', 'kitchen'),
                        ];

                        final role = roles[index];

                        return RoleCard(
                          icon: role.$2,
                          title: role.$1,
                          subtitle: role.$3,
                          isSelected: _selectedRole == role.$4,
                          onTap: () => setState(
                            () => _selectedRole = role.$4,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    const Text('Email',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress, // 🔥 ADD
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text('Password',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done, // 🔥 ADD
                      onSubmitted: (_) => _handleLogin(), // 🔥 ADD
                      decoration: const InputDecoration(
                        hintText: 'Enter your password',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            authProvider.isLoading ? null : _handleLogin,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Sign up",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
