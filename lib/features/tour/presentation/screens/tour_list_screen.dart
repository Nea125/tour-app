import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../providers/tour_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class TourListScreen extends ConsumerWidget {
  const TourListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toursAsync = ref.watch(tourListControllerProvider);
    final selectedDestinationId = ref.watch(tourDestinationFilterProvider);
    final destinationsAsync = ref.watch(destinationListControllerProvider);
    final user = ref.watch(currentUserProvider);
    final canManage =
        user?.role == UserRole.ADMIN || user?.role == UserRole.MANAGER;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tours'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push(AppRoutes.tourForm),
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
                hintText: 'Search tours...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  ref.read(tourSearchQueryProvider.notifier).state = value,
            ),
          ),
          SizedBox(
            height: AppSpacing.s40,
            child: destinationsAsync.when(
              data: (destinations) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: destinations.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ChoiceChip(
                        label: const Text('All'),
                        selected: selectedDestinationId == null,
                        onSelected: (_) =>
                            ref
                                    .read(
                                      tourDestinationFilterProvider.notifier,
                                    )
                                    .state =
                                null,
                      );
                    }
                    final destination = destinations[index - 1];
                    return ChoiceChip(
                      label: Text(destination.name),
                      selected: selectedDestinationId == destination.id,
                      onSelected: (_) =>
                          ref
                                  .read(tourDestinationFilterProvider.notifier)
                                  .state =
                              destination.id,
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Expanded(
            child: toursAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(tourListControllerProvider.notifier).refresh(),
              ),
              data: (tours) {
                if (tours.isEmpty) {
                  return const EmptyView(
                    message: 'No tours found',
                    icon: Icons.card_travel_rounded,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(tourListControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s0,
                      AppSpacing.s16,
                      AppSpacing.s16,
                    ),
                    itemCount: tours.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s12),
                    itemBuilder: (context, index) {
                      final tour = tours[index];
                      final ratingAsync = ref.watch(
                        averageRatingForTourProvider(tour.id),
                      );
                      return GestureDetector(
                        onTap: () => context.push(AppRoutes.tour(tour.id)),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppNetworkImage(
                                  url: tour.images.first,
                                  width: AppSpacing.s120,
                                  borderRadius: BorderRadius.zero,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.s12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tour.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.s6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.s4,
                                            ),
                                            Text(
                                              '${tour.durationDays}D${tour.durationNights}N',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: AppFontSizes.f12,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.s10,
                                            ),
                                            ratingAsync.when(
                                              data: (r) => RatingStars(
                                                rating: r,
                                                size: 13,
                                              ),
                                              loading: () =>
                                                  const SizedBox.shrink(),
                                              error: (_, _) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.s6),
                                        Chip(
                                          visualDensity: VisualDensity.compact,
                                          label: Text(
                                            'Max ${tour.maxParticipants}',
                                            style: const TextStyle(
                                              fontSize: AppFontSizes.f11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.s6),
                                        Text(
                                          Formatters.currency(tour.price),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: AppFontSizes.f16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
