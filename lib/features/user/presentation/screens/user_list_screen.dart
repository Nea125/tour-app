import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/profile_image_provider.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/user_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

Color roleColor(UserRole role) {
  switch (role) {
    case UserRole.ADMIN:
      return AppColors.error;
    case UserRole.MANAGER:
      return AppColors.secondary;
    case UserRole.GUIDE:
      return AppColors.info;
    case UserRole.CUSTOMER:
      return AppColors.success;
  }
}

Color statusColor(UserStatus status) {
  switch (status) {
    case UserStatus.active:
      return AppColors.success;
    case UserStatus.inactive:
      return AppColors.textSecondary;
    case UserStatus.suspended:
      return AppColors.error;
  }
}

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => context.push(AppRoutes.adminCreateUser),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  ref.read(userSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(userListControllerProvider.notifier).refresh(),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyView(
                    message: 'No users found',
                    icon: Icons.people_outline_rounded,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(userListControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    itemCount: users.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s10),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: profileImageProvider(
                                  user.profileImage,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.s2),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: AppFontSizes.f13,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.s6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        StatusBadge(
                                          label: user.role.label,
                                          color: roleColor(user.role),
                                        ),
                                        StatusBadge(
                                          label: user.status.label,
                                          color: statusColor(user.status),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.s4),
                                    Text(
                                      'Joined ${Formatters.date(user.createdAt)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: AppFontSizes.f11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  final controller = ref.read(
                                    userListControllerProvider.notifier,
                                  );
                                  String? error;
                                  if (value.startsWith('status_')) {
                                    error = await controller.setStatus(
                                      user.id,
                                      UserStatusX.fromString(
                                        value.substring(7),
                                      ),
                                    );
                                  } else if (value.startsWith('role_')) {
                                    error = await controller.changeRole(
                                      user.id,
                                      UserRoleX.fromString(value.substring(5)),
                                    );
                                  } else if (value == 'delete') {
                                    error = await controller.deleteUser(
                                      user.id,
                                    );
                                  }
                                  if (error != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  ...UserStatus.values.map(
                                    (s) => PopupMenuItem(
                                      value: 'status_${s.name}',
                                      child: Text('Set ${s.label}'),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  ...UserRole.values.map(
                                    (r) => PopupMenuItem(
                                      value: 'role_${r.name}',
                                      child: Text('Set as ${r.label}'),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
