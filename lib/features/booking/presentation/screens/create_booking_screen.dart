import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_app/core/constants/log.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../providers/booking_provider.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String scheduleId;

  const CreateBookingScreen({super.key, required this.scheduleId});

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  int _numberOfPeople = 1;
  bool _submitting = false;
  @override
  void initState() {
    super.initState();
    // Fetch available slots for the schedule when the screen is initialized.
    Future.microtask(() {
      ref.invalidate(availableSlotsProvider(widget.scheduleId));
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(int availableSlots) async {
    if (_numberOfPeople < 1 || _numberOfPeople > availableSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $availableSlots slot(s) available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final result = await ref
        .read(myBookingsControllerProvider.notifier)
        .createBooking(
          tourScheduleId: widget.scheduleId,
          numberOfPeople: _numberOfPeople,
          // specialRequest: _notesController.text.trim(),
        );

    if (!mounted) return;

    setState(() => _submitting = false);

    result.when(
      success: (booking) {
        context.pushReplacement(AppRoutes.bookingParticipants(booking.id));
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleByIdProvider(widget.scheduleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Book Tour')),
      body: scheduleAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (schedule) {
          final tourAsync = ref.watch(tourByIdProvider(schedule.tourId));

          final slotsAsync = ref.watch(availableSlotsProvider(schedule.id));

          return tourAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (tour) {
              final availableSlots = slotsAsync.valueOrNull ?? 0;
              printMe('Available slots: $availableSlots');

              // Calculate total price based on number of people.
              final totalPrice = tour.price * _numberOfPeople;

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  children: [
                    // TOUR INFORMATION
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tour.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.s4),

                            Text(
                              '${Formatters.date(schedule.startDate)} → '
                              '${Formatters.date(schedule.endDate)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppFontSizes.f12,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.s4),

                            slotsAsync.when(
                              data: (slots) => Text(
                                '$slots slot(s) available',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.f12,
                                  color: AppColors.success,
                                ),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s20),

                    // =========================
                    // NUMBER OF PEOPLE
                    // =========================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Number of People',
                          style: TextStyle(
                            fontSize: AppFontSizes.f12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.s8),

                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.groups_outlined),

                              const Spacer(),

                              // Decrement
                              IconButton(
                                onPressed: _numberOfPeople > 1
                                    ? () {
                                        setState(() {
                                          _numberOfPeople--;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),

                              // Number
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '$_numberOfPeople',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.f16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              // Increment
                              IconButton(
                                onPressed: _numberOfPeople < availableSlots
                                    ? () {
                                        setState(() {
                                          _numberOfPeople++;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.s4),

                        Text(
                          '$_numberOfPeople of '
                          '$availableSlots slot(s) selected',
                          style: const TextStyle(
                            fontSize: AppFontSizes.f12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s16),

                    // =========================
                    // TOTAL PRICE
                    // =========================
                    Card(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Price',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),

                            Text(
                              Formatters.currency(totalPrice),
                              style: const TextStyle(
                                fontSize: AppFontSizes.f20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s20),

                    // CONTINUE TO PAYMENT
                    ElevatedButton(
                      onPressed: _submitting || availableSlots < 1
                          ? null
                          : () => _submit(availableSlots),
                      child: _submitting
                          ? const SizedBox(
                              height: AppSpacing.s20,
                              width: AppSpacing.s20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continue to Payment'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
