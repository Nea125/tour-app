import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/presentation/screens/my_bookings_screen.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../guide/presentation/providers/guide_provider.dart';
import '../../../review/presentation/providers/report_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text('Hi, ${user.firstName} 👋')),
      body: switch (user.role) {
        UserRole.ADMIN || UserRole.MANAGER => const _ManagementHome(),
        UserRole.GUIDE => _GuideHome(userId: user.id),
        UserRole.CUSTOMER => const _CustomerHome(),
      },
    );
  }
}

class _CustomerHome extends ConsumerWidget {
  const _CustomerHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(destinationListControllerProvider);
    final toursAsync = ref.watch(tourListControllerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(destinationListControllerProvider.notifier).refresh();
        await ref.read(tourListControllerProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          const SectionHeader(title: 'Explore Destinations'),
          SizedBox(
            height: AppSpacing.s190,
            child: destinationsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (destinations) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: destinations.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s12),
                  itemBuilder: (context, index) {
                    final d = destinations[index];
                    return GestureDetector(
                      onTap: () => context.push(AppRoutes.destination(d.id)),
                      child: SizedBox(
                        width: AppSpacing.s150,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AppNetworkImage(
                                  url: d.imageUrl,
                                  width: double.infinity,
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.s8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: AppFontSizes.f13,
                                      ),
                                    ),
                                    Text(
                                      d.country,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: AppFontSizes.f11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          const SectionHeader(title: 'Popular Tours'),
          toursAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (tours) {
              return Column(
                children: tours.take(5).map((tour) {
                  final ratingAsync = ref.watch(
                    averageRatingForTourProvider(tour.id),
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.s10),
                      onTap: () => context.push(AppRoutes.tour(tour.id)),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AppNetworkImage(
                          url: tour.images.first,
                          width: AppSpacing.s60,
                          height: AppSpacing.s60,
                        ),
                      ),
                      title: Text(
                        tour.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${tour.durationDays}D${tour.durationNights}N • ${Formatters.currency(tour.price)}',
                      ),
                      trailing: ratingAsync.when(
                        data: (r) => RatingStars(rating: r, size: 13),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GuideHome extends ConsumerWidget {
  final String userId;
  const _GuideHome({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(guideByUserIdProvider(userId));

    return guideAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (guide) {
        if (guide == null) {
          return const Center(
            child: Text(
              'No guide profile linked to this account yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        final schedulesAsync = ref.watch(schedulesForGuideProvider(guide.id));
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${guide.experienceYears} years experience',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppFontSizes.f16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'License ${guide.licenseNumber}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppFontSizes.f12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      guide.languages,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppFontSizes.f12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            const SectionHeader(title: 'Your Assigned Schedules'),
            schedulesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (schedules) {
                if (schedules.isEmpty)
                  return const Text(
                    'No schedules assigned yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                return Column(
                  children: schedules.map((schedule) {
                    final tourAsync = ref.watch(
                      tourByIdProvider(schedule.tourId),
                    );
                    return tourAsync.when(
                      data: (tour) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpacing.s10),
                          onTap: () => context.push(AppRoutes.tour(tour.id)),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AppNetworkImage(
                              url: tour.images.first,
                              width: AppSpacing.s56,
                              height: AppSpacing.s56,
                            ),
                          ),
                          title: Text(
                            tour.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${Formatters.date(schedule.startDate)} → ${Formatters.date(schedule.endDate)}',
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: AppSpacing.s76,
                        child: LoadingWidget(),
                      ),
                      error: (e, _) => Text(e.toString()),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ManagementHome extends ConsumerWidget {
  const _ManagementHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportSummaryProvider);
    final recentBookingsAsync = ref.watch(allBookingsControllerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(reportSummaryProvider);
        await ref.read(allBookingsControllerProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          reportAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (report) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _MiniStat(
                  label: 'Revenue',
                  value: Formatters.currency(report.totalRevenue),
                  color: AppColors.primary,
                ),
                _MiniStat(
                  label: 'Bookings',
                  value: '${report.totalBookings}',
                  color: AppColors.info,
                ),
                _MiniStat(
                  label: 'Tours',
                  value: '${report.totalTours}',
                  color: AppColors.secondary,
                ),
                _MiniStat(
                  label: 'Customers',
                  value: '${report.totalCustomers}',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(AppRoutes.adminReports),
              child: const Text('View full report →'),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          SectionHeader(
            title: 'Recent Bookings',
            actionLabel: 'View all',
            onAction: () => context.push(AppRoutes.adminBookings),
          ),
          recentBookingsAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (bookings) {
              final recent = bookings.take(5).toList();
              if (recent.isEmpty)
                return const Text(
                  'No bookings yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              return Column(
                children: recent.map((b) {
                  final scheduleAsync = ref.watch(
                    scheduleByIdProvider(b.tourScheduleId),
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: ListTile(
                      onTap: () => context.push(AppRoutes.booking(b.id)),
                      title: Text(b.bookingCode),
                      subtitle: scheduleAsync.when(
                        data: (schedule) => Text(
                          '${Formatters.date(schedule.startDate)} • ${b.numberOfPeople} pax',
                        ),
                        loading: () => const Text('...'),
                        error: (_, _) => Text('${b.numberOfPeople} pax'),
                      ),
                      trailing: StatusBadge(
                        label: b.status.label,
                        color: bookingStatusColor(b.status),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppFontSizes.f18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
