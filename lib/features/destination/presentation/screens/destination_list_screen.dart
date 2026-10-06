import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_status.dart';
import '../providers/destination_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';

class DestinationListScreen extends ConsumerWidget {
  const DestinationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(destinationListControllerProvider);
    final user = ref.watch(currentUserProvider);
    final canManage =
        user?.role == UserRole.ADMIN || user?.role == UserRole.MANAGER;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destinations'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Add destination',
              icon: const Icon(Icons.add_location_alt_rounded),
              onPressed: () => context.push(AppRoutes.destinationForm),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header + search
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where to next?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore places and plan your next trip',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search destinations, provinces, countries...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) =>
                      ref.read(destinationSearchQueryProvider.notifier).state =
                          value,
                ),
              ],
            ),
          ),
          Expanded(
            child: destinationsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref
                    .read(destinationListControllerProvider.notifier)
                    .refresh(),
              ),
              data: (destinations) {
                if (destinations.isEmpty) {
                  return const EmptyView(
                    message: 'No destinations found',
                    icon: Icons.map_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(destinationListControllerProvider.notifier)
                      .refresh(),
                  child: GridView.builder(
                    // Needed so pull-to-refresh works with few items.
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final d = destinations[index];
                      return _DestinationCard(
                        destination: d,
                        onTap: () => context.push(AppRoutes.destination(d.id)),
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

/// Photo card: full-bleed cover, gradient overlay with name and location,
/// and a badge showing how many photos the destination has.
class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination, required this.onTap});

  final Destination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = destination;
    final photoCount = d.images.isNotEmpty
        ? d.images.length
        : (d.imageUrl.isNotEmpty ? 1 : 0);

    return Material(
      color: Colors.transparent,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image
              AppNetworkImage(
                url: d.imageUrl,
                width: double.infinity,
                borderRadius: BorderRadius.zero,
                placeholderIcon: Icons.landscape_rounded,
              ),

              // Bottom gradient for text readability
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1.0],
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),

              // Photo count badge (top right)
              if (photoCount > 1)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$photoCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Inactive badge (top left)
              if (d.status == DestinationStatus.inactive)
                Positioned(
                  top: 10,
                  left: 10,
                  child: StatusBadge(
                    label: 'Inactive',
                    color: AppColors.textSecondary,
                  ),
                ),

              // Name + location (bottom)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${d.province}, ${d.country}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
