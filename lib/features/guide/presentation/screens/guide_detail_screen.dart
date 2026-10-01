import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/profile_image_provider.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../schedule/domain/entities/schedule_status.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/guide_status.dart';
import '../providers/guide_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class GuideDetailScreen extends ConsumerWidget {
  final String guideId;
  const GuideDetailScreen({super.key, required this.guideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(guideByIdProvider(guideId));
    final user = ref.watch(currentUserProvider);
    final canManage =
        user?.role == UserRole.ADMIN || user?.role == UserRole.MANAGER;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Profile'),
        actions: canManage
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => guideAsync.whenData(
                    (g) => context.push(AppRoutes.guideForm, extra: g),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    final guide = guideAsync.valueOrNull;
                    if (guide == null) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete guide'),
                        content: const Text('Remove this guide profile?'),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => context.pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final error = await ref
                          .read(guideListControllerProvider.notifier)
                          .deleteGuide(guide.id);
                      if (context.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        } else {
                          context.pop();
                        }
                      }
                    }
                  },
                ),
              ]
            : null,
      ),
      body: guideAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (guide) {
          final userAsync = ref.watch(userByIdProvider(guide.userId));
          final schedulesAsync = ref.watch(schedulesForGuideProvider(guide.id));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s20),
            children: [
              Center(
                child: Column(
                  children: [
                    userAsync.when(
                      data: (u) => CircleAvatar(
                        radius: 48,
                        backgroundImage: profileImageProvider(u.profileImage),
                      ),
                      loading: () => const CircleAvatar(radius: 48),
                      error: (_, _) => const CircleAvatar(
                        radius: 48,
                        child: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      userAsync.valueOrNull?.fullName ?? '...',
                      style: AppTextStyles.screenTitle,
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    StatusBadge(
                      label: guide.status.label,
                      color: guide.status == GuideStatus.active
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatTile(
                    label: 'Experience',
                    value: '${guide.experienceYears} yrs',
                  ),
                  _StatTile(label: 'License', value: guide.licenseNumber),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              const SectionHeader(title: 'About'),
              Text(guide.bio, style: const TextStyle(height: 1.5)),
              const SizedBox(height: AppSpacing.s16),
              const SectionHeader(title: 'Languages'),
              Wrap(
                spacing: 8,
                children: guide.languageList
                    .map((l) => Chip(label: Text(l)))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.s20),
              const SectionHeader(title: 'Assigned Schedules'),
              schedulesAsync.when(
                data: (schedules) {
                  if (schedules.isEmpty)
                    return const Text(
                      'No schedules assigned yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  return Column(
                    children: schedules.map((schedule) {
                      final tourAsync = ref.watch(
                        tourByIdProvider(schedule.tourId),
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpacing.s10),
                          title: Text(
                            tourAsync.valueOrNull?.title ?? '...',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${Formatters.date(schedule.startDate)} → ${Formatters.date(schedule.endDate)}',
                          ),
                          trailing: StatusBadge(
                            label: schedule.status.label,
                            color: schedule.status == ScheduleStatus.open
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          onTap: () => tourAsync.whenData(
                            (t) => context.push(AppRoutes.tour(t.id)),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (e, _) => ErrorView(message: e.toString()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: AppFontSizes.f16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.f12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
