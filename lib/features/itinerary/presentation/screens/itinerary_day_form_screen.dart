import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/itinerary.dart';
import '../providers/itinerary_provider.dart';
import '../../../../core/constants/app_spacing.dart';

class ItineraryDayFormScreen extends ConsumerStatefulWidget {
  final String tourId;
  final Itinerary? day;
  const ItineraryDayFormScreen({super.key, required this.tourId, this.day});

  @override
  ConsumerState<ItineraryDayFormScreen> createState() =>
      _ItineraryDayFormScreenState();
}

class _ItineraryDayFormScreenState
    extends ConsumerState<ItineraryDayFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dayNumberController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _submitting = false;

  bool get _isEditing => widget.day != null;

  @override
  void initState() {
    super.initState();
    final d = widget.day;
    _dayNumberController = TextEditingController(
      text: d?.dayNumber.toString() ?? '',
    );
    _titleController = TextEditingController(text: d?.title ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
  }

  @override
  void dispose() {
    _dayNumberController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final now = DateTime.now();
    final day = Itinerary(
      id: widget.day?.id ?? '',
      tourId: widget.tourId,
      dayNumber: int.parse(_dayNumberController.text.trim()),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: widget.day?.createdAt ?? now,
      updatedAt: now,
    );

    final controller = ref.read(itineraryControllerProvider.notifier);
    final error = _isEditing
        ? await controller.updateDay(day)
        : await controller.addDay(day);

    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Day' : 'Add Day')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            CustomTextField(
              controller: _dayNumberController,
              label: 'Day Number',
              keyboardType: TextInputType.number,
              validator: (v) => Validators.number(v, label: 'Day number'),
            ),
            const SizedBox(height: AppSpacing.s16),
            CustomTextField(
              controller: _titleController,
              label: 'Title',
              validator: (v) => Validators.required(v, label: 'Title'),
            ),
            const SizedBox(height: AppSpacing.s16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              validator: (v) => Validators.required(v, label: 'Description'),
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
                  : Text(_isEditing ? 'Save Changes' : 'Add Day'),
            ),
          ],
        ),
      ),
    );
  }
}
