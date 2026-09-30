import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

Future<void> _launch(BuildContext context, Uri uri, String failureLabel) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open $failureLabel'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

Future<void> launchPhoneCall(BuildContext context, String phoneNumber) {
  return _launch(
    context,
    Uri(scheme: 'tel', path: phoneNumber),
    'the phone app',
  );
}

Future<void> launchEmail(BuildContext context, String email) {
  return _launch(context, Uri(scheme: 'mailto', path: email), 'your email app');
}

Future<void> launchWebsite(BuildContext context, String url) {
  return _launch(context, Uri.parse(url), url);
}
