import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_app/core/widgets/multi_image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_status.dart';
import '../providers/tour_provider.dart';
import '../../../../core/constants/app_spacing.dart';

class TourFormScreen extends ConsumerStatefulWidget {
  final Tour? tour;
  const TourFormScreen({super.key, this.tour});

  @override
  ConsumerState<TourFormScreen> createState() => _TourFormScreenState();
}

class _TourFormScreenState extends ConsumerState<TourFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationDaysController;
  late final TextEditingController _durationNightsController;
  late final TextEditingController _maxParticipantsController;
  late List<String> _images;
  String? _destinationId;
  // The API has no tour status; kept as-is so edits don't flip it.
  TourStatus _status = TourStatus.active;
  bool _submitting = false;

  bool get _isEditing => widget.tour != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tour;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _priceController = TextEditingController(
      text: t?.price.toStringAsFixed(0) ?? '',
    );
    _durationDaysController = TextEditingController(
      text: t?.durationDays.toString() ?? '',
    );
    _durationNightsController = TextEditingController(
      text: t?.durationNights.toString() ?? '',
    );
    _maxParticipantsController = TextEditingController(
      text: t?.maxParticipants.toString() ?? '',
    );
    _images = [...?t?.images];
    _destinationId = t?.destinationId;
    _status = t?.status ?? TourStatus.active;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationDaysController.dispose();
    _durationNightsController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final tour = Tour(
      id: widget.tour?.id ?? '',
      destinationId: _destinationId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationDays: int.parse(_durationDaysController.text.trim()),
      durationNights: int.parse(_durationNightsController.text.trim()),
      maxParticipants: int.parse(_maxParticipantsController.text.trim()),
      price: double.parse(_priceController.text.trim()),
      status: _status,
      // On edit, a local path replaces the server image at the same index.
      images: _images,
      createdAt: widget.tour?.createdAt ?? now,
      updatedAt: now,
    );

    final controller = ref.read(tourListControllerProvider.notifier);
    final error = _isEditing
        ? await controller.updateTour(tour)
        : await controller.createTour(tour);

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
    final destinationsAsync = ref.watch(destinationListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Tour' : 'Add Tour')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Tour Title',
              validator: (v) => Validators.required(v, label: 'Title'),
            ),
            const SizedBox(height: AppSpacing.s16),
            destinationsAsync.when(
              data: (destinations) => DropdownButtonFormField<String>(
                initialValue: destinationId(
                  destinations.map((d) => d.id).toList(),
                ),
                decoration: const InputDecoration(labelText: 'Destination'),
                items: destinations
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text('${d.name}, ${d.country}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _destinationId = v),
                validator: (v) => v == null ? 'Select a destination' : null,
              ),
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(message: e.toString()),
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _durationDaysController,
                    label: 'Days',
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.number(v, label: 'Days'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: CustomTextField(
                    controller: _durationNightsController,
                    label: 'Nights',
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.number(v, label: 'Nights'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _priceController,
                    label: 'Price (USD)',
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.number(v, label: 'Price'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: CustomTextField(
                    controller: _maxParticipantsController,
                    label: 'Max Participants',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        Validators.number(v, label: 'Max participants'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            MultiImagePickerField(
              label: 'Images',
              initialValue: _images,
              required: !_isEditing,
              // The API only accepts new images when creating.
              canAddRemove: !_isEditing,
              onChanged: (images) => _images = images,
            ),
            const SizedBox(height: AppSpacing.s16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              validator: (v) => Validators.required(v, label: 'Description'),
            ),
            const SizedBox(height: AppSpacing.s20),
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
                  : Text(_isEditing ? 'Save Changes' : 'Create Tour'),
            ),
          ],
        ),
      ),
    );
  }

  String? destinationId(List<String> validIds) =>
      validIds.contains(_destinationId) ? _destinationId : null;
}
