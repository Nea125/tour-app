import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/location_map_preview.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../domain/entities/destination_status.dart';
import '../providers/destination_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class DestinationDetailScreen extends ConsumerStatefulWidget {
  final String destinationId;
  const DestinationDetailScreen({super.key, required this.destinationId});

  @override
  ConsumerState<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState
    extends ConsumerState<DestinationDetailScreen> {
  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinationAsync = ref.watch(
      destinationByIdProvider(widget.destinationId),
    );
    final user = ref.watch(currentUserProvider);
    final canManage =
        user?.role == UserRole.admin || user?.role == UserRole.tourManager;

    return Scaffold(
      body: destinationAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (destination) {
          final toursAsync = ref.watch(
            toursByDestinationProvider(widget.destinationId),
          );
          final images = <String>[destination.imageUrl];
          for (final tour in toursAsync.valueOrNull ?? const []) {
            for (final url in tour.images) {
              if (!images.contains(url)) images.add(url);
            }
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.background,
                foregroundColor: Colors.white,
                actions: canManage
                    ? [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => context.push(
                            AppRoutes.destinationForm,
                            extra: destination,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            destination.status == DestinationStatus.active
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () async {
                            final newStatus =
                                destination.status == DestinationStatus.active
                                ? DestinationStatus.inactive
                                : DestinationStatus.active;
                            final error = await ref
                                .read(
                                  destinationListControllerProvider.notifier,
                                )
                                .setStatus(destination.id, newStatus);
                            ref.invalidate(
                              destinationByIdProvider(widget.destinationId),
                            );
                            if (context.mounted && error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete destination'),
                                content: Text(
                                  'Delete "${destination.name}"? This cannot be undone.',
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
                                  .read(
                                    destinationListControllerProvider.notifier,
                                  )
                                  .deleteDestination(destination.id);
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
                        children: images
                            .map(
                              (url) => AppNetworkImage(
                                url: url,
                                borderRadius: BorderRadius.zero,
                              ),
                            )
                            .toList(),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (index) {
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
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              destination.name,
                              style: const TextStyle(
                                fontSize: AppFontSizes.f24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusBadge(
                            label:
                                destination.status == DestinationStatus.active
                                ? 'Active'
                                : 'Inactive',
                            color:
                                destination.status == DestinationStatus.active
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Text(
                            '${destination.province}, ${destination.country}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Row(
                        children: [
                          const Icon(
                            Icons.explore_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Text(
                            '${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppFontSizes.f12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        destination.description,
                        style: const TextStyle(
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s20),
                      const SectionHeader(title: 'Location'),
                      const SizedBox(height: AppSpacing.s10),
                      LocationMapPreview(
                        latitude: destination.latitude,
                        longitude: destination.longitude,
                      ),
                      const SizedBox(height: AppSpacing.s20),
                      const SectionHeader(title: 'Available Tours'),
                      toursAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.s24),
                          child: LoadingWidget(),
                        ),
                        error: (e, _) => ErrorView(message: e.toString()),
                        data: (tours) {
                          if (tours.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.s16,
                              ),
                              child: Text(
                                'No tours available for this destination yet.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: tours.map((tour) {
                              final ratingAsync = ref.watch(
                                averageRatingForTourProvider(tour.id),
                              );
                              return Card(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.s10,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(
                                    AppSpacing.s10,
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: AppNetworkImage(
                                      url: tour.images.first,
                                      width: AppSpacing.s64,
                                      height: AppSpacing.s64,
                                    ),
                                  ),
                                  title: Text(
                                    tour.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.s4,
                                    ),
                                    child: Text(
                                      '${tour.durationDays}D${tour.durationNights}N • ${Formatters.currency(tour.price)}',
                                    ),
                                  ),
                                  trailing: ratingAsync.when(
                                    data: (r) => r > 0
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 14,
                                                color: AppColors.secondary,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.s2,
                                              ),
                                              Text(
                                                r.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontSize: AppFontSizes.f12,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, _) => const SizedBox.shrink(),
                                  ),
                                  onTap: () =>
                                      context.push(AppRoutes.tour(tour.id)),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
