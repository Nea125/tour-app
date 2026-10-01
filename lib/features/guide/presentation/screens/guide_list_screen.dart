import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/utils/profile_image_provider.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/guide_status.dart';
import '../providers/guide_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class GuideListScreen extends ConsumerWidget {
  const GuideListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(guideListControllerProvider);
    final user = ref.watch(currentUserProvider);
    final canManage =
        user?.role == UserRole.ADMIN || user?.role == UserRole.MANAGER;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Guides'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push(AppRoutes.guideForm),
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
                hintText: 'Search guides by name or license...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  ref.read(guideSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: guidesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(guideListControllerProvider.notifier).refresh(),
              ),
              data: (guides) {
                if (guides.isEmpty)
                  return const EmptyView(
                    message: 'No guides found',
                    icon: Icons.support_agent_rounded,
                  );
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(guideListControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    itemCount: guides.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s10),
                    itemBuilder: (context, index) {
                      final guide = guides[index];
                      final userAsync = ref.watch(
                        userByIdProvider(guide.userId),
                      );
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpacing.s12),
                          onTap: () => context.push(AppRoutes.guide(guide.id)),
                          leading: userAsync.when(
                            data: (u) => CircleAvatar(
                              radius: 28,
                              backgroundImage: profileImageProvider(
                                u.profileImage,
                              ),
                            ),
                            loading: () => const CircleAvatar(radius: 28),
                            error: (_, _) => const CircleAvatar(
                              radius: 28,
                              child: Icon(Icons.person),
                            ),
                          ),
                          title: Text(
                            userAsync.valueOrNull?.fullName ?? '...',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${guide.experienceYears} years experience • License ${guide.licenseNumber}',
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.f12,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                Text(
                                  guide.languages,
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.f12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: StatusBadge(
                            label: guide.status.label,
                            color: guide.status == GuideStatus.active
                                ? Colors.green
                                : Colors.grey,
                          ),
                          isThreeLine: true,
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
