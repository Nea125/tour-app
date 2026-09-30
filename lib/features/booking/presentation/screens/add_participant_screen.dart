import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/booking_participant.dart';
import '../providers/participant_provider.dart';
import '../../../../core/constants/app_spacing.dart';

class AddParticipantScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final BookingParticipant? participant;
  const AddParticipantScreen({
    super.key,
    required this.bookingId,
    this.participant,
  });

  @override
  ConsumerState<AddParticipantScreen> createState() =>
      _AddParticipantScreenState();
}

class _AddParticipantScreenState extends ConsumerState<AddParticipantScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  DateTime _dateOfBirth = DateTime(DateTime.now().year - 25);
  Gender _gender = Gender.other;
  bool _submitting = false;

  bool get _isEditing => widget.participant != null;

  @override
  void initState() {
    super.initState();
    final p = widget.participant;
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _dateOfBirth = p?.dateOfBirth ?? _dateOfBirth;
    _gender = p?.gender ?? Gender.other;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final participant = BookingParticipant(
      id: widget.participant?.id ?? '',
      bookingId: widget.bookingId,
      fullName: _nameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    final controller = ref.read(participantControllerProvider.notifier);
    final error = _isEditing
        ? await controller.updateParticipant(participant)
        : await controller.addParticipant(participant);

    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Participant' : 'Add Participant'),
      ),
      body: Form(
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
                  .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v ?? _gender),
            ),
            const SizedBox(height: AppSpacing.s16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                child: Text(
                  '${_dateOfBirth.year}-${_dateOfBirth.month.toString().padLeft(2, '0')}-${_dateOfBirth.day.toString().padLeft(2, '0')}',
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
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.s24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: AppSpacing.s20,
                      width: AppSpacing.s20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Participant'),
            ),
          ],
        ),
      ),
    );
  }
}
