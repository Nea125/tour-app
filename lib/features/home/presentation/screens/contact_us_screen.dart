import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/company_info.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/location_map_preview.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s20),
        children: [
          const Center(child: AppLogo(size: 56)),
          const SizedBox(height: AppSpacing.s20),
          Card(
            child: Column(
              children: [
                _ContactTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  subtitle: CompanyInfo.phone,
                  onTap: () => launchPhoneCall(context, CompanyInfo.phone),
                ),
                const Divider(height: AppSpacing.s1),
                _ContactTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: CompanyInfo.email,
                  onTap: () => launchEmail(context, CompanyInfo.email),
                ),
                const Divider(height: AppSpacing.s1),
                _ContactTile(
                  icon: Icons.facebook_rounded,
                  title: 'Facebook',
                  subtitle: 'Cambodia Travel App',
                  onTap: () => launchWebsite(context, CompanyInfo.facebookUrl),
                ),
                const Divider(height: AppSpacing.s1),
                _ContactTile(
                  icon: Icons.send_outlined,
                  title: 'Telegram',
                  subtitle: '@travelappcambodia',
                  onTap: () => launchWebsite(context, CompanyInfo.telegramUrl),
                ),
                const Divider(height: AppSpacing.s1),
                _ContactTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: CompanyInfo.address,
                  onTap: () => openInGoogleMaps(
                    context,
                    CompanyInfo.latitude,
                    CompanyInfo.longitude,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          const LocationMapPreview(
            latitude: CompanyInfo.latitude,
            longitude: CompanyInfo.longitude,
            initialZoom: 15,
            height: 200,
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
