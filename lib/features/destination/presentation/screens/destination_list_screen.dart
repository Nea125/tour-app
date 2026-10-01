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
import '../../domain/entities/destination_status.dart';
import '../providers/destination_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class DestinationListScreen extends ConsumerWidget {
  const DestinationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(destinationListControllerProvider);
    final user = ref.watch(currentUserProvider);
    final canManage =
        user?.role == UserRole.ADMIN || user?.role == UserRole.MANAGER;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destinations'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push(AppRoutes.destinationForm),
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
                hintText: 'Search destinations, provinces, countries...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  ref.read(destinationSearchQueryProvider.notifier).state =
                      value,
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
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final d = destinations[index];
                      return GestureDetector(
                        onTap: () => context.push(AppRoutes.destination(d.id)),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppNetworkImage(
                                      url: d.imageUrl,
                                      width: double.infinity,
                                      borderRadius: BorderRadius.zero,
                                      placeholderIcon: Icons.landscape_rounded,
                                    ),
                                    if (d.status == DestinationStatus.inactive)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: StatusBadge(
                                          label: 'Inactive',
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.s10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: AppFontSizes.f15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppSpacing.s2),
                                    Text(
                                      '${d.province}, ${d.country}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: AppFontSizes.f12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
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
