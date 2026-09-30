import 'package:flutter/material.dart';

/// The app's brand mark — a palm-and-sunset "Time to Travel" badge —
/// reused across the splash and auth screens.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/app_icon_foreground.png',
      width: size,
      height: size,
    );
  }
}
