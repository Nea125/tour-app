import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/booking_participant.dart';
import '../providers/participant_provider.dart';


class UpdateParticipantScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String participantId;

  const UpdateParticipantScreen({
    super.key,
    required this.bookingId,
    required this.participantId,
  });

  @override
  ConsumerState<UpdateParticipantScreen> createState() =>
      _UpdateParticipantScreenState();
}

class _UpdateParticipantScreenState
    extends ConsumerState<UpdateParticipantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime _dateOfBirth = DateTime(DateTime.now().year - 25);
  Gender _gender = Gender.other;

  bool _initialised = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }


  void _fill(BookingParticipant p) {
    if (_initialised) return;
    _nameController.text = p.fullName;
    _phoneController.text = p.phone;
    _emailController.text = p.email;
    _dateOfBirth = p.dateOfBirth;
    _gender = p.gender;
    _initialised = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit(BookingParticipant original) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final updated = original.copyWith(
      fullName: _nameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    // Calls PUT /participants/{id} through the repository + datasource.
    final error = await ref
        .read(participantControllerProvider.notifier)
        .updateParticipant(updated);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Traveler updated'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(
      participantsByBookingProvider(widget.bookingId),
    );
    final currentEmail = ref.watch(currentUserProvider)?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Traveler')),
      body: participantsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            participantsByBookingProvider(widget.bookingId),
          ),
        ),
        data: (participants) {
          final matches = participants.where(
            (p) => p.id == widget.participantId,
          );
          if (matches.isEmpty) {
            return const ErrorView(message: 'Traveler not found');
          }

          final participant = matches.first;
          _fill(participant);

          // The purchaser is recognised by email on the travelers screen,
          // so their email must not change.
          final isPurchaser =
              currentEmail.isNotEmpty &&
              participant.email.trim().toLowerCase() ==
                  currentEmail.trim().toLowerCase();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s20),
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  validator: (v) => Validators.required(v, label: 'Full name'),
                ),
                const SizedBox(height: AppSpacing.s16),
                DropdownButtonFormField<Gender>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: Gender.values
                      .map(
                        (g) =>
                            DropdownMenuItem(value: g, child: Text(g.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v ?? _gender),
                ),
                const SizedBox(height: AppSpacing.s16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                    ),
                    child: Text(
                      '${_dateOfBirth.year}-'
                      '${_dateOfBirth.month.toString().padLeft(2, '0')}-'
                      '${_dateOfBirth.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: Validators.phone,
                ),
                const SizedBox(height: AppSpacing.s16),
                if (isPurchaser)
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      helperText: 'Your account email can\'t be changed here',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  )
                else
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.email,
                  ),
                const SizedBox(height: AppSpacing.s24),
                ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(participant),
                  child: _submitting
                      ? const SizedBox(
                          height: AppSpacing.s20,
                          width: AppSpacing.s20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}