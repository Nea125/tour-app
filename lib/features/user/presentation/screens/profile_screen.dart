import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_app/core/constants/log.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/profile_image_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    prettyPrintJson(user);
    if (user == null) return const SizedBox.shrink();
    final canManage =
        user.role == UserRole.ADMIN || user.role == UserRole.MANAGER;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: profileImageProvider(user.profileImage),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(user.fullName, style: AppTextStyles.screenTitle),
                const SizedBox(height: AppSpacing.s4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  const Divider(height: AppSpacing.s24),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: user.phone,
                  ),
                  const Divider(height: AppSpacing.s24),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Member since',
                    value: Formatters.date(user.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                const Divider(height: AppSpacing.s1),
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
                if (user.role == UserRole.CUSTOMER) ...[
                  const Divider(height: AppSpacing.s1),
                  ListTile(
                    leading: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('My Bookings'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.bookings),
                  ),
                ],
                if (user.role == UserRole.CUSTOMER) ...[
                  const Divider(height: AppSpacing.s1),

                  const Divider(height: AppSpacing.s1),
                  const Divider(height: AppSpacing.s1),
                  ListTile(
                    leading: const Icon(
                      Icons.rate_review_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('My Reviews'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.myReviews),
                  ),
                ],
                // Only customer Role
                if (user.role == UserRole.CUSTOMER) ...[
                  const Divider(height: AppSpacing.s1),
                  ListTile(
                    leading: const Icon(
                      Icons.contact_phone_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Contact Us'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.contactUs),
                  ),
                ],
                if (user.role == UserRole.GUIDE) ...[
                  const Divider(height: AppSpacing.s1),
                  ListTile(
                    leading: const Icon(
                      Icons.schedule_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('My Schedules'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.mySchedules),
                  ),
                ],
                // Only Admin and Manager Roles
                if (user.role == UserRole.ADMIN) ...[
                  const Divider(height: AppSpacing.s1),
                  ListTile(
                    leading: const Icon(
                      Icons.people_outline,
                      color: AppColors.primary,
                    ),
                    title: const Text('User Management'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.adminUsers),
                  ),
                ],
                if (canManage) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('All Bookings'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.adminBookings),
                  ),
                  const Divider(height: AppSpacing.s1),
                  ListTile(
                    leading: const Icon(
                      Icons.insights_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Reports & Analytics'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.adminReports),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.login);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.s12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
