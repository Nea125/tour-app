import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

Color bookingStatusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return AppColors.warning;
    case BookingStatus.paid:
      return AppColors.success;
    case BookingStatus.cancelled:
      return AppColors.error;
  }
}

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(myBookingsControllerProvider.notifier).refresh(),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyView(
              message:
                  'You have no bookings yet.\nExplore tours to get started!',
              icon: Icons.confirmation_number_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(myBookingsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: bookings.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final scheduleAsync = ref.watch(
                  scheduleByIdProvider(booking.tourScheduleId),
                );
                return GestureDetector(
                  onTap: () => context.push(AppRoutes.booking(booking.id)),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s12),
                      child: scheduleAsync.when(
                        data: (schedule) {
                          final tourAsync = ref.watch(
                            tourByIdProvider(schedule.tourId),
                          );
                          return tourAsync.when(
                            data: (tour) => Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AppNetworkImage(
                                    url: tour.images.first,
                                    width: AppSpacing.s72,
                                    height: AppSpacing.s72,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tour.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          StatusBadge(
                                            label: booking.status.label,
                                            color: bookingStatusColor(
                                              booking.status,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.s6),
                                      Text(
                                        '${booking.bookingCode} • ${Formatters.date(schedule.startDate)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: AppFontSizes.f12,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.s4),
                                      Text(
                                        '${booking.numberOfPeople} traveler(s) • ${Formatters.currency(tour.price * booking.numberOfPeople)}',
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.f12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (booking.canPayBefore(
                                        schedule.startDate,
                                      )) ...[
                                        const SizedBox(height: AppSpacing.s8),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(
                                                0,
                                                AppSpacing.s32,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.s12,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize: AppFontSizes.f12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.payment_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Pay Now'),
                                            onPressed: () => context.push(
                                              AppRoutes.payment(booking.id),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox(
                              height: AppSpacing.s72,
                              child: LoadingWidget(),
                            ),
                            error: (e, _) => Text(e.toString()),
                          );
                        },
                        loading: () => const SizedBox(
                          height: AppSpacing.s72,
                          child: LoadingWidget(),
                        ),
                        error: (e, _) => Text(e.toString()),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
