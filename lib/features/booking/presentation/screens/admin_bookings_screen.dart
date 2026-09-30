import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_provider.dart';
import 'my_bookings_screen.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(allBookingsControllerProvider);
    final statusFilter = ref.watch(bookingStatusFilterProvider);
    final usersAsync = ref.watch(userListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: Column(
        children: [
          SizedBox(
            height: AppSpacing.s44,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s4,
              ),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: statusFilter == null,
                    onSelected: (_) =>
                        ref.read(bookingStatusFilterProvider.notifier).state =
                            null,
                  ),
                ),
                ...BookingStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s8),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: statusFilter == s,
                      onSelected: (_) =>
                          ref.read(bookingStatusFilterProvider.notifier).state =
                              s,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(allBookingsControllerProvider.notifier).refresh(),
              ),
              data: (bookings) {
                if (bookings.isEmpty)
                  return const EmptyView(
                    message: 'No bookings found',
                    icon: Icons.receipt_long_outlined,
                  );
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(allBookingsControllerProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    itemCount: bookings.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s10),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final scheduleAsync = ref.watch(
                        scheduleByIdProvider(booking.tourScheduleId),
                      );
                      final matchingUsers =
                          usersAsync.valueOrNull?.where(
                            (u) => u.id == booking.userId,
                          ) ??
                          const [];
                      final customerName = matchingUsers.isNotEmpty
                          ? matchingUsers.first.fullName
                          : 'Customer';
                      return scheduleAsync.when(
                        data: (schedule) {
                          final tourAsync = ref.watch(
                            tourByIdProvider(schedule.tourId),
                          );
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(
                                AppSpacing.s12,
                              ),
                              onTap: () =>
                                  context.push(AppRoutes.booking(booking.id)),
                              title: Text(
                                tourAsync.valueOrNull?.title ?? 'Loading...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.s4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$customerName • ${booking.bookingCode}',
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.f12,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.s2),
                                    Text(
                                      '${Formatters.date(schedule.startDate)} • ${booking.numberOfPeople} pax • ${Formatters.currency((tourAsync.valueOrNull?.price ?? 0) * booking.numberOfPeople)}',
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.f12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: StatusBadge(
                                label: booking.status.label,
                                color: bookingStatusColor(booking.status),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                        loading: () => const Card(
                          child: SizedBox(
                            height: AppSpacing.s72,
                            child: LoadingWidget(),
                          ),
                        ),
                        error: (e, _) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s12),
                            child: Text(e.toString()),
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
