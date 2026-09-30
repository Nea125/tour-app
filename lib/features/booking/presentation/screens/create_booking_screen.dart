import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../providers/booking_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

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
  final _peopleController = TextEditingController(text: '1');
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _submit(int availableSlots) async {
    if (!_formKey.currentState!.validate()) return;
    final people = int.tryParse(_peopleController.text) ?? 0;
    if (people < 1 || people > availableSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $availableSlots slot(s) available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final error = await ref
        .read(myBookingsControllerProvider.notifier)
        .createBooking(
          tourScheduleId: widget.scheduleId,
          numberOfPeople: people,
          specialRequest: _notesController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request submitted!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.bookings);
    }
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
              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  children: [
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
                              '${Formatters.date(schedule.startDate)} → ${Formatters.date(schedule.endDate)}',
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
                    CustomTextField(
                      controller: _peopleController,
                      label: 'Number of People',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.groups_outlined),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Enter a valid number';
                        if (n > availableSlots)
                          return 'Only $availableSlots slot(s) available';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    CustomTextField(
                      controller: _notesController,
                      label: 'Special Requests (optional)',
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.note_outlined),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    AnimatedBuilder(
                      animation: _peopleController,
                      builder: (context, _) {
                        final people =
                            int.tryParse(_peopleController.text) ?? 1;
                        final total = tour.price * people;
                        return Card(
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
                                  Formatters.currency(total),
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.f20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    ElevatedButton(
                      onPressed: _submitting
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
                          : const Text('Confirm Booking'),
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
