import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/features/booking/domain/entities/booking.dart';
import 'package:travel_app/features/booking/presentation/providers/booking_provider.dart';
import 'package:travel_app/features/booking/presentation/providers/participant_provider.dart';
import 'package:travel_app/features/booking/presentation/screens/my_bookings_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';


/// Bookings and their participants for one schedule.
/// Only ADMIN, MANAGER and GUIDE can open it (also enforced by the backend).
class ScheduleBookingsScreen extends ConsumerWidget {
  final String scheduleId;
  const ScheduleBookingsScreen({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ---- Role guard ----
    if (!ref.watch(canViewScheduleBookingsProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookings & Participants')),
        body: const EmptyView(
          message: 'You do not have permission to view this page',
          icon: Icons.lock_outline,
        ),
      );
    }

    final bookingsAsync = ref.watch(bookingsByScheduleProvider(scheduleId));
    final scheduleAsync = ref.watch(scheduleByIdProvider(scheduleId));

    Future<void> refresh() async {
      ref.invalidate(bookingsByScheduleProvider(scheduleId));
      try {
        await ref.read(bookingsByScheduleProvider(scheduleId).future);
      } catch (_) {
        // The error is shown by the screen itself.
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings & Participants')),
      body: bookingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: refresh),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyView(
              message: 'No bookings for this schedule yet',
              icon: Icons.receipt_long_outlined,
            );
          }

          final paidBookings = bookings
              .where((b) => b.status == BookingStatus.paid)
              .toList();
          final paidPeople = paidBookings.fold<int>(
            0,
            (sum, b) => sum + b.numberOfPeople,
          );

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                // ---- Summary ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (scheduleAsync.valueOrNull != null)
                          Text(
                            '${Formatters.date(scheduleAsync.valueOrNull!.startDate)} → '
                            '${Formatters.date(scheduleAsync.valueOrNull!.endDate)}',
                            style: AppTextStyles.cardTitle,
                          ),
                        const SizedBox(height: AppSpacing.s6),
                        Text(
                          '${bookings.length} bookings • '
                          '${paidBookings.length} paid • '
                          '$paidPeople confirmed travelers',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppFontSizes.f12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),

                // ---- One expandable card per booking ----
                ...bookings.map((b) => _BookingTile(booking: b)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BookingTile extends ConsumerWidget {
  final Booking booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(booking.userId));
    final customerName = userAsync.valueOrNull?.fullName ?? 'Customer';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          booking.bookingCode,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$customerName • ${booking.numberOfPeople} pax',
          style: const TextStyle(fontSize: AppFontSizes.f12),
        ),
        trailing: StatusBadge(
          label: booking.status.label,
          color: bookingStatusColor(booking.status),
        ),
        // Children are built only when the tile is expanded, so participants
        // are loaded one booking at a time.
        children: [_ParticipantsList(bookingId: booking.id)],
      ),
    );
  }
}

class _ParticipantsList extends ConsumerWidget {
  final String bookingId;
  const _ParticipantsList({required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantsByBookingProvider(bookingId));

    return participantsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: SizedBox(height: 40, child: LoadingWidget()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Text(
          e.toString(),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (participants) {
        if (participants.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: Text(
              'No participants registered yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return Column(
          children: participants.map((p) {
            final details = [
              p.gender.name,
              '${p.age} yrs',
              if (p.phone.isNotEmpty) p.phone,
              if (p.email.isNotEmpty) p.email,
            ].join(' • ');
            return ListTile(
              dense: true,
              leading: const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person_outline_rounded, size: 18),
              ),
              title: Text(
                p.isMinor ? '${p.fullName} (Minor)' : p.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                details,
                style: const TextStyle(fontSize: AppFontSizes.f12),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}