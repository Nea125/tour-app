
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../../core/router/app_routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _login();
    });
  }

  Future<void> _login() async {
    final error = await ref
        .read(authControllerProvider.notifier)
        .login();

    if (!mounted) return;

    if (error != null) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );

      return;
    }

    // Login succeeded.
    // Your auth controller/router should normally redirect automatically.
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Login failed'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Try Again'),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text('Create Account'),
                  ),
                ],
              ),
      ),
    );
  }
}