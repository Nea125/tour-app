import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_provider.dart';
import '../providers/participant_provider.dart';
import 'my_bookings_screen.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));
    final user = ref.watch(currentUserProvider);
    final canManage =
        user?.role == UserRole.ADMIN || user?.role == UserRole.MANAGER;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: bookingAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (booking) {
          final scheduleAsync = ref.watch(
            scheduleByIdProvider(booking.tourScheduleId),
          );
          final myReviewsAsync = ref.watch(myReviewsControllerProvider);
          final participantsAsync = ref.watch(
            participantsByBookingProvider(booking.id),
          );
          final alreadyReviewed =
              myReviewsAsync.valueOrNull?.any(
                (r) => r.bookingId == booking.id,
              ) ??
              false;
          final bookingUserAsync = ref.watch(userByIdProvider(booking.userId));

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(booking.bookingCode, style: AppTextStyles.screenTitle),
                  StatusBadge(
                    label: booking.status.label,
                    color: bookingStatusColor(booking.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              scheduleAsync.when(
                data: (schedule) {
                  final tourAsync = ref.watch(
                    tourByIdProvider(schedule.tourId),
                  );
                  return tourAsync.when(
                    data: (tour) => Column(
                      children: [
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              AppNetworkImage(
                                url: tour.images.first,
                                height: AppSpacing.s140,
                                width: double.infinity,
                                borderRadius: BorderRadius.zero,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.s12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tour.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: AppFontSizes.f16,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.s4),
                                    Text(
                                      '${tour.durationDays}D${tour.durationNights}N',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            child: Column(
                              children: [
                                _Row(
                                  label: 'Schedule',
                                  value:
                                      '${Formatters.date(schedule.startDate)} → ${Formatters.date(schedule.endDate)}',
                                ),
                                const Divider(height: AppSpacing.s20),
                                _Row(
                                  label: 'Travelers',
                                  value: '${booking.numberOfPeople}',
                                ),
                                const Divider(height: AppSpacing.s20),
                                _Row(
                                  label: 'Contact Phone',
                                  value:
                                      bookingUserAsync.valueOrNull?.phone ??
                                      '—',
                                ),
                                const Divider(height: AppSpacing.s20),
                                _Row(
                                  label: 'Booking Date',
                                  value: Formatters.date(booking.bookingDate),
                                ),
                                if (booking.specialRequest.isNotEmpty) ...[
                                  const Divider(height: AppSpacing.s20),
                                  _Row(
                                    label: 'Special Request',
                                    value: booking.specialRequest,
                                  ),
                                ],
                                const Divider(height: AppSpacing.s20),
                                _Row(
                                  label: 'Total Price',
                                  value: Formatters.currency(
                                    tour.price * booking.numberOfPeople,
                                  ),
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const LoadingWidget(),
                    error: (e, _) => ErrorView(message: e.toString()),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (e, _) => ErrorView(message: e.toString()),
              ),
              const SizedBox(height: AppSpacing.s20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Participants',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppFontSizes.f16,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Add'),
                    onPressed: () =>
                        context.push(AppRoutes.addParticipant(booking.id)),
                  ),
                ],
              ),
              participantsAsync.when(
                data: (participants) {
                  if (participants.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.s8),
                      child: Text(
                        'No participants added yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return Column(
                    children: participants.map((p) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: ListTile(
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(p.fullName),
                          subtitle: Text(
                            '${p.gender.label} • ${p.age} yrs • ${p.phone}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                            ),
                            onPressed: () => ref
                                .read(participantControllerProvider.notifier)
                                .removeParticipant(p.id, booking.id),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (e, _) => ErrorView(message: e.toString()),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final eligibilityAsync = ref.watch(
                    bookingEligibilityProvider(booking.id),
                  );
                  return eligibilityAsync.when(
                    data: (issue) {
                      if (issue == null) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.s8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 16,
                              ),
                              SizedBox(width: AppSpacing.s6),
                              Text(
                                'All participants registered',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: AppFontSizes.f12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 16,
                            ),
                            const SizedBox(width: AppSpacing.s6),
                            Expanded(
                              child: Text(
                                issue,
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: AppFontSizes.f12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s12),
              if (canManage) ...[
                const Text(
                  'Update Status',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BookingStatus.values.map((status) {
                    return ChoiceChip(
                      label: Text(status.label),
                      selected: booking.status == status,
                      onSelected: (_) async {
                        final error = await ref
                            .read(allBookingsControllerProvider.notifier)
                            .updateStatus(booking.id, status);
                        ref.invalidate(bookingByIdProvider(bookingId));
                        if (context.mounted && error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ] else ...[
                if (booking.status == BookingStatus.pending ||
                    booking.status == BookingStatus.confirmed)
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Cancel Booking',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel booking'),
                          content: const Text(
                            'Are you sure you want to cancel this booking?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => context.pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => context.pop(true),
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(myBookingsControllerProvider.notifier)
                            .cancelBooking(booking.id);
                        ref.invalidate(bookingByIdProvider(bookingId));
                      }
                    },
                  ),
                if (booking.status == BookingStatus.completed &&
                    !alreadyReviewed)
                  scheduleAsync.when(
                    data: (schedule) => ElevatedButton.icon(
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Write a Review'),
                      onPressed: () => context.push(
                        AppRoutes.addReview(schedule.tourId, booking.id),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                if (booking.status == BookingStatus.completed &&
                    alreadyReviewed)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.s8),
                    child: Text(
                      'You already reviewed this tour. Thank you!',
                      style: TextStyle(color: AppColors.success),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Row({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 16 : 14,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
