import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';


class PaymentFailedScreen extends StatelessWidget {
  final String bookingId;
  final bool cancelled;
  final String? message;

  const PaymentFailedScreen({
    super.key,
    required this.bookingId,
    this.cancelled = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final title = cancelled ? 'Payment Cancelled' : 'Payment Failed';
    final detail = cancelled
        ? 'You cancelled the payment, so nothing was charged.'
        : (message ?? 'We couldn\'t process your payment.');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cancelled ? Icons.cancel_outlined : Icons.error_outline,
                    size: AppSpacing.s64,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                Text(title, style: AppTextStyles.screenTitle),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s8),
                const Text(
                  'Your booking is still pending. You can pay for it from '
                  'My Bookings before the tour starts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppFontSizes.f12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Back to Home'),
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.payment(bookingId)),
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
