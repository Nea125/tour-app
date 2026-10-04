import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
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
          final isOwner = user?.id == booking.userId;
          // Travelers are managed during checkout only; this screen is
          // read-only for them.
          final isPending = booking.status == BookingStatus.pending;

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
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (e, _) => ErrorView(message: e.toString()),
              ),
              if (isPending)
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
              if (isOwner && isPending)
                // The backend decides whether this booking can still be paid.
                ref.watch(canPayBookingProvider(booking.id)).when(
                  data: (eligibility) => eligibility.canPay
                      ? Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s8,
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.payment_rounded),
                            label: const Text('Pay Now'),
                            // Travelers come first; that screen continues to
                            // payment once everyone is registered.
                            onPressed: () => context.push(
                              AppRoutes.bookingParticipants(booking.id),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                          child: Text(
                            eligibility.message ??
                                'This booking can no longer be paid.',
                            style: const TextStyle(color: AppColors.warning),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              if (isOwner) ...[
                if (booking.status == BookingStatus.paid &&
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
                if (booking.status == BookingStatus.paid &&
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