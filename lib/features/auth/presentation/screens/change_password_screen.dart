import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_spacing.dart';

/// Passwords are owned by Keycloak, so the change happens on its
/// "update password" page (application-initiated action), which verifies
/// the current credentials itself.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.changePassword();
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      },
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s20),
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.s16),
          const Text(
            'You will be taken to the secure sign-in page to confirm your '
            'identity and choose a new password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: AppSpacing.s20,
                    width: AppSpacing.s20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}
