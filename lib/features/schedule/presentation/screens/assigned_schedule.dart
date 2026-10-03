import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_app/features/guide/presentation/providers/guide_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../schedule/domain/entities/schedule_status.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';


class MyAssignedSchedulesScreen extends ConsumerWidget {
  const MyAssignedSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not found'),
        ),
      );
    }

    final guideAsync = ref.watch(
      guideByUserIdProvider(user.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Schedules'),
      ),
      body: guideAsync.when(
        loading: () => const LoadingWidget(),

        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
        ),

        data: (guide) {
          if (guide == null) {
            return const Center(
              child: Text('Guide profile not found'),
            );
          }

          final schedulesAsync = ref.watch(
            schedulesForGuideProvider(guide.id),
          );

          return schedulesAsync.when(
            loading: () => const LoadingWidget(),

            error: (error, stackTrace) => ErrorView(
              message: error.toString(),
            ),

            data: (schedules) {
              if (schedules.isEmpty) {
                return const _EmptySchedulesView();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(
                    schedulesForGuideProvider(guide.id),
                  );
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  itemCount: schedules.length,
                  separatorBuilder: (_, __) => const SizedBox(
                    height: AppSpacing.s12,
                  ),
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];

                    final tourAsync = ref.watch(
                      tourByIdProvider(schedule.tourId),
                    );

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                          vertical: AppSpacing.s10,
                        ),

                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.primary,
                          ),
                        ),

                        title: Text(
                          tourAsync.valueOrNull?.title ?? 'Loading...',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        subtitle: Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.s6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.date_range_outlined,
                                    size: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      '${Formatters.date(schedule.startDate)}'
                                      ' → '
                                      '${Formatters.date(schedule.endDate)}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Capacity: ${schedule.capacity}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        trailing: StatusBadge(
                          label: schedule.status.label,
                          color: schedule.status == ScheduleStatus.open
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),

                        onTap: () {
                          final tour = tourAsync.valueOrNull;

                          if (tour != null) {
                            context.push(
                              AppRoutes.tour(tour.id),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptySchedulesView extends StatelessWidget {
  const _EmptySchedulesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(
                alpha: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            const Text(
              'No Assigned Schedules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            const Text(
              'You don\'t have any tour schedules assigned yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}