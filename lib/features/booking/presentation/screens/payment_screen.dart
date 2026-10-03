import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Test card the simulated gateway always declines.
const _declinedCard = '4000000000000002';

/// Resets the stack to Home and opens the booking on top of it, so Back
/// from the booking returns Home rather than to the payment form.
void openBookingFromHome(BuildContext context, String bookingId) {
  final router = GoRouter.of(context);
  router.go(AppRoutes.home);
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => router.push(AppRoutes.booking(bookingId)),
  );
}

/// Simulated credit-card checkout for a PENDING booking. Any valid card
/// pays through `POST /payments`, which confirms the booking immediately.
class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _digits => _numberController.text.replaceAll(' ', '');

  Future<void> _confirmCancel() async {
    if (_processing) return;
    final cancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel payment?'),
        content: const Text(
          'Your booking stays pending. You can pay for it from My Bookings '
          'before the tour starts.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Keep Paying'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text(
              'Cancel Payment',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (cancel == true && mounted) {
      context.go(AppRoutes.paymentFailed(widget.bookingId, cancelled: true));
    }
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);

    // Stand-in for the card network round trip.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (_digits == _declinedCard) {
      setState(() => _processing = false);
      context.go(
        AppRoutes.paymentFailed(widget.bookingId),
        extra: 'Your card was declined. Try another card.',
      );
      return;
    }

    final error = await ref
        .read(myBookingsControllerProvider.notifier)
        .payBooking(widget.bookingId);
    if (!mounted) return;
    setState(() => _processing = false);

    if (error != null) {
      context.go(AppRoutes.paymentFailed(widget.bookingId), extra: error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Your booking is confirmed.'),
        backgroundColor: AppColors.success,
      ),
    );
    openBookingFromHome(context, widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmCancel,
          ),
        ),
        body: bookingAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (booking) {
            final scheduleAsync = ref.watch(
              scheduleByIdProvider(booking.tourScheduleId),
            );
            return scheduleAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (schedule) {
                final tourAsync = ref.watch(tourByIdProvider(schedule.tourId));
                return tourAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => ErrorView(message: e.toString()),
                  data: (tour) {
                    if (!booking.canPayBefore(schedule.startDate)) {
                      return _NotPayable(booking: booking);
                    }
                    final total = tour.price * booking.numberOfPeople;
                    return _buildForm(
                      title: tour.title,
                      dates:
                          '${Formatters.date(schedule.startDate)} → ${Formatters.date(schedule.endDate)}',
                      booking: booking,
                      total: total,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm({
    required String title,
    required String dates,
    required Booking booking,
    required num total,
  }) {
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
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '${booking.bookingCode} • $dates',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.f12,
                    ),
                  ),
                  const Divider(height: AppSpacing.s20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${booking.numberOfPeople} traveler(s)',
                        style: const TextStyle(color: AppColors.textSecondary),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          AnimatedBuilder(
            animation: Listenable.merge([
              _numberController,
              _nameController,
              _expiryController,
            ]),
            builder: (context, _) => _CardPreview(
              number: _numberController.text,
              holder: _nameController.text,
              expiry: _expiryController.text,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          CustomTextField(
            controller: _numberController,
            label: 'Card Number',
            hint: '4242 4242 4242 4242',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.credit_card_rounded),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            validator: _CardValidators.number,
          ),
          const SizedBox(height: AppSpacing.s16),
          CustomTextField(
            controller: _nameController,
            label: 'Cardholder Name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            textCapitalization: TextCapitalization.characters,
            validator: (v) => _CardValidators.holder(v),
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _expiryController,
                  label: 'Expiry (MM/YY)',
                  hint: 'MM/YY',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.event_outlined),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                  validator: _CardValidators.expiry,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: CustomTextField(
                  controller: _cvvController,
                  label: 'CVV',
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: _CardValidators.cvv,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s40),
          ElevatedButton(
            onPressed: _processing ? null : _pay,
            child: _processing
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: AppSpacing.s20,
                        width: AppSpacing.s20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: AppSpacing.s12),
                      Text('Processing...'),
                    ],
                  )
                : Text('Pay ${Formatters.currency(total)}'),
          ),
          const SizedBox(height: AppSpacing.s8),
          TextButton(
            onPressed: _processing ? null : _confirmCancel,
            child: const Text(
              'Cancel Payment',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the booking was paid, cancelled, or its tour already began.
class _NotPayable extends StatelessWidget {
  final Booking booking;
  const _NotPayable({required this.booking});

  @override
  Widget build(BuildContext context) {
    final message = booking.status == BookingStatus.pending
        ? 'This tour has already started, so the booking can no longer be paid.'
        : 'This booking is ${booking.status.label.toLowerCase()} and needs no payment.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: AppSpacing.s56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s20),
            ElevatedButton(
              onPressed: () => openBookingFromHome(context, booking.id),
              child: const Text('View Booking'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  final String number;
  final String holder;
  final String expiry;
  const _CardPreview({
    required this.number,
    required this.holder,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    final digits = number.replaceAll(' ', '').padRight(16, '•');
    final grouped = [
      for (var i = 0; i < 16; i += 4) digits.substring(i, i + 4),
    ].join('  ');
    const label = TextStyle(color: Colors.white70, fontSize: AppFontSizes.f11);
    const value = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    );
    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.memory_rounded, color: Colors.white70, size: 32),
                Icon(Icons.contactless_outlined, color: Colors.white70),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                grouped,
                style: value.copyWith(fontSize: AppFontSizes.f20),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CARDHOLDER', style: label),
                      Text(
                        holder.isEmpty ? 'YOUR NAME' : holder.toUpperCase(),
                        style: value,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EXPIRES', style: label),
                    Text(expiry.isEmpty ? 'MM/YY' : expiry, style: value),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardValidators {
  _CardValidators._();

  static String? number(String? value) {
    final digits = (value ?? '').replaceAll(' ', '');
    if (digits.isEmpty) return 'Card number is required';
    if (digits.length < 13 || !_luhn(digits)) {
      return 'Enter a valid card number';
    }
    return null;
  }

  static String? holder(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Cardholder name is required';
    }
    return null;
  }

  static String? expiry(String? value) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value ?? '');
    if (match == null) return 'Use MM/YY';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    // Cards are valid through the end of their expiry month.
    if (!DateTime(year, month + 1).isAfter(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }
    return null;
  }

  static String? cvv(String? value) {
    final v = value ?? '';
    if (v.length < 3) return 'Invalid CVV';
    return null;
  }

  static bool _luhn(String digits) {
    var sum = 0;
    var doubleIt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = int.parse(digits[i]);
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }
}

/// Groups digits as `1234 5678 9012 3456`.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formats up to four digits as `MM/YY`.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text;
    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
