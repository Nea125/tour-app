import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../guide/presentation/providers/guide_provider.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../../itinerary/presentation/screens/itinerary_management_screen.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../schedule/domain/entities/schedule_status.dart';
import '../../../schedule/domain/entities/tour_schedule.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../providers/tour_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class TourDetailScreen extends ConsumerStatefulWidget {
  final String tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  ConsumerState<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends ConsumerState<TourDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tourAsync = ref.watch(tourByIdProvider(widget.tourId));
    final user = ref.watch(currentUserProvider);
    final canManage =
        user?.role == UserRole.admin || user?.role == UserRole.tourManager;

    return Scaffold(
      body: tourAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (tour) {
          final destinationAsync = ref.watch(
            destinationByIdProvider(tour.destinationId),
          );
          final ratingAsync = ref.watch(averageRatingForTourProvider(tour.id));

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.background,
                foregroundColor: Colors.white,
                actions: canManage
                    ? [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              context.push(AppRoutes.tourForm, extra: tour),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete tour'),
                                content: Text('Delete "${tour.title}"?'),
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
                                  .read(tourListControllerProvider.notifier)
                                  .deleteTour(tour.id);
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
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView(
                        controller: _imagePageController,
                        onPageChanged: (index) =>
                            setState(() => _currentImagePage = index),
                        children: tour.images
                            .map(
                              (url) => AppNetworkImage(
                                url: url,
                                borderRadius: BorderRadius.zero,
                              ),
                            )
                            .toList(),
                      ),
                      if (tour.images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(tour.images.length, (
                              index,
                            ) {
                              final isActive = index == _currentImagePage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s3,
                                ),
                                width: isActive ? 18 : 6,
                                height: AppSpacing.s6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    AppSpacing.s16,
                    AppSpacing.s20,
                    AppSpacing.s0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tour.title,
                              style: const TextStyle(
                                fontSize: AppFontSizes.f22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ratingAsync.when(
                            data: (r) => RatingStars(rating: r),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      destinationAsync.when(
                        data: (d) => Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.s4),
                            Text(
                              '${d.province}, ${d.country}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label:
                                '${tour.durationDays}D${tour.durationNights}N',
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          _InfoChip(
                            icon: Icons.groups_outlined,
                            label: 'Max ${tour.maxParticipants}',
                          ),
                          if (destinationAsync.valueOrNull != null) ...[
                            const SizedBox(width: AppSpacing.s8),
                            _InfoChip(
                              icon: Icons.map_outlined,
                              label: 'Open in Maps',
                              onTap: () => openInGoogleMaps(
                                context,
                                destinationAsync.valueOrNull!.latitude,
                                destinationAsync.valueOrNull!.longitude,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Itinerary'),
                      Tab(text: 'Schedules'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(tour: tour),
                _ItineraryTab(tourId: tour.id, canManage: canManage),
                _SchedulesTab(tourId: tour.id, canManage: canManage),
                _ReviewsTab(tourId: tour.id, canManage: canManage),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _InfoChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAction = onTap != null;
    final color = isAction ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s6,
        ),
        decoration: BoxDecoration(
          color: isAction
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.s4),
            Text(
              label,
              style: TextStyle(fontSize: AppFontSizes.f12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _OverviewTab extends StatelessWidget {
  final dynamic tour;
  const _OverviewTab({required this.tour});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s20),
      children: [
        const Text('About this tour', style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.s8),
        Text(
          tour.description,
          style: const TextStyle(height: 1.5, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s20),
        const Text('Trip Details', style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.s8),
        _DetailRow(
          label: 'Duration',
          value: '${tour.durationDays} days / ${tour.durationNights} nights',
        ),
        _DetailRow(label: 'Max Participants', value: '${tour.maxParticipants}'),
        _DetailRow(
          label: 'Price per Person',
          value: Formatters.currency(tour.price),
        ),
        const SizedBox(height: AppSpacing.s40),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ItineraryTab extends ConsumerWidget {
  final String tourId;
  final bool canManage;
  const _ItineraryTab({required this.tourId, required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryByTourProvider(tourId));
    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.small(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ItineraryManagementScreen(tourId: tourId),
                ),
              ),
              child: const Icon(Icons.edit_calendar_outlined),
            )
          : null,
      body: itineraryAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (days) {
          if (days.isEmpty) {
            return const Center(
              child: Text(
                'No itinerary available yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.s20),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final activitiesAsync = ref.watch(
                activitiesByItineraryProvider(day.id),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            '${day.dayNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: AppFontSizes.f12,
                            ),
                          ),
                        ),
                        if (index != days.length - 1)
                          Container(
                            width: AppSpacing.s2,
                            height: AppSpacing.s70,
                            color: AppColors.divider,
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s4),
                              Text(
                                day.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: AppFontSizes.f13,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s8),
                              activitiesAsync.when(
                                data: (activities) => Column(
                                  children: activities
                                      .map(
                                        (a) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.s3,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: AppSpacing.s90,
                                                child: Text(
                                                  '${a.startTime.format(context)} - ${a.endTime.format(context)}',
                                                  style: const TextStyle(
                                                    fontSize: AppFontSizes.f11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '${a.title} — ${a.location}',
                                                  style: const TextStyle(
                                                    fontSize: AppFontSizes.f12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SchedulesTab extends ConsumerWidget {
  final String tourId;
  final bool canManage;
  const _SchedulesTab({required this.tourId, required this.canManage});

  Color _statusColor(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.open:
        return AppColors.success;
      case ScheduleStatus.closed:
        return AppColors.warning;
      case ScheduleStatus.completed:
        return AppColors.info;
      case ScheduleStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesByTourProvider(tourId));
    final user = ref.watch(currentUserProvider);
    final isCustomer = user?.role == UserRole.customer;

    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.small(
              onPressed: () => context.push(AppRoutes.scheduleForm(tourId)),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: schedulesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (schedules) {
          if (schedules.isEmpty) {
            return const Center(
              child: Text(
                'No schedules available yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.s20),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final TourSchedule schedule = schedules[index];
              final slotsAsync = ref.watch(availableSlotsProvider(schedule.id));
              final guideIdsAsync = ref.watch(
                guideIdsForScheduleProvider(schedule.id),
              );
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.s12),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${Formatters.date(schedule.startDate)} → ${Formatters.date(schedule.endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Row(
                            children: [
                              StatusBadge(
                                label: schedule.status.label,
                                color: _statusColor(schedule.status),
                              ),
                              if (canManage)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => context.push(
                                    AppRoutes.scheduleForm(tourId),
                                    extra: schedule,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      slotsAsync.when(
                        data: (slots) => Text(
                          '$slots of ${schedule.capacity} slots available',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppFontSizes.f12,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      guideIdsAsync.when(
                        data: (guideIds) {
                          if (guideIds.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s6),
                            child: Wrap(
                              spacing: 6,
                              children: guideIds.map((guideId) {
                                final guideAsync = ref.watch(
                                  guideByIdProvider(guideId),
                                );
                                return guideAsync.when(
                                  data: (guide) {
                                    final userAsync = ref.watch(
                                      userByIdProvider(guide.userId),
                                    );
                                    return ActionChip(
                                      avatar: const Icon(
                                        Icons.support_agent_rounded,
                                        size: 14,
                                      ),
                                      label: Text(
                                        userAsync.valueOrNull?.fullName ??
                                            'Guide',
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.f11,
                                        ),
                                      ),
                                      onPressed: () => context.push(
                                        AppRoutes.guide(guide.id),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, _) => const SizedBox.shrink(),
                                );
                              }).toList(),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      if (isCustomer &&
                          schedule.status == ScheduleStatus.open) ...[
                        const SizedBox(height: AppSpacing.s10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push(
                              AppRoutes.createBooking(schedule.id),
                            ),
                            child: const Text('Book This Schedule'),
                          ),
                        ),
                      ],
                      if (canManage) ...[
                        const SizedBox(height: AppSpacing.s10),
                        Wrap(
                          spacing: 8,
                          children: ScheduleStatus.values.map((s) {
                            return ChoiceChip(
                              label: Text(
                                s.label,
                                style: const TextStyle(
                                  fontSize: AppFontSizes.f11,
                                ),
                              ),
                              selected: schedule.status == s,
                              onSelected: (_) => ref
                                  .read(scheduleControllerProvider.notifier)
                                  .setStatus(schedule.id, s),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  final String tourId;
  final bool canManage;
  const _ReviewsTab({required this.tourId, required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsByTourProvider(tourId));
    return reviewsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Text(
              'No reviews yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.s20),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const Divider(height: AppSpacing.s24),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RatingStars(rating: review.rating.toDouble(), size: 14),
                    const Spacer(),
                    Text(
                      Formatters.date(review.createdAt),
                      style: const TextStyle(
                        fontSize: AppFontSizes.f11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Report inappropriate review',
                      onPressed: () async {
                        final reason = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final controller = TextEditingController();
                            return AlertDialog(
                              title: const Text('Report review'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: 'Why is this review inappropriate?',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => context.pop(controller.text),
                                  child: const Text('Report'),
                                ),
                              ],
                            );
                          },
                        );
                        if (reason != null &&
                            reason.trim().isNotEmpty &&
                            context.mounted) {
                          final error = await ref
                              .read(myReviewsControllerProvider.notifier)
                              .reportReview(
                                reviewId: review.id,
                                reason: reason.trim(),
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error ?? 'Review reported. Thank you.',
                                ),
                                backgroundColor: error != null
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    if (canManage)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        tooltip: 'Delete review',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete review'),
                              content: const Text(
                                'Delete this review? This cannot be undone.',
                              ),
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
                                .read(adminReviewControllerProvider.notifier)
                                .deleteReview(review.id);
                            if (context.mounted && error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(review.comment),
              ],
            );
          },
        );
      },
    );
  }
}
