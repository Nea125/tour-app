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

/// Admin / manager screen: all bookings, searchable by booking ID or code
/// and filterable by status.
class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    // Restore the previous query if the user comes back to this screen.
    _searchCtrl = TextEditingController(
      text: ref.read(bookingSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String value) =>
      ref.read(bookingSearchQueryProvider.notifier).state = value.trim();

  void _clearSearch() {
    _searchCtrl.clear();
    _search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ---- Role guard: only admin and manager ----
    if (!ref.watch(canManageBookingsProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Bookings')),
        body: const EmptyView(
          message: 'You do not have permission to view this page',
          icon: Icons.lock_outline,
        ),
      );
    }

    final bookingsAsync = ref.watch(allBookingsControllerProvider);
    final statusFilter = ref.watch(bookingStatusFilterProvider);
    final searchQuery = ref.watch(bookingSearchQueryProvider);
    final usersAsync = ref.watch(userListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: Column(
        children: [
          // ---- Search by booking ID or booking code ----
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s4,
            ),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              onChanged: (v) {
                setState(() {}); // refresh the clear button
                if (v.isEmpty) _search('');
              },
              decoration: InputDecoration(
                hintText: 'Search by booking ID or code',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),

          // ---- Status filter chips ----
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
                  // (s) => Padding(
                  //   padding: const EdgeInsets.only(right: AppSpacing.s8),
                  //   child: ChoiceChip(
                  //     label: Text(s.label),
                  //     selected: statusFilter == s,
                  //     onSelected: (_) =>
                  //         ref.read(bookingStatusFilterProvider.notifier).state =
                  //             s,
                  //   ),
                  // ),
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s8),
                    child: ChoiceChip(
                      label: Text(s.label),
                      backgroundColor: switch (s.label) {
                        'Pending' => Colors.orange.shade100,
                        'Paid' => Colors.green.shade100,
                        'Cancelled' => Colors.red.shade100,
                        _ => Colors.grey.shade200,
                      },
                      selectedColor: switch (s.label) {
                        'Pending' => Colors.orange,
                        'Paid' => Colors.green,
                        'Cancelled' => Colors.red,
                        _ => Colors.blue,
                      },
                      labelStyle: TextStyle(
                        color: statusFilter == s
                            ? Colors.white
                            : Colors.black87,
                      ),
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

          // ---- Results ----
          Expanded(
            child: bookingsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(allBookingsControllerProvider.notifier).refresh(),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return EmptyView(
                    message: searchQuery.isEmpty
                        ? 'No bookings found'
                        : 'No booking matches your search',
                    icon: Icons.receipt_long_outlined,
                  );
                }
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
                                      '$customerName • #${booking.id} • ${booking.bookingCode}',
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
