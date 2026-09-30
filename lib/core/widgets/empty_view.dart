import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 56),
            const SizedBox(height: AppSpacing.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSizes.f15,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.s16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
