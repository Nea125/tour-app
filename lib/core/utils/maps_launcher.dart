import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
/// Opens the Google Maps app (or the web fallback) at the given coordinates.
/// Shows an error snackbar if nothing on the device can handle the link.
Future<void> openInGoogleMaps(
  BuildContext context,
  double latitude,
  double longitude,
) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open Google Maps'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
