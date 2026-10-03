import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/participant_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Checkout step between creating a booking and paying for it.
///
/// The purchaser is registered as the first traveler from their profile.
/// A one-person booking is then complete and goes straight to payment;
/// larger bookings collect the remaining travelers here first.
class BookingParticipantsScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingParticipantsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingParticipantsScreen> createState() =>
      _BookingParticipantsScreenState();
}

class _BookingParticipantsScreenState
    extends ConsumerState<BookingParticipantsScreen> {
  bool _preparing = true;
  String? _prepareError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    setState(() {
      _preparing = true;
      _prepareError = null;
    });
    try {
      final id = widget.bookingId;
      final booking = await ref.read(bookingByIdProvider(id).future);
      var participants = await ref.read(
        participantsByBookingProvider(id).future,
      );
      if (participants.isEmpty) {
        final error = await ref
            .read(participantControllerProvider.notifier)
            .addPurchaser(id);
        if (error != null) throw Exception(error);
        participants = await ref.read(participantsByBookingProvider(id).future);
      }
      if (!mounted) return;
      if (participants.length >= booking.numberOfPeople) {
        _continueToPayment();
        return;
      }
      setState(() => _preparing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preparing = false;
        _prepareError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _continueToPayment() =>
      context.pushReplacement(AppRoutes.payment(widget.bookingId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travelers')),
      body: _preparing
          ? const LoadingWidget()
          : _prepareError != null
          ? ErrorView(message: _prepareError!, onRetry: _prepare)
          : _buildList(),
    );
  }

  Widget _buildList() {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));
    final participantsAsync = ref.watch(
      participantsByBookingProvider(widget.bookingId),
    );
    final purchaserEmail = ref.watch(currentUserProvider)?.email;

    return bookingAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (booking) => participantsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            participantsByBookingProvider(widget.bookingId),
          ),
        ),
        data: (participants) {
          final declared = booking.numberOfPeople;
          final count = participants.length;
          final remaining = declared - count;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  children: [
                    const Text(
                      'Who is travelling?',
                      style: AppTextStyles.screenTitle,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'This booking is for $declared people. You were added '
                      'from your profile — add the other travelers to '
                      'continue.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      '$count of $declared added',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: remaining == 0
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    ...participants.map((p) {
                      final isPurchaser =
                          purchaserEmail != null &&
                          purchaserEmail.isNotEmpty &&
                          p.email == purchaserEmail;
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: ListTile(
                          leading: Icon(
                            isPurchaser
                                ? Icons.verified_user_outlined
                                : Icons.person_outline_rounded,
                            color: isPurchaser ? AppColors.primary : null,
                          ),
                          title: Text(
                            isPurchaser ? '${p.fullName} (You)' : p.fullName,
                          ),
                          subtitle: Text(
                            '${p.gender.label} • ${p.age} yrs'
                            '${p.phone.isNotEmpty ? ' • ${p.phone}' : ''}',
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
                    }),
                    if (remaining > 0)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text('Add Traveler ($remaining left)'),
                        onPressed: () =>
                            context.push(AppRoutes.addParticipant(booking.id)),
                      ),
                    if (remaining < 0)
                      Text(
                        'Too many travelers — remove ${-remaining}.',
                        style: const TextStyle(color: AppColors.error),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    AppSpacing.s8,
                    AppSpacing.s20,
                    AppSpacing.s16,
                  ),
                  child: ElevatedButton(
                    onPressed: remaining == 0 ? _continueToPayment : null,
                    child: const Text('Continue to Payment'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
