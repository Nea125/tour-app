import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/participant_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

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

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('You must be signed in');
      }

      // Check whether the purchaser is already a participant.
      final purchaserExists = participants.any(
        (p) => _sameEmail(p.email, currentUser.email),
      );

      // Add purchaser automatically if not already added.
      if (!purchaserExists) {
        final error = await ref
            .read(participantControllerProvider.notifier)
            .addPurchaser(id);

        if (error != null) {
          throw Exception(error);
        }

        participants = await ref.read(participantsByBookingProvider(id).future);
      }

      if (!mounted) return;

      // All travelers have been added.
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

  bool _sameEmail(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _continueToPayment() =>
      context.pushReplacement(AppRoutes.payment(widget.bookingId));

  void _editParticipant(String bookingId, String participantId) {
    context.push(AppRoutes.updateParticipant(bookingId, participantId));
  }

  Future<void> _removeParticipant(
    String participantId,
    String bookingId,
  ) async {
    final error = await ref
        .read(participantControllerProvider.notifier)
        .removeParticipant(participantId, bookingId);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

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
          onRetry: () {
            ref.invalidate(participantsByBookingProvider(widget.bookingId));
          },
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
                      'This booking is for $declared people. '
                      'You were added automatically from your profile. '
                      'Add the other travelers below.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: AppSpacing.s16),

                    // Participant count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$count of $declared travelers',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (remaining > 0)
                          Text(
                            '$remaining remaining',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (remaining == 0)
                          const Text(
                            'Complete',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s12),

                    // Participants
                    ...participants.map((p) {
                      final isPurchaser =
                          purchaserEmail != null &&
                          purchaserEmail.isNotEmpty &&
                          _sameEmail(p.email, purchaserEmail);

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              isPurchaser
                                  ? Icons.person
                                  : Icons.person_outline_rounded,
                            ),
                          ),
                          title: Text(
                            isPurchaser ? '${p.fullName} (You)' : p.fullName,
                          ),
                          subtitle: Text(
                            '${p.gender} • ${p.age} yrs'
                            '${p.phone.isNotEmpty ? ' • ${p.phone}' : ''}',
                          ),

                          // Tapping a traveler card opens the update screen.
                          onTap: () => _editParticipant(booking.id, p.id),

                          // Everyone can be edited; the purchaser can't be
                          // deleted (their email is locked on the update screen).
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit traveler',
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.primary,
                                ),
                                onPressed: () =>
                                    _editParticipant(booking.id, p.id),
                              ),
                              if (isPurchaser)
                                const Padding(
                                  padding: EdgeInsets.only(
                                    right: AppSpacing.s8,
                                  ),
                                  child: Icon(
                                    Icons.verified_outlined,
                                    color: AppColors.primary,
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: 'Remove traveler',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () =>
                                      _removeParticipant(p.id, booking.id),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: AppSpacing.s8),

                    // Add another traveler
                    if (remaining > 0)
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.addParticipant(booking.id));
                        },
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text('Add Traveler ($remaining left)'),
                      ),

                    if (remaining < 0) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Too many travelers. Please remove '
                        '${-remaining} traveler(s).',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom action
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    AppSpacing.s8,
                    AppSpacing.s20,
                    AppSpacing.s16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: remaining == 0 ? _continueToPayment : null,
                      icon: const Icon(Icons.payment_outlined),
                      label: const Text('Continue to Payment'),
                    ),
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
