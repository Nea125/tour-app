import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(size: 96),
            SizedBox(height: AppSpacing.s16),
            Text(
              'Travel App',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppFontSizes.f26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.s24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
